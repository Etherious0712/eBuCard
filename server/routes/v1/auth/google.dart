import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/services.dart';

/// `POST /v1/auth/google` `{identityToken}`: signs in with the identity token
/// the app got from Google sign-in. Creates the account on first
/// use, or links it to an account with the same confirmed email. Errors:
/// `invalid_identity_token` (401), `provider_not_configured` (404).
Future<Response> onRequest(RequestContext context) async {
  allowMethods(context, {HttpMethod.post});
  final services = context.read<Services>()..authLimiter.hit(clientIp(context));
  final body = await readJsonObject(context);
  final identity = await services.google.verify(
    requireString(body, 'identityToken'),
  );
  final result = await services.accounts.signInWithProvider(
    services.google.provider,
    identity,
  );
  return Response.json(body: result.toJson());
}
