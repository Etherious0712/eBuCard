import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/email/server_strings.dart';
import 'package:ebucard_server/src/http/auth_guard.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/services.dart';

/// `POST /v1/auth/resend_verification` (signed in): sends the confirmation
/// email again, in the `Accept-Language` language. 204 even if the email
/// is already confirmed.
Future<Response> onRequest(RequestContext context) async {
  allowMethods(context, {HttpMethod.post});
  final services = context.read<Services>()..authLimiter.hit(clientIp(context));
  final user = await requireUser(context);
  await services.accounts.sendVerificationEmail(
    user,
    localeFromHeader(context.request.headers['accept-language']),
  );
  return Response(statusCode: HttpStatus.noContent);
}
