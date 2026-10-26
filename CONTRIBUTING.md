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
| App entry & routes | `app/lib/main.dart`, `app/lib/src/app.dart` | Riverpod scope, theme, languages, route table |
| Bottom tabs | `app/lib/src/home_shell.dart` | My Cards / Exchange / Inbox navigation |
| Local database | `app/lib/src/data/app_database.dart` | SQLite tables (drift) |
| Card storage | `app/lib/src/data/card_repository.dart` | Save, find, list, delete own cards |
| Inbox storage | `app/lib/src/data/received_card_repository.dart` | Save, search, find duplicates, delete received cards |
| Preferences | `app/lib/src/data/settings_repository.dart` | The default card |
| Contacts / links | `app/lib/src/data/contacts_service.dart`, `link_launcher.dart` | Open the phone's new-contact screen; call, email, open websites |
| Images | `app/lib/src/data/card_image_service.dart` | Pick, square-crop, store and show photo/logo |
| Providers | `app/lib/src/data/providers.dart` | How screens get the database and services |
| My Cards | `app/lib/src/features/cards/my_cards_screen.dart` | List of the user's cards |
| Card editor | `app/lib/src/features/cards/card_editor_screen.dart` | Create, edit and delete a card |
| Exchange | `app/lib/src/features/exchange/` | Show my QR code, scan a QR code, and what happens after a scan (`receive_card.dart`); NFC to come |
| Inbox | `app/lib/src/features/inbox/` | Received cards: list, search, detail, note, Save to Contacts |
| Sign in | `app/lib/src/features/auth/` | Placeholder for a later PR |
| Platform rules | `app/lib/src/core/exchange_capabilities.dart` | Which phones can send/receive by NFC or QR |
| Languages | `app/lib/src/l10n/*.arb`, `core/locale_resolution.dart` | UI text in en / zh-Hant / zh-Hans |
| Android NFC | `app/android/app/src/main/kotlin/.../nfc/CardHostApduService.kt` | NFC tag emulation (stub) |
| Server | `server/routes/` | One file per endpoint (Dart Frog); stubs return 501 |

## Conventions

* **Doc comments are required.** Every package enables the `public_member_api_docs` lint, so `analyze` fails on a public class, function or field without a `///` comment. Also comment private functions and classes, and start each feature file with a short `//` header saying what the feature does.
* **Shared rules go in `ebucard_models`.** The app and the server must agree on the data format, validation and vCard output, so that logic lives in the shared package.
* **Screens talk to repositories, not the database.** Get them through the providers in `app/lib/src/data/providers.dart`.
* **No hard-coded UI text.** Add every string to all four ARB files (`app_en`, `app_zh_Hant`, `app_zh_Hans`, and `app_zh`, which mirrors Simplified Chinese), then run `flutter gen-l10n`.
* **Model JSON is stored data.** Add new fields as optional with a default, and never rename enum values. Old cards must keep loading.
* **Generated code is committed.** After changing a drift table, run `dart run build_runner build` in `app/` and commit `app_database.g.dart`.

## Checks to run before a PR

```sh
cd packages/ebucard_models && dart format . && dart analyze && dart test
cd server && dart format . && dart analyze && dart test
cd app && dart format lib test && flutter analyze && flutter test
```

### Writing app tests

* Use `pumpApp` and `memoryDatabase` from `app/test/support/test_app.dart`. They start the real app with an in-memory database and fakes for the camera (`FakeScanner`: call `scan(text)`), image picker, Contacts and link opening.
* Inside `testWidgets`, wrap direct database calls in `dbCall(tester, ...)` (or `tester.runAsync`); otherwise they never complete.
* NFC and camera behaviour can't run in tests. Use the manual device test matrix in `docs/DESIGN.md` §11.

## Branches and commits

* Branch from `main` as `feature/<topic>` and open a pull request into `main`.
* Keep each PR to one roadmap step (see `docs/DESIGN.md` §11).
