# Xonix32 Mobile

Faithful Android/iOS port of Xonix32 v2.51 by Shawn A. VanNess (1997–98,
GPL v2). See [`../PROPOSAL.md`](../PROPOSAL.md) for the full plan.

## Status

- **M1 — engine port: done.** The complete game logic lives in
  `lib/engine/` as pure, headless Dart with no Flutter imports: the 8bpp
  framebuffer and drawing primitives (`screen.dart`), the game objects
  (`objects.dart`), one-timeslice-per-tick gameplay (`game.dart`), the
  splash/demo/play mode machine (`controller.dart`), the palette
  (`palette.dart`), an MSVC-CRT-compatible `rand()` (`rand.dart`), and a
  byte-compatible `HiScores.dat` codec (`hi_scores.dart`).
- **M2 — Flutter/Flame shell: done.** `lib/main.dart` +
  `lib/game_shell.dart` run the engine at its fixed timestep and blit the
  framebuffer with nearest-neighbor integer scaling (fat pixels). Input:
  swipe anywhere to steer, tap to start; arrow keys / F2 on desktop.
  `lib/render/` decodes the original 8bpp BMPs (`bmp.dart`) — the splash
  and all six message overlays ship unmodified in `assets/` and are OR-
  blitted into the surface exactly like `DoBitBlt` did. Android/iOS
  scaffolding lives in `android/` and `ios/`.
- **M3 — full game loop UI: done.** Pause (tap during play, or
  F3/P/Pause; auto-pauses when the app is backgrounded), the high-score
  chain (game-over scan → name entry → table, persisted as an original-
  format `HiScores.dat` via `path_provider`), and a settings panel with
  the original ranges: game speed 10–50 FPS (F5's slider) and starting
  level 1–20 (F6's spinner). Long-press (or F5/F6) opens settings; F7
  shows the score table; F4 ends the game.
- **M4 — release polish: done.** Launcher icons on both platforms are
  generated from the original `MainFrame.ico` (`tool/make_icons.py`,
  no dependencies), launch screens are black, the app is named
  "Xonix32" and locked to landscape on Android and iOS, and the GPL
  license ships in `LICENSE`. Store listing copy, privacy policy, and
  the 512px listing icon live in `store/`; build/signing/GPL guidance
  in [`RELEASE.md`](RELEASE.md). Version 1.0.0+1. Producing the actual
  `.aab`/`.ipa` requires the Android SDK / Xcode (see RELEASE.md).

## Running

```sh
flutter pub get
flutter run           # on an attached Android/iOS device or emulator
flutter run -d chrome # or in a browser — the web build is fully
                      # self-hosted (local CanvasKit, bundled font)
flutter test          # engine suite (86 checks) + shell/council tests
dart test/engine_test.dart   # engine suite standalone, no device needed
```

For a static web deployment: `flutter build web --release`, then serve
`build/web/` from any web server — no CDN or network access needed at
runtime, verified by playing a full session in headless Chromium.

The engine suite verifies the difficulty formulas, palette layering,
board geometry, flood-fill capture, wiper erasure, collision rules,
timeout/win scoring, a full seeded capture run, the mode machine, and —
using the original `HiScores.dat` shipped in the repo root — the
high-score file format.

## Adversarial review

The port has been through a "10th man" council review — an audit that
assumed it was wrong and went hunting: line-by-line comparison against
the original C++, whole-game soak tests, a flood-fill cross-check
against an independent BFS, and codec fuzzing. Findings and fixes:
[`doc/COUNCIL.md`](doc/COUNCIL.md).

## Headless frame verification

`dart run tool/render_frames.dart` runs the engine without Flutter and
dumps PNG frames (splash, READY?, mid-game capture) to `doc/` using the
original assets — see `doc/frame_*.png` for what the port looks like.

## Fidelity notes

- Class-for-class port of `Game.cpp`, `Objects.cpp`, `Screen.cpp`,
  `DibSection.cpp`, and the `GameWnd.cpp` mode machine; constants match
  `macros.h` value-for-value.
- `CRand` reproduces the MSVC CRT `rand()` (seed 1 → 41, 18467, 6334, …)
  so object placement matches the Win32 build.
- The flood fill is iterative instead of recursive; the marked pixel set
  is identical.
- `DrawBmpFromRes` became `DibSection.drawBmp` taking decoded pixels —
  BMP resource decoding belongs to the app shell (M2).
