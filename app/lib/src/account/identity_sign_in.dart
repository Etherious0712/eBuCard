// Gets an identity token from Apple or Google on the phone. The token is
// then sent to the server (POST /v1/auth/apple or /google), which checks it.
//
// Both buttons stay hidden until configured (see AppConfig): Apple needs
// the Sign in with Apple capability in Xcode, Google needs OAuth client
// IDs. Apple is offered on iPhone only, as App Store rules expect.

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../core/config.dart';

/// Which provider.
enum IdentityProviderKind {
  /// Sign in with Apple.
  apple,

  /// Google sign-in.
  google,
}

/// Gets identity tokens from Apple/Google. Tests replace it with a fake.
abstract class IdentitySignIn {
  /// Providers to show buttons for on this phone.
  Set<IdentityProviderKind> get available;

  /// Asks the user to sign in with [provider]; returns the identity token,
  /// or null if they cancelled.
  Future<String?> identityToken(IdentityProviderKind provider);
}

/// The real [IdentitySignIn] using the platform sign-in sheets.
class DeviceIdentitySignIn implements IdentitySignIn {
  bool _googleReady = false;

  @override
  Set<IdentityProviderKind> get available => {
    if (AppConfig.appleSignInEnabled &&
        defaultTargetPlatform == TargetPlatform.iOS)
      IdentityProviderKind.apple,
    if (AppConfig.googleServerClientId.isNotEmpty) IdentityProviderKind.google,
  };

  @override
  Future<String?> identityToken(IdentityProviderKind provider) async {
    switch (provider) {
      case IdentityProviderKind.apple:
        try {
          final credential = await SignInWithApple.getAppleIDCredential(
            scopes: [AppleIDAuthorizationScopes.email],
          );
          return credential.identityToken;
        } on SignInWithAppleAuthorizationException catch (e) {
          if (e.code == AuthorizationErrorCode.canceled) return null;
          rethrow;
        }
      case IdentityProviderKind.google:
        final google = GoogleSignIn.instance;
        if (!_googleReady) {
          await google.initialize(
            serverClientId: AppConfig.googleServerClientId,
          );
          _googleReady = true;
        }
        try {
          final account = await google.authenticate();
          return account.authentication.idToken;
        } on GoogleSignInException catch (e) {
          if (e.code == GoogleSignInExceptionCode.canceled) return null;
          rethrow;
        }
    }
  }
}
