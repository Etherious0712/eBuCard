// Server settings, read from environment variables so the same build runs
// locally, in tests and on Google Cloud Run. See server/README.md for the
// full list and example values.

/// All settings the server needs.
class Config {
  /// Creates a config; use [Config.fromEnvironment] in the app.
  const Config({
    required this.publicBaseUrl,
    required this.database,
    required this.jwtSecret,
    this.smtp,
    this.storage,
    this.appleClientIds = const [],
    this.googleClientIds = const [],
    this.breachCheckEnabled = true,
  });

  /// Reads settings from [env] (normally `Platform.environment`).
  ///
  /// Throws [ConfigException] naming every missing required variable.
  factory Config.fromEnvironment(Map<String, String> env) {
    final missing = <String>[];
    String required(String key) {
      final value = env[key];
      if (value == null || value.isEmpty) missing.add(key);
      return value ?? '';
    }

    List<String> list(String key) => (env[key] ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final config = Config(
      publicBaseUrl: Uri.parse(
        env['PUBLIC_BASE_URL'] ?? 'https://api.example.com',
      ),
      database: DatabaseConfig(
        host: env['DB_HOST'] ?? 'localhost',
        port: int.parse(env['DB_PORT'] ?? '5432'),
        name: env['DB_NAME'] ?? 'ebucard',
        user: env['DB_USER'] ?? 'ebucard',
        password: env['DB_PASSWORD'] ?? '',
        unixSocket: env['DB_SOCKET'],
        requireSsl: env['DB_SSL'] == 'true',
      ),
      jwtSecret: required('JWT_SECRET'),
      smtp: env['SMTP_HOST'] == null
          ? null
          : SmtpConfig(
              host: env['SMTP_HOST']!,
              port: int.parse(env['SMTP_PORT'] ?? '587'),
              username: env['SMTP_USERNAME'] ?? '',
              password: env['SMTP_PASSWORD'] ?? '',
              from: required('SMTP_FROM'),
              ssl: env['SMTP_SSL'] == 'true',
            ),
      storage: env['S3_BUCKET'] == null
          ? null
          : StorageConfig(
              endpoint: Uri.parse(
                env['S3_ENDPOINT'] ?? 'https://storage.googleapis.com',
              ),
              region: env['S3_REGION'] ?? 'auto',
              bucket: env['S3_BUCKET']!,
              accessKey: required('S3_ACCESS_KEY'),
              secretKey: required('S3_SECRET_KEY'),
              pathStyle: env['S3_PATH_STYLE'] != 'false',
            ),
      appleClientIds: list('APPLE_CLIENT_IDS'),
      googleClientIds: list('GOOGLE_CLIENT_IDS'),
      breachCheckEnabled: env['BREACH_CHECK'] != 'false',
    );
    if (missing.isNotEmpty) throw ConfigException(missing);
    if (config.jwtSecret.length < 32) {
      throw const ConfigException(['JWT_SECRET (at least 32 characters)']);
    }
    return config;
  }

  /// Public address of this server, used in emails and card links.
  /// Placeholder until the production domain is chosen.
  final Uri publicBaseUrl;

  /// PostgreSQL connection.
  final DatabaseConfig database;

  /// Secret for signing access tokens (HS256). Keep it in Secret Manager.
  final String jwtSecret;

  /// Outgoing email; null logs emails instead of sending (development).
  final SmtpConfig? smtp;

  /// Image storage; null stores images in memory (development and tests).
  final StorageConfig? storage;

  /// Accepted `aud` values for Sign in with Apple (iOS bundle id, and the
  /// Services ID if web/Android sign-in is used).
  final List<String> appleClientIds;

  /// Accepted `aud` values for Google sign-in (OAuth client IDs).
  final List<String> googleClientIds;

  /// Whether new passwords are checked against known data breaches.
  final bool breachCheckEnabled;
}

/// PostgreSQL connection settings.
class DatabaseConfig {
  /// Creates database settings.
  const DatabaseConfig({
    required this.host,
    required this.port,
    required this.name,
    required this.user,
    required this.password,
    this.unixSocket,
    this.requireSsl = false,
  });

  /// Host name (ignored when [unixSocket] is set).
  final String host;

  /// TCP port.
  final int port;

  /// Database name.
  final String name;

  /// Database user.
  final String user;

  /// Database password.
  final String password;

  /// Unix socket path, e.g. `/cloudsql/<project>:<region>:<instance>/.s.PGSQL.5432`
  /// on Cloud Run with a Cloud SQL connection.
  final String? unixSocket;

  /// Require TLS for TCP connections.
  final bool requireSsl;
}

/// SMTP settings for verification and password-reset emails.
class SmtpConfig {
  /// Creates SMTP settings.
  const SmtpConfig({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.from,
    this.ssl = false,
  });

  /// SMTP server host.
  final String host;

  /// SMTP port (587 with STARTTLS, 465 with [ssl]).
  final int port;

  /// SMTP user name.
  final String username;

  /// SMTP password.
  final String password;

  /// Sender address, e.g. `eBuCard <no-reply@example.com>`.
  final String from;

  /// Use implicit TLS (port 465) instead of STARTTLS.
  final bool ssl;
}

/// S3-compatible object storage (Google Cloud Storage via its XML API with
/// HMAC keys, AWS S3, Cloudflare R2, MinIO, ...).
class StorageConfig {
  /// Creates storage settings.
  const StorageConfig({
    required this.endpoint,
    required this.region,
    required this.bucket,
    required this.accessKey,
    required this.secretKey,
    this.pathStyle = true,
  });

  /// Service endpoint, e.g. `https://storage.googleapis.com`.
  final Uri endpoint;

  /// Signing region; `auto` works for Google Cloud Storage and R2.
  final String region;

  /// Bucket name.
  final String bucket;

  /// HMAC access key id.
  final String accessKey;

  /// HMAC secret.
  final String secretKey;

  /// `https://endpoint/bucket/key` (true) or `https://bucket.endpoint/key`.
  final bool pathStyle;
}

/// Thrown when required settings are missing or invalid.
class ConfigException implements Exception {
  /// Creates the exception listing [missing] settings.
  const ConfigException(this.missing);

  /// Names of the missing or invalid settings.
  final List<String> missing;

  @override
  String toString() => 'Missing or invalid settings: ${missing.join(', ')}';
}
