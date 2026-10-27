import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/sync/sync_handlers.dart';
import 'package:ebucard_server/src/sync/sync_store.dart';

/// `/v1/cards/{id}` (signed in, confirmed email):
///
/// * `PUT` with `BusinessCard` JSON: stores it if newer than the server's
///   copy (last writer wins); returns the stored version. 422
///   `card_invalid` if it breaks the card rules.
/// * `DELETE` with `{updatedAt}`: deletes it unless the server has a newer
///   version.
///
/// Another user's card id answers 404.
Future<Response> onRequest(RequestContext context, String id) {
  allowMethods(context, {HttpMethod.put, HttpMethod.delete});
  return context.request.method == HttpMethod.put
      ? putRecord(context, SyncKind.cards, id)
      : deleteRecord(context, SyncKind.cards, id);
}
