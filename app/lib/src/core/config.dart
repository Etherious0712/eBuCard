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
}
