import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_server/src/http/api_error.dart';
import 'package:ebucard_server/src/http/auth_guard.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/services.dart';

/// `/v1/cards/{id}/share_link` (signed in, confirmed email): the card's
/// public link (DESIGN.md §4.1). Links are made automatically when a card
/// first syncs; this lets the owner change that.
///
/// * `POST`: a new link; the old one stops working.
/// * `DELETE`: no link; none is made again until `POST`.
///
/// Both answer with the card record (as in sync), so the phone can store
/// the new `shareSlug`. Another user's or a deleted card answers 404.
Future<Response> onRequest(RequestContext context, String id) async {
  allowMethods(context, {HttpMethod.post, HttpMethod.delete});
  final user = await requireUser(context, requireSync: true);
  if (!isUuid(id)) throw const ApiException.notFound();
  final links = context.read<Services>().shareLinks;
  final record = context.request.method == HttpMethod.post
      ? await links.regenerate(user.id, id)
      : await links.revoke(user.id, id);
  return Response.json(body: record.toJson());
}
