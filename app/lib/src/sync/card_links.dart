// Card links on the phone (DESIGN.md §4.1): open someone's link to get
// their card, and let the owner replace or turn off their own link. The
// server makes each card's link when it first syncs.

import 'dart:convert';

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../account/account_providers.dart';
import '../account/api_client.dart';
import '../core/config.dart';
import '../data/card_repository.dart';
import '../data/providers.dart';

/// Builds and reads offline card links (the card inside the link, opened
/// by the static web card page; no server needed).
final offlineLinksProvider = Provider<OfflineCardLink>(
  (ref) => OfflineCardLink(AppConfig.webCardUrl),
);

/// Builds and reads card links for this app's server.
final sharePayloadProvider = Provider<SharePayload>(
  (ref) => SharePayload(baseUrl: AppConfig.apiBaseUrl),
);

/// [card] as kept in the Inbox: without its owner's card name or link
/// (the link is remembered in `ReceivedCard.sourceSlug`).
BusinessCard inboxSnapshot(BusinessCard card) => BusinessCard.fromJson({
  ...card.toJson(),
  'cardName': '',
  'shareSlug': null,
});

/// Whether [a] and [b] show the same details (ignoring id and time).
bool sameDetails(BusinessCard a, BusinessCard b) {
  Map<String, Object?> details(BusinessCard c) =>
      c.toJson()..removeWhere((k, _) => k == 'id' || k == 'updatedAt');
  return jsonEncode(details(a)) == jsonEncode(details(b));
}

/// Opens card links and changes the user's own links.
class CardLinks {
  /// Creates the service.
  CardLinks(this._api, this._cards, this._payload);

  final ApiClient _api;
  final CardRepository _cards;
  final SharePayload _payload;

  /// The slug in [text] if it is a card link of this server, else null.
  String? slugIn(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) {
      return null;
    }
    return _payload.slugFromUrl(uri);
  }

  /// The card behind [slug], as its owner has it now.
  ///
  /// Throws [ApiError]: `not_found` when the link is off or replaced,
  /// `network` without a connection.
  Future<BusinessCard> fetch(String slug) async {
    final json = await _api.getPublic(
      '/c/${Uri.encodeComponent(slug)}?format=json',
    );
    final card = json['card'];
    if (card is! Map<String, Object?>) throw const ApiError('invalid_card');
    return BusinessCard.fromJson(card);
  }

  /// Gives the user's card [cardId] a new link; the old one stops working.
  Future<void> regenerate(String cardId) => _change('POST', cardId);

  /// Turns off the link of card [cardId] until [regenerate] is called.
  Future<void> revoke(String cardId) => _change('DELETE', cardId);

  /// Asks the server for the change and stores the slug it now has.
  Future<void> _change(String method, String cardId) async {
    final record = await _api.authed(
      method,
      '/v1/cards/${Uri.encodeComponent(cardId)}/share_link',
    );
    final data = record['data'];
    final slug = data is Map<String, Object?> ? data['shareSlug'] : null;
    await _cards.setShareSlug(cardId, slug is String ? slug : null);
  }
}

/// See [CardLinks].
final cardLinksProvider = Provider<CardLinks>(
  (ref) => CardLinks(
    ref.watch(apiClientProvider),
    ref.watch(cardRepositoryProvider),
    ref.watch(sharePayloadProvider),
  ),
);
