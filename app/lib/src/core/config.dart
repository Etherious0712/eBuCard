import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build-time configuration, supplied with `--dart-define`.
class AppConfig {
  const AppConfig._();

  /// Whether the cloud features are on: accounts, sync, server card links
  /// and Check for updates. Off by default: the app works without any
  /// server (DESIGN.md §2, "Serverless mode"). Turn on with
  /// `--dart-define=EBUCARD_CLOUD=true` once a server is deployed. Screens
  /// read it through `cloudEnabledProvider`, so tests can switch it.
  static const cloudEnabled = bool.fromEnvironment('EBUCARD_CLOUD');

  /// The static web card page that opens offline card links
  /// (web/c/ on GitHub Pages). It only displays what is in the link.
  static final Uri webCardUrl = Uri.parse(
    const String.fromEnvironment(
      'EBUCARD_WEB_CARD_URL',
      defaultValue: 'https://etherious0712.github.io/eBuCard/c/',
    ),
  );

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

/// Whether the cloud features are on (see [AppConfig.cloudEnabled]).
/// Overridden in tests.
final cloudEnabledProvider = Provider<bool>((_) => AppConfig.cloudEnabled);
