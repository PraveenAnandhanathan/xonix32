// Headless verification: runs the engine exactly as the shell would and
// dumps PNG frames of the splash screen and mid-game play, using the
// original BMP assets. Run from app/:  dart run tool/render_frames.dart

import 'dart:io';
import 'dart:typed_data';

import '../lib/engine.dart';
import '../lib/render/bmp.dart';

import 'png.dart';

Uint8List _frameRgb(DibSection screen) {
  final rgb = Uint8List(screen.width * screen.height * 3);
  var d = 0;
  for (var y = 0; y < screen.height; y++) {
    for (var x = 0; x < screen.width; x++) {
      final argb = palette256[screen.getPel(x, y)];
      rgb[d++] = (argb >> 16) & 0xFF;
      rgb[d++] = (argb >> 8) & 0xFF;
      rgb[d++] = argb & 0xFF;
    }
  }
  return rgb;
}

void _shot(Game game, String path) {
  final png =
      encodePng(game.screen.width, game.screen.height, _frameRgb(game.screen));
  File(path).writeAsBytesSync(png);
  print('wrote $path (${png.length} bytes)');
}

void main() {
  final res = Directory('../src/res').existsSync() ? '../src/res' : 'src/res';
  XonBitmap bmp(String name) =>
      decodeBmp(File('$res/$name.bmp').readAsBytesSync());

  Directory('doc').createSync();

  final game = Game(IntRect(0, 0, wndSizeX, wndSizeY), rand: CRand(7));
  final ctl = GameController(game);

  // Splash: title bitmap plus a little demo-mode animation of the "X"
  final splash = bmp('splash');
  game.initSplash(
      titleBmp: splash.pixels, bmpW: splash.width, bmpH: splash.height);
  for (var i = 0; i < 12; i++) {
    game.demo();
  }
  _shot(game, 'doc/frame_splash.png');

  // READY? screen, exactly as DoBitBlt overlays it
  ctl.startGame(1);
  ctl.step(); // initLevel happens on the first newLevel tick
  final ready = bmp('msg_ready');
  game.screen.drawBmp(game.rcScr.right ~/ 2, game.rcScr.bottom ~/ 2,
      ready.width, ready.height, ready.pixels,
      center: true, mop: MaskOp.or);
  _shot(game, 'doc/frame_ready.png');

  // Play: capture a strip, then wander to show trail drawing
  game.initLevel(true); // clean board (drops the burned-in READY?)
  game.setDirection(Direction.down);
  var drew = false;
  for (var i = 0; i < 200; i++) {
    game.runGame();
    drew |= game.guy.isDrawing;
    if (drew && !game.guy.isDrawing) break;
  }
  game.setDirection(Direction.right);
  for (var i = 0; i < 10 && game.runGame() == RetCode.okay; i++) {}
  game.setDirection(Direction.up);
  for (var i = 0; i < 25 && game.runGame() == RetCode.okay; i++) {}
  game.screen.countFilledPix(game.rcScr);
  print('fill after capture: ${game.fillFrac / 10}%');
  _shot(game, 'doc/frame_play.png');
}
