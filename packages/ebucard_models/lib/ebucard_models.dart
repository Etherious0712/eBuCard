/// Shared eBuCard domain models and encoders, used by both `app/` and
/// `server/` so they agree on the data format.
///
/// * `business_card.dart`: the card data model and its JSON form.
/// * `card_validation.dart`: rules a card must meet before saving.
/// * `vcard_encoder.dart`: card → vCard 3.0 text for Contacts apps.
/// * `share_payload.dart`: what goes into a QR code or NFC tag.
library;

export 'src/business_card.dart';
export 'src/card_validation.dart';
export 'src/share_payload.dart';
export 'src/vcard_encoder.dart';
