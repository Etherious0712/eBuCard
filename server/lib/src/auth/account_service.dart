// Everything about accounts: register, sign in (password, Apple, Google),
// refresh, sign out, email confirmation, password reset and deletion.
// Routes stay thin and call this; it throws ApiException for the client.

import 'package:ebucard_models/ebucard_models.dart' show isValidEmail;
import 'package:ebucard_server/src/auth/access_tokens.dart';
import 'package:ebucard_server/src/auth/email_tokens.dart';
import 'package:ebucard_server/src/auth/identity_providers.dart';
import 'package:ebucard_server/src/auth/passwords.dart';
import 'package:ebucard_server/src/auth/sessions.dart';
import 'package:ebucard_server/src/auth/users.dart';
import 'package:ebucard_server/src/email/email_sender.dart';
import 'package:ebucard_server/src/email/server_strings.dart';
import 'package:ebucard_server/src/http/api_error.dart';
import 'package:postgres/postgres.dart';

/// What a successful sign-in returns to the app.
class SignInResult {
  /// Creates the result.
  const SignInResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  /// The account.
  final User user;

  /// Short-lived access token for API calls.
  final String accessToken;

  /// Long-lived token for getting new access tokens.
  final String refreshToken;

  /// JSON response body.
  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresIn': AccessTokens.lifetime.inSeconds,
    'account': user.toJson(),
  };
}

/// Account rules and flows.
class AccountService {
  /// Creates the service from its parts.
  AccountService({
    required this.db,
    required this.users,
    required this.sessions,
    required this.emailTokens,
    required this.accessTokens,
    required this.passwords,
    required this.breaches,
    required this.email,
    required this.publicBaseUrl,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Database pool, for transactions.
  final Pool<void> db;

  /// Users table.
  final Users users;

  /// Refresh tokens.
  final Sessions sessions;

  /// Email link tokens.
  final EmailTokens emailTokens;

  /// Access tokens.
  final AccessTokens accessTokens;

  /// Password hashing.
  final PasswordHasher passwords;

  /// Breach check for new passwords.
  final BreachChecker breaches;

  /// Outgoing email.
  final EmailSender email;

  /// Base of links in emails.
  final Uri publicBaseUrl;

  final DateTime Function() _now;

  /// How long a deleted account can still be restored by signing in.
  static const deletionGrace = Duration(days: 30);

  /// A real-looking hash, verified when the email is unknown so a failed
  /// sign-in takes the same time whether or not the account exists.
  String? _dummyHash;

  /// Creates an email/password account, sends the confirmation email and
  /// signs the new user in. Sync stays off until the email is confirmed.
  Future<SignInResult> register({
    required String emailAddress,
    required String password,
    required ServerLocale locale,
  }) async {
    final address = emailAddress.trim().toLowerCase();
    if (!isValidEmail(address)) {
      throw const ApiException.badRequest('invalid_email');
    }
    await _checkPassword(password);
    if (await users.byEmail(address) != null) {
      throw const ApiException.conflict('email_taken');
    }
    final User user;
    try {
      user = await users.create(
        email: address,
        passwordHash: await passwords.hash(password),
      );
    } on UniqueViolationException {
      // Registered at the same moment by another request.
      throw const ApiException.conflict('email_taken');
    }
    await sendVerificationEmail(user, locale);
    return _signIn(user);
  }

  /// Signs in with email and password. Signing in during the deletion grace
  /// period cancels the deletion.
  Future<SignInResult> login({
    required String emailAddress,
    required String password,
  }) async {
    final user = await users.byEmail(emailAddress);
    final hash = user?.passwordHash;
    if (user == null || hash == null) {
      _dummyHash ??= await passwords.hash('not-a-real-password');
      await passwords.verify(password, _dummyHash!);
      throw const ApiException.unauthorized('invalid_credentials');
    }
    if (!await passwords.verify(password, hash)) {
      throw const ApiException.unauthorized('invalid_credentials');
    }
    return _signIn(user);
  }

  /// Signs in with an Apple or Google identity that was already verified.
  ///
  /// Finds the account by provider id; otherwise links it to an account
  /// with the same confirmed email; otherwise creates a new account.
  Future<SignInResult> signInWithProvider(
    IdentityProvider provider,
    VerifiedIdentity identity,
  ) async {
    final isApple = provider.name == 'apple';
    final user = await db.runTx((tx) async {
      final existing = isApple
          ? await users.byAppleSub(identity.subject, tx: tx)
          : await users.byGoogleSub(identity.subject, tx: tx);
      if (existing != null) return existing;

      final email = identity.emailVerified ? identity.email : null;
      final sameEmail = email == null
          ? null
          : await users.byEmail(email, tx: tx);
      if (sameEmail != null) {
        if (sameEmail.emailVerifiedAt == null) {
          // Someone registered this address without confirming it. The
          // provider proves who owns it, so that unconfirmed password (and
          // any session made with it) must not keep access.
          await users.update(sameEmail.id, clearPassword: true, tx: tx);
          await sessions.revokeAll(sameEmail.id, tx: tx);
        }
        await users.update(
          sameEmail.id,
          appleSub: isApple ? identity.subject : null,
          googleSub: isApple ? null : identity.subject,
          emailVerifiedAt: _now(),
          tx: tx,
        );
        return (await users.byId(sameEmail.id, tx: tx))!;
      }
      return users.create(
        email: email,
        appleSub: isApple ? identity.subject : null,
        googleSub: isApple ? null : identity.subject,
        emailVerifiedAt: email == null ? null : _now(),
        tx: tx,
      );
    });
    return _signIn(user);
  }

  /// New access and refresh tokens for a refresh token (see [Sessions]).
  Future<SignInResult> refresh(String refreshToken) async {
    final rotated = await sessions.rotate(refreshToken);
    final user = await users.byId(rotated.userId);
    if (user == null || user.deactivatedAt != null) {
      throw const ApiException.unauthorized('invalid_refresh_token');
    }
    return SignInResult(
      user: user,
      accessToken: accessTokens.issue(user.id),
      refreshToken: rotated.refreshToken,
    );
  }

  /// Signs out the session of [refreshToken].
  Future<void> logout(String refreshToken) => sessions.revoke(refreshToken);

  /// Sends (or re-sends) the "confirm your email" email.
  Future<void> sendVerificationEmail(User user, ServerLocale locale) async {
    final address = user.email;
    if (address == null || user.emailVerifiedAt != null) return;
    final token = await emailTokens.create(user.id, EmailTokenPurpose.verify);
    final strings = ServerStrings.of(locale);
    await email.send(
      to: address,
      subject: strings.verifySubject,
      body: strings.verifyBody(_link('/email/verify', token)),
    );
  }

  /// Confirms the email of the token's user. False if the link is invalid.
  Future<bool> verifyEmail(String token) async {
    final userId = await emailTokens.redeem(token, EmailTokenPurpose.verify);
    if (userId == null) return false;
    await users.update(userId, emailVerifiedAt: _now());
    return true;
  }

  /// Sends a password-reset email if an account has [emailAddress].
  /// Always succeeds, so the response doesn't reveal which emails exist.
  Future<void> requestPasswordReset(
    String emailAddress,
    ServerLocale locale,
  ) async {
    final user = await users.byEmail(emailAddress);
    if (user == null || user.email == null) return;
    final token = await emailTokens.create(user.id, EmailTokenPurpose.reset);
    final strings = ServerStrings.of(locale);
    await email.send(
      to: user.email!,
      subject: strings.resetSubject,
      body: strings.resetBody(_link('/password/reset', token)),
    );
  }

  /// Sets a new password from a reset link. Returns the problem with the
  /// password, or null on success. Throws a 400 `invalid_link` if the link
  /// is expired or used. All the user's sessions are ended.
  Future<PasswordProblem?> resetPassword(String token, String password) async {
    final problem = await checkNewPassword(password, breaches);
    if (problem != null) return problem;
    final userId = await emailTokens.redeem(token, EmailTokenPurpose.reset);
    if (userId == null) throw const ApiException.badRequest('invalid_link');
    await users.update(
      userId,
      passwordHash: await passwords.hash(password),
      // Opening the emailed link proves the address belongs to them.
      emailVerifiedAt: _now(),
    );
    await sessions.revokeAll(userId);
    return null;
  }

  /// Starts deletion of [userId]: signs out everywhere; data is erased after
  /// [deletionGrace] unless the user signs in again before then.
  Future<void> requestDeletion(String userId) async {
    await users.deactivate(userId, _now(), deletionGrace);
    await sessions.revokeAll(userId);
  }

  /// Throws a 400 explaining why [password] isn't allowed.
  Future<void> _checkPassword(String password) async {
    final problem = await checkNewPassword(password, breaches);
    if (problem != null) {
      throw ApiException.badRequest(switch (problem) {
        PasswordProblem.tooShort => 'password_too_short',
        PasswordProblem.tooLong => 'password_too_long',
        PasswordProblem.breached => 'password_breached',
      });
    }
  }

  /// Issues tokens for [user], cancelling a pending deletion first.
  Future<SignInResult> _signIn(User user) async {
    var current = user;
    if (user.deactivatedAt != null) {
      await users.reactivate(user.id);
      current = (await users.byId(user.id))!;
    }
    return SignInResult(
      user: current,
      accessToken: accessTokens.issue(current.id),
      refreshToken: await sessions.issue(current.id),
    );
  }

  /// `https://<server>/<path>?token=<token>`.
  String _link(String path, String token) => publicBaseUrl
      .replace(path: path, queryParameters: {'token': token})
      .toString();
}
