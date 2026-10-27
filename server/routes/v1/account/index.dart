import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/http/auth_guard.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/services.dart';

/// `/v1/account` (signed in):
///
/// * `GET`: the account (email, whether it is confirmed and can sync, how
///   it signs in).
/// * `DELETE`: starts account deletion. The user is signed out everywhere
///   and everything is erased after 30 days, unless they sign in again
///   before then (which cancels it). Answers 202 with `deleteAfter`.
Future<Response> onRequest(RequestContext context) async {
  allowMethods(context, {HttpMethod.get, HttpMethod.delete});
  final user = await requireUser(context);
  if (context.request.method == HttpMethod.get) {
    return Response.json(body: user.toJson());
  }
  final accounts = context.read<Services>().accounts;
  await accounts.requestDeletion(user.id);
  final updated = await accounts.users.byId(user.id);
  return Response.json(
    statusCode: HttpStatus.accepted,
    body: {'deleteAfter': updated?.deleteAfter?.toUtc().toIso8601String()},
  );
}
