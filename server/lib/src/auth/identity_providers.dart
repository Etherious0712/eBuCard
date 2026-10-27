// Sign in with Apple and Google: the app gets an identity token (a JWT
// signed by Apple or Google) and sends it here. This checks the signature
// against the provider's published keys and the standard claims, so the
// server knows which Apple/Google account it is.

import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:ebucard_server/src/auth/jwt_header.dart';
import 'package:ebucard_server/src/http/api_error.dart';
import 'package:http/http.dart' as http;

/// Settings for one identity provider.
class IdentityProvider {
  /// Creates provider settings.
  const IdentityProvider({
    required this.name,
    required this.issuers,
    required this.jwksUri,
    required this.clientIds,
  });

  /// Sign in with Apple, accepting tokens issued for [clientIds].
  factory IdentityProvider.apple(List<String> clientIds) => IdentityProvider(
    name: 'apple',
    issuers: const {'https://appleid.apple.com'},
    jwksUri: Uri.parse('https://appleid.apple.com/auth/keys'),
    clientIds: clientIds.toSet(),
  );

  /// Google sign-in, accepting tokens issued for [clientIds].
  factory IdentityProvider.google(List<String> clientIds) => IdentityProvider(
    name: 'google',
    issuers: const {'https://accounts.google.com', 'accounts.google.com'},
    jwksUri: Uri.parse('https://www.googleapis.com/oauth2/v3/certs'),
    clientIds: clientIds.toSet(),
  );

  /// Short name: `apple` or `google`.
  final String name;

  /// Accepted `iss` values.
  final Set<String> issuers;

  /// Where the provider publishes its signing keys.
  final Uri jwksUri;

  /// Accepted `aud` values (our app / OAuth client ids). Empty = disabled.
  final Set<String> clientIds;
}

/// Who signed in, according to a verified identity token.
class VerifiedIdentity {
  /// Creates an identity.
  const VerifiedIdentity({
    required this.subject,
    this.email,
    this.emailVerified = false,
  });

  /// The provider's stable user id (`sub`).
  final String subject;

  /// Email address, if the provider shared one. For Apple this may be a
  /// private relay address.
  final String? email;

  /// Whether the provider says the email is verified.
  final bool emailVerified;
}

/// Verifies identity tokens for one [provider].
class IdentityTokenVerifier {
  /// Creates a verifier. [now] can be replaced in tests.
  IdentityTokenVerifier(this.provider, this.client, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Which provider this verifies.
  final IdentityProvider provider;

  /// HTTP client for fetching keys.
  final http.Client client;

  final DateTime Function() _now;
  Map<String, JWTKey> _keys = {};
  DateTime? _keysFetchedAt;

  /// Clock skew tolerated for `exp`/`iat`.
  static const _leeway = Duration(minutes: 1);

  /// Checks [token] and returns who it belongs to. Throws a 401
  /// `invalid_identity_token` for anything wrong with it, or a 404
  /// `provider_not_configured` if this provider has no client ids.
  Future<VerifiedIdentity> verify(String token) async {
    if (provider.clientIds.isEmpty) {
      throw const ApiException(404, 'provider_not_configured');
    }
    const invalid = ApiException.unauthorized('invalid_identity_token');

    final header = jwtHeader(token);
    final kid = header?['kid'];
    if (header?['alg'] != 'RS256' || kid is! String) throw invalid;
    final key = await _key(kid);
    if (key == null) throw invalid;

    final Map<String, dynamic> claims;
    try {
      // Claims are checked below, with leeway and multiple issuers.
      claims =
          JWT
                  .verify(
                    token,
                    key,
                    checkHeaderType: false,
                    checkExpiresIn: false,
                    checkNotBefore: false,
                  )
                  .payload
              as Map<String, dynamic>;
    } on Object {
      throw invalid;
    }

    final now = _now();
    final exp = claims['exp'];
    if (exp is! num ||
        now
            .subtract(_leeway)
            .isAfter(
              DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000),
            )) {
      throw invalid;
    }
    if (!provider.issuers.contains(claims['iss'])) throw invalid;
    final aud = claims['aud'];
    final audiences = aud is List ? aud.cast<Object?>() : [aud];
    if (!audiences.any(provider.clientIds.contains)) throw invalid;
    final sub = claims['sub'];
    if (sub is! String || sub.isEmpty) throw invalid;

    final email = claims['email'];
    final verified = claims['email_verified'];
    return VerifiedIdentity(
      subject: sub,
      email: email is String ? email.toLowerCase() : null,
      // Apple sends "true" as a string, Google as a boolean.
      emailVerified: verified == true || verified == 'true',
    );
  }

  /// The signing key [kid], fetching the key set when it is unknown or
  /// more than an hour old (providers rotate keys).
  Future<JWTKey?> _key(String kid) async {
    final fetchedAt = _keysFetchedAt;
    final stale =
        fetchedAt == null ||
        _now().difference(fetchedAt) > const Duration(hours: 1);
    if (stale || !_keys.containsKey(kid)) await _fetchKeys();
    return _keys[kid];
  }

  /// Downloads the provider's JSON Web Key Set.
  Future<void> _fetchKeys() async {
    try {
      final response = await client
          .get(provider.jwksUri)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return;
      final keys = (jsonDecode(response.body) as Map)['keys'] as List;
      _keys = {
        for (final k in keys.cast<Map<String, dynamic>>())
          if (k['kid'] is String && k['kty'] == 'RSA')
            k['kid'] as String: JWTKey.fromJWK(k),
      };
      _keysFetchedAt = _now();
    } on Object {
      // Keep the old keys; the token is rejected if its key is unknown.
    }
  }
}
