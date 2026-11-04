# Contributing to eBuCard

Start with [`docs/DESIGN.md`](docs/DESIGN.md) for *what* the product does and *why*. This page covers *where things are in the code* and *how to work on it*.

## Code tour

| Area | Where | What it does |
|---|---|---|
| Card data model | `packages/ebucard_models/lib/src/business_card.dart` | `BusinessCard` and its parts, with JSON used for storage, API and sync |
| Save rules | `packages/ebucard_models/lib/src/card_validation.dart` | `validateCard`: full name, plus at least one phone or email |
| vCard | `packages/ebucard_models/lib/src/vcard_encoder.dart` | Card → vCard 3.0 text that phone Contacts apps import |
| Share payload | `packages/ebucard_models/lib/src/share_payload.dart` | What goes into a QR code / NFC tag; parses card links |
| Reading QR data | `packages/ebucard_models/lib/src/contact_decoder.dart` | vCard 2.1/3.0/4.0 or MECARD text → card |
| Inbox model | `packages/ebucard_models/lib/src/received_card.dart` | A received card plus the user's private note |
| Same person? | `packages/ebucard_models/lib/src/contact_matching.dart` | Decides when a scan should offer "Update or keep both" |
| NFC payload | `packages/ebucard_models/lib/src/nfc_payload.dart` | The NDEF message a phone shares; contact text and links from a read message |
| Offline links | `packages/ebucard_models/lib/src/offline_link.dart` | The card inside a link (serverless mode, DESIGN.md §4.5); test vectors in `test/fixtures/offline_links.json` |
| App entry & routes | `app/lib/main.dart`, `app/lib/src/app.dart` | Riverpod scope, theme, languages, route table |
| Bottom tabs | `app/lib/src/home_shell.dart` | My Cards / Exchange / Inbox navigation |
| Local database | `app/lib/src/data/app_database.dart` | SQLite tables (drift) |
| Card storage | `app/lib/src/data/card_repository.dart` | Save, find, list, delete own cards |
| Inbox storage | `app/lib/src/data/received_card_repository.dart` | Save, search, find duplicates, delete received cards |
| Preferences | `app/lib/src/data/settings_repository.dart` | The default card |
| Contacts / links | `app/lib/src/data/contacts_service.dart`, `link_launcher.dart` | Open the phone's new-contact screen; call, email, open websites |
| NFC | `app/lib/src/data/nfc_service.dart` | NFC status, share (Android, via channel `ebucard/nfc`) and read |
| Images | `app/lib/src/data/card_image_service.dart` | Pick, square-crop, store and show photo/logo |
| Providers | `app/lib/src/data/providers.dart` | How screens get the database and services |
| My Cards | `app/lib/src/features/cards/my_cards_screen.dart` | List of the user's cards |
| Card editor | `app/lib/src/features/cards/card_editor_screen.dart` | Create, edit and delete a card |
| Exchange | `app/lib/src/features/exchange/` | Show QR / scan QR, NFC share / NFC read, the shared card choice (`share_card.dart`) and what happens after a card is received (`receive_card.dart`) |
| Inbox | `app/lib/src/features/inbox/` | Received cards: list, search, detail, note, Save to Contacts |
| Account screen | `app/lib/src/features/auth/` | `/account`: sign in / create account (`sign_in_view.dart`), account status, sync, sign-out and deletion (`account_view.dart`), error texts |
| Accounts | `app/lib/src/account/` | `ApiClient` (tokens, refresh on 401), `SessionStore` (secure storage), `AuthController`, Apple/Google sign-in, providers |
| Sync | `app/lib/src/sync/` | `SyncEngine` (images, push, pull, last writer wins), `SyncController` (when sync runs, status), `LocalSyncState` (cursors, pending deletions), pull-to-refresh, `CardLinks` (open someone's card link, replace / turn off your own) |
| Card links in the app | `app/lib/src/features/exchange/` | `card_link_section.dart` (my link under the QR code), `card_link_screen.dart` (link opened from outside the app), `receive_card.dart` (link or vCard → Inbox) |
| Theme | `app/lib/src/core/theme.dart`, `app/assets/fonts/` | Colours, fonts and component styles from the design system; `card_avatar.dart` (in `features/cards/`) draws a photo or initials |
| Platform rules | `app/lib/src/core/exchange_capabilities.dart` | Which phones can send/receive by NFC or QR |
| Languages | `app/lib/src/l10n/*.arb`, `core/locale_resolution.dart` | UI text in en / zh-Hant / zh-Hans |
| Android NFC | `app/android/app/src/main/kotlin/.../nfc/` and `MainActivity.kt` | Type 4 tag emulation (`Type4Tag.kt`), the HCE service, and the `ebucard/nfc` channel |
| Web card (no server) | `web/` | Static page on GitHub Pages that shows offline links (`web/c/`), with Save contact, Open in eBuCard and Download; see `web/README.md` |
| Server routes | `server/routes/` | One file per endpoint (Dart Frog); each calls a service and stays thin |
| Server services | `server/lib/src/` | `auth/` (accounts, passwords, tokens, Apple/Google), `sync/` (sync and card links), `storage/` (images, S3 signing), `email/` (emails and all server text), `web/` (web card, app-link files), `http/html_page.dart` (page layout and styles), `db/` (pool, migrations), `services.dart` (wiring) |
| Design system | `docs/design-system/ebucard/MASTER.md` | Colours, fonts and rules for every screen and page; its "eBuCard decisions" section wins over the generated part |
| Server entrypoint | `server/main.dart` | Reads settings, migrates the database, schedules the daily purge |

## Conventions

* **Cloud features are behind a switch.** Accounts, sync, server links and Check for updates only run when `cloudEnabledProvider` (`app/lib/src/core/config.dart`, build setting `EBUCARD_CLOUD`) is true; it is off by default. Gate any new server-dependent UI the same way.
* **Doc comments are required.** Every package enables the `public_member_api_docs` lint, so `analyze` fails on a public class, function or field without a `///` comment. Also comment private functions and classes, and start each feature file with a short `//` header saying what the feature does.
* **Shared rules go in `ebucard_models`.** The app and the server must agree on the data format, validation and vCard output, so that logic lives in the shared package.
* **Screens talk to repositories, not the database.** Get them through the providers in `app/lib/src/data/providers.dart`.
* **No hard-coded colours or text styles.** Use `Theme.of(context).colorScheme` and `textTheme` (see `docs/design-system/ebucard/MASTER.md`); `theme_test.dart` checks the contrast of every colour pair.
* **No hard-coded UI text.** Add every string to all four ARB files (`app_en`, `app_zh_Hant`, `app_zh_Hans`, and `app_zh`, which mirrors Simplified Chinese), then run `flutter gen-l10n`.
* **Model JSON is stored data.** Add new fields as optional with a default, and never rename enum values. Old cards must keep loading.
* **Generated code is committed.** After changing a drift table, run `dart run build_runner build` in `app/` and commit `app_database.g.dart`.

## Checks to run before a PR

```sh
cd packages/ebucard_models && dart format . && dart analyze && dart test
cd server && docker compose up -d && dart format . && dart analyze && dart test
cd app && dart format lib test && flutter analyze && flutter test
cd app/android && ./gradlew test   # Kotlin unit tests (NFC tag emulation)
node --test web/test/*.test.mjs   # web card logic (same test vectors as the app)
```

### Writing app tests

* Use `pumpApp` and `memoryDatabase` from `app/test/support/test_app.dart`. They start the real app with an in-memory database and fakes for the camera (`FakeScanner`: call `scan(text)`), NFC (`FakeNfcService`: set `current`, call `deliver(message)`, inspect `sharing`), image picker, Contacts and link opening.
* For iPhone-only behaviour, pass `variant: TargetPlatformVariant.only(TargetPlatform.iOS)` to `testWidgets`.
* Inside `testWidgets`, wrap direct database calls in `dbCall(tester, ...)` (or `tester.runAsync`); otherwise they never complete.
* `pumpApp` starts the default (serverless) build; pass `cloud: true` for account, sync and server-link tests.
* To start a test signed in, save `server.sessionFor(user)` in a `MemorySessionStore` and pass it as `sessions:`.
* Sign-in and sync tests pass `server: FakeServer()` (`app/test/support/fake_server.dart`), an in-memory copy of the server API. Use `addUser`, `putFromOtherPhone`, `live`, `linkSlug` / `unlinkSlug` / `cardForSlug`, `online = false`, `expireSessions()` and `requests` to set up and check. `FakeIdentitySignIn` stands in for Apple/Google.
* `app/test/live/live_server_test.dart` runs two "phones" against a real server. It is skipped unless `EBUCARD_LIVE_API` (server URL) and `EBUCARD_LIVE_EMAIL_LOG` (the server's log file, to read confirmation links) are set.
* Real NFC and camera behaviour can't run in tests. Use the manual device test matrix in `docs/DESIGN.md` §11.

### Writing server tests

* `TestServer.start()` (`server/test/support/test_server.dart`) wipes the test database, migrates it and wires the real services with fakes: emails are kept in `email.sent`, images in `storage.objects`, and the clock is `now` (move it forward to test expiry).
* Call routes with `server.call(route.onRequest, jsonRequest(...))`; errors come back as JSON exactly as in production.
* Database changes go in a **new** entry at the end of `server/lib/src/db/migrations.dart`; never edit a released migration.

## Branches and commits

* Branch from `main` as `feature/<topic>` and open a pull request into `main`.
* Keep each PR to one roadmap step (see `docs/DESIGN.md` §11).
