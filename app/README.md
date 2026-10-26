# eBuCard app (Flutter)

Android and iOS client. See `../docs/DESIGN.md` for the full design.

```sh
flutter pub get
flutter run --dart-define=EBUCARD_API_BASE_URL=http://<host>:8080
flutter analyze
flutter test
```

- `lib/src/features/` – `cards` (own cards), `exchange` (NFC / QR), `inbox` (received cards), `auth`.
- `lib/src/core/` – config, platform exchange capabilities, locale resolution.
- `lib/src/l10n/` – ARB strings for `en`, `zh_Hant`, `zh_Hans` (`app_zh.arb` is the required base and mirrors Simplified Chinese).
- `android/.../nfc/CardHostApduService.kt` – NFC Host Card Emulation service (stub).
- `ios/Runner/Runner.entitlements` – Core NFC entitlement.
