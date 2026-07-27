// Port of palette.h: the 256-entry palette as 0xAARRGGBB values.
//
// Xonix32 uses only 6 colors, arranged so each color bit acts as a
// "layer" with a fixed priority (ytext > white > yellow > bluegrn > red >
// black), repeating every 32 entries so the invisible high bits (mark1
// etc.) don't affect the visible color.

const int rgbBlack = 0xFF000000;
const int rgbRed = 0xFFFF0000;
const int rgbTeal = 0xFF008484; // the filled "blueness" (XBC_BLUEGRN)
const int rgbOlive = 0xFF848400; // the yellow wipers (XBC_YELLOW)
const int rgbWhite = 0xFFFFFFFF;
const int rgbYellow = 0xFFFFFF00; // HUD text (XBC_YTEXT)

/// Visible color for a framebuffer byte, replicating g_rgbPalette.
int paletteColor(int index) {
  final i = index & 0x1F; // pattern repeats every 32 entries
  if (i >= 16) return rgbYellow;
  if (i >= 8) return rgbWhite;
  if (i >= 4) return rgbOlive;
  if (i >= 2) return rgbTeal;
  if (i >= 1) return rgbRed;
  return rgbBlack;
}

/// The full 256-entry table, for blitting the framebuffer to RGBA.
final List<int> palette256 =
    List<int>.unmodifiable(List<int>.generate(256, paletteColor));
