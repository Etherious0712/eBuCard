// The signed-in state of the app and every account action: register, sign
// in (email, Apple, Google), sign out, delete the account, email
// confirmation and password reset.
//
// Rules (DESIGN.md §2):
// * Signing in is optional; everything works offline without an account.
// * The first sign-in on a phone merges its cards and Inbox into the
//   account. If the phone's data belongs to another account, it is cleared
//   first, so accounts never mix.
// * Signing out (and deleting the account) removes the account's data from
//   the phone; it stays safe in the account.
// * If the session expires (90 days unused, or ended elsewhere) the data
//   stays until someone signs in again.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../sync/sync_controller.dart';
import 'account.dart';
import 'account_providers.dart';
import 'api_client.dart';
import 'identity_sign_in.dart';
import 'session_store.dart';

/// Holds the signed-in [Account], or null when signed out.
class AuthController extends AsyncNotifier<Account?> {
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  Future<Account?> build() async {
    final stored = await ref.read(sessionStoreProvider).load();
    return stored?.account;
  }

  /// Creates an email/password account and signs in. Sync starts once the
  /// email is confirmed. Throws [ApiError] (e.g. `email_taken`).
  Future<void> register(String email, String password) async => _signedIn(
    SignedIn.fromJson(
      await _api.postPublic('/v1/auth/register', {
        'email': email.trim(),
        'password': password,
      }),
    ),
  );

  /// Signs in with email and password. Throws [ApiError]
  /// (`invalid_credentials`, `too_many_requests`, `network`).
  Future<void> signIn(String email, String password) async => _signedIn(
    SignedIn.fromJson(
      await _api.postPublic('/v1/auth/login', {
        'email': email.trim(),
        'password': password,
      }),
    ),
  );

  /// Signs in with Apple or Google. Returns false if the user cancelled.
  Future<bool> signInWith(IdentityProviderKind provider) async {
    final token = await ref
        .read(identitySignInProvider)
        .identityToken(provider);
    if (token == null) return false;
    await _signedIn(
      SignedIn.fromJson(
        await _api.postPublic('/v1/auth/${provider.name}', {
          'identityToken': token,
        }),
      ),
    );
    return true;
  }

  /// Emails a password-reset link (the server always accepts).
  Future<void> requestPasswordReset(String email) =>
      _api.postPublic('/v1/auth/password_reset', {'email': email.trim()});

  /// Sends the confirmation email again.
  Future<void> resendVerification() =>
      _api.authed('POST', '/v1/auth/resend_verification');

  /// Reloads the account (e.g. after the email was confirmed).
  Future<Account?> refreshAccount() async {
    if (state.value == null) return null;
    final account = Account.fromJson(await _api.authed('GET', '/v1/account'));
    final stored = await ref.read(sessionStoreProvider).load();
    if (stored != null) {
      await _api.sessions.save(StoredSession(stored.refreshToken, account));
    }
    state = AsyncData(account);
    return account;
  }

  /// Signs out: ends the session on the server (best effort) and removes
  /// the account's data from this phone.
  Future<void> signOut() async {
    final stored = await ref.read(sessionStoreProvider).load();
    if (stored != null) {
      try {
        await _api.postPublic('/v1/auth/logout', {
          'refreshToken': stored.refreshToken,
        });
      } on ApiError {
        // Offline: the session will expire on its own.
      }
    }
    await _forgetEverything();
  }

  /// Asks the server to delete the account (erased after 30 days unless
  /// the user signs in again), then clears this phone like [signOut].
  Future<void> deleteAccount() async {
    await _api.authed('DELETE', '/v1/account');
    await _forgetEverything();
  }

  /// Whether the last sign-out happened because the session expired, so
  /// the sign-in form can say why.
  bool sessionWasExpired = false;

  /// Called by the API client when the session can't be renewed. The data
  /// stays on the phone until someone signs in again.
  void sessionExpired() {
    sessionWasExpired = true;
    state = const AsyncData(null);
  }

  /// Starts the session, makes sure accounts never mix, then syncs.
  Future<void> _signedIn(SignedIn signedIn) async {
    await _api.startSession(signedIn);
    final syncState = ref.read(localSyncStateProvider);
    final previous = await syncState.accountId();
    if (previous != null && previous != signedIn.account.id) {
      await _clearLocalData();
    }
    await syncState.setAccountId(signedIn.account.id);
    sessionWasExpired = false;
    state = AsyncData(signedIn.account);
    ref.read(syncControllerProvider.notifier).requestSync();
  }

  /// Ends the session and clears this phone's account data.
  Future<void> _forgetEverything() async {
    await _api.endSession();
    await _clearLocalData();
    state = const AsyncData(null);
  }

  /// Removes cards, Inbox, sync state and images from this phone.
  Future<void> _clearLocalData() async {
    await ref.read(appDatabaseProvider).clearAccountData();
    await ref.read(cardImageServiceProvider).deleteAll();
  }
}
