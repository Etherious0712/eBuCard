import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/services.dart';

/// `POST /v1/auth/refresh` `{refreshToken}`: returns a new access token and
/// a new refresh token (the old one stops working). Error:
/// `invalid_refresh_token` (401): the app must sign in again.
Future<Response> onRequest(RequestContext context) async {
  allowMethods(context, {HttpMethod.post});
  final body = await readJsonObject(context);
  final result = await context.read<Services>().accounts.refresh(
    requireString(body, 'refreshToken'),
  );
  return Response.json(body: result.toJson());
}
