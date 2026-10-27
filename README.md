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
dart pub global activate dart_frog_cli
DB_PASSWORD=ebucard_dev JWT_SECRET=dev-secret-at-least-32-characters-long dart_frog dev

# App
cd app && flutter pub get && flutter test && flutter run
```

## Status

MVP done: card editor with local storage, QR exchange (show and scan), NFC exchange (Android shares; Android and iPhone read), the Inbox, and Save to Contacts. Server done: accounts (email/password, Apple, Google), sync API, images, account deletion, ready for Cloud Run. App sign-in and sync done: optional account, automatic sync of cards, Inbox and images between phones. Card links done: every synced card gets a link that opens a web card (Save contact) for people without the app, or the app itself. The app has its new look (v0.8.0, beta). Still to come: the store release; see the roadmap in `docs/DESIGN.md` §11.
