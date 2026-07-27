// Port of DibSection.cpp/.h and Screen.cpp/.h: the 8bpp framebuffer,
// drawing primitives, flood fill, and the fill-fraction accounting.
//
// The original recursed in DrawFloodFill; we use an explicit stack (the
// marked pixel set is identical, only visit order differs).

import 'dart:typed_data';

import 'constants.dart';
import 'geometry.dart';

int _clamp(int x, int lo, int hi) => x < lo ? lo : (x > hi ? hi : x);

class DibSection {
  final int width, height;
  final int scanSize; // stride, dword-aligned like the Win32 DIB
  final Uint8List bits;

  DibSection(this.width, this.height)
      : scanSize = ((width + 3) ~/ 4) * 4,
        bits = Uint8List((((width + 3) ~/ 4) * 4) * height);

  int _p(int x, int y) => y * scanSize + x;

  int getPel(int x, int y, [int c = 0, MaskOp? mop]) {
    x = _clamp(x, 0, width - 1);
    y = _clamp(y, 0, height - 1);
    final p = bits[_p(x, y)];
    if (mop == null) return p;
    return maskOp(p, c, mop);
  }

  void setPel(int x, int y, int c, [MaskOp? mop]) {
    x = _clamp(x, 0, width - 1);
    y = _clamp(y, 0, height - 1);
    final i = _p(x, y);
    bits[i] = mop == null ? c : maskOp(bits[i], c, mop);
  }

  void setAll(int c, [MaskOp? mop]) {
    for (var i = 0; i < bits.length; i++) {
      bits[i] = mop == null ? c : maskOp(bits[i], c, mop);
    }
  }

  void drawHorzLine(int x0, int x1, int y, int c, [MaskOp? mop]) {
    // (x1,y) not included
    x0 = _clamp(x0, 0, width);
    x1 = _clamp(x1, 0, width);
    y = _clamp(y, 0, height - 1);
    if (x1 < x0) {
      final t = x0;
      x0 = x1;
      x1 = t;
    }
    var i = _p(x0, y);
    while (x0 < x1) {
      bits[i] = mop == null ? c : maskOp(bits[i], c, mop);
      x0++;
      i++;
    }
  }

  void drawLine(int x0, int y0, int x1, int y1, int w, int c, [MaskOp? mop]) {
    // (x1,y1) not included
    x0 = _clamp(x0, 0, width);
    y0 = _clamp(y0, 0, height);
    x1 = _clamp(x1, 0, width);
    y1 = _clamp(y1, 0, height);
    w = _clamp(w, 1, 5);

    final dx = x1 - x0, dy = y1 - y0;
    final dt = dx.abs() > dy.abs() ? dx.abs() : dy.abs();

    final rc = IntRect(0, 0, 0, 0);
    for (var tt = 0; tt < dt; tt++) {
      final xx = x0 + (tt * dx) ~/ dt;
      final yy = y0 + (tt * dy) ~/ dt;
      if (w == 1) {
        setPel(xx, yy, c, mop);
      } else {
        rc.left = xx - (w ~/ 2);
        rc.top = yy - (w ~/ 2);
        rc.right = rc.left + w;
        rc.bottom = rc.top + w;
        drawRect(rc, c, mop);
      }
    }
  }

  void drawRect(IntRect rcIn, int c, [MaskOp? mop]) {
    // left&top included, right&bottom not included
    final rc = IntRect.copy(rcIn);
    rc.left = _clamp(rc.left, 0, width);
    rc.top = _clamp(rc.top, 0, height);
    rc.right = _clamp(rc.right, 0, width);
    rc.bottom = _clamp(rc.bottom, 0, height);
    rc.normalize();

    for (var y = rc.top; y < rc.bottom; y++) {
      var i = _p(rc.left, y);
      for (var x = rc.left; x < rc.right; x++) {
        bits[i] = mop == null ? c : maskOp(bits[i], c, mop);
        i++;
      }
    }
  }

  /// Scanline flood fill: paints c over the region reachable from (x,y)
  /// bounded by pixels carrying any of the (c|cc) bits.
  void drawFloodFill(int x, int y, int c, int cc, [MaskOp? mop]) {
    x = _clamp(x, 0, width - 1);
    y = _clamp(y, 0, height - 1);

    final stack = <int>[x, y];
    while (stack.isNotEmpty) {
      final py = stack.removeLast();
      final px = stack.removeLast();

      if (getPel(px, py, c | cc, MaskOp.and) != 0) continue;

      var xl = px, xr = px;
      while (getPel(xl, py, c | cc, MaskOp.and) == 0) {
        xl--;
        if (xl < -1) break; // defensive: original relies on a border
      }
      while (getPel(xr, py, c | cc, MaskOp.and) == 0) {
        xr++;
        if (xr > width) break; // defensive: original relies on a border
      }
      if (xl < px) xl++;
      drawHorzLine(xl, xr, py, c, mop);

      for (var xx = xl; xx < xr; xx++) {
        stack..add(xx)..add(py - 1);
        stack..add(xx)..add(py + 1);
      }
    }
  }

  void copyBlit(int x, int y, int w, int h, Uint8List dst) {
    x = _clamp(x, 0, width - 1);
    y = _clamp(y, 0, height - 1);
    w = _clamp(w, 0, width - x);
    h = _clamp(h, 0, height - y);

    var d = 0;
    for (var yy = y; yy < y + h; yy++) {
      var i = _p(x, yy);
      for (var xx = x; xx < x + w; xx++) {
        dst[d++] = bits[i++];
      }
    }
  }

  void drawBlit(int x, int y, int w, int h, Uint8List src) {
    x = _clamp(x, 0, width - 1);
    y = _clamp(y, 0, height - 1);
    w = _clamp(w, 0, width - x);
    h = _clamp(h, 0, height - y);

    var s = 0;
    for (var yy = y; yy < y + h; yy++) {
      var i = _p(x, yy);
      for (var xx = x; xx < x + w; xx++) {
        if (src[s] != 255) bits[i] = src[s]; // transparent color-key
        s++;
        i++;
      }
    }
  }

  /// Replacement for DrawBmpFromRes: blits a top-down w*h bitmap of
  /// palette indices (bitmap decoding is the app shell's job in M2).
  void drawBmp(int x, int y, int w, int h, Uint8List pixels,
      {bool center = false, IntRect? outRect, MaskOp? mop}) {
    if (center) {
      x -= w ~/ 2;
      y -= h ~/ 2;
    }
    x = _clamp(x, 0, width - 1);
    y = _clamp(y, 0, height - 1);
    w = _clamp(w, 0, width - x);
    h = _clamp(h, 0, height - y);

    outRect?.setRect(x, y, x + w, y + h);

    var s = 0;
    for (var yy = y; yy < y + h; yy++) {
      var i = _p(x, yy);
      for (var xx = x; xx < x + w; xx++) {
        bits[i] = mop == null ? pixels[s] : maskOp(bits[i], pixels[s], mop);
        s++;
        i++;
      }
    }
  }
}

/// Port of CXonScreen: the game surface with fill-fraction accounting.
class XonScreen extends DibSection {
  int _fillFraction1k = 0; // fraction of surface filled (1000 = 100%)
  int _fudgeFactor1k = 0; // subtracted from the fraction for aesthetics
  int _filledPix = 0; // accumulator for bluegrn pixel count
  int _scanLine = 0; // accumulator raster-marker

  XonScreen(super.width, super.height);

  void setFudgeFactor(int i) {
    if (_fudgeFactor1k == 0) _fudgeFactor1k = i - 150; // 15% base value
  }

  int getFillFraction() => _fillFraction1k - _fudgeFactor1k;

  void wipeRedToBluegrn(IntRect rc) {
    for (var yy = rc.top; yy < rc.bottom; yy++) {
      var i = _p(rc.left, yy);
      for (var xx = rc.left; xx < rc.right; xx++) {
        if (bits[i] & xbcRed != 0) {
          bits[i] = (bits[i] & ~xbcRed) | xbcBluegrn;
        }
        i++;
      }
    }
  }

  void fillUnmarkedArea(IntRect rc) {
    for (var yy = rc.top; yy < rc.bottom; yy++) {
      var i = _p(rc.left, yy);
      for (var xx = rc.left; xx < rc.right; xx++) {
        if (bits[i] & xbcMark1 != 0) {
          bits[i] &= ~xbcMark1;
        } else {
          bits[i] |= xbcBluegrn;
        }
        i++;
      }
    }
  }

  /// Counts bluegrn pixels. nScanLines=0 restarts and scans everything;
  /// otherwise scans incrementally, updating the fraction when a full
  /// pass completes (the original amortizes the count over frames).
  void countFilledPix(IntRect rc, [int nScanLines = 0]) {
    if (nScanLines == 0) {
      nScanLines = rc.height;
      _filledPix = 0;
      _scanLine = rc.top;
    }
    final nEndLine =
        rc.bottom < _scanLine + nScanLines ? rc.bottom : _scanLine + nScanLines;
    for (var yy = _scanLine; yy < nEndLine; yy++) {
      for (var xx = rc.left; xx < rc.right; xx++) {
        if (getPel(xx, yy, xbcBluegrn, MaskOp.and) != 0) _filledPix++;
      }
    }
    _scanLine = nEndLine;
    if (nEndLine >= rc.bottom) {
      _fillFraction1k = (1000 * _filledPix) ~/ (rc.width * rc.height);
      _filledPix = 0;
      _scanLine = 0;
    }
  }
}
