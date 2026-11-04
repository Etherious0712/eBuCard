// Offline card links: the whole card inside the link, so sharing works
// without the eBuCard server (DESIGN.md §4.5).
//
//   https://etherious0712.github.io/eBuCard/c/#1<data>
//
// <data> is the card as compact JSON, compressed (raw deflate) and encoded
// as base64url without padding. The leading `1` is the format version.
// Everything after `#` stays in the browser: the static web card page
// (web/c/) decodes it there, so the website never receives the card.
//
// The same data also travels in `ebucard://card/receive/1<data>`, which
// the web page uses to hand the card to the app.

import 'dart:convert';
import 'dart:io' show ZLibCodec;

import 'business_card.dart';

/// Builds and reads offline card links for the web card at [baseUrl].
class OfflineCardLink {
  /// Creates links for the static web card page at [baseUrl], e.g.
  /// `https://etherious0712.github.io/eBuCard/c/`.
  const OfflineCardLink(this.baseUrl);

  /// The web card page (without fragment).
  final Uri baseUrl;

  /// Format version, the first character of the data.
  static const version = '1';

  /// Longest data accepted when reading, in characters. Real cards are a
  /// few hundred; anything far bigger isn't from eBuCard.
  static const maxDataLength = 8000;

  /// Largest decompressed card accepted, in bytes (guards against
  /// "zip bombs" in scanned codes).
  static const maxJsonBytes = 32 * 1024;

  /// The offline link for [card] (no images, id or card name).
  Uri linkFor(BusinessCard card) => baseUrl.replace(fragment: encodeData(card));

  /// The app link that opens [card] in eBuCard directly.
  static Uri appLinkFor(BusinessCard card) =>
      Uri.parse('ebucard://card/receive/${encodeData(card)}');

  /// The version-prefixed data part of a link for [card].
  static String encodeData(BusinessCard card) {
    final json = utf8.encode(jsonEncode(compactJson(card)));
    final packed = ZLibCodec(raw: true, level: 9).encode(json);
    return version + base64Url.encode(packed).replaceAll('=', '');
  }

  /// The data part of [text] if it is an offline link to this web card
  /// (any query or trailing slash differences ignored), or an `ebucard://`
  /// app link; otherwise null.
  String? dataIn(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null) return null;
    if (uri.scheme == 'ebucard') {
      final segments = uri.pathSegments;
      return segments.length == 2 && segments.first == 'receive'
          ? segments.last
          : null;
    }
    if (uri.scheme != baseUrl.scheme || uri.host != baseUrl.host) return null;
    String trim(String path) =>
        path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    if (trim(uri.path) != trim(baseUrl.path)) return null;
    return uri.hasFragment && uri.fragment.isNotEmpty ? uri.fragment : null;
  }

  /// The card in [text] (an offline or app link), with [id] and [now] as
  /// its id and change time, or null if [text] isn't a readable link.
  BusinessCard? decode(
    String text, {
    required String id,
    required DateTime now,
  }) {
    final data = dataIn(text);
    return data == null ? null : decodeData(data, id: id, now: now);
  }

  /// The card in version-prefixed [data], or null if it can't be read or
  /// has no name.
  static BusinessCard? decodeData(
    String data, {
    required String id,
    required DateTime now,
  }) {
    if (data.length < 2 || data.length > maxDataLength) return null;
    if (!data.startsWith(version)) return null;
    try {
      final body = data.substring(1);
      final padded = body.padRight((body.length + 3) ~/ 4 * 4, '=');
      final inflated = ZLibCodec(raw: true).decode(base64Url.decode(padded));
      if (inflated.length > maxJsonBytes) return null;
      final json = jsonDecode(utf8.decode(inflated));
      if (json is! Map<String, Object?>) return null;
      return fromCompactJson(json, id: id, now: now);
    } on Object {
      return null;
    }
  }

  /// The card as compact JSON: short keys, empty fields left out.
  ///
  /// `n` name, `t` job title, `o` company, `p` phones and `e` emails as
  /// `[label, value]`, `w` websites, `a` addresses as `[label, street,
  /// city, region, postal code, country]`, `s` social links as
  /// `[network, handle or URL]`.
  static Map<String, Object?> compactJson(BusinessCard card) => {
    'n': card.fullName,
    if (card.jobTitle.isNotEmpty) 't': card.jobTitle,
    if (card.company.isNotEmpty) 'o': card.company,
    if (card.phones.isNotEmpty)
      'p': [
        for (final p in card.phones) [p.label.name, p.value],
      ],
    if (card.emails.isNotEmpty)
      'e': [
        for (final e in card.emails) [e.label.name, e.value],
      ],
    if (card.websites.isNotEmpty) 'w': card.websites,
    if (card.addresses.isNotEmpty)
      'a': [
        for (final a in card.addresses)
          [a.label.name, a.street, a.city, a.region, a.postalCode, a.country],
      ],
    if (card.socialLinks.isNotEmpty)
      's': [
        for (final s in card.socialLinks) [s.network.name, s.handleOrUrl],
      ],
  };

  /// Reads [compactJson] output. Unknown labels become `other`; anything
  /// malformed is skipped. Returns null without a name.
  static BusinessCard? fromCompactJson(
    Map<String, Object?> json, {
    required String id,
    required DateTime now,
  }) {
    String text(Object? v) => v is String ? v.trim() : '';
    List<List<String>> rows(Object? v) => [
      if (v is List)
        for (final row in v)
          if (row is List) [for (final cell in row) text(cell)],
    ];
    ContactLabel label(String name) =>
        ContactLabel.values.asNameMap()[name] ?? ContactLabel.other;
    String at(List<String> row, int i) => i < row.length ? row[i] : '';

    final name = text(json['n']);
    if (name.isEmpty) return null;
    return BusinessCard(
      id: id,
      cardName: '',
      fullName: name,
      jobTitle: text(json['t']),
      company: text(json['o']),
      phones: [
        for (final r in rows(json['p']))
          if (at(r, 1).isNotEmpty)
            LabeledValue(label: label(at(r, 0)), value: at(r, 1)),
      ],
      emails: [
        for (final r in rows(json['e']))
          if (at(r, 1).isNotEmpty)
            LabeledValue(label: label(at(r, 0)), value: at(r, 1)),
      ],
      websites: [
        if (json['w'] is List)
          for (final w in json['w']! as List)
            if (text(w).isNotEmpty) text(w),
      ],
      addresses: [
        for (final r in rows(json['a']))
          if (r.skip(1).any((p) => p.isNotEmpty))
            PostalAddress(
              label: label(at(r, 0)),
              street: at(r, 1),
              city: at(r, 2),
              region: at(r, 3),
              postalCode: at(r, 4),
              country: at(r, 5),
            ),
      ],
      socialLinks: [
        for (final r in rows(json['s']))
          if (at(r, 1).isNotEmpty)
            SocialLink(
              network:
                  SocialNetwork.values.asNameMap()[at(r, 0)] ??
                  SocialNetwork.other,
              handleOrUrl: at(r, 1),
            ),
      ],
      updatedAt: now,
    );
  }
}
