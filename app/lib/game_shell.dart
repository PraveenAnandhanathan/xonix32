// The Flame shell around the engine: fixed-timestep stepping of the
// GameController, framebuffer-to-texture blitting with nearest-neighbor
// scaling (fat pixels, like 1998), swipe/keyboard input, and the yellow
// HUD strip that stands in for the original status bar.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:flutter/services.dart';

import 'engine.dart' as engine;
import 'render/assets.dart';
import 'render/framebuffer.dart';

class XonixFlameGame extends FlameGame
    with KeyboardEvents, DragCallbacks, TapCallbacks {
  late final engine.Game game;
  late final engine.GameController controller;
  late final GameAssets gameAssets;

  ui.Image? _frame;
  bool _building = false;
  Uint8List? _rgba;
  double _accMs = 0;
  double _flashClock = 0;
  bool _flash = false; // m_bFlash: gates the LOW TIME overlay

  // Swipe detection
  static const double _swipeThreshold = 24;
  double _dragX = 0, _dragY = 0;

  static const double _hudH = 17;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    gameAssets = await GameAssets.load(images.bundle);
    game = engine.Game(
        engine.IntRect(0, 0, engine.wndSizeX, engine.wndSizeY));
    controller = engine.GameController(game);
    _rgba = Uint8List(game.screen.width * game.screen.height * 4);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _flashClock += dt;
    if (_flashClock >= 0.5) {
      _flashClock = 0;
      _flash = !_flash;
    }

    _accMs += dt * 1000;
    var stepped = false;
    // Cap catch-up work so a long pause doesn't fast-forward the game
    var budget = 5;
    while (_accMs >= controller.tickDelayMs && budget-- > 0) {
      _accMs -= controller.tickDelayMs;
      controller.step();
      stepped = true;
    }
    if (_accMs >= controller.tickDelayMs) _accMs = 0;

    if (stepped) {
      _drawOverlay();
      _rebuildFrame();
    }
  }

  /// DoBitBlt: OR the message bitmap into the game surface.
  void _drawOverlay() {
    final o = controller.overlay;
    if (o == null) return;
    if (o == engine.MessageOverlay.lowTime && !_flash) return;
    final bmp = gameAssets.forOverlay(o);
    game.screen.drawBmp(game.rcScr.right ~/ 2, game.rcScr.bottom ~/ 2,
        bmp.width, bmp.height, bmp.pixels,
        center: true, mop: engine.MaskOp.or);
  }

  void _rebuildFrame() {
    if (_building) return;
    _building = true;
    final w = game.screen.width, h = game.screen.height;
    framebufferToRgba(game.screen, _rgba!.buffer.asUint32List());
    ui.decodeImageFromPixels(_rgba!, w, h, ui.PixelFormat.rgba8888, (img) {
      _frame?.dispose();
      _frame = img;
      _building = false;
    });
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final frame = _frame;
    if (frame == null) return;

    final vw = frame.width.toDouble();
    final vh = frame.height + _hudH;

    // Integer ("fat pixel") scale when possible, fractional when the
    // screen is too small for even 1x.
    var scale = (size.x / vw).floorToDouble();
    final vScale = (size.y / vh).floorToDouble();
    if (vScale < scale) scale = vScale;
    if (scale < 1) scale = (size.x / vw).clamp(0.1, 1.0);

    final dx = (size.x - vw * scale) / 2;
    final dy = (size.y - vh * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    canvas.drawImageRect(
      frame,
      ui.Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );

    _renderHud(canvas, frame.height.toDouble());
    canvas.restore();
  }

  static final TextPaint _hudText = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFFFF00), // RGB_YTEXT
      fontSize: 11,
      fontFamily: 'monospace',
    ),
  );

  void _renderHud(ui.Canvas canvas, double top) {
    final String text;
    if (controller.isGameActive) {
      text = 'SCORE ${game.score}  LEVEL ${game.level}  '
          'XONI ${game.lives}  TIME ${game.timer}  '
          'FILL ${(game.fillFrac / 10).toStringAsFixed(1)}%';
    } else {
      text = '${engine.gameTitle}  ${engine.release} - tap to play';
    }
    _hudText.render(canvas, text, Vector2(2, top + 2));
  }

  // --- Input -------------------------------------------------------

  void _startIfIdle() {
    if (!controller.isGameActive) controller.startGame(1);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    _startIfIdle();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _dragX += event.canvasDelta.x;
    _dragY += event.canvasDelta.y;
    if (_dragX.abs() < _swipeThreshold && _dragY.abs() < _swipeThreshold) {
      return;
    }
    if (_dragX.abs() > _dragY.abs()) {
      game.setDirection(
          _dragX > 0 ? engine.Direction.right : engine.Direction.left);
    } else {
      game.setDirection(
          _dragY > 0 ? engine.Direction.down : engine.Direction.up);
    }
    _dragX = 0;
    _dragY = 0;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _dragX = 0;
    _dragY = 0;
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      game.setDirection(engine.Direction.left);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      game.setDirection(engine.Direction.up);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      game.setDirection(engine.Direction.right);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      game.setDirection(engine.Direction.down);
    } else if (key == LogicalKeyboardKey.f2 ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      _startIfIdle();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }
}
