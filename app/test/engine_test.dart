// Headless test suite for the Xonix32 engine port (M1).
//
// Runs under both `flutter test` and a plain `dart test/engine_test.dart`.

import 'dart:io';

import 'package:test/test.dart' as t;

import 'package:xonix32/engine.dart';

int _passed = 0;
final List<String> _failures = <String>[];

void check(String name, bool cond) {
  if (cond) {
    _passed++;
  } else {
    _failures.add(name);
    stderr.writeln('FAIL: $name');
  }
}

void expectEq(String name, Object? actual, Object? expected) {
  check('$name (expected $expected, got $actual)', actual == expected);
}

//-----------------
void testRand() {
  // MSVC CRT rand() with seed 1 famously yields this sequence; matching
  // it proves object placement will match the original Win32 build.
  final r = CRand(1);
  final got = [for (var i = 0; i < 5; i++) r.next()];
  expectEq('msvcrt rand sequence', got.join(','), '41,18467,6334,26500,19169');
}

//-----------------
void testLevelFormulas() {
  // (level, bdots, wdots, lines) computed from the original macros
  const table = [
    (1, 1, 3, 0),
    (2, 1, 3, 1),
    (3, 1, 4, 1),
    (4, 2, 4, 1),
    (6, 2, 5, 2),
    (9, 3, 6, 3),
    (12, 4, 7, 4),
    (30, 4, 8, 4), // capped at the maximums
  ];
  for (final (lev, b, w, l) in table) {
    expectEq('level $lev bdots', level2BDots(lev), b);
    expectEq('level $lev wdots', level2WDots(lev), w);
    expectEq('level $lev lines', level2Lines(lev), l);
  }
}

//-----------------
void testPalette() {
  expectEq('palette black', paletteColor(0x00), rgbBlack);
  expectEq('palette red', paletteColor(0x01), rgbRed);
  expectEq('palette bluegrn', paletteColor(0x02), rgbTeal);
  expectEq('palette red|bluegrn', paletteColor(0x03), rgbTeal);
  expectEq('palette yellow', paletteColor(0x04), rgbOlive);
  expectEq('palette white', paletteColor(0x08), rgbWhite);
  expectEq('palette ytext', paletteColor(0x10), rgbYellow);
  // The invisible high bits must not change the visible color
  expectEq('palette mark1|bluegrn', paletteColor(0x42), rgbTeal);
  expectEq('palette mark1', paletteColor(0x40), rgbBlack);
}

//-----------------
void testRectQuantization() {
  final rc = IntRect(0, 0, wndSizeX, wndSizeY);
  final game = Game(rc, rand: CRand(1));
  // 512 -> n=126 (even) -> 126*4+7 = 511; 384 -> n=94 -> 94*4+7 = 383
  expectEq('quantized width', rc.right, 511);
  expectEq('quantized height', rc.bottom, 383);

  game.initGame(1);
  game.initLevel(true);
  expectEq('guy start x', game.guy.x, (126 ~/ 2) * objMove + objOffset);
  expectEq('guy start y', game.guy.y, objOffset);
}

//-----------------
void testBoardInit() {
  final game = Game(IntRect(0, 0, wndSizeX, wndSizeY), rand: CRand(1));
  game.initGame(1);
  game.initLevel(true);

  // Border is bluegrn, interior is black
  check('border pixel is bluegrn',
      game.screen.getPel(0, 0) & xbcBluegrn != 0);
  check('interior pixel is black',
      game.screen.getPel(200, 200) == xbcBlack);

  // The fudge factor pins the initial displayed fill at exactly 15.0%
  expectEq('initial fill fraction', game.fillFrac, 150);

  // Level 1 population
  expectEq('level 1 bdots', game.activeBDots, 1);
  expectEq('level 1 wdots', game.activeWDots, 3);
  expectEq('level 1 lines', game.activeLines, 0);

  // Level 1 time limit: 60s at 30fps
  expectEq('level 1 timer', game.timer, 60);
}

//-----------------
void testFloodFill() {
  final ds = DibSection(20, 20);
  ds.drawRect(IntRect(0, 0, 20, 20), xbcBluegrn); // all boundary
  ds.drawRect(IntRect(1, 1, 19, 19), xbcBlack); // carve interior
  ds.drawFloodFill(10, 10, xbcMark1, xbcBluegrn, MaskOp.or);

  var marked = 0, leaked = 0;
  for (var y = 0; y < 20; y++) {
    for (var x = 0; x < 20; x++) {
      final p = ds.getPel(x, y);
      final inside = x >= 1 && x < 19 && y >= 1 && y < 19;
      if (p & xbcMark1 != 0) {
        marked++;
        if (!inside) leaked++;
      }
    }
  }
  expectEq('flood fill marks interior', marked, 18 * 18);
  expectEq('flood fill respects boundary', leaked, 0);
}

//-----------------
void testWipeAndFill() {
  final s = XonScreen(10, 10);
  final all = IntRect(0, 0, 10, 10);
  s.setPel(5, 5, xbcRed);
  s.setPel(6, 5, xbcRed | xbcBluegrn);
  s.wipeRedToBluegrn(all);
  expectEq('red became bluegrn', s.getPel(5, 5), xbcBluegrn);
  expectEq('red bit stripped', s.getPel(6, 5), xbcBluegrn);

  s.setAll(0);
  s.setPel(2, 2, xbcMark1);
  s.fillUnmarkedArea(all);
  expectEq('marked pixel unmarked, not filled', s.getPel(2, 2), 0);
  expectEq('unmarked pixel filled', s.getPel(3, 3), xbcBluegrn);
}

//-----------------
void testWiperErasesTrail() {
  final ds = DibSection(30, 30);
  ds.setAll(xbcRed | xbcBluegrn);
  final line = XonLine();
  line.dot0.x = 5;
  line.dot0.y = 15;
  line.dot1.x = 25;
  line.dot1.y = 15;
  line.erase(ds);
  // The wiper's erase NANDs away red+bluegrn+yellow along its path
  expectEq('wiped pixel cleared', ds.getPel(15, 15), 0);
  check('off-path pixel intact', ds.getPel(15, 5) == (xbcRed | xbcBluegrn));
}

//-----------------
void testWDotHitTest() {
  final game = Game(IntRect(0, 0, wndSizeX, wndSizeY), rand: CRand(1));
  game.initGame(1);
  game.initLevel(true);

  final w = game.wDots[0];
  w.x = 100;
  w.y = 100;
  w.dx = 0;
  w.dy = 0;
  check('no hit without red', !w.hitTest(game.screen));
  game.screen.setPel(100, 100, xbcRed, MaskOp.or);
  check('hit on red trail', w.hitTest(game.screen));
}

//-----------------
void testTimeout() {
  final game = Game(IntRect(0, 0, wndSizeX, wndSizeY), rand: CRand(1));
  game.initGame(1);
  game.initLevel(true);
  game.debugSetTimeRemaining(1);
  final ret = game.runGame();
  expectEq('timeout return', ret, RetCode.timeout);
  expectEq('timeout costs a life', game.lives, 2);
}

//-----------------
void testWinScoring() {
  final game = Game(IntRect(0, 0, wndSizeX, wndSizeY), rand: CRand(1));
  game.initGame(1);
  game.initLevel(true);

  // Flood the whole board and recount
  game.screen.setAll(xbcBluegrn);
  game.screen.countFilledPix(game.rcScr);
  final fillBefore = game.fillFrac;
  final bonusBefore = game.bonus;
  check('bonus eligible on fresh level', bonusBefore > 0);

  final ret = game.runGame();
  expectEq('win return', ret, RetCode.newLevel);
  expectEq('win advances level', game.level, 2);
  expectEq('win grants a life', game.lives, 4);
  expectEq('win score', game.score,
      1 * 100 + 1 * (fillBefore - 750) + bonusBefore);
}

//-----------------
void testCaptureRun() {
  // Steer the Xoni straight down across the sea: it must start drawing
  // when leaving the border, and convert the trail on arrival.
  final game = Game(IntRect(0, 0, wndSizeX, wndSizeY), rand: CRand(7));
  game.initGame(1);
  game.initLevel(true);

  final fillBefore = game.fillFrac;
  game.setDirection(Direction.down);

  var drew = false;
  var ret = RetCode.okay;
  for (var i = 0; i < 200 && ret == RetCode.okay; i++) {
    ret = game.runGame();
    drew |= game.guy.isDrawing;
    if (drew && !game.guy.isDrawing) break; // capture completed
  }

  check('guy drew a trail', drew);
  check('run survived (seed 7)', ret == RetCode.okay);
  check('guy stopped after capture', game.guy.dx == 0 && game.guy.dy == 0);

  // Full recount: captured territory must have increased the fill
  game.screen.countFilledPix(game.rcScr);
  check('fill increased after capture (${game.fillFrac})',
      game.fillFrac > fillBefore);

  // No red trail may survive the capture
  var redPixels = 0;
  for (var y = 0; y < game.rcScr.bottom; y++) {
    for (var x = 0; x < game.rcScr.right; x++) {
      if (game.screen.getPel(x, y) & xbcRed != 0) redPixels++;
    }
  }
  expectEq('no red left after capture', redPixels, 0);
}

//-----------------
void testControllerFlow() {
  final game = Game(IntRect(0, 0, wndSizeX, wndSizeY), rand: CRand(1));
  final ctl = GameController(game);

  expectEq('boots into splash', ctl.mode, Mode.splash);
  expectEq('attract cadence is 50ms', ctl.tickDelayMs, 50);

  for (var i = 0; i < 101 && ctl.mode == Mode.splash; i++) {
    ctl.step();
  }
  expectEq('splash rolls into demo', ctl.mode, Mode.demo);

  ctl.startGame(1);
  expectEq('new game shows READY?', ctl.overlay, MessageOverlay.ready);
  for (var i = 0; i < 41 && ctl.mode == Mode.playNewLevel; i++) {
    ctl.step();
  }
  expectEq('READY? rolls into play', ctl.mode, Mode.play);
  expectEq('play cadence is game speed', ctl.tickDelayMs, 1000 ~/ nomFps);

  // Pause freezes the mode machine and the game clock
  final timerBefore = game.timer;
  ctl.paused = true;
  for (var i = 0; i < 10; i++) {
    ctl.step();
  }
  expectEq('paused mode frozen', ctl.mode, Mode.play);
  expectEq('paused clock frozen', game.timer, timerBefore);
  ctl.paused = false;

  int? reportedScore;
  ctl.onGameOverScore = (s) => reportedScore = s;
  ctl.endGame();
  for (var i = 0; i < 81 && ctl.mode == Mode.playGameOver; i++) {
    ctl.step();
  }
  expectEq('game over rolls back to splash', ctl.mode, Mode.splash);
  check('high-score scan fired', reportedScore != null);
}

//-----------------
void testHiScoresRoundtrip() {
  final list = ScoreList();
  expectEq('empty slot name', list.getName(0), '...empty...');

  list.insert(0, 'PRAVEEN', 5000);
  list.insert(1, 'CLAUDE', 2500);
  expectEq('slot placement', list.findSlot(3000), 1);
  expectEq('non-placing score', list.findSlot(0), 10);

  final restored = ScoreList()..load(list.save());
  expectEq('roundtrip name', restored.getName(0), 'PRAVEEN');
  expectEq('roundtrip score', restored.getScore(0), 5000);
  expectEq('roundtrip name 2', restored.getName(1), 'CLAUDE');
}

//-----------------
void testOriginalHiScoresDat() {
  // The repo ships the author's own HiScores.dat — proof our decoder
  // matches the original obfuscated format.
  for (final path in ['../HiScores.dat', 'HiScores.dat']) {
    final f = File(path);
    if (!f.existsSync()) continue;
    final list = ScoreList();
    check('original HiScores.dat parses', list.load(f.readAsBytesSync()));
    var sorted = true;
    for (var i = 1; i < ScoreList.slots; i++) {
      if (list.getScore(i) > list.getScore(i - 1)) sorted = false;
    }
    check('original scores are sorted', sorted);
    check('original top name is printable ASCII',
        RegExp(r'^[\x20-\x7E]*$').hasMatch(list.getName(0)));
    print('  (original table: '
        '${list.getName(0)} ${list.getScore(0)}, '
        '${list.getName(1)} ${list.getScore(1)}, ...)');
    return;
  }
  check('HiScores.dat found', false);
}

//-----------------
void main() {
  t.test('Xonix32 engine suite', () {
    testRand();
    testLevelFormulas();
    testPalette();
    testRectQuantization();
    testBoardInit();
    testFloodFill();
    testWipeAndFill();
    testWiperErasesTrail();
    testWDotHitTest();
    testTimeout();
    testWinScoring();
    testCaptureRun();
    testControllerFlow();
    testHiScoresRoundtrip();
    testOriginalHiScoresDat();

    print('$_passed checks passed, ${_failures.length} failed');
    t.expect(_failures, t.isEmpty);
  });
}
