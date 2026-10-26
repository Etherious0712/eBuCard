import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/not_implemented.dart';

/// `/v1/cards`: the signed-in user's own cards.
///
/// * `GET` lists all of them.
/// * `POST` creates one (body: `BusinessCard` JSON from `ebucard_models`,
///   checked with `validateCard`).
Response onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.get => notImplemented('GET /v1/cards'),
    HttpMethod.post => notImplemented('POST /v1/cards'),
    _ => methodNotAllowed(),
  };
}
