import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/email/server_strings.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/services.dart';

/// `POST /v1/auth/password_reset` `{email}`: emails a link to choose a new
/// password (opened in the browser: `/password/reset`). Always 202, so it
/// doesn't reveal whether the email has an account.
Future<Response> onRequest(RequestContext context) async {
  allowMethods(context, {HttpMethod.post});
  final services = context.read<Services>()..authLimiter.hit(clientIp(context));
  final body = await readJsonObject(context);
  await services.accounts.requestPasswordReset(
    requireString(body, 'email'),
    localeFromHeader(context.request.headers['accept-language']),
  );
  return Response(statusCode: HttpStatus.accepted);
}
