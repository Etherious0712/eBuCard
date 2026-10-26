import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/not_implemented.dart';

/// `/v1/received/{id}`: one received card.
///
/// * `PUT` updates the user's note or tags.
/// * `DELETE` removes it (kept as a tombstone so other devices sync it).
Response onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.put => notImplemented('PUT /v1/received/{id}'),
    HttpMethod.delete => notImplemented('DELETE /v1/received/{id}'),
    _ => methodNotAllowed(),
  };
}
