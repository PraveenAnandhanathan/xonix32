# Xonix32 Mobile

Faithful Android/iOS port of Xonix32 v2.51 by Shawn A. VanNess (1997–98,
GPL v2). See [`../PROPOSAL.md`](../PROPOSAL.md) for the full plan.

## Status

- **M1 — engine port (this directory): done.** The complete game logic
  lives in `lib/engine/` as pure, headless Dart with no Flutter imports:
  the 8bpp framebuffer and drawing primitives (`screen.dart`), the game
  objects (`objects.dart`), one-timeslice-per-tick gameplay (`game.dart`),
  the splash/demo/play mode machine (`controller.dart`), the palette
  (`palette.dart`), an MSVC-CRT-compatible `rand()` (`rand.dart`), and a
  byte-compatible `HiScores.dat` codec (`hi_scores.dart`).
- M2 — Flame rendering + swipe input: next.
- M3 — full game loop UI (splash/demo/HUD/high scores): pending.
- M4 — polish + store release: pending.

## Running the tests

The test suite is dependency-free:

```sh
dart pub get   # once, resolves the empty package config
dart test/engine_test.dart
```

It verifies the difficulty formulas, palette layering, board geometry,
flood-fill capture, wiper erasure, collision rules, timeout/win scoring, a
full seeded capture run, the mode machine, and — using the original
`HiScores.dat` shipped in the repo root — the high-score file format.

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
