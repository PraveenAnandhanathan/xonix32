// Shell integration tests for the M3 flows: pause, the high-score
// dialog chain, and the settings overlay — all against the real engine
// and a real HiScores.dat file on disk.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xonix32/engine.dart' as engine;
import 'package:xonix32/game_shell.dart';
import 'package:xonix32/hiscores_store.dart';
import 'package:xonix32/main.dart';

/// Pumps the REAL production widget tree (buildApp), so a missing
/// ancestor (MaterialApp, Directionality, ...) fails here before it can
/// crash on a device.
Future<XonixFlameGame> _pumpGame(WidgetTester tester, {File? scoreFile}) async {
  final game =
      XonixFlameGame(storeOpener: () async => HiScoreStore(scoreFile));
  await tester.pumpWidget(buildApp(gameFactory: () => game));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return game;
}

void main() {
  testWidgets('tap pauses and resumes a running game', (tester) async {
    final game = await _pumpGame(tester);
    game.controller.startGame(1);
    for (var i = 0; i < 41; i++) {
      game.controller.step();
    }
    expect(game.controller.mode, engine.Mode.play);

    game.togglePause();
    expect(game.controller.paused, isTrue);
    final score = game.game.timer;
    for (var i = 0; i < 20; i++) {
      game.update(1 / 30);
    }
    expect(game.game.timer, score); // frozen

    game.togglePause();
    expect(game.controller.paused, isFalse);
  });

  testWidgets('high-score chain: dialog, insert, save, table',
      (tester) async {
    // Real file-backed store in a temp dir
    final dir = Directory.systemTemp.createTempSync('xonix32_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/HiScores.dat');
    final game = await _pumpGame(tester, scoreFile: file);

    // Play a game to its game-over scan; endGame covers the "gave up"
    // path, and the scan fires 2s into the game-over screen.
    game.controller.startGame(1);
    for (var i = 0; i < 41; i++) {
      game.controller.step();
    }
    // The scan reports the real score; with a fresh table any score > 0
    // places, so hand the callback a real captured-territory score path:
    game.controller.onGameOverScore!.call(1234);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(game.overlays.isActive('nameEntry'), isTrue);
    expect(game.controller.paused, isTrue); // modal, like the original
    expect(find.textContaining('NEW HIGH SCORE'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'PRAVEEN');
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(game.overlays.isActive('nameEntry'), isFalse);
    expect(game.controller.paused, isFalse);
    expect(game.overlays.isActive('scores'), isTrue);
    expect(find.text('HIGH SCORES'), findsOneWidget);
    expect(find.text('PRAVEEN'), findsOneWidget);

    // The file on disk must round-trip through the original format
    expect(file.existsSync(), isTrue);
    final reloaded = engine.ScoreList()..load(file.readAsBytesSync());
    expect(reloaded.getName(0), 'PRAVEEN');
    expect(reloaded.getScore(0), 1234);

    await tester.tap(find.text('CLOSE'));
    await tester.pump();
    expect(game.overlays.isActive('scores'), isFalse);
  });

  testWidgets('settings overlay changes speed and start level',
      (tester) async {
    final game = await _pumpGame(tester);
    game.openSettingsOverlay();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('OPTIONS'), findsOneWidget);

    // Speed slider covers the original 10..50 range
    await tester.drag(find.byType(Slider), const Offset(400, 0));
    await tester.pump();
    expect(game.controller.fps, engine.maxFps);

    // Starting level spinner (1..20)
    await tester.tap(find.text('+'));
    await tester.tap(find.text('+'));
    await tester.pump();
    expect(game.startLevel, 3);

    await tester.tap(find.text('CLOSE'));
    await tester.pump();
    expect(game.overlays.isActive('settings'), isFalse);

    // A new game starts at the chosen level with the real engine
    game.startNewGame();
    expect(game.game.level, 3);
  });

  testWidgets('message overlays never burn into the framebuffer',
      (tester) async {
    final game = await _pumpGame(tester);
    game.controller.startGame(1);

    // Drive the shell through READY? (40 ticks of 50ms) into play; the
    // original drew each message, blitted, then NAND-erased it — so
    // after any update() the surface must hold no ytext bits.
    var sawReady = false;
    for (var i = 0; i < 120; i++) {
      game.update(0.05);
      sawReady |= game.controller.overlay == engine.MessageOverlay.ready;
      final bits = game.game.screen.bits;
      for (var p = 0; p < bits.length; p++) {
        if (bits[p] & engine.xbcYText != 0) {
          fail('ytext residue at pixel $p on update $i '
              '(mode ${game.controller.mode})');
        }
      }
      if (game.controller.mode == engine.Mode.play) break;
    }
    expect(sawReady, isTrue, reason: 'test never saw the READY? overlay');
    expect(game.controller.mode, engine.Mode.play);
  });
}
