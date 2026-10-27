# eBuCard

Electronic business cards for Android and iPhone. Exchange cards by **NFC tap** (sent from Android) or by **QR code** (any phone), and give people without the app a hosted web card.

See [`docs/DESIGN.md`](docs/DESIGN.md) for requirements, platform constraints, the exchange protocol, the data model, the API and the roadmap, and [`CONTRIBUTING.md`](CONTRIBUTING.md) for a code tour and project conventions.

## Repository layout

| Path | What |
|---|---|
| `app/` | Flutter client (Android + iOS) |
| `server/` | Dart Frog API server and public web card, PostgreSQL |
| `packages/ebucard_models/` | Shared Dart models, vCard and share-payload encoding |
| `docs/` | Design documentation |

## Getting started

Requires the Flutter SDK (stable channel, which includes Dart).

```sh
# Shared models
cd packages/ebucard_models && dart pub get && dart test

# Server
cd server && docker compose up -d && dart pub get && dart test
dart pub global activate dart_frog_cli && dart_frog dev

# App
cd app && flutter pub get && flutter test && flutter run
```

## Status

MVP done: card editor with local storage, QR exchange (show and scan), NFC exchange (Android shares; Android and iPhone read), the Inbox, and Save to Contacts. Still to come: accounts and sync, card links and the web card, and the server API (endpoints return `501`); see the roadmap in `docs/DESIGN.md` §11.
