import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/not_implemented.dart';

/// `/v1/received`: cards the user has received from other people.
///
/// * `GET ?since=<cursor>` returns changes since the last sync.
/// * `POST` uploads newly received cards from the device.
Response onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.get => notImplemented('GET /v1/received'),
    HttpMethod.post => notImplemented('POST /v1/received'),
    _ => methodNotAllowed(),
  };
}
