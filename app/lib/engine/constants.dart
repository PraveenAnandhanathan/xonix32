// Port of macros.h from the original Xonix32 v2.51 source
// by Shawn A. VanNess (1997-98), GPL v2.
//
// Every value here mirrors the original macro of the same (translated)
// name. Do not "fix" or round anything — the odd numbers are the game.

import 'dart:math' as math;

// Game info
const String gameTitle = 'Xonix32';
const String release = 'Version 2.51 (31 Dec 1998)';

// Game params (WND_SIZEX/Y, *_FPS, BONUS_CALC)
const int wndSizeX = 128 * 4; // 512
const int wndSizeY = 128 * 3; // 384
const int minFps = 10;
const int maxFps = 50;
const int nomFps = (minFps + maxFps) ~/ 2; // 30

int bonusCalc(int time) => 10 * math.max(0, time ~/ nomFps);

// Enemy counts per level (MAXBDOTS.., LEVEL2BDOTS..)
const int maxBDots = 4;
const int maxWDots = 8;
const int maxLines = 4;

int level2BDots(int lev) => math.min(maxBDots, 1 + (lev - 1) ~/ 3);
int level2WDots(int lev) => math.min(maxWDots, 3 + lev ~/ 3);
int level2Lines(int lev) => math.min(maxLines, (lev + 1) ~/ 3);

// Sizing params (OBJ_OFFSET, OBJ_SIZE, OBJ_MOVE, BRD_SIZE)
const int objOffset = 3;
const int objSize = 2 * objOffset + 1; // 7x7 sprites
const int objMove = 4; // pixels per tick
const int brdSize = 4 * objMove + objSize - 1; // 22px border

// XBC color bits: one bit per color "layer" in the 8bpp framebuffer.
const int xbcBlack = 0x00;
const int xbcRed = 0x01;
const int xbcBluegrn = 0x02;
const int xbcYellow = 0x04;
const int xbcWhite = 0x08;
const int xbcYText = 0x10;
const int xbcMark1 = 0x40; // invisible flood-fill marker

// Raster ops (MASK_*). A null op in the drawing APIs means MASK_COPY.
enum MaskOp { and, or, xor, nand }

int maskOp(int op1, int op2, MaskOp mop) {
  switch (mop) {
    case MaskOp.and:
      return op1 & op2;
    case MaskOp.or:
      return op1 | op2;
    case MaskOp.xor:
      return op1 ^ op2;
    case MaskOp.nand:
      return op1 & (~op2 & 0xFF);
  }
}

// RunGame return codes (RET_*)
enum RetCode { okay, newLevel, death, timeout }

// Window modes (MODE_*)
enum Mode {
  splash,
  demo,
  play,
  playNewLevel,
  playSuccess,
  playDeath,
  playTimeout,
  playGameOver,
}

// Message overlays chosen by DoBitBlt in GameWnd.cpp (IDB_MSG_*)
enum MessageOverlay {
  ready,
  levelComplete,
  crash,
  outOfTime,
  gameOver,
  lowTime,
}
