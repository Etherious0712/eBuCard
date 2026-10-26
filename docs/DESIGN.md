# eBuCard: Design Document

Status: **Draft for review** · Scope: architecture and scaffold (PR 1)

## 1. Goal

eBuCard is an electronic business card service. Business people and anyone else who wants to introduce themselves can create one or more digital cards and exchange them phone-to-phone:

| Sender → Receiver | Primary method | Fallback |
|---|---|---|
| Android → Android | NFC tap | QR code |
| Android → iPhone | NFC tap | QR code |
| iPhone → Android | **QR code** | – |
| iPhone → iPhone | **QR code** | – |

## 2. Decisions taken

| Topic | Decision |
|---|---|
| Client | Flutter, one codebase for Android and iOS. Native Kotlin/Swift only where NFC requires it |
| Exchange data | Hybrid: offline vCard **and** a hosted card link (web card for people without the app) |
| iPhone as sender | Shows a QR code |
| Backend | Custom server in Dart ([Dart Frog](https://dart-frog.dev)) with PostgreSQL |
| Sign-in | Email + password, Sign in with Apple, Google sign-in |
| Card content | Core contact fields, profile photo, company logo, social links. **Several cards per user** |
| Received cards | Stored on the device **and** synced to the user's account |
| App identity | Display name `eBuCard`, package / bundle ID `com.etherious.ebucard` |
| UI languages | English, Traditional Chinese (zh-Hant), Simplified Chinese (zh-Hans) |

## 3. Platform constraints (why the exchange works this way)

* **NFC P2P no longer exists.** Android Beam (NFC P2P/SNEP) was removed in Android 10. iOS has never offered NFC P2P to apps. Phone-to-phone NFC therefore has to use **Host Card Emulation (HCE)**: one phone pretends to be an NFC tag and the other phone reads it.
* **Android can emulate a tag.** `HostApduService` lets the app act as an *NFC Forum Type 4 Tag* that serves an NDEF message. Android readers (in-app reader mode) and iPhones (Core NFC) can read it.
* **iPhone can read but (practically) not emulate.** Core NFC reads NDEF tags, including on iPhone XS and newer from the background. Apple's card-emulation APIs are limited by region and require a special entitlement and a commercial agreement with Apple. That is why iPhone senders show a QR code. If Apple's policy changes, this can be revisited.
* **Two Android phones:** both phones could emulate at the same time, so the receiver must have the app open on its *Receive* screen (reader mode). The sender is on its *Share* screen (HCE active).

Capability matrix as implemented in `app/lib/src/core/exchange_capabilities.dart`:

| Platform | Send | Receive |
|---|---|---|
| Android with NFC + HCE | NFC (HCE), QR | NFC read, QR scan |
| Android without NFC/HCE | QR | QR scan (NFC read if NFC present) |
| iPhone | QR | NFC read, QR scan |

## 4. Exchange payloads

### 4.1 Card URL
`https://<card-domain>/c/<slug>`. The `slug` is a random, unguessable value (≥128 bits, base62) that the owner can revoke and regenerate. The production domain is **still to be decided** (see §12).

* On a phone **with** eBuCard: the link opens the app (Android App Links / iOS Universal Links). The app fetches the card and saves it to the Inbox.
* On a phone **without** eBuCard: the link opens the web card, which offers "Save contact (.vcf)" and an app download link.

### 4.2 NFC (Android HCE → any reader)
* AID `D2760000850101` (NFC Forum NDEF Tag Application), Type 4 Tag v2.0 command set: SELECT AID → SELECT CC file (`E103`) → READ BINARY → SELECT NDEF file → READ BINARY.
* NDEF message:
  1. **URI record**: card URL (only if the card has been synced and has a slug).
  2. **MIME record `text/vcard`**: compact vCard (§4.4) so the exchange also works offline.
* HCE is active only while the Share screen is open and the device is unlocked (`requireDeviceUnlock`). That way the card is never broadcast in the background.

### 4.3 QR code
* Default: the card URL (short, so the code is easy to scan).
* "Offline QR" option, or when the card has not been synced yet: a compact vCard.
* The receiver scans with the in-app scanner. The phone's own camera app also works: a URL opens the app or web card, and a vCard offers to add the contact.

### 4.4 vCard
* **vCard 3.0** (RFC 2426): the version Android and iOS Contacts import most reliably. Lines are folded at 75 octets and are UTF-8 safe for CJK names.
* *Full* vCard: all fields. The photo and logo are referenced by URL, never embedded.
* *Compact* vCard: name, title, company, first phone, first email, card URL.
* Implemented in `packages/ebucard_models/lib/src/vcard_encoder.dart` (tested).

## 5. Architecture

```
eBuCard/
├─ app/                     Flutter client (Android + iOS)
│   ├─ lib/src/features/    cards · exchange · inbox · auth
│   ├─ lib/src/core/        config · exchange capabilities · locale
│   ├─ lib/src/l10n/        en · zh_Hant · zh_Hans
│   ├─ android/…/nfc/       CardHostApduService (HCE)
│   └─ ios/Runner/          Core NFC entitlement, Info.plist usage strings
├─ server/                  Dart Frog API + public web card, PostgreSQL
├─ packages/ebucard_models/ Shared pure-Dart models + vCard/payload encoding
└─ docs/DESIGN.md
```

The app and server share `ebucard_models`, so the JSON format and the vCard encoding stay identical on both sides.

## 6. Data model

**User**: `id`, `email` (nullable for Apple "hide my email" relay), `password_hash` (Argon2id, nullable for social-only accounts), linked identities (`apple_sub`, `google_sub`), `created_at`, `deleted_at`.

**Card** (own card, 0..n per user): `id`, `user_id`, `card_name` (e.g. "Work"), `full_name`, `job_title`, `company`, `phones[]`, `emails[]`, `websites[]`, `addresses[]`, `social_links[]`, `photo_url`, `logo_url`, `share_slug` (nullable, unique), `updated_at`.

**ReceivedCard**: `id`, `owner_user_id`, `source_card_id` (nullable, set when received by URL), `snapshot` (card JSON at time of receipt), `received_via` (`nfc` | `qr` | `link`), `received_at`, `note`, `tags[]`, `updated_at`, `deleted_at` (tombstone for sync).

**Local storage**: SQLite on the device holds own cards and received cards, so the app works offline. **Sync**: each record carries `updated_at` and a tombstone. The client pushes local changes and pulls changes since the last sync cursor. Conflicts resolve as last-writer-wins per record.

## 7. API outline (`/v1`, JSON, Bearer access token)

| Method & path | Purpose |
|---|---|
| `POST /v1/auth/register`, `POST /v1/auth/login` | Email + password |
| `POST /v1/auth/apple`, `POST /v1/auth/google` | Exchange the provider ID token (verified server-side) for eBuCard tokens |
| `POST /v1/auth/refresh`, `POST /v1/auth/logout` | Rotate / revoke refresh token |
| `GET/POST /v1/cards`, `GET/PUT/DELETE /v1/cards/{id}` | Own cards |
| `POST/DELETE /v1/cards/{id}/share_link` | Create / revoke public slug |
| `GET/POST /v1/received`, `PUT/DELETE /v1/received/{id}` | Received-card sync (`GET` supports `?since=<cursor>`) |
| `GET /c/{slug}` | Public web card (HTML). `Accept: text/vcard` or `?format=vcf` returns the vCard |
| `GET /health` | Liveness |

Still needed: account deletion endpoint (App Store requirement), image upload endpoint, `/.well-known/assetlinks.json` and `/.well-known/apple-app-site-association` for app links.

## 8. Security & privacy

* A share link exposes **only** the fields on that card. The owner can revoke the link at any time; afterwards `/c/{slug}` returns 404 and future NFC/QR shares use the new slug. Cards that were already received keep their snapshot.
* NFC is emitted only while the Share screen is open on an unlocked phone.
* Passwords use Argon2id. Access tokens are short-lived and refresh tokens rotate. Apple/Google ID tokens are verified against the provider keys.
* Rate limiting on `/c/{slug}` and the auth endpoints. No public listing or search of cards.
* App Store rules: Sign in with Apple must be offered because Google sign-in is offered, and in-app account deletion is required.
* A privacy policy and data-residency decision are needed before launch (§12).

## 9. Planned client packages (added in feature PRs)

| Need | Package |
|---|---|
| NFC read (both platforms) | `nfc_manager` |
| NFC send (Android HCE) | Native `CardHostApduService` + platform channel |
| QR scan / render | `mobile_scanner` / `qr_flutter` |
| Local DB | `drift` (SQLite) |
| Sign-in | `sign_in_with_apple`, `google_sign_in` |
| Routing / i18n | `go_router`, `flutter_localizations` + ARB (already in scaffold) |

## 10. Internationalisation

ARB files in `app/lib/src/l10n/`. Devices often report Chinese without a script code (e.g. `zh_TW`), so `resolveAppLocale` maps TW/HK/MO to Traditional Chinese, other Chinese to Simplified Chinese, and everything else to English (tested). The Chinese strings in this scaffold are a first draft and should be reviewed by a native speaker.

## 11. Roadmap

1. **PR 1 (this one):** design doc and scaffold.
2. **MVP:** card editor (multiple cards, photo/logo), local storage, QR share and scan, NFC read, Android HCE send, save to phone Contacts.
3. **Accounts & sync:** auth endpoints, PostgreSQL schema and migrations, card and inbox sync, share links.
4. **Web card & app links:** `/c/{slug}` HTML page, `.vcf` download, App Links / Universal Links.
5. **Release:** store listings, privacy policy, account deletion, analytics/crash reporting (to be decided).

### Manual device test matrix (NFC/QR cannot be tested in CI)

| # | Sender | Receiver | Method | Expect |
|---|---|---|---|---|
| 1 | Android (app, Share) | Android (app, Receive) | NFC | Card saved to Inbox |
| 2 | Android (app, Share) | iPhone (app, Receive) | NFC | Card saved to Inbox |
| 3 | Android (app, Share) | iPhone (no app) | NFC background read | Web card opens |
| 4 | Android (app, Share) | Android (no app) | NFC | Web card opens (to verify on several vendors) |
| 5 | iPhone / Android | any (app) | QR | Card saved to Inbox |
| 6 | iPhone / Android | any (camera app, no app) | QR URL | Web card opens |
| 7 | any | any | Offline QR | Contact import dialog |

## 12. Open questions for the product owner

1. Production domain for card links and the API, and the hosting provider/region.
2. Apple Developer Team ID and Google Play account (needed for signing, app links and Sign in with Apple).
3. Where to store photos and logos (object storage provider), and size limits.
4. Minimum OS versions to support.
5. Should receiving a card offer to send your own card back automatically ("exchange")?
6. Privacy policy, target markets and data-residency requirements (e.g. GDPR, Hong Kong PDPO, Mainland China PIPL).
7. Business model (free / premium cards / team plans), since it affects the data model.
8. Web card visual design and branding.
