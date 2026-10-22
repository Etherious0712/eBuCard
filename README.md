# eBuCard

A digital business card you swap by tapping phones together.

This is the phase 1 proof of concept: it checks that a tap between two real
phones can pass a card across, on Android and iPhone.

## How the tap works

Phones can no longer talk NFC peer-to-peer (Android Beam was removed in
Android 10, and iPhones never had it). Instead, one phone pretends to be an
NFC tag and the other phone reads it.

| Pairing | Works by tap? | How |
| --- | --- | --- |
| Android + Android | Yes | The sharing phone acts as a tag |
| Android + iPhone | Yes | The Android phone shares, the iPhone reads |
| iPhone + iPhone | No | Scan the QR code instead |

- **Android** sends with `CardEmulationService.kt`, which acts as an NFC
  Forum Type 4 tag holding one link while the Share screen is open.
- **Both** receive with the `nfc_manager` plugin on the Receive screen.
- The card itself rides inside the link's `#fragment`, so no server is
  needed yet. Phase 2 swaps `cardLinkBase` in `lib/src/business_card.dart`
  for the real domain and adds the two-way swap.

## Trying it on phones

You need Flutter installed, plus Android Studio for Android, or a Mac with
Xcode for iPhone.

```sh
flutter pub get
flutter run          # with a phone plugged in
```

**Android without building:** every push builds a debug APK. Open the
latest run under the repo's Actions tab, download `ebucard-debug-apk`, and
install it on the phone (allow installs from unknown sources).

**iPhone:** open `ios/Runner.xcworkspace` in Xcode, pick your team under
Signing & Capabilities, and run on a plugged-in iPhone 7 or newer. The NFC
capability is already set in `Runner.entitlements`.

## Test script

1. On both phones, open the app and create a card.
2. Phone A: tap **Share**. Phone B: tap **Receive** (on iPhone, then press
   **Read by tap**).
3. Touch the backs of the phones together. On an iPhone, the top edge holds
   the NFC antenna.
4. Phone B should show phone A's card. Repeat 10 times and note how many
   work and roughly how long each took.
5. Try the **Scan QR code** button between two iPhones.

Pairings to cover: Android to Android, Android to iPhone, iPhone to iPhone
(QR). Also try with Google Wallet set as the default payment app on the
Android phone.
