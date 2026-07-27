import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_shell.dart';
import 'ui/overlays.dart';

/// The production widget tree. The MaterialApp wrapper is load-bearing:
/// the overlay dialogs (TextField et al.) need Directionality, theme,
/// and localizations. Tests pump this exact tree with an injected
/// [gameFactory] so they can't drift from what ships.
Widget buildApp({XonixFlameGame Function()? gameFactory}) {
  return MaterialApp(
    title: 'Xonix32',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
    ),
    home: GameWidget<XonixFlameGame>.controlled(
      gameFactory: gameFactory ?? XonixFlameGame.new,
      overlayBuilderMap: {
        'nameEntry': (context, game) => NameEntryOverlay(game: game),
        'scores': (context, game) => ScoresOverlay(game: game),
        'settings': (context, game) => SettingsOverlay(game: game),
      },
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(buildApp());
}
