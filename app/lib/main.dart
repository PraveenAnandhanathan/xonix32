import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_shell.dart';
import 'ui/overlays.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(GameWidget<XonixFlameGame>.controlled(
    gameFactory: XonixFlameGame.new,
    overlayBuilderMap: {
      'nameEntry': (context, game) => NameEntryOverlay(game: game),
      'scores': (context, game) => ScoresOverlay(game: game),
      'settings': (context, game) => SettingsOverlay(game: game),
    },
  ));
}
