// Port of Objects.cpp/.h: the Xoni, the black/white diamonds, and the
// yellow wiper lines.

import 'dart:typed_data';

import 'constants.dart';
import 'geometry.dart';
import 'obj_data.dart';
import 'rand.dart';
import 'screen.dart';

abstract class XonObject {
  void randomize(IntRect rc, int nMinD, int nMaxD, CRand rand);
  void erase(DibSection pds);
  void move(DibSection pds, IntRect rc);
  void draw(DibSection pds);
  bool hitTest(DibSection pds);
}

class XonDot extends XonObject {
  int bkgSig = xbcBlack;
  final Uint8List? image;
  final Uint8List? _bkg;

  int x = 0, y = 0, dx = 0, dy = 0;

  XonDot([this.image]) : _bkg = image != null ? Uint8List(64) : null;

  bool get visible => image != null;

  @override
  void randomize(IntRect rc, int nMinD, int nMaxD, CRand rand) {
    x = (rand.next() % (rc.right - rc.left)) + rc.left;
    y = (rand.next() % (rc.bottom - rc.top)) + rc.top;
    dx = (rand.next() % ((nMaxD + 1) - nMinD)) + nMinD;
    if (rand.next() % 2 != 0) dx = -dx;
    dy = (rand.next() % ((nMaxD + 1) - nMinD)) + nMinD;
    if (rand.next() % 2 != 0) dy = -dy;
  }

  @override
  void erase(DibSection pds) {
    if (!visible) return;
    // Please replace divot
    pds.drawBlit(x - objOffset, y - objOffset, objSize, objSize, _bkg!);
  }

  @override
  void move(DibSection pds, IntRect rc) {
    var xx = x + dx;
    var yy = y + dy;

    // If we clip out, bounce!
    if (xx - objOffset < rc.left) {
      xx = rc.left + objOffset;
      dx = -dx;
    }
    if (xx + objOffset >= rc.right) {
      xx = rc.right - 1 - objOffset;
      dx = -dx;
    }
    if (yy - objOffset < rc.top) {
      yy = rc.top + objOffset;
      dy = -dy;
    }
    if (yy + objOffset >= rc.bottom) {
      yy = rc.bottom - 1 - objOffset;
      dy = -dy;
    }

    // Bounce off bluegrn/black surface
    var xc = xx, yc = yy;
    if (dx < 0) xc = xx - objOffset;
    if (dx > 0) xc = xx + objOffset;
    if (dy < 0) yc = yy - objOffset;
    if (dy > 0) yc = yy + objOffset;

    final cx = pds.getPel(xc, yy, xbcBluegrn, MaskOp.and);
    final cy = pds.getPel(xx, yc, xbcBluegrn, MaskOp.and);

    if (cx != bkgSig) dx = -dx;
    if (cy != bkgSig) dy = -dy;

    x = xx;
    y = yy;
  }

  @override
  void draw(DibSection pds) {
    if (!visible) return;
    // Snapshot the background before painting, then transparent blit
    pds.copyBlit(x - objOffset, y - objOffset, objSize, objSize, _bkg!);
    pds.drawBlit(x - objOffset, y - objOffset, objSize, objSize, image!);
  }

  @override
  bool hitTest(DibSection pds) => false; // no testing, by default

  bool isNearDot(XonDot dot) {
    final xx = (x - dot.x).abs();
    final yy = (y - dot.y).abs();
    return xx + yy <= objSize;
  }
}

/// Our main character.
class XonGuy extends XonDot {
  bool _drawing = false, _drawingPrev = false;

  XonGuy() : super(guyImage) {
    bkgSig = xbcBluegrn;
  }

  bool get isDrawing => _drawing;
  bool get wasDrawing => _drawingPrev;

  void reset() => _drawing = _drawingPrev = false;

  @override
  void move(DibSection pds, IntRect rc) {
    var xx = x + dx;
    var yy = y + dy;

    // If we clip out, stop!
    if (xx - objOffset < rc.left) {
      xx = rc.left + objOffset;
      dx = 0;
    }
    if (xx + objOffset >= rc.right) {
      xx = rc.right - 1 - objOffset;
      dx = 0;
    }
    if (yy - objOffset < rc.top) {
      yy = rc.top + objOffset;
      dy = 0;
    }
    if (yy + objOffset >= rc.bottom) {
      yy = rc.bottom - 1 - objOffset;
      dy = 0;
    }

    // Update our drawing state
    _drawingPrev = _drawing;
    _drawing = pds.getPel(xx, yy, xbcBluegrn, MaskOp.and) == 0;

    x = xx;
    y = yy;
  }

  @override
  bool hitTest(DibSection pds) {
    // Guy/redline collision NOT enforced in version 2.0 and higher
    return false;
  }
}

/// The black diamonds (bounce inside the filled area).
class XonDotB extends XonDot {
  XonDotB() : super(bDotImage) {
    bkgSig = xbcBluegrn;
  }
}

/// The white diamonds (bounce in the sea; deadly to the red trail).
class XonDotW extends XonDot {
  XonDotW() : super(wDotImage);

  @override
  bool hitTest(DibSection pds) {
    var xc = x, yc = y;
    if (dx < 0) xc = x - objOffset;
    if (dx > 0) xc = x + objOffset;
    if (dy < 0) yc = y - objOffset;
    if (dy > 0) yc = y + objOffset;

    if (pds.getPel(x, y, xbcRed, MaskOp.and) != 0) return true;
    if (pds.getPel(xc, y, xbcRed, MaskOp.and) != 0) return true;
    if (pds.getPel(x, yc, xbcRed, MaskOp.and) != 0) return true;
    return false;
  }
}

/// The yellow wiper lines: drawing ORs in yellow, erasing NANDs away
/// red, bluegrn, and yellow — which is what makes them "wipe".
class XonLine extends XonObject {
  final XonDot dot0 = XonDot();
  final XonDot dot1 = XonDot();

  @override
  void randomize(IntRect rc, int nMinD, int nMaxD, CRand rand) {
    dot0.randomize(rc, nMinD, nMaxD, rand);
    dot1.randomize(rc, nMinD, nMaxD, rand);
  }

  @override
  void erase(DibSection pds) {
    pds.drawLine(dot0.x, dot0.y, dot1.x, dot1.y, 3,
        xbcRed | xbcBluegrn | xbcYellow, MaskOp.nand);
  }

  @override
  void move(DibSection pds, IntRect rc) {
    dot0.move(pds, rc);
    dot1.move(pds, rc);
  }

  @override
  void draw(DibSection pds) {
    pds.drawLine(dot0.x, dot0.y, dot1.x, dot1.y, 3, xbcYellow, MaskOp.or);
  }

  @override
  bool hitTest(DibSection pds) => false;
}
