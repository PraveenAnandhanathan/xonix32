# 10th-man council review

An adversarial audit of the port, conducted on the assumption that it
was wrong somewhere. Every claim below was checked against the original
C++ (`../src/`) line by line, and the fixes are covered by regression
tests (`test/council_test.dart`, `test/shell_test.dart`).

## Confirmed defects (fixed)

| # | Severity | Area | Finding | Fix |
|---|---|---|---|---|
| 1 | High | Shell rendering | Message bitmaps (READY?, LOW TIME, …) were OR-blitted into the framebuffer and left there — but `GameWnd.cpp:359-369` draws the message, blits the frame, then **NAND-erases the ytext bits** from the message rect. Ours burned the text into the playfield until the next level init. | `_presentFrame()` now replicates draw → snapshot → erase exactly. Regression: "message overlays never burn into the framebuffer". |
| 2 | High | Overlay UI | `main.dart` mounted `GameWidget` without `MaterialApp`; the name-entry `TextField` requires `Directionality`/`Material` ancestors and would **crash on a real device**. Tests didn't catch it because they wrapped the game in their own `MaterialApp`. | Production tree moved into `buildApp()` (with `MaterialApp`); all shell tests now pump `buildApp()` itself so the tested tree can't drift from the shipped one. |
| 3 | High | Score codec | `ScoreList.save()` used `ascii.encode(name)`, which **throws** on any non-ASCII name ("Pravëen✨", CJK, emoji) — a crash at the exact moment a player sets a high score. | `sanitizeName()` clamps to printable ASCII (`?` substitution) and the 15-char limit at insert time, like the original's `char[16]`. Fuzzed with hostile names. |
| 4 | Medium | Shell timing | The LOW TIME flash used a fixed 0.5 s; the original's clock delay is `1000*NOM_FPS/fps` ms (`GameWnd.cpp:657`) — the blink tracks the speed setting. | Flash period now `nomFps/fps` seconds. |
| 5 | Low | Input | Key repeats were processed; the original ignores them (`nFlags & 0x4000`, `GameWnd.cpp:551`). | Only `KeyDownEvent` handled. |
| 6 | Low | Lifecycle | `scores` was `late` and unset until the async store open finished — an early F7 could hit `LateInitializationError`. | In-memory table assigned synchronously, swapped for the persistent store when it resolves. |
| 7 | Low | Resources | The frame `ui.Image` was never disposed on game teardown. | Disposed in `onRemove()`. |

## Attacked and held (no defect)

- **Flood-fill capture**: cross-checked against an independent BFS
  reference on 60 randomized boards — identical pixel sets every time.
- **Whole-game soak**: 3 seeds × 2 full games of pseudo-random play
  (up to 30 000 ticks each) with per-tick invariants — score
  monotonicity within a game, sane lives/level/fill ranges, and
  periodic full-framebuffer sweeps proving only the four gameplay color
  bits ever persist between ticks (no `MARK1` leak, no ytext leak).
- **Pause semantics**: `GameApp.cpp:92` shows pause gates the whole
  idle loop (all modes) — `controller.paused` matches; engine test
  asserts frozen mode and clock.
- **Amortized fill counting**: the 20-scanline incremental recount and
  its reset semantics match `Screen.cpp:90-113` including the
  fraction-only-updates-on-complete-pass behavior.
- **Difficulty/scoring/bonus formulas, rand sequence, wiper NAND
  erasure, wdot hit tests, guy drawing-state transitions**: all pinned
  by the 86-check engine suite, including the MSVC `rand()` sequence
  byte-match.

## Deliberate divergences (documented, not defects)

- Tap only starts a game when idle; the original's F2 mid-game asked a
  confirmation dialog. On mobile an accidental restart is worse than a
  missing shortcut.
- Pause is offered only during play (the original could pause the
  splash screen too); a tap on the splash starts the game instead.
- The Esc "boss key" (minimize + retitle to "Microsoft Excel") has no
  mobile equivalent; backgrounding auto-pauses instead, which
  `OnActivateApp` (`GameWnd.cpp:486`) also did.
- The name-entry dialog prefills the last name entered this session;
  the original prefilled the name of the player being displaced.

## Known environment limits

- `.aab`/`.ipa` binaries still require the Android SDK / Xcode
  (`RELEASE.md`); this CI-like environment cannot reach
  `dl.google.com`, so Gradle/AGP artifacts are unfetchable here. All
  Dart/Flutter-level verification (analyze + 9 test groups) is green.
