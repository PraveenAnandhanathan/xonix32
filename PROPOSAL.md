# Proposal: Xonix32 Mobile (Android + iOS)

## 1. Goal

A faithful mobile port of Xonix32 v2.51 — not a "modern reimagining." Same
512×384 playfield feel, same six-color palette, same movement cadence, same
splash/demo/message screens, same scoring. The only things that change are
what *must* change on a phone: input and screen fitting.

## 2. What "same feel" actually means — the extracted spec

Pulled directly from the original source (`macros.h`, `palette.h`,
`Game.cpp`, `obj_data.h`), so we're cloning facts, not memories.

### Colors (only 6 in the whole game)

| Element | Original value | Hex |
|---|---|---|
| Sea (unfilled) | black | `#000000` |
| Xoni (player) + trail | red | `#FF0000` |
| Filled area ("blueness") | teal | `#008484` |
| Yellow wipers (lines) | olive | `#848400` |
| White diamonds | white | `#FFFFFF` |
| HUD text | yellow | `#FFFF00` |

### Geometry & timing (`macros.h`)

- Playfield 512×384 (`128*4 × 128*3`), border thickness 22 px
- Every object is a 7×7 pixel sprite (`OBJ_SIZE`), defined as byte arrays in
  `obj_data.h`
- Movement step is 4 px per tick (`OBJ_MOVE`) — this quantized, chunky
  motion *is* the vibe
- Game clock: 10–50 FPS adjustable (F5), nominal 30 — logic tick and speed
  setting must be preserved exactly

### Difficulty curve (`macros.h` / `Game.cpp`)

- Black dots: `min(4, 1+(level−1)/3)`, white dots: `min(8, 3+level/3)`,
  wipers: `min(4, (level+1)/3)` — so level 1 = 1 black, 3 white, 0 wipers
- Win at 75% fill; overfill bonus = `level × (fill‰ − 750)`; time bonus =
  `10 × seconds remaining`; +1 life per level; time limit = level minutes,
  capped at 5

### Screens & chrome

- Splash screen (`splash.bmp`), attract/demo mode, and the six in-game
  message bitmaps (READY?, LEVEL COMPLETE, GAME OVER, crash, low-time,
  out-of-time) — all shipped in `src/res/`, all reusable as-is
- Yellow-text HUD: score, level, lives, time, fill %
- Top-10 score table persisted like `HiScores.dat`

## 3. Recommended stack: Flutter + Flame

One codebase, both stores, and the right rendering model for this game:

- The whole game is a 512×384 indexed-color framebuffer. Flame (Flutter's
  2D game engine) renders to a fixed 512×384 virtual canvas scaled up with
  **nearest-neighbor integer scaling** — crisp fat pixels, no smoothing
  (`FixedResolutionViewport`).
- The original logic is small (~2,500 lines of C++ across `Game.cpp`,
  `Objects.cpp`, `Screen.cpp`, `DibSection.cpp`) and ports almost
  mechanically to Dart, class-for-class.
- Alternatives considered: Unity (huge runtime for a 6-color game),
  React Native (weaker canvas performance and game-loop control),
  native ×2 (double the work for zero fidelity gain), Godot (fine, but
  Flutter has better store tooling).

## 4. Architecture

```
app/
├── lib/
│   ├── engine/          # pure Dart port, no Flutter imports — testable headless
│   │   ├── game.dart        # CGame port: modes, levels, scoring, timer
│   │   ├── objects.dart     # Guy, black/white dots, wiper lines
│   │   ├── screen.dart      # the 512×384 byte grid + flood-fill capture
│   │   └── constants.dart   # every macro from macros.h, same names/values
│   ├── render/          # Flame: framebuffer → texture, palette, integer scaling
│   ├── input/           # touch → direction events
│   ├── ui/              # HUD, menus, high-score table, settings
│   └── assets/          # splash.bmp, message bitmaps, icon (converted to PNG)
```

Key principle: **the engine is a deterministic fixed-timestep port** of the
original. Rendering interpolates nothing — one logic tick, one frame, just
like 1998. The screen grid keeps the original's indexed-byte-per-pixel
design (it's how flood-fill area capture works in `DibSection.cpp`), so
fill behavior is bit-identical.

## 5. Controls

The original is 4-directional with instant turns. In priority order:

1. **Swipe-anywhere** (primary): swipe any direction anywhere on screen to
   turn — zero screen occlusion.
2. **Optional on-screen D-pad** (settings toggle): translucent,
   corner-positioned.
3. Tap to pause (F3), long-press pause menu for the F5 speed / F6 start
   level settings. No boss key — Esc doesn't survive the platform
   transition.

Landscape orientation, 4:3 playfield letterboxed on black (invisible, since
the sea is black). HUD in the letterbox margins in the original yellow.

## 6. Fidelity extras

- **Demo/attract mode** after idle on the title screen, like the original
  (splash 5 s → demo 15 s → repeat).
- **High scores**: same top-10 table; mirror the original `HiScores.dat`
  format (XOR-0x55 obfuscation and all) so the table is byte-compatible.
- **Sound**: the original had none. Ship silent by default (that *is* the
  vibe); optionally retro SFX behind an off-by-default toggle.
- **Verification**: run the original `Xonix32.exe` under Wine, capture
  frames, and pixel-compare against the port at the same tick.

## 7. Licensing

The original is **GPL v2**. A port is a derivative work, so the mobile
app's source must also be GPL and published (it can live in this repo).

- **Android / Play Store**: GPL apps are fine.
- **iOS / App Store**: known historical friction between GPLv2 and App
  Store terms (VLC was pulled over it in 2011, later resolved by
  relicensing). Lowest-risk path: email Shawn A. VanNess
  (`xonix@mindspring.com`, from the source headers) for a blessing /
  dual-license for App Store distribution. If unreachable, the pragmatic
  reading most GPL game ports use today is to ship anyway with full source
  published — a call to make knowingly.

## 8. Milestones

| Phase | Deliverable | Effort |
|---|---|---|
| M1 | Engine port in pure Dart, headless tests (fill capture, collisions, scoring vs. original formulas) | ~1 week |
| M2 | Flame rendering (palette framebuffer, integer scaling) + swipe input → playable level 1 on a device | ~1 week |
| M3 | Full game loop: splash, demo mode, HUD, message bitmaps, levels, high scores, pause/speed settings | ~1 week |
| M4 | Polish, D-pad option, app icons (from `MainFrame.ico`), store metadata, Wine-based fidelity pass, release builds | ~1 week |

Everything lives in this repo under `app/`, keeping the original source
untouched at the root as the reference implementation.
