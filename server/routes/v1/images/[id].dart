import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/http/auth_guard.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/services.dart';

/// `DELETE /v1/images/{id}` (signed in): deletes one of the user's images.
Future<Response> onRequest(RequestContext context, String id) async {
  allowMethods(context, {HttpMethod.delete});
  final user = await requireUser(context);
  await context.read<Services>().images.delete(user.id, id);
  return Response(statusCode: HttpStatus.noContent);
}
