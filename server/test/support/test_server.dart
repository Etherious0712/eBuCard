// Test harness for the server: a real PostgreSQL database (wiped before
// each test), fakes for email, image storage, the breach check and the
// clock, and helpers to call route handlers the way Dart Frog does.
//
// Needs a PostgreSQL the tests may wipe. The defaults match
// `docker compose up -d` (database ebucard_test on localhost:5432); set
// TEST_DB_HOST/PORT/NAME/USER/PASSWORD to use another one. Without a
// database, the database tests are skipped (not failed).

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/auth/passwords.dart';
import 'package:ebucard_server/src/config.dart';
import 'package:ebucard_server/src/db/database.dart';
import 'package:ebucard_server/src/email/email_sender.dart';
import 'package:ebucard_server/src/http/api_error.dart';
import 'package:ebucard_server/src/services.dart';
import 'package:ebucard_server/src/storage/image_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgres/postgres.dart';

/// Connection settings for the test database.
DatabaseConfig testDatabaseConfig() {
  final env = Platform.environment;
  return DatabaseConfig(
    host: env['TEST_DB_HOST'] ?? '127.0.0.1',
    port: int.parse(env['TEST_DB_PORT'] ?? '5432'),
    name: env['TEST_DB_NAME'] ?? 'ebucard_test',
    user: env['TEST_DB_USER'] ?? 'ebucard',
    password: env['TEST_DB_PASSWORD'] ?? 'ebucard_dev',
  );
}

/// Null if the test database is reachable, otherwise a reason to skip.
Future<String?> skipWithoutDatabase() async {
  final db = Database.connect(testDatabaseConfig());
  try {
    await db.pool.execute('SELECT 1');
    return null;
  } on Object catch (e) {
    return 'No test database (${e.runtimeType}); see server/README.md';
  } finally {
    await db.close();
  }
}

/// Records emails instead of sending them.
class MemoryEmailSender implements EmailSender {
  /// Sent emails, oldest first.
  final sent = <({String to, String subject, String body})>[];

  @override
  Future<void> send({
    required String to,
    required String subject,
    required String body,
  }) async => sent.add((to: to, subject: subject, body: body));

  /// The `token` query parameter of the link in the last email to [to].
  String lastToken(String to) {
    final body = sent.lastWhere((e) => e.to == to).body;
    final link = RegExp(r'https?://\S+').firstMatch(body)!.group(0)!;
    return Uri.parse(link).queryParameters['token']!;
  }
}

/// Breach checker that reports only the passwords in [breached].
class FakeBreachChecker implements BreachChecker {
  /// Passwords to report as breached.
  final breached = <String>{'password123'};

  @override
  Future<bool> isBreached(String password) async => breached.contains(password);
}

/// A server wired to the test database with fakes. Create one per test
/// with [TestServer.start] and [close] it in `tearDown`.
class TestServer {
  TestServer._(this.services, this.email, this.storage, this.breaches);

  /// Wipes the test database, applies migrations and builds services.
  /// [jwks] is served for Apple's and Google's key URLs.
  static Future<TestServer> start({Map<String, Object?>? jwks}) async {
    final database = Database.connect(testDatabaseConfig());
    await database.pool.execute(
      'DROP SCHEMA public CASCADE; CREATE SCHEMA public;',
      queryMode: QueryMode.simple,
    );
    await database.migrate();
    final email = MemoryEmailSender();
    final storage = MemoryImageStorage();
    final breaches = FakeBreachChecker();
    late final TestServer server;
    final services = Services.create(
      Config(
        publicBaseUrl: Uri.parse('https://api.example.com'),
        database: testDatabaseConfig(),
        jwtSecret: 'test-secret-that-is-long-enough-for-hs256!',
        appleClientIds: const ['com.etherious.ebucard'],
        googleClientIds: const ['google-client-id'],
      ),
      database: database,
      email: email,
      storage: storage,
      breaches: breaches,
      // Cheap settings: real Argon2id, but fast enough for many tests.
      passwords: const PasswordHasher(memoryKiB: 64, iterations: 1),
      httpClient: MockClient(
        (request) async =>
            http.Response(jsonEncode(jwks ?? {'keys': <Object?>[]}), 200),
      ),
      now: () => server.now,
    );
    return server = TestServer._(services, email, storage, breaches);
  }

  /// The services under test.
  final Services services;

  /// Emails "sent".
  final MemoryEmailSender email;

  /// Stored images.
  final MemoryImageStorage storage;

  /// Breach check.
  final FakeBreachChecker breaches;

  /// The current time as the server sees it; tests move it forward.
  DateTime now = DateTime.utc(2026, 10, 27, 9);

  /// Closes the database pool.
  Future<void> close() => services.database.close();

  /// Calls a route handler with [request], applying the error handling of
  /// routes/_middleware.dart.
  Future<Response> call(
    Future<Response> Function(RequestContext context) route,
    Request request,
  ) async {
    final context = _MockContext();
    when(() => context.request).thenReturn(request);
    when(() => context.read<Services>()).thenReturn(services);
    return await errorHandler()(route)(context);
  }
}

/// Stand-in for Dart Frog's request context.
class _MockContext extends Mock implements RequestContext {}

/// A JSON request to `https://api.example.com[path]`, from address [ip].
Request jsonRequest(
  HttpMethod method,
  String path, {
  Object? body,
  String? accessToken,
  String ip = '203.0.113.1',
  String? acceptLanguage,
}) => Request(
  method.value,
  Uri.parse('https://api.example.com$path'),
  body: body == null ? null : jsonEncode(body),
  headers: {
    'content-type': 'application/json',
    'x-forwarded-for': ip,
    if (accessToken != null) 'authorization': 'Bearer $accessToken',
    if (acceptLanguage != null) 'accept-language': acceptLanguage,
  },
);

/// The response body as a JSON object.
Future<Map<String, dynamic>> jsonBody(Response response) async =>
    jsonDecode(await response.body()) as Map<String, dynamic>;

/// Sample image bytes for upload tests.
abstract final class Uint8ListHelper {
  /// The start of a JPEG file (enough for type detection).
  static final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10]);

  /// The start of a PNG file.
  static final png = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0x0D, //
  ]);
}
