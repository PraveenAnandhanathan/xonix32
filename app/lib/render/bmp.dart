// Decoder for the original 8bpp BMP resources (splash.bmp, msg_*.bmp).
//
// Replaces the resource-loading half of DrawBmpFromRes: the bitmaps'
// color tables are identical to the game palette, so the pixel bytes are
// used directly as XBC framebuffer values (0 = black, 0x10 = ytext).

import 'dart:typed_data';

class XonBitmap {
  final int width, height;

  /// Top-down rows of palette indices, width*height long.
  final Uint8List pixels;

  XonBitmap(this.width, this.height, this.pixels);
}

/// Decodes an uncompressed 8bpp bottom-up BMP into top-down indices.
XonBitmap decodeBmp(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  if (bytes.length < 54 || bytes[0] != 0x42 || bytes[1] != 0x4D) {
    throw FormatException('not a BMP file');
  }
  final pixelOffset = data.getUint32(10, Endian.little);
  final width = data.getInt32(18, Endian.little);
  final height = data.getInt32(22, Endian.little);
  final bpp = data.getUint16(28, Endian.little);
  final compression = data.getUint32(30, Endian.little);
  if (bpp != 8 || compression != 0) {
    throw FormatException('expected uncompressed 8bpp BMP, got '
        '$bpp bpp compression $compression');
  }

  final absHeight = height.abs();
  final stride = ((width + 3) ~/ 4) * 4; // rows are dword-aligned
  final out = Uint8List(width * absHeight);
  for (var y = 0; y < absHeight; y++) {
    // positive height means bottom-up storage
    final srcRow = height > 0 ? absHeight - 1 - y : y;
    final src = pixelOffset + srcRow * stride;
    out.setRange(y * width, y * width + width, bytes, src);
  }
  return XonBitmap(width, absHeight, out);
}
