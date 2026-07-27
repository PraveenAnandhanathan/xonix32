// Port of HiScoreTbl.cpp/.h: the 10-slot high-score table, including
// the exact HiScores.dat wire format (int32 scores then 16-byte names,
// both XORed with 0x55) so the original file loads byte-for-byte.

import 'dart:convert';
import 'dart:typed_data';

class ScoreList {
  static const int slots = 10;
  static const int nameLen = 16;

  final List<int> _scores = List.filled(slots, 0);
  final List<String> _names = List.filled(slots, '...empty...');

  int getScore(int slot) => slot < slots ? _scores[slot] : 0;
  String getName(int slot) => slot < slots ? _names[slot] : '';

  /// The slot a score would occupy, or [slots] if it doesn't place
  /// (the scan loop from CGameWnd::DoGameOver).
  int findSlot(int score) {
    var n = 0;
    while (n < slots && _scores[n] >= score) {
      n++;
    }
    return n;
  }

  void insert(int slot, String name, int score) {
    var n = slots - 1;
    while (n > slot) {
      _scores[n] = _scores[n - 1];
      _names[n] = _names[n - 1];
      n--;
    }
    _scores[n] = score;
    _names[n] = name;
  }

  /// Parses HiScores.dat bytes (the original obfuscated format).
  bool load(Uint8List? bytes) {
    if (bytes == null || bytes.length < slots * 4 + slots * nameLen) {
      for (var i = 0; i < slots; i++) {
        _scores[i] = 0;
        _names[i] = '...empty...';
      }
      return false;
    }
    final data = ByteData.sublistView(bytes);
    for (var i = 0; i < slots; i++) {
      _scores[i] = data.getInt32(i * 4, Endian.little) ^ 0x55555555;
    }
    for (var i = 0; i < slots; i++) {
      final start = slots * 4 + i * nameLen;
      final raw = [
        for (var j = 0; j < nameLen; j++) bytes[start + j] ^ 0x55,
      ];
      final end = raw.indexOf(0);
      _names[i] = ascii.decode(raw.sublist(0, end < 0 ? nameLen : end),
          allowInvalid: true);
    }
    return true;
  }

  /// Serializes to HiScores.dat bytes (the original obfuscated format).
  Uint8List save() {
    final bytes = Uint8List(slots * 4 + slots * nameLen);
    final data = ByteData.sublistView(bytes);
    for (var i = 0; i < slots; i++) {
      data.setInt32(i * 4, _scores[i] ^ 0x55555555, Endian.little);
    }
    for (var i = 0; i < slots; i++) {
      final start = slots * 4 + i * nameLen;
      final raw = ascii.encode(_names[i]);
      for (var j = 0; j < nameLen; j++) {
        final b = j < raw.length ? raw[j] : 0;
        bytes[start + j] = b ^ 0x55;
      }
    }
    return bytes;
  }
}
