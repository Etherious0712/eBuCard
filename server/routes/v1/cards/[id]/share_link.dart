import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/not_implemented.dart';

/// `/v1/cards/{id}/share_link`: the card's public link (`/c/{slug}`).
///
/// * `POST` creates a new random slug, replacing any old one.
/// * `DELETE` revokes the slug so the old link stops working.
Response onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.post => notImplemented('POST /v1/cards/{id}/share_link'),
    HttpMethod.delete => notImplemented('DELETE /v1/cards/{id}/share_link'),
    _ => methodNotAllowed(),
  };
}
