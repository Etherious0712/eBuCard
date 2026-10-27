import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/services.dart';

/// `POST /v1/auth/logout` `{refreshToken}`: ends that session. Always 204.
Future<Response> onRequest(RequestContext context) async {
  allowMethods(context, {HttpMethod.post});
  final body = await readJsonObject(context);
  await context.read<Services>().accounts.logout(
    requireString(body, 'refreshToken'),
  );
  return Response(statusCode: HttpStatus.noContent);
}
