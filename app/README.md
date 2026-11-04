# eBuCard app (Flutter)

Android and iOS client. See `../docs/DESIGN.md` for the full design.

```sh
flutter pub get
flutter run --dart-define=EBUCARD_API_BASE_URL=http://<host>:8080 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>.apps.googleusercontent.com \
  --dart-define=APPLE_SIGN_IN=true
flutter analyze
flutter test
```

- `lib/src/features/` – `cards` (own cards), `exchange` (NFC / QR), `inbox` (received cards), `auth` (account screen).
- `lib/src/account/` – API client, secure session, sign-in. `lib/src/sync/` – sync engine and when it runs.
- `lib/src/core/` – config, theme (design system, `theme.dart`), platform exchange capabilities, locale resolution.
- `assets/fonts/` – Poppins and Open Sans (Latin, SIL Open Font License; licence files next to them). Chinese text uses the phone's system font.
- `lib/src/l10n/` – ARB strings for `en`, `zh_Hant`, `zh_Hans` (`app_zh.arb` is the required base and mirrors Simplified Chinese).
- `android/.../nfc/CardHostApduService.kt` – NFC Host Card Emulation service (Type 4 tag emulation).
- `ios/Runner/Runner.entitlements` – Core NFC entitlement.

## Build settings

| `--dart-define` | Meaning |
|---|---|
| `EBUCARD_CLOUD` | `true` turns on accounts, sync, server card links and Check for updates. **Off by default**: the app needs no server (DESIGN.md §2) |
| `EBUCARD_WEB_CARD_URL` | Static web card page for offline links. Default `https://etherious0712.github.io/eBuCard/c/` |
| `EBUCARD_API_BASE_URL` | Server address (cloud features only). Default `http://localhost:8080` (development) |
| `GOOGLE_SERVER_CLIENT_ID` | Google OAuth **web** client ID; the server must list it in `GOOGLE_CLIENT_IDS`. Unset: no Google button |
| `APPLE_SIGN_IN` | `true` shows Sign in with Apple on iPhone. Leave unset until the capability below is set up |

Sign-in setup still needed before release (needs the Apple Developer account and Google Cloud project, DESIGN.md §12):

- **Apple (iOS):** add the *Sign in with Apple* capability to the Runner target in Xcode (adds `com.apple.developer.applesignin` to `Runner.entitlements`) and enable it for the App ID `com.etherious.ebucard`.
- **Google (iOS):** add `GIDClientID` (iOS client ID) and the reversed client ID as a URL scheme to `ios/Runner/Info.plist`.
- **Google (Android):** register the app's SHA-1 signing fingerprint in an Android OAuth client in the same Google Cloud project.

**Card links that open the app** (DESIGN.md §4.1) also need the domain:

- **Android:** set the link host (the server's `PUBLIC_BASE_URL` host) with the Gradle property `ebucard.linkHost`, e.g. `ebucard.linkHost=cards.example.com` in `android/gradle.properties` (default `api.example.com`). The server must have `ANDROID_CERT_SHA256` set to the release signing certificate.
- **iOS:** add the *Associated Domains* capability with `applinks:<host>` to `ios/Runner/Runner.entitlements`; the server must have `APPLE_TEAM_ID` set.

The app already handles `https://<host>/c/<slug>` (route `/c/:slug`).

The Android release build needs the `INTERNET` permission for sync; it is in `android/app/src/main/AndroidManifest.xml` (debug builds get it automatically).
