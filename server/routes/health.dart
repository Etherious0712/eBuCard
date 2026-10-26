import 'package:dart_frog/dart_frog.dart';

/// `GET /health`: liveness check for load balancers and monitoring.
/// Always answers `200 {"status": "ok"}` and needs no auth or database.
Response onRequest(RequestContext context) =>
    Response.json(body: {'status': 'ok'});
