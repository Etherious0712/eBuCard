import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/not_implemented.dart';

/// `GET /c/{slug}`: the public web card, for people without the app.
///
/// Planned: an HTML page with "Save contact"; `?format=vcf` or
/// `Accept: text/vcard` returns the vCard instead. Unknown or revoked
/// slugs answer 404.
Response onRequest(RequestContext context, String slug) {
  return switch (context.request.method) {
    HttpMethod.get => notImplemented('GET /c/{slug}'),
    _ => methodNotAllowed(),
  };
}
