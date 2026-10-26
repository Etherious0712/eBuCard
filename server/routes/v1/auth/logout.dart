import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/not_implemented.dart';

Response onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.post => notImplemented('POST /v1/auth/logout'),
    _ => methodNotAllowed(),
  };
}
