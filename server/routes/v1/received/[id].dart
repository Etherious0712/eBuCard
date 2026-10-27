import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/sync/sync_handlers.dart';
import 'package:ebucard_server/src/sync/sync_store.dart';

/// `/v1/received/{id}` (signed in, confirmed email):
///
/// * `PUT` with `ReceivedCard` JSON: stores it if newer (last writer wins).
/// * `DELETE` with `{updatedAt}`: deletes it unless the server has a newer
///   version.
Future<Response> onRequest(RequestContext context, String id) {
  allowMethods(context, {HttpMethod.put, HttpMethod.delete});
  return context.request.method == HttpMethod.put
      ? putRecord(context, SyncKind.received, id)
      : deleteRecord(context, SyncKind.received, id);
}
