// Port of Game.cpp/.h: CGame — one timeslice of gameplay per runGame()
// call, exactly as the original ran one per timer tick.

import 'dart:typed_data';

import 'constants.dart';
import 'geometry.dart';
import 'objects.dart';
import 'rand.dart';
import 'screen.dart';

enum Direction { left, up, right, down }

class Game {
  late final XonScreen screen;
  final IntRect rcScr;
  final CRand rand;

  late final int _guyStartX;
  final XonGuy guy = XonGuy();
  int _nBDots = 0, _nWDots = 0, _nLines = 0;
  final List<XonDotB> bDots = List.generate(maxBDots, (_) => XonDotB());
  final List<XonDotW> wDots = List.generate(maxWDots, (_) => XonDotW());
  final List<XonLine> lines = List.generate(maxLines, (_) => XonLine());

  int _nLives = 0, _nLevel = 0, _nScore = 0;
  int _iLevelTimeLimit = 0, _iTimeRemaining = 0;
  bool _bBonusElligible = false;

  /// Mirrors CGame::CGame + CreateDS: quantizes the client rect so that
  /// size = n*OBJ_MOVE + OBJ_SIZE with n even horizontally, then creates
  /// the screen surface.
  Game(IntRect rc, {CRand? rand})
      : rcScr = rc,
        rand = rand ?? CRand(DateTime.now().millisecondsSinceEpoch & 0x7FFF) {
    var n = ((rc.right - rc.left) - objSize) ~/ objMove;
    if (n & 0x01 != 0) n--; // n must be even to center the start pos
    rc.right = rc.left + n * objMove + objSize;
    _guyStartX = (n ~/ 2) * objMove + objOffset;

    n = ((rc.bottom - rc.top) - objSize) ~/ objMove;
    rc.bottom = rc.top + n * objMove + objSize;

    screen = XonScreen(rc.width, rc.height);
    screen.setAll(xbcBlack);
  }

  int get fillFrac => screen.getFillFraction();
  int get level => _nLevel;
  int get lives => _nLives;
  int get score => _nScore;
  int get bonus => _bBonusElligible ? bonusCalc(_iTimeRemaining) : 0;
  int get timer => _iTimeRemaining ~/ nomFps; // seconds remaining

  int get activeBDots => _nBDots;
  int get activeWDots => _nWDots;
  int get activeLines => _nLines;

  /// Port of HandleKbd: arrows set the Xoni's velocity outright.
  void setDirection(Direction d) {
    switch (d) {
      case Direction.left:
        guy.dx = -objMove;
        guy.dy = 0;
      case Direction.up:
        guy.dx = 0;
        guy.dy = -objMove;
      case Direction.right:
        guy.dx = objMove;
        guy.dy = 0;
      case Direction.down:
        guy.dx = 0;
        guy.dy = objMove;
    }
  }

  /// Port of InitSplash. The title bitmap is drawn by the shell (M2);
  /// pass its pixels here to reproduce the original exactly.
  void initSplash({Uint8List? titleBmp, int bmpW = 0, int bmpH = 0}) {
    final rc = IntRect.copy(rcScr);
    screen.drawRect(rc, xbcBluegrn);
    rc.deflate(brdSize, brdSize);
    screen.drawRect(rc, xbcBlack);

    if (titleBmp != null) {
      screen.drawBmp(rcScr.right ~/ 2, rcScr.bottom ~/ 2, bmpW, bmpH, titleBmp,
          center: true, outRect: rc);
    } else {
      final cx = rcScr.right ~/ 2, cy = rcScr.bottom ~/ 2;
      rc.setRect(cx, cy, cx, cy);
    }

    // Create yellow lines for the "X"
    lines[0].randomize(rcScr, 2, 2, rand);
    lines[1].randomize(rcScr, 2, 2, rand);

    final x = rc.left - 10;
    final y = (rc.top + rc.bottom) ~/ 2 - 5;
    lines[0].dot0.x = x - 20;
    lines[0].dot0.y = y - 40;
    lines[0].dot1.x = x + 20;
    lines[0].dot1.y = y + 40;
    lines[0].draw(screen);
    lines[1].dot0.x = x - 20;
    lines[1].dot0.y = y + 40;
    lines[1].dot1.x = x + 20;
    lines[1].dot1.y = y - 40;
    lines[1].draw(screen);
  }

  void splash() {
    // nothing, for now (as in the original)
  }

  void initDemo() {
    // nothing, for now (as in the original)
  }

  /// Port of Demo: animate the two yellow lines.
  void demo() {
    lines[1].erase(screen);
    lines[0].erase(screen);
    lines[0].move(screen, rcScr);
    lines[1].move(screen, rcScr);
    lines[0].draw(screen);
    lines[1].draw(screen);
  }

  void initGame(int nInitLevel) {
    _nLevel = nInitLevel;
    _nScore = 0;
    _nLives = 3;
    if (nInitLevel >= 10) _nLives = 5; // a little help
  }

  void initLevel(bool bClear) {
    final rc = IntRect(0, 0, 0, 0);

    // Erase old objects if restarting after a death
    if (!bClear) {
      eraseObjects();
      screen.setAll(xbcBluegrn, MaskOp.and);
    }

    // Initialize the board, if necessary
    if (bClear) {
      final b = IntRect.copy(rcScr);
      screen.drawRect(b, xbcBluegrn);
      b.deflate(brdSize, brdSize);
      screen.drawRect(b, xbcBlack);
      screen.countFilledPix(rcScr);
      screen.setFudgeFactor(screen.getFillFraction());
    }

    // Grant/revoke bonus elligibility
    _bBonusElligible = bClear;

    // Calculate time limit based on level
    final capped = 60 * _nLevel < 60 * 5 ? 60 * _nLevel : 60 * 5;
    _iLevelTimeLimit = nomFps * capped;
    _iTimeRemaining = _iLevelTimeLimit;

    // Set starting position at top center of screen
    guy.x = _guyStartX;
    guy.y = objOffset;
    guy.dx = 0;
    guy.dy = 0;
    guy.reset();

    // Always randomize the bdots
    _nBDots = level2BDots(_nLevel);
    rc.setRect(20, rcScr.bottom - 10, rcScr.right - 20, rcScr.bottom - 8);
    for (var i = 0; i < _nBDots; i++) {
      bDots[i].randomize(rc, 2, objMove - 1, rand);
    }

    // Don't randomize wdots and ylines after a death
    if (bClear) {
      _nWDots = level2WDots(_nLevel);
      rc.setRect(50, 50, rcScr.right - 50, rcScr.bottom - 50);
      for (var i = 0; i < _nWDots; i++) {
        wDots[i].randomize(rc, 1, objMove - 1, rand);
      }

      _nLines = level2Lines(_nLevel);
      rc.setRect(50, 50, rcScr.right - 50, rcScr.bottom - 50);
      for (var i = 0; i < _nLines; i++) {
        lines[i].randomize(rc, 1, objMove - 2, rand);
      }
    }

    drawObjects();
  }

  /// Port of RunGame: one timeslice. Returns what happened.
  RetCode runGame() {
    var bDead = false;

    eraseObjects();

    guy.move(screen, rcScr);

    // Starting to draw?
    if (!guy.wasDrawing && guy.isDrawing) {
      // Paint a little extra redness to ensure a good connection
      final rc = IntRect(guy.x - 2, guy.y - 2, guy.x + 3, guy.y + 3);
      rc.offset(-(guy.dx ~/ 2), -(guy.dy ~/ 2));
      screen.drawRect(rc, xbcRed, MaskOp.or);
    }

    // Finished drawing?
    if (guy.wasDrawing && !guy.isDrawing) {
      // Paint a little extra redness to ensure a good connection
      final rc = IntRect(guy.x - 2, guy.y - 2, guy.x + 3, guy.y + 3);
      rc.offset(-(guy.dx ~/ 2), -(guy.dy ~/ 2));
      screen.drawRect(rc, xbcRed, MaskOp.or);

      // Change water into wine
      screen.wipeRedToBluegrn(rcScr);

      // Mark wdot- and yline-territory
      for (var i = 0; i < _nWDots; i++) {
        screen.drawFloodFill(
            wDots[i].x, wDots[i].y, xbcMark1, xbcBluegrn, MaskOp.or);
      }
      for (var i = 0; i < _nLines; i++) {
        screen.drawFloodFill(lines[i].dot0.x, lines[i].dot0.y, xbcMark1,
            xbcBluegrn, MaskOp.or);
        screen.drawFloodFill(lines[i].dot1.x, lines[i].dot1.y, xbcMark1,
            xbcBluegrn, MaskOp.or);
      }

      // Any unmarked black becomes blue!
      screen.fillUnmarkedArea(rcScr);

      // Stop the guy, and notify him of the state-change
      guy.dx = 0;
      guy.dy = 0;
      guy.reset();

      // Calculate our fill fraction
      screen.countFilledPix(rcScr);
    }

    // Move other objects (includes bouncing and clipping logic)
    for (var i = 0; i < _nBDots; i++) {
      bDots[i].move(screen, rcScr);
    }
    for (var i = 0; i < _nWDots; i++) {
      wDots[i].move(screen, rcScr);
    }
    for (var i = 0; i < _nLines; i++) {
      lines[i].move(screen, rcScr);
    }

    // Collision detection: wdot/redline
    for (var i = 0; i < _nWDots; i++) {
      bDead |= wDots[i].hitTest(screen);
    }

    // Proximity collision detection: guy/bdot or guy/wdot
    if (guy.isDrawing) {
      for (var i = 0; i < _nWDots; i++) {
        bDead |= guy.isNearDot(wDots[i]);
      }
    } else {
      for (var i = 0; i < _nBDots; i++) {
        bDead |= guy.isNearDot(bDots[i]);
      }
    }

    // Update fill percentage (amortized)
    screen.countFilledPix(rcScr, 20);

    drawObjects();

    // Check if we've won
    if (screen.getFillFraction() >= 750) {
      _nScore += _nLevel * 100;
      _nScore += _nLevel * (screen.getFillFraction() - 750); // overfilling
      _nScore += bonus; // for speed
      _nLevel++;
      _nLives++;
      return RetCode.newLevel;
    }

    // Check timer
    if (--_iTimeRemaining <= 0) {
      _nLives--;
      return RetCode.timeout;
    }

    // Check death flag
    if (bDead) {
      _nLives--;
      return RetCode.death;
    }

    return RetCode.okay;
  }

  void drawObjects() {
    // Redness under the guy while drawing
    final rc = IntRect(guy.x - 2, guy.y - 2, guy.x + 3, guy.y + 3);
    if (guy.wasDrawing || guy.isDrawing) {
      screen.drawRect(rc, xbcRed, MaskOp.or);
    }

    // Draw/erase must occur in opposite order!
    for (var i = 0; i < _nLines; i++) {
      lines[i].draw(screen);
    }
    for (var i = 0; i < _nWDots; i++) {
      wDots[i].draw(screen);
    }
    for (var i = 0; i < _nBDots; i++) {
      bDots[i].draw(screen);
    }
    guy.draw(screen);
  }

  void eraseObjects() {
    // Draw/erase must occur in opposite order!
    guy.erase(screen);
    for (var i = _nBDots - 1; i >= 0; i--) {
      bDots[i].erase(screen);
    }
    for (var i = _nWDots - 1; i >= 0; i--) {
      wDots[i].erase(screen);
    }
    for (var i = _nLines - 1; i >= 0; i--) {
      lines[i].erase(screen);
    }
  }

  void gameOver() {
    if (screen.getFillFraction() >= 200) {
      _nScore += (_nLevel * screen.getFillFraction()) ~/ 10;
    }
  }

  /// Test hook: force the remaining time (in ticks).
  void debugSetTimeRemaining(int ticks) => _iTimeRemaining = ticks;
}
