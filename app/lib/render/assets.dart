// Loads the original BMP resources from the Flutter asset bundle.

import 'package:flutter/services.dart';

import '../engine/constants.dart';
import 'bmp.dart';

class GameAssets {
  final XonBitmap splash;
  final XonBitmap ready;
  final XonBitmap levelComplete;
  final XonBitmap crash;
  final XonBitmap lowTime;
  final XonBitmap outOfTime;
  final XonBitmap gameOver;

  GameAssets({
    required this.splash,
    required this.ready,
    required this.levelComplete,
    required this.crash,
    required this.lowTime,
    required this.outOfTime,
    required this.gameOver,
  });

  static Future<GameAssets> load(AssetBundle bundle) async {
    Future<XonBitmap> bmp(String name) async =>
        decodeBmp((await bundle.load('assets/$name')).buffer.asUint8List());

    return GameAssets(
      splash: await bmp('splash.bmp'),
      ready: await bmp('msg_ready.bmp'),
      levelComplete: await bmp('msg_level_complete.bmp'),
      crash: await bmp('msg_crash.bmp'),
      lowTime: await bmp('msg_low_time.bmp'),
      outOfTime: await bmp('msg_out_of_time.bmp'),
      gameOver: await bmp('msg_game_over.bmp'),
    );
  }

  /// The bitmap DoBitBlt would pick for a given overlay.
  XonBitmap forOverlay(MessageOverlay o) => switch (o) {
        MessageOverlay.ready => ready,
        MessageOverlay.levelComplete => levelComplete,
        MessageOverlay.crash => crash,
        MessageOverlay.lowTime => lowTime,
        MessageOverlay.outOfTime => outOfTime,
        MessageOverlay.gameOver => gameOver,
      };
}
