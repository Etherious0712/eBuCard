// The public web card (`/c/<slug>`, DESIGN.md §4.1): what someone without
// the app sees after scanning a QR code, tapping an NFC tag or opening a
// shared link. It shows only the fields on that card, offers "Save
// contact" (.vcf), and, once store listings exist, links to the app.
//
// Every value comes from the card's owner, so all of it is escaped, and
// only http(s), tel: and mailto: links are made from it.

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:ebucard_server/src/config.dart';
import 'package:ebucard_server/src/email/server_strings.dart';
import 'package:ebucard_server/src/http/html_page.dart';

/// Line icons (Lucide, ISC licence) drawn inline, so the page needs no
/// icon font or image requests.
const _icons = {
  'phone':
      '<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/>',
  'mail':
      '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>',
  'globe':
      '<circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/><path d="M2 12h20"/>',
  'pin':
      '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>',
  'link':
      '<path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>',
  'add':
      '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M19 8v6M22 11h-6"/>',
};

/// An inline SVG icon; decorative, so hidden from screen readers.
String _icon(String name) =>
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" '
    'stroke-width="2" stroke-linecap="round" stroke-linejoin="round" '
    'aria-hidden="true">${_icons[name]}</svg>';

/// The web card for [card], reachable at [cardUrl]. [imageBase] is where
/// this server's images live (`…/images/`); only those are shown.
Response webCardPage(
  ServerStrings s,
  BusinessCard card, {
  required Uri cardUrl,
  required String imageBase,
  required AppLinksConfig appLinks,
}) {
  final name = card.fullName;
  final subtitle = [
    card.jobTitle,
    card.company,
  ].where((t) => t.isNotEmpty).join(' · ');
  final photo = _localImage(card.photoUrl, imageBase);
  final logo = _localImage(card.logoUrl, imageBase);

  final rows = <String>[
    for (final p in card.phones)
      _row(
        'phone',
        p.value,
        s.label(p.label.name),
        p.label == ContactLabel.fax ? null : _telUri(p.value),
      ),
    for (final e in card.emails)
      _row(
        'mail',
        e.value,
        s.label(e.label.name),
        Uri(scheme: 'mailto', path: e.value).toString(),
      ),
    for (final w in card.websites) _row('globe', w, null, _webUri(w)),
    for (final a in card.addresses)
      if (_addressText(a).isNotEmpty)
        _row('pin', _addressText(a), s.label(a.label.name), null),
    for (final l in card.socialLinks)
      _row(
        'link',
        _shortUrl(l.handleOrUrl),
        _networkName(l.network).isEmpty ? null : _networkName(l.network),
        _webUri(l.handleOrUrl, requireScheme: true),
      ),
  ];

  String store(Uri url, String label) =>
      '<a class="button store" href="${escapeHtml('$url')}" '
      'rel="noopener noreferrer">${escapeHtml(label)}</a>';
  final stores = [
    if (appLinks.playStoreUrl case final url?) store(url, s.playStore),
    if (appLinks.appStoreUrl case final url?) store(url, s.appStore),
  ];

  final avatar = photo != null
      ? '<img class="avatar" src="${escapeHtml(photo)}" '
            'alt="${escapeHtml(s.photoOf(name))}" width="80" height="80">'
      : '<div class="avatar" aria-hidden="true">'
            '${escapeHtml(initials(name))}</div>';

  final ogImage = card.photoUrl != null && photo != null
      ? '<meta property="og:image" content="${escapeHtml(card.photoUrl!)}">'
      : '';

  return pageResponse(
    s,
    title: name,
    // Revoking a link must work at once, so browsers re-check each time.
    cacheControl: 'no-cache',
    headHtml:
        '''
<meta property="og:type" content="profile">
<meta property="og:title" content="${escapeHtml(name)}">
<meta property="og:description" content="${escapeHtml(subtitle)}">
<meta property="og:url" content="${escapeHtml('$cardUrl')}">
$ogImage''',
    bodyHtml:
        '''
<main class="card">
${logo == null ? '' : '<img class="logo" src="${escapeHtml(logo)}" alt="${escapeHtml(s.logoOf(card.company.isEmpty ? name : card.company))}">'}
<div class="hero">
$avatar
<div class="who">
<h1>${escapeHtml(name)}</h1>
${subtitle.isEmpty ? '' : '<p>${escapeHtml(subtitle)}</p>'}
</div>
</div>
<a class="button save" href="?format=vcf" download>${_icon('add')}${escapeHtml(s.saveContact)}</a>
<p class="hint">${escapeHtml(s.saveContactHint)}</p>
${rows.isEmpty ? '' : '<ul class="rows">\n${rows.join('\n')}\n</ul>'}
</main>
<footer class="foot">
${stores.isEmpty ? '' : '<h2>${escapeHtml(s.getApp)}</h2>\n${stores.join('\n')}'}
<p>${escapeHtml(s.sharedWith)}</p>
</footer>''',
  );
}

/// The page for a link that doesn't work (revoked, replaced or unknown).
Response cardGonePage(ServerStrings s) => htmlPage(
  s,
  s.cardGoneTitle,
  bodyHtml: '<p>${escapeHtml(s.cardGoneBody)}</p>',
  status: HttpStatus.notFound,
);

/// The card as a vCard file for phone Contacts.
Response vcardResponse(BusinessCard card) {
  final fileName =
      '${card.fullName.trim().isEmpty ? 'card' : card.fullName}'
      '.vcf';
  return Response(
    headers: {
      'content-type': 'text/vcard; charset=utf-8',
      'content-disposition':
          'attachment; filename="card.vcf"; '
          "filename*=UTF-8''${Uri.encodeComponent(fileName)}",
      'cache-control': 'no-cache',
      'x-content-type-options': 'nosniff',
    },
    body: const VCardEncoder().encode(card),
  );
}

/// The card as JSON for the eBuCard app (it saves a snapshot to the
/// Inbox, DESIGN.md §4.1).
Response cardJsonResponse(BusinessCard card) => Response(
  headers: {
    'content-type': 'application/json',
    'cache-control': 'no-cache',
  },
  body: jsonEncode({'card': card.toJson()}),
);

/// Up to two initials for a placeholder avatar: the first letters of the
/// first and last word, or the first character of a CJK name.
String initials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '?';
  final first = String.fromCharCode(words.first.runes.first);
  if (words.length == 1) return first.toUpperCase();
  return (first + String.fromCharCode(words.last.runes.first)).toUpperCase();
}

/// One contact row; a link when [href] is given.
String _row(String icon, String value, String? label, String? href) {
  final text =
      '${_icon(icon)}<span>${escapeHtml(value)}'
      '${label == null ? '' : '<small>${escapeHtml(label)}</small>'}</span>';
  return href == null
      ? '<li><div class="row">$text</div></li>'
      : '<li><a class="row" href="${escapeHtml(href)}" '
            'rel="noopener noreferrer nofollow">$text</a></li>';
}

/// A path on this server for an image URL hosted here, else null.
String? _localImage(String? url, String imageBase) =>
    url != null && url.startsWith(imageBase)
    ? '/images/${url.substring(imageBase.length)}'
    : null;

/// `tel:` link with only the digits and a leading +.
String? _telUri(String number) {
  final digits = number.replaceAll(RegExp('[^0-9+]'), '');
  return digits.replaceAll('+', '').isEmpty ? null : 'tel:$digits';
}

/// An http(s) link for [text]. A bare domain gets `https://` unless
/// [requireScheme]; any other scheme (javascript:, data:, …) is not linked.
String? _webUri(String text, {bool requireScheme = false}) {
  final value = text.trim();
  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  if (uri.scheme == 'http' || uri.scheme == 'https') {
    return uri.host.isEmpty ? null : value;
  }
  if (requireScheme || uri.scheme.isNotEmpty || value.contains(' ')) {
    return null;
  }
  final withScheme = Uri.tryParse('https://$value');
  return withScheme != null && withScheme.host.contains('.')
      ? withScheme.toString()
      : null;
}

/// [text] without a leading `https://` and `www.`, for display.
String _shortUrl(String text) =>
    text.trim().replaceFirst(RegExp(r'^https?://(www\.)?'), '');

/// An address on one line, skipping empty parts.
String _addressText(PostalAddress a) => [
  a.street,
  a.city,
  a.region,
  a.postalCode,
  a.country,
].map((p) => p.trim()).where((p) => p.isNotEmpty).join(', ');

/// Display name of a social network (brand names stay in English).
String _networkName(SocialNetwork n) => switch (n) {
  SocialNetwork.linkedin => 'LinkedIn',
  SocialNetwork.wechat => 'WeChat',
  SocialNetwork.whatsapp => 'WhatsApp',
  SocialNetwork.x => 'X',
  SocialNetwork.facebook => 'Facebook',
  SocialNetwork.instagram => 'Instagram',
  SocialNetwork.line => 'LINE',
  SocialNetwork.telegram => 'Telegram',
  SocialNetwork.other => '',
};
