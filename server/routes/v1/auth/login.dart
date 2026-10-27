import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/services.dart';

/// `POST /v1/auth/login` `{email, password}`: signs in. Signing in also
/// cancels a pending account deletion. Error: `invalid_credentials` (401).
Future<Response> onRequest(RequestContext context) async {
  allowMethods(context, {HttpMethod.post});
  final services = context.read<Services>()..authLimiter.hit(clientIp(context));
  final body = await readJsonObject(context);
  final result = await services.accounts.login(
    emailAddress: requireString(body, 'email'),
    password: requireString(body, 'password'),
  );
  return Response.json(body: result.toJson());
}
