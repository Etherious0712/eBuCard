import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/not_implemented.dart';

/// `POST /v1/auth/refresh`: exchange a refresh token for a new access
/// token. Planned: refresh tokens rotate on every use.
Response onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.post => notImplemented('POST /v1/auth/refresh'),
    _ => methodNotAllowed(),
  };
}
