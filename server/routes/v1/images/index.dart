import 'dart:io';
import 'dart:typed_data';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/http/auth_guard.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/services.dart';

/// `POST /v1/images` (signed in, confirmed email) with the raw JPEG or PNG
/// bytes as the body: stores the image and returns `{id, url}`. The app puts
/// the url in the card's `photoUrl` / `logoUrl`. Errors: 413
/// `image_too_large` (over 2 MB), 415 `unsupported_image_type`.
Future<Response> onRequest(RequestContext context) async {
  allowMethods(context, {HttpMethod.post});
  final user = await requireUser(context, requireSync: true);
  final bytes = <int>[];
  await for (final chunk in context.request.bytes()) {
    bytes.addAll(chunk);
    if (bytes.length > 2 * 1024 * 1024) break; // Stop reading huge bodies.
  }
  final result = await context.read<Services>().images.upload(
    user.id,
    Uint8List.fromList(bytes),
  );
  return Response.json(statusCode: HttpStatus.created, body: result);
}
