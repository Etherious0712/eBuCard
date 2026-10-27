// Decides what goes into an NFC tag or QR code for a card, and parses card
// links back out of scanned URLs.

import 'business_card.dart';
import 'vcard_encoder.dart';

/// Builds what is actually transferred over NFC or shown in a QR code.
///
/// See `docs/DESIGN.md` §4 for the format. In short:
/// * NFC (Android HCE): an NDEF message with a URI record (card URL) first,
///   followed by a `text/vcard` MIME record (full vCard without images) for
///   offline use. Built by `cardNdefMessage` in `nfc_payload.dart`.
/// * QR: the card URL by default; the full vCard without images when the
///   user chooses the offline QR or the card has not been synced yet (the
///   MVP has no server, so it always uses the vCard).
class SharePayload {
  /// Creates a payload builder for cards hosted at [baseUrl].
  SharePayload({required this.baseUrl, this.encoder = const VCardEncoder()});

  /// e.g. `https://card.example.com` – the host serving `/c/<slug>`.
  final Uri baseUrl;

  /// Produces the vCard text used for offline payloads.
  final VCardEncoder encoder;

  /// Public URL of a card, or null if the card has no share slug yet.
  Uri? cardUrl(BusinessCard card) {
    final slug = card.shareSlug;
    if (slug == null) return null;
    return baseUrl.replace(
      pathSegments: [
        ...baseUrl.pathSegments.where((s) => s.isNotEmpty),
        'c',
        slug,
      ],
    );
  }

  /// Text to encode in a QR code. Uses the URL when available, otherwise the
  /// full vCard without images (DESIGN.md §2, "MVP exchange payload").
  String qrText(BusinessCard card, {bool offline = false}) {
    final url = cardUrl(card);
    if (!offline && url != null) return url.toString();
    return encoder.encode(card, includeImages: false);
  }

  /// Extracts the share slug from a scanned/received URL, or null if the URL
  /// does not belong to [baseUrl].
  String? slugFromUrl(Uri url) {
    if (url.host != baseUrl.host) return null;
    final segments = url.pathSegments.where((s) => s.isNotEmpty).toList();
    final i = segments.indexOf('c');
    if (i == -1 || i + 1 >= segments.length) return null;
    return segments[i + 1];
  }
}
