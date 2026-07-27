// Smoke test: the Flame shell boots, loads the original BMP assets,
// steps the mode machine, and accepts input.

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xonix32/engine.dart' as engine;
import 'package:xonix32/game_shell.dart';

void main() {
  testWidgets('shell boots into splash and starts a game', (tester) async {
    final game = XonixFlameGame();
    await tester.pumpWidget(GameWidget<XonixFlameGame>(game: game));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(game.controller.mode, engine.Mode.splash);
    expect(game.gameAssets.splash.width, 121);
    expect(game.gameAssets.ready.height, 16);

    // Start a game and roll through READY? into play
    game.controller.startGame(1);
    expect(game.controller.overlay, engine.MessageOverlay.ready);
    for (var i = 0; i < 41; i++) {
      game.controller.step();
    }
    expect(game.controller.mode, engine.Mode.play);

    // Steer the Xoni: engine must accept the direction
    game.game.setDirection(engine.Direction.down);
    expect(game.game.guy.dy, engine.objMove);

    // Run a bunch of shell updates: framebuffer conversion must not throw
    for (var i = 0; i < 30; i++) {
      game.update(1 / 30);
    }
    await tester.pump(const Duration(milliseconds: 100));
  });
}
