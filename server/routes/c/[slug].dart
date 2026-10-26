import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/not_implemented.dart';

Response onRequest(RequestContext context, String slug) {
  return switch (context.request.method) {
    HttpMethod.get => notImplemented('GET /c/{slug}'),
    _ => methodNotAllowed(),
  };
}
