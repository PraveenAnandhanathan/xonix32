// Converts the engine's 8bpp indexed framebuffer to RGBA bytes using
// the original palette. Pure Dart so the headless tools can use it too.

import 'dart:typed_data';

import '../engine/palette.dart';
import '../engine/screen.dart';

/// 256-entry palette as little-endian RGBA words (bytes r,g,b,a).
final Uint32List _rgbaPalette = (() {
  final t = Uint32List(256);
  for (var i = 0; i < 256; i++) {
    final argb = palette256[i];
    final r = (argb >> 16) & 0xFF, g = (argb >> 8) & 0xFF, b = argb & 0xFF;
    t[i] = (0xFF << 24) | (b << 16) | (g << 8) | r;
  }
  return t;
})();

/// Fills [rgba] (a width*height Uint32List view) from the screen bits.
void framebufferToRgba(DibSection screen, Uint32List rgba) {
  final bits = screen.bits;
  final w = screen.width, h = screen.height, stride = screen.scanSize;
  var d = 0;
  for (var y = 0; y < h; y++) {
    var s = y * stride;
    for (var x = 0; x < w; x++) {
      rgba[d++] = _rgbaPalette[bits[s++]];
    }
  }
}
