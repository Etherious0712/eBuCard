/// Build-time configuration, supplied with `--dart-define`.
class AppConfig {
  const AppConfig._();

  /// Base URL of the eBuCard server, which also hosts public cards at
  /// `/c/<slug>`. The production domain has not been chosen yet.
  static final Uri apiBaseUrl = Uri.parse(
    const String.fromEnvironment(
      'EBUCARD_API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    ),
  );

  /// Google sign-in "server client ID" (the web OAuth client the server
  /// accepts in GOOGLE_CLIENT_IDS). Empty hides the Google button.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// Whether Sign in with Apple is set up (the iOS capability is enabled
  /// and the server has APPLE_CLIENT_IDS). Off hides the Apple button.
  static const appleSignInEnabled = bool.fromEnvironment('APPLE_SIGN_IN');
}
