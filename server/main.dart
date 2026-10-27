// Custom Dart Frog entrypoint: reads the configuration, connects to the
// database, applies migrations, schedules the daily purge of deleted
// accounts, then serves requests. Routes get the services via
// routes/_middleware.dart.

import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/config.dart';
import 'package:ebucard_server/src/services.dart';

/// Services shared by all requests; set in [init].
late Services services;

/// Called once before the server starts.
Future<void> init(InternetAddress ip, int port) async {
  services = Services.create(Config.fromEnvironment(Platform.environment));
  await services.database.migrate();
  unawaited(services.purgeDeletedAccounts(DateTime.now()));
  Timer.periodic(
    const Duration(days: 1),
    (_) => services.purgeDeletedAccounts(DateTime.now()),
  );
}

/// Starts the HTTP server. Binds to `HOST` if set (e.g. `0.0.0.0`; Cloud
/// Run sets `PORT`), otherwise to Dart Frog's default address.
Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  final host = Platform.environment['HOST'];
  return serve(
    handler,
    host == null ? ip : InternetAddress(host),
    int.parse(Platform.environment['PORT'] ?? '$port'),
  );
}
