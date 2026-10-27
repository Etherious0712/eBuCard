# eBuCard: Design Document

Status: **Living document** · Last updated with the app's new look (PR G)

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
| Sign-in | Email + password, Sign in with Apple, Google sign-in. **Optional**: the app works fully offline without an account; signing in adds backup and sync |
| Hosting | Google Cloud: Cloud Run (container), Cloud SQL for PostgreSQL, Cloud Storage for images (S3-compatible XML API with HMAC keys) |
| Domain | Not chosen yet: `https://api.example.com` placeholder, one setting (`PUBLIC_BASE_URL`) |
| Email | SMTP (any provider), for confirmation and password-reset emails |
| Email confirmation | Required **before sync**. Signing in works at once. Apple/Google accounts count as confirmed |
| Password rules | At least 8 characters (max 128), and not found in known data breaches (Have I Been Pwned, k-anonymity: only 5 hex chars of the SHA-1 leave the server; if the service is down, sign-up is not blocked) |
| Session length | Signed in until sign-out; ends after **90 days without use** (refresh tokens rotate on every use) |
| Account deletion | **30-day grace period**: signed out everywhere at once; signing in again within 30 days cancels; then account, cards, Inbox and images are erased |
| First sign-in on a phone with data | Merge the phone's cards and Inbox into the account (newer copy wins per record) |
| Sign-out | Syncs first, then **removes the account's cards and Inbox from the phone** (warns if changes could not be synced) |
| Session expired | Local data stays; the user is asked to sign in again. Signing in to a **different** account first clears the previous account's data from the phone |
| Apple / Google buttons | Hidden until configured: Apple needs `APPLE_SIGN_IN=true` (iOS only), Google needs `GOOGLE_SERVER_CLIENT_ID` |
| When sync runs | Automatically: at start, when the app returns to the foreground, 2 s after a local change, and on pull-to-refresh or "Sync now" |
| Card content | Core contact fields, profile photo, company logo, social links. **Several cards per user** |
| Received cards | Stored on the device **and** synced to the user's account |
| App identity | Display name `eBuCard`, package / bundle ID `com.etherious.ebucard` |
| UI languages | English, Traditional Chinese (zh-Hant), Simplified Chinese (zh-Hans) |
| Minimum OS | Android 7.0 (API 24), iOS 15. iOS 13 was requested, but current Flutter is built for iOS 15+ |
| State management | Riverpod |
| Required card fields | Full name, plus at least one phone number or email address. A blank card name becomes "My card" |
| Card images | Profile photo and logo from the photo library or camera, cropped to a square, max 1024 px JPEG |
| Exchange payload | **Card link** once the card has synced (QR code, and first on the NFC tag), with an **Offline QR** switch for the full vCard without images. Before sync, or signed out: the full vCard |
| Card links | Made **automatically** when a card first syncs (signed in, email confirmed). The owner can **replace** it (old link stops) or **turn it off** (stays off until they make a new one). Deleting the card or the account ends the link |
| Receiving a link | The app downloads the card and saves a **snapshot** to the Inbox that remembers the link, so **Check for updates** can fetch the latest version while the link works. NFC: the link when online, otherwise the tag's vCard |
| Web card | `/c/<slug>` in the visitor's language (en / zh-Hant / zh-Hans from the browser), **Save contact (.vcf)**, store buttons only once `PLAY_STORE_URL` / `APP_STORE_URL` are set. Not indexed by search engines |
| Look and feel | eBuCard design system (`docs/design-system/ebucard/MASTER.md`): flat, professional blue, Poppins + Open Sans, light and dark |
| Save to Contacts | Open the system new-contact screen, pre-filled (`flutter_contacts` `showCreator`; no Contacts permission) |
| Scanning other QR codes | Any contact QR is accepted: vCard 2.1/3.0/4.0 and MECARD. Anything else shows "Not a business card" |
| Same person scanned again | Ask: **Update** the saved card (keeps its note and received date) or **Keep both**. Same person = same name plus a shared email, or a shared phone number (≥ 8 digits, country code optional) |
| Inbox | Newest first; search by name, company or email; detail view; private note; delete; tap a phone/email/website to call/write/open |
| Card shown on the QR screen | The user's **default card** (star in My Cards / editor), switchable on the QR screen. With no default chosen, the first card |
| Images in received cards | From a vCard: ignored (embedded images are large, and loading a stranger's remote image would tell them when the card was opened). From a card link: kept, because they are hosted by the eBuCard server, so the owner can't see when they load |
| NFC send (Android) | Its own screen, Exchange → **Tap phones (NFC)**. The phone shares only while that screen is open and the app is in front |
| NFC receive | Its own screen, Exchange → **Read by NFC**. Android listens while it is open; iPhone opens the system scan sheet, with **Try again** if closed |
| NFC off | The NFC screens say "NFC is off" with **Open NFC settings** (Android) and **Use QR code instead** |
| Card sent by NFC | The same card as the QR screen: the default card, or the one picked on either share screen this session |

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
`https://<card-domain>/c/<slug>`. The `slug` is a random, unguessable value (22 base62 characters, about 131 bits) that the server makes when the card first syncs; the owner can turn it off or replace it. The card domain is the server's `PUBLIC_BASE_URL`; the production domain is **still to be decided** (see §12).

* On a phone **with** eBuCard: the link opens the app (Android App Links / iOS Universal Links, once `ANDROID_CERT_SHA256` / `APPLE_TEAM_ID` are set on the server and the app is built for the domain). The app fetches the card (`/c/<slug>?format=json`) and saves a snapshot to the Inbox, remembering the link for **Check for updates**. Scanning a link QR code in the app does the same.
* On a phone **without** eBuCard: the link opens the web card, which offers "Save contact (.vcf)" and, once store listings exist, app download buttons.
* Code: server `server/lib/src/sync/share_links.dart`, `server/lib/src/web/`, `routes/c/[slug].dart`; app `app/lib/src/sync/card_links.dart`, `features/exchange/receive_card.dart`, `card_link_section.dart`, `card_link_screen.dart`.

### 4.2 NFC (Android HCE → any reader)
* AID `D2760000850101` (NFC Forum NDEF Tag Application), Type 4 Tag v2.0 command set: SELECT AID → SELECT CC file (`E103`) → READ BINARY → SELECT NDEF file → READ BINARY. The tag is read-only (writes are refused) and serves up to 255 bytes per READ BINARY.
* NDEF message:
  1. **URI record**: card URL (once the card has synced and has a link). A receiving eBuCard app uses it when online and falls back to the vCard below.
  2. **MIME record `text/vcard`**: the full vCard without images (§4.4), so the exchange works offline.
* The phone shares only while the **Tap phones (NFC)** screen is open, the app is in front and the phone is unlocked (`requireDeviceUnlock`). The card lives only in memory (`CardShareState`), and `MainActivity` clears it when the app pauses. While sharing, the app asks Android to prefer its service for the AID (`CardEmulation.setPreferredService`), in case another app registered the same AID.
* Code: NDEF message in `packages/ebucard_models/lib/src/nfc_payload.dart`; tag emulation in `app/android/.../nfc/Type4Tag.kt` (plain Kotlin, unit tested in `src/test`) and `CardHostApduService.kt`; Flutter ↔ Android channel `ebucard/nfc` in `MainActivity.kt` and `app/lib/src/data/nfc_service.dart`.
* Reading (both platforms) uses `nfc_manager`: Android reader mode, iPhone `NFCTagReaderSession` (the AID is listed in `Info.plist`). Any NDEF message with a vCard/MECARD (MIME or text record) is accepted.
* **Phones without eBuCard (to verify on devices, matrix rows 3–4):** an iPhone without the app reads tags in the background only for web links, so it opens the web card only when the tag carries a card link. An Android phone without the app may offer to import the vCard into Contacts, depending on the vendor.

### 4.3 QR code
* Default: the card URL (short, so the code is easy to scan, and always the latest card).
* "Offline QR" switch, or when the card has no link (not synced, signed out, or link turned off): the full vCard without images (§2). Full vCards make denser QR codes, which may be harder to scan from a distance.
* The receiver scans with the in-app scanner. The phone's own camera app also works: a URL opens the app or web card, and a vCard offers to add the contact.
* The QR code uses the lowest error-correction level (most room for data). If a card is still too large for one QR code, the screen says so and asks the user to remove some fields.
* Parsing is in `packages/ebucard_models/lib/src/contact_decoder.dart`; the scan → Inbox flow is in `app/lib/src/features/exchange/receive_card.dart`.

### 4.4 vCard
* **vCard 3.0** (RFC 2426): the version Android and iOS Contacts import most reliably. Lines are folded at 75 octets and are UTF-8 safe for CJK names.
* *Full* vCard: all fields. The photo and logo are referenced by `http(s)` URL, never embedded. Local `file:` images (before sync) are left out.
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

**ReceivedCard**: `id`, `owner_user_id`, `source_slug` (nullable, the card link it came from, for Check for updates), `snapshot` (card JSON at time of receipt), `received_via` (`nfc` | `qr` | `link`), `received_at`, `note`, `tags[]`, `updated_at`, `deleted_at` (tombstone for sync).

**Local storage**: SQLite on the device (drift) holds own cards and received cards, so the app works offline. Own cards live in the `own_cards` table as the card's JSON (same format as the API) plus `sort_order` and `updated_at`. Received cards live in `received_cards` (the `ReceivedCard` JSON plus `search_text`, `received_at`, `updated_at`), and small preferences such as the default card in `settings` (key/value). Schema version 3; older databases are upgraded in place. For sync, each card and Inbox row has a `dirty` flag (changed since last upload), deletions wait in `pending_deletions` until the server has them, and `settings` also keeps the sync cursors (`sync_cursor_cards`, `sync_cursor_received`) and the signed-in account id (`sync_account_id`). Images are files in the app's documents folder (`card_images/`), referenced by `file:` URI until sync uploads them. **Sync**: each record carries `updated_at` and a tombstone. The client first uploads local `file:` images, then per kind pushes deletions, pushes dirty records and pulls changes since the last sync cursor. Conflicts resolve as last-writer-wins per record. The refresh token is kept in the phone's secure storage (Keychain / Android Keystore).

## 7. API outline (`/v1`, JSON, Bearer access token)

| Method & path | Purpose |
|---|---|
| `POST /v1/auth/register`, `POST /v1/auth/login` | Email + password |
| `POST /v1/auth/apple`, `POST /v1/auth/google` | Exchange the provider ID token (verified server-side) for eBuCard tokens |
| `POST /v1/auth/refresh`, `POST /v1/auth/logout` | Rotate / revoke refresh token |
| `POST /v1/auth/resend_verification`, `POST /v1/auth/password_reset` | Confirmation and reset emails |
| `GET /email/verify`, `GET/POST /password/reset` | Small web pages opened from those emails (en / zh-Hant / zh-Hans) |
| `GET/DELETE /v1/account` | Account details; request deletion (30-day grace) |
| `GET /v1/cards?since=`, `PUT/DELETE /v1/cards/{id}` | Own-card sync |
| `GET /v1/received?since=`, `PUT/DELETE /v1/received/{id}` | Inbox sync |
| `POST /v1/images`, `DELETE /v1/images/{id}`, `GET /images/{id}` | Card images |
| `POST/DELETE /v1/cards/{id}/share_link` | Replace / turn off the card's link (it is made automatically on first sync) |
| `GET /c/{slug}` | Public web card (HTML). `?format=vcf` / `Accept: text/vcard` returns the vCard, `?format=json` / `Accept: application/json` the card JSON for the app |
| `GET /.well-known/assetlinks.json`, `/.well-known/apple-app-site-association` | App Links / Universal Links, once configured |
| `GET /health` | Liveness |

Details, sync protocol and settings: `server/README.md`.

## 8. Security & privacy

* A share link exposes **only** the fields on that card. The owner can revoke the link at any time; afterwards `/c/{slug}` returns 404 and future NFC/QR shares use the new slug. Cards that were already received keep their snapshot.
* NFC is emitted only while the Share screen is open on an unlocked phone.
* Passwords use Argon2id (19 MiB, 2 passes; checked against the RFC 9106 test vector). Access tokens are HS256 JWTs valid 15 minutes. Refresh tokens are random 256-bit values stored only as SHA-256 hashes, and they rotate on every use. **Replaying an old refresh token ends all of that user's sessions** (theft detection). Email links are single-use, hashed, and expire (24 h confirmation, 1 h reset).
* Apple/Google ID tokens are verified against the provider's published keys (RS256 only; `iss`, `aud`, `exp` checked).
* **Account linking:** an Apple/Google sign-in with a provider-confirmed email joins an existing account with that email only if that account's email is confirmed. If it isn't, the provider proves ownership, so the unconfirmed password is removed and its sessions are ended.
* Sign-in errors don't reveal whether an email has an account (same answer and similar timing). Password-reset requests always answer 202.
* Synced data is per user. Another user's record ids answer 404, and malformed ids are rejected before reaching SQL. Cards are checked with the same `validateCard` rules as the app. The server keeps only its own image URLs and owns the share link.
* Images: JPEG/PNG only (detected from the bytes), ≤ 2 MB, private bucket, served by random UUID.
* Rate limiting on the auth endpoints and on opening card links (per instance). No public listing or search of cards; web cards send `noindex` so search engines skip them.
* The web card escapes everything the owner typed and only links `http(s)`, `tel:` and `mailto:` values; it runs no scripts and loads nothing from other sites (strict Content-Security-Policy).
* App Store rules: Sign in with Apple must be offered because Google sign-in is offered, and in-app account deletion is required.
* A privacy policy and data-residency decision are needed before launch (§12).

## 9. Planned client packages (added in feature PRs)

| Need | Package |
|---|---|
| NFC read (both platforms) | `nfc_manager` + `nfc_manager_ndef`; NDEF encoding with `ndef_record` |
| NFC send (Android HCE) | Native `CardHostApduService` + `Type4Tag` + platform channel `ebucard/nfc` |
| QR scan / render | `mobile_scanner` / `qr_flutter` |
| Local DB | `drift` (SQLite) |
| Save to Contacts | `flutter_contacts` (native creator screen only) |
| Call / email / open website | `url_launcher` |
| Sign-in | `sign_in_with_apple`, `google_sign_in` |
| Routing / i18n | `go_router`, `flutter_localizations` + ARB (already in scaffold) |

## 10. Internationalisation

ARB files in `app/lib/src/l10n/`. Devices often report Chinese without a script code (e.g. `zh_TW`), so `resolveAppLocale` maps TW/HK/MO to Traditional Chinese, other Chinese to Simplified Chinese, and everything else to English (tested). The Chinese strings in this scaffold are a first draft and should be reviewed by a native speaker.

## 11. Roadmap

1. **PR 1 (done):** design doc and scaffold.
2. **MVP**, split into three PRs:
   * **PR A (done):** card editor (multiple cards, photo/logo with square crop, validation) and local storage.
   * **PR B (done):** QR share and scan, Inbox of received cards, save to phone Contacts.
   * **PR C (done):** NFC: Android HCE send, NFC read on both platforms.
3. **Accounts & sync**, split into two PRs:
   * **PR D (done):** server: PostgreSQL schema and migrations, email/password + Apple + Google sign-in, sessions, confirmation and reset emails, card and Inbox sync, images, account deletion, Cloud Run image.
   * **PR E (done):** app: sign-in screens, sync engine, image upload, first-sign-in merge, account deletion.
4. **Web card & app links:**
   * **PR F (done):** card links made on sync, replace / turn off, web card with `.vcf` download, link QR + Offline QR, NFC link record, receive by link with Check for updates, App Links / Universal Links files and app routes, new look for the server pages.
   * **PR G (this one):** new look for the app: design-system theme (light/dark), bundled Poppins + Open Sans, photo/initials avatars, web-card-style card header, version 0.8.0.
5. **Release:** store listings, privacy policy, account deletion, analytics/crash reporting (to be decided).

### Manual device test matrix (NFC/QR cannot be tested in CI)

| # | Sender | Receiver | Method | Expect |
|---|---|---|---|---|
| 1 | Android (app, Share) | Android (app, Receive) | NFC | Card saved to Inbox |
| 2 | Android (app, Share) | iPhone (app, Receive) | NFC | Card saved to Inbox |
| 3 | Android (app, Share) | iPhone (no app) | NFC background read | Signed out: nothing happens. Card with a link: web card opens |
| 4 | Android (app, Share) | Android (no app) | NFC | Possibly an offer to import the contact, depending on vendor (to verify) |
| 4a | Android (app, Share) | any | NFC with app in background / screen locked | Nothing is shared |
| 4b | any (app, Receive) | NFC switched off | — | "NFC is off" with settings button (Android) and QR fallback |
| 5 | iPhone / Android | any (app) | QR | Card saved to Inbox; scanning again asks Update / Keep both |
| 6 | iPhone / Android | any (camera app, no app) | QR URL | Web card opens |
| 7 | any | any (camera app, no app) | vCard QR (MVP) | Phone offers to add the contact |
| 8 | paper card / other app | any (app) | vCard or MECARD QR | Card saved to Inbox |
| 9 | Phone A and B, same account | — | Sync | A card edited on A appears on B after pull-to-refresh; deleting it on B removes it on A |
| 10 | iPhone | — | Sign in with Apple / Google | Signs in; on first sign-in with local cards they are uploaded |
| 11 | any | — | Sync with a card photo | Photo uploaded; shows on the other phone |
| 12 | any, signed in | — | Sign out, then sign in to another account | First account's data is gone from the phone |
| 13 | any (app, signed in) | any (camera app, no app) | Link QR | Web card opens; Save contact adds the contact |
| 14 | any (app) | any (app) | Link QR / NFC | Card saved with photo; Check for updates picks up the owner's later edit |
| 15 | Android (app, Share), link on | Android (app), no internet | NFC | Card saved from the tag's vCard |
| 16 | owner turns the link off | anyone | Old link | "This card link is no longer active" |
| 17 | Android / iPhone (app installed, app links configured) | — | Tap a card link in Messages / Mail | eBuCard opens and saves the card |

## 12. Open questions for the product owner

1. Production domain for card links and the API (placeholder `api.example.com` for now), and the Google Cloud region.
2. Apple Developer Team ID and Google Play account (needed for signing, app links and Sign in with Apple), plus the Google OAuth client IDs.
3. Which SMTP account sends the emails, and the sender address.
4. Should receiving a card offer to send your own card back automatically ("exchange")?
5. Privacy policy, target markets and data-residency requirements (e.g. GDPR, Hong Kong PDPO, Mainland China PIPL).
6. Business model (free / premium cards / team plans), since it affects the data model.
7. Web card visual design and branding.
