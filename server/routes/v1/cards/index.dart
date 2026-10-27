import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/sync/sync_handlers.dart';
import 'package:ebucard_server/src/sync/sync_store.dart';

/// `GET /v1/cards?since=<cursor>`: the signed-in user's own cards changed
/// after the cursor, with deletions as tombstones (needs a confirmed email:
/// otherwise 403 `email_not_verified`).
Future<Response> onRequest(RequestContext context) {
  allowMethods(context, {HttpMethod.get});
  return listChanges(context, SyncKind.cards);
}
