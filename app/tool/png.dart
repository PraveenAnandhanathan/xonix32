// Minimal PNG encoder (truecolor, no interlace) for the headless
// verification tool. Uses dart:io's zlib for the IDAT stream.

import 'dart:io';
import 'dart:typed_data';

final Uint32List _crcTable = (() {
  final t = Uint32List(256);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    t[n] = c;
  }
  return t;
})();

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

void _chunk(BytesBuilder out, String type, List<int> data) {
  final len = ByteData(4)..setUint32(0, data.length);
  out.add(len.buffer.asUint8List());
  final body = [...type.codeUnits, ...data];
  out.add(body);
  final crc = ByteData(4)..setUint32(0, _crc32(body));
  out.add(crc.buffer.asUint8List());
}

/// Encodes RGB rows (3 bytes per pixel, top-down) as a PNG.
Uint8List encodePng(int width, int height, Uint8List rgb) {
  final out = BytesBuilder();
  out.add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  final ihdr = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 2) // truecolor
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  _chunk(out, 'IHDR', ihdr.buffer.asUint8List());

  final raw = Uint8List(height * (1 + width * 3));
  for (var y = 0; y < height; y++) {
    final row = y * (1 + width * 3);
    raw[row] = 0; // filter: none
    raw.setRange(row + 1, row + 1 + width * 3, rgb, y * width * 3);
  }
  _chunk(out, 'IDAT', ZLibEncoder(level: 9).convert(raw));
  _chunk(out, 'IEND', const []);
  return out.toBytes();
}
