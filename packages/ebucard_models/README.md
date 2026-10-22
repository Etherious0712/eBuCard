# ebucard_models

Pure-Dart package shared by the Flutter app (`app/`) and the server (`server/`).

- `BusinessCard` and related value types (phones, emails, addresses, social links).
- `VCardEncoder` – serialises a card to vCard 3.0 (the version both Android and iOS Contacts import reliably).
- `SharePayload` – builds the card URL and the NDEF/QR payloads described in `docs/DESIGN.md`.

```sh
dart pub get
dart test
```
