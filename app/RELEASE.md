# Release guide

How to produce store builds from this directory. Requires the Flutter
SDK plus the platform toolchains (Android SDK for Android, Xcode on
macOS for iOS) — neither is bundled in this repo.

## Preflight (any machine with Flutter)

```sh
flutter pub get
flutter analyze          # must be clean
flutter test             # engine suite + shell tests must pass
dart run tool/render_frames.dart   # optional: eyeball doc/frame_*.png
```

## Android

```sh
flutter build appbundle --release   # Play Store upload (.aab)
flutter build apk --release         # sideloadable .apk
```

Signing: the default is the debug key. For the Play Store, create an
upload keystore and a `android/key.properties`, then wire it into
`android/app/build.gradle.kts` as per
https://docs.flutter.dev/deployment/android#sign-the-app. Never commit
the keystore or `key.properties`.

Play Console assets: `store/icon_512.png` (listing icon),
`store/listing.md` (copy), `store/privacy.md` (privacy policy — host it
at a public URL, e.g. in this repo).

## iOS

On macOS with Xcode and an Apple Developer account:

```sh
flutter build ipa --release
```

Then upload via Xcode Organizer or `xcrun altool`/Transporter. The
bundle id is `com.praveenanandhanathan.xonix32`; display name, landscape
lock, and icons are already configured in `ios/Runner`.

## GPL compliance (both stores)

Xonix32 is a derivative of GPL v2 source (see `LICENSE`). To stay
compliant when distributing binaries:

- Keep the full corresponding source public — this repository is the
  canonical location; keep the store listing's source link accurate.
- Ship the license: `LICENSE` is included in the repo and referenced in
  the listing copy.
- App Store note: GPLv2 and Apple's terms have historic friction (the
  2011 VLC takedown). The lowest-risk path is a distribution blessing
  from the original author, Shawn A. VanNess
  (xonix@mindspring.com, per the source headers). Shipping with full
  public source is the pragmatic route many GPL ports take — decide
  knowingly.

## Version bumps

`pubspec.yaml` `version: X.Y.Z+N` — X.Y.Z is the user-facing version,
N the monotonically increasing build number both stores require.
