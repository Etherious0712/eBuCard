import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/services.dart';

/// `GET /images/{id}`: a card image, public so shared cards can show it.
/// Ids are random UUIDs, so images can't be listed or guessed. Images never
/// change (a new photo gets a new id), so they are cached for a year.
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final image = await context.read<Services>().images.read(id);
  if (image == null) return Response(statusCode: HttpStatus.notFound);
  final (bytes, contentType) = image;
  return Response.bytes(
    body: bytes,
    headers: {
      'content-type': contentType,
      'cache-control': 'public, max-age=31536000, immutable',
      'x-content-type-options': 'nosniff',
    },
  );
}
