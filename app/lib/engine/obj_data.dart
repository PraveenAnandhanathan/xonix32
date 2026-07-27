// Port of obj_data.h: the 7x7 sprite images as 8bpp palette indices.
// 255 means transparent. Values are XBC color bits (see constants.dart).

import 'dart:typed_data';

/// The Xoni (player) — a white cross.
final Uint8List guyImage = Uint8List.fromList(const [
  8, 8, 8, 255, 8, 8, 8, //
  8, 8, 8, 255, 8, 8, 8, //
  8, 8, 255, 255, 255, 8, 8, //
  255, 255, 255, 255, 255, 255, 255, //
  8, 8, 255, 255, 255, 8, 8, //
  8, 8, 8, 255, 8, 8, 8, //
  8, 8, 8, 255, 8, 8, 8, //
]);

/// Black diamond (lives in the filled area).
final Uint8List bDotImage = Uint8List.fromList(const [
  255, 255, 2, 0, 2, 255, 255, //
  255, 2, 0, 0, 0, 2, 255, //
  2, 0, 0, 0, 0, 0, 2, //
  0, 0, 0, 0, 0, 0, 0, //
  2, 0, 0, 0, 0, 0, 2, //
  255, 2, 0, 0, 0, 2, 255, //
  255, 255, 2, 0, 2, 255, 255, //
]);

/// White diamond (lives in the sea).
final Uint8List wDotImage = Uint8List.fromList(const [
  255, 255, 255, 8, 255, 255, 255, //
  255, 255, 8, 8, 8, 255, 255, //
  255, 8, 8, 8, 8, 8, 255, //
  8, 8, 8, 8, 8, 8, 8, //
  255, 8, 8, 8, 8, 8, 255, //
  255, 255, 8, 8, 8, 255, 255, //
  255, 255, 255, 8, 255, 255, 255, //
]);
