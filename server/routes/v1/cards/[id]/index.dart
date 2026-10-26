import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/not_implemented.dart';

/// `/v1/cards/{id}`: one of the signed-in user's cards.
///
/// * `GET` returns it, `PUT` replaces it, `DELETE` removes it.
/// * Requests for another user's card must answer 404, not 403, so card IDs
///   can't be probed.
Response onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.get => notImplemented('GET /v1/cards/{id}'),
    HttpMethod.put => notImplemented('PUT /v1/cards/{id}'),
    HttpMethod.delete => notImplemented('DELETE /v1/cards/{id}'),
    _ => methodNotAllowed(),
  };
}
