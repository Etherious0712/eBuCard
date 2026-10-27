import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/sync/sync_handlers.dart';
import 'package:ebucard_server/src/sync/sync_store.dart';

/// `GET /v1/received?since=<cursor>`: the signed-in user's Inbox entries
/// changed after the cursor, with deletions as tombstones.
Future<Response> onRequest(RequestContext context) {
  allowMethods(context, {HttpMethod.get});
  return listChanges(context, SyncKind.received);
}
