/// Shared eBuCard domain models and encoders, used by both `app/` and
/// `server/` so they agree on the data format.
///
/// * `business_card.dart`: the card data model and its JSON form.
/// * `card_validation.dart`: rules a card must meet before saving.
/// * `vcard_encoder.dart`: card → vCard 3.0 text for Contacts apps.
/// * `share_payload.dart`: what goes into a QR code or NFC tag.
/// * `contact_decoder.dart`: scanned vCard / MECARD text → card.
/// * `received_card.dart`: a card in the user's Inbox.
/// * `contact_matching.dart`: is this scanned card someone already saved?
/// * `nfc_payload.dart`: the NFC (NDEF) message for a card, and reading
///   contact text back out of one.
/// * `offline_link.dart`: links that carry the whole card, for sharing
///   without the server.
library;

export 'src/business_card.dart';
export 'src/card_validation.dart';
export 'src/contact_decoder.dart';
export 'src/contact_matching.dart';
export 'src/nfc_payload.dart';
export 'src/offline_link.dart';
export 'src/received_card.dart';
export 'src/share_payload.dart';
export 'src/vcard_encoder.dart';
