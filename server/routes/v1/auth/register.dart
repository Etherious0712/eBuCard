import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/email/server_strings.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/services.dart';

/// `POST /v1/auth/register` `{email, password}`: creates an email/password
/// account, emails a confirmation link (in the `Accept-Language` language)
/// and signs in. Errors: `invalid_email`, `password_too_short`,
/// `password_too_long`, `password_breached`, `email_taken` (409).
Future<Response> onRequest(RequestContext context) async {
  allowMethods(context, {HttpMethod.post});
  final services = context.read<Services>()..authLimiter.hit(clientIp(context));
  final body = await readJsonObject(context);
  final result = await services.accounts.register(
    emailAddress: requireString(body, 'email'),
    password: requireString(body, 'password'),
    locale: localeFromHeader(context.request.headers['accept-language']),
  );
  return Response.json(statusCode: HttpStatus.created, body: result.toJson());
}
