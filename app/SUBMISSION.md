# Store submission checklist

Everything in this repo is ready; what remains needs your accounts and
a Mac. Build commands and signing live in [`RELEASE.md`](RELEASE.md);
listing copy in [`store/listing.md`](store/listing.md).

## Before you start

| Item | Where | Notes |
| --- | --- | --- |
| Play Console account | play.google.com/console/signup | $25 one-time |
| Apple Developer Program | developer.apple.com/programs | $99/year, enrol early — verification can take days |
| A Mac with Xcode | — | required for iOS; Android builds work anywhere |
| Upload keystore | your machine | `keytool` + copy `android/key.properties.example` → `key.properties`; Gradle is already wired. Back it up, never commit it |
| Privacy policy URL | this repo (public) | `app/store/privacy.md` on GitHub |
| Source URL (GPL) | this repo | keep public while binaries are distributed |

Optional but recommended: email Shawn A. VanNess
(`xonix@mindspring.com`, from the source headers) for a distribution
blessing. GPLv2 and the App Store have historic friction — see
`RELEASE.md` → GPL compliance.

## Assets already in the repo

- `store/icon_512.png` — Play listing icon (from the original .ico)
- `store/feature_graphic.png` — Play feature graphic, 1024×500
- `store/screenshots/android-phone/` — 5 × 1920×1080
- `store/screenshots/ios-6.9/` — 5 × 2868×1320
- `store/screenshots/ios-6.5/` — 5 × 2688×1242
- `store/screenshots/ipad-13/` — 5 × 2732×2048
- `store/listing.md` — name, short & full description, keywords
- `store/privacy.md` — "no data collected", which is literally true

All screenshots are real gameplay, regenerable with
`tool/store_screenshots.js` (see `RELEASE.md`).

## Google Play

1. Set up the upload key (above), then
   `flutter build appbundle --release` →
   `build/app/outputs/bundle/release/app-release.aab`.
   Watch the build log: a "will be DEBUG-SIGNED" warning means
   `key.properties` was not found and Play will reject the upload.
2. Play Console → **Create app**: name "Xonix32", Game, Free.
3. **App content** forms:
   - Privacy policy → the `store/privacy.md` URL
   - Data safety → *no data collected, no data shared*
   - Ads → *no ads*
   - Content rating questionnaire → Everyone
   - Target audience → 13+ keeps the form simplest
   - Government app → no; Financial features → none
4. **Internal testing** first: upload the `.aab`, install on your own
   phone from the opt-in link, play a full level. This is where swipe
   feel and speed on real hardware get judged.
5. **Store listing**: paste from `store/listing.md`, upload
   `icon_512.png`, `feature_graphic.png`, and at least 2 (use all 5)
   phone screenshots.
6. Promote to Production → submit.

Timing: reviews commonly take 1–7 days. New personal developer
accounts must first run a **closed test with 12+ testers for 14
consecutive days** before production access is granted — start that
early if it applies to you.

## Apple App Store

1. On the Mac: `flutter build ipa --release`. Xcode's automatic
   signing registers `com.praveenanandhanathan.xonix32` on first
   build once you are signed into your team.
2. App Store Connect → **My Apps → +** → New App; pick the bundle id;
   SKU `xonix32`; primary language English.
3. Upload the build (Xcode Organizer, or the Transporter app).
4. **TestFlight** first — install on your iPhone and play.
5. Metadata:
   - Description / keywords / support URL from `store/listing.md`
   - **App Privacy** → *Data Not Collected*
   - Age rating → 4+
   - Category → Games ▸ Arcade
   - Screenshots: 6.9" and 6.5" sets are required; iPad 13" is
     required because the app declares iPad support (drop it by
     restricting `TARGETED_DEVICE_FAMILY` to iPhone if you prefer)
6. Submit for review. In *Notes for review*, mention it is an
   open-source GPL port and link this repository — reviewers respond
   well to that.

Export compliance is already answered: `ITSAppUsesNonExemptEncryption`
is `false` in `Info.plist`, so uploads skip that prompt.

## After release

- Bump `version:` in `pubspec.yaml` for every upload (`X.Y.Z+N`, N
  strictly increasing).
- Keep the source public for as long as binaries are distributed —
  that is the GPL obligation, and the store listings link here.
- The web demo redeploys itself from `main`; no action needed.
