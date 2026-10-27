// Checks the access token on API requests that need a signed-in user.

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/auth/users.dart';
import 'package:ebucard_server/src/http/api_error.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/services.dart';

/// The signed-in user of this request. Throws a 401 if the access token is
/// missing, invalid or expired (the app then refreshes it), or if the
/// account is being deleted.
///
/// With [requireSync], also throws a 403 `email_not_verified` until the
/// user has confirmed their email.
Future<User> requireUser(
  RequestContext context, {
  bool requireSync = false,
}) async {
  final services = context.read<Services>();
  final token = bearerToken(context);
  final userId = token == null
      ? null
      : services.accounts.accessTokens.verify(token);
  if (userId == null) throw const ApiException.unauthorized();
  final user = await services.accounts.users.byId(userId);
  if (user == null || user.deactivatedAt != null) {
    throw const ApiException.unauthorized();
  }
  if (requireSync && !user.canSync) {
    throw const ApiException.forbidden('email_not_verified');
  }
  return user;
}
