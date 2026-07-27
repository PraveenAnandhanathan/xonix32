// File-backed high-score table. Persists the exact HiScores.dat format
// (see engine/hi_scores.dart) in the app documents directory, so the
// table survives reinstalls-via-backup and is byte-compatible with the
// original game's file.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'engine/hi_scores.dart';

class HiScoreStore {
  /// Null only when no writable location exists (then scores simply
  /// don't persist for this run — gameplay is unaffected).
  final File? file;
  final ScoreList list = ScoreList();

  HiScoreStore(this.file) {
    try {
      final f = file;
      list.load(f != null && f.existsSync() ? f.readAsBytesSync() : null);
    } catch (e) {
      debugPrint('HiScoreStore: failed to read ${file?.path}: $e');
      list.load(null);
    }
  }

  static Future<HiScoreStore> open() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return HiScoreStore(File('${dir.path}/HiScores.dat'));
    } catch (e) {
      // No platform storage (e.g. running headless): keep scores in memory
      debugPrint('HiScoreStore: no documents directory: $e');
      return HiScoreStore(null);
    }
  }

  void save() {
    final f = file;
    if (f == null) return;
    try {
      f.writeAsBytesSync(list.save());
    } catch (e) {
      debugPrint('HiScoreStore: failed to write ${f.path}: $e');
    }
  }
}
