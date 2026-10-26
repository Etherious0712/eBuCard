# eBuCard

Electronic business cards for Android and iPhone. Exchange cards by **NFC tap** (sent from Android) or by **QR code** (any phone), and give people without the app a hosted web card.

See [`docs/DESIGN.md`](docs/DESIGN.md) for requirements, platform constraints, the exchange protocol, the data model, the API and the roadmap.

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

Scaffold only. Screens are placeholders and API endpoints return `501` until the feature PRs listed in the roadmap land.
