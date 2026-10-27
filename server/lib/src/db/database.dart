// PostgreSQL access: a connection pool plus the migration runner.

import 'package:ebucard_server/src/config.dart';
import 'package:ebucard_server/src/db/migrations.dart';
import 'package:postgres/postgres.dart';

/// The server's PostgreSQL connection pool.
class Database {
  Database._(this.pool);

  /// Opens a pool for [config]. Connections are made lazily.
  factory Database.connect(DatabaseConfig config) {
    final socket = config.unixSocket;
    final endpoint = Endpoint(
      host: socket ?? config.host,
      port: config.port,
      database: config.name,
      username: config.user,
      password: config.password,
      isUnixSocket: socket != null,
    );
    return Database._(
      Pool.withEndpoints(
        [endpoint],
        settings: PoolSettings(
          maxConnectionCount: 10,
          sslMode: config.requireSsl ? SslMode.require : SslMode.disable,
        ),
      ),
    );
  }

  /// The pool; use `pool.execute` or `pool.runTx`.
  final Pool<void> pool;

  /// Applies migrations not yet recorded in `schema_migrations`.
  ///
  /// Uses an advisory lock so several Cloud Run instances starting at once
  /// don't migrate concurrently.
  Future<void> migrate() => pool.runTx((tx) async {
    await tx.execute('SELECT pg_advisory_xact_lock(727274)');
    await tx.execute(
      'CREATE TABLE IF NOT EXISTS schema_migrations (version INTEGER '
      'PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT now())',
    );
    final rows = await tx.execute(
      'SELECT COALESCE(MAX(version), 0) FROM schema_migrations',
    );
    final current = rows.first.first! as int;
    for (var v = current + 1; v <= migrations.length; v++) {
      await tx.execute(migrations[v - 1], queryMode: QueryMode.simple);
      await tx.execute(
        Sql.named('INSERT INTO schema_migrations (version) VALUES (@v)'),
        parameters: {'v': v},
      );
    }
  });

  /// Closes all connections.
  Future<void> close() => pool.close();
}
