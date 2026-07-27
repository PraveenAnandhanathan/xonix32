// The Flame shell around the engine: fixed-timestep stepping of the
// GameController, framebuffer-to-texture blitting with nearest-neighbor
// scaling (fat pixels, like 1998), swipe/keyboard input, pause, the
// high-score flow, and the yellow HUD strip that stands in for the
// original status bar.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show KeyEventResult, AppLifecycleState;
import 'package:flutter/services.dart';

import 'engine.dart' as engine;
import 'hiscores_store.dart';
import 'render/assets.dart';
import 'render/framebuffer.dart';

class XonixFlameGame extends FlameGame
    with KeyboardEvents, DragCallbacks, TapCallbacks {
  /// How to open the persistent score table. Defaults to the platform
  /// documents directory; tests substitute a temp-file store.
  final Future<HiScoreStore> Function() _openStore;

  XonixFlameGame({Future<HiScoreStore> Function()? storeOpener})
      : _openStore = storeOpener ?? HiScoreStore.open;

  late final engine.Game game;
  late final engine.GameController controller;
  late final GameAssets gameAssets;
  late HiScoreStore scores;

  /// The F6 setting (1..20, like CLevelDialog).
  int startLevel = 1;

  ui.Image? _frame;
  bool _building = false;
  Uint8List? _rgba;
  double _accMs = 0;
  double _flashClock = 0;
  bool _flash = false; // m_bFlash: gates the LOW TIME overlay

  // High-score entry state (CNewHighScoreDialog)
  int pendingHighScore = 0;
  int _pendingSlot = engine.ScoreList.slots;
  String _lastName = '';

  bool _pausedByMenu = false;
  bool _pausedByLifecycle = false;

  // Swipe detection
  static const double _swipeThreshold = 24;
  double _dragX = 0, _dragY = 0;

  static const double _hudH = 17;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  bool _ready = false;

  @override
  Future<void> onLoad() async {
    // Engine first, synchronously: input and stepping never see a
    // half-built shell.
    game = engine.Game(
        engine.IntRect(0, 0, engine.wndSizeX, engine.wndSizeY));
    controller = engine.GameController(game);
    controller.onGameOverScore = _onGameOverScore;
    _rgba = Uint8List(game.screen.width * game.screen.height * 4);
    // In-memory table immediately (so F7 can't race the async open),
    // replaced by the persistent store as soon as it resolves.
    scores = HiScoreStore(null);
    gameAssets = await GameAssets.load(images.bundle);
    scores = await _openStore();
    _ready = true;
  }

  @override
  void onRemove() {
    _frame?.dispose();
    _frame = null;
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_ready) return;

    // The original's flash clock ran at 1000*NOM_FPS/fps ms, so the
    // LOW TIME blink tracks the game speed setting.
    _flashClock += dt;
    if (_flashClock >= engine.nomFps / controller.fps) {
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

    if (stepped) _presentFrame();
  }

  /// DoBitBlt, faithfully: OR the message bitmap into the game surface,
  /// snapshot the frame, then NAND the ytext bits back out — the
  /// original never let a message linger in the framebuffer.
  void _presentFrame() {
    engine.IntRect? msgRect;
    final o = controller.overlay;
    if (o != null && (o != engine.MessageOverlay.lowTime || _flash)) {
      final bmp = gameAssets.forOverlay(o);
      msgRect = engine.IntRect(0, 0, 0, 0);
      game.screen.drawBmp(game.rcScr.right ~/ 2, game.rcScr.bottom ~/ 2,
          bmp.width, bmp.height, bmp.pixels,
          center: true, outRect: msgRect, mop: engine.MaskOp.or);
    }
    _rebuildFrame(); // pixel conversion happens synchronously inside
    if (msgRect != null) {
      game.screen.drawRect(msgRect, engine.xbcYText, engine.MaskOp.nand);
    }
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
    if (scale < 1) {
      // Screen too small for 1x: fit fractionally on BOTH axes (many
      // phones are under 400 logical px tall in landscape).
      final fx = size.x / vw, fy = size.y / vh;
      scale = (fx < fy ? fx : fy).clamp(0.1, 1.0);
    }

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
      fontFamily: 'XonixMono', // bundled DejaVu Sans Mono
      fontFamilyFallback: ['monospace', 'Courier New', 'Courier'],
    ),
  );

  void _renderHud(ui.Canvas canvas, double top) {
    final String text;
    if (controller.paused) {
      text = 'PAUSED - tap to resume';
    } else if (controller.isGameActive) {
      text = 'SCORE ${game.score}  LEVEL ${game.level}  '
          'XONI ${game.lives}  TIME ${game.timer}  '
          'FILL ${(game.fillFrac / 10).toStringAsFixed(1)}%';
    } else {
      text = '${engine.gameTitle}  ${engine.release} - '
          'tap to play, hold for options';
    }
    _hudText.render(canvas, text, Vector2(2, top + 2));
  }

  // --- Game flow ---------------------------------------------------

  void startNewGame() {
    if (!controller.isGameActive) controller.startGame(startLevel);
  }

  void togglePause() {
    if (!controller.isGameActive) return;
    controller.paused = !controller.paused;
  }

  /// DoGameOver's scan, 2 seconds into the game-over screen.
  void _onGameOverScore(int score) {
    final slot = scores.list.findSlot(score);
    if (slot >= engine.ScoreList.slots) return; // didn't place
    pendingHighScore = score;
    _pendingSlot = slot;
    // The original dialog was modal: freeze the mode machine while the
    // player types.
    controller.paused = true;
    overlays.add('nameEntry');
  }

  /// Prefill for the name dialog: the last name entered this session.
  String get highScoreDefaultName => _lastName;

  void submitHighScoreName(String name) {
    if (name.isEmpty) name = 'XONI';
    _lastName = name;
    scores.list.insert(_pendingSlot, name, pendingHighScore);
    scores.save();
    _pendingSlot = engine.ScoreList.slots;
    overlays.remove('nameEntry');
    controller.paused = false;
    overlays.add('scores'); // OnViewScores: show the new table
  }

  void openSettingsOverlay() {
    if (overlays.isActive('settings')) return;
    if (controller.isGameActive && !controller.paused) {
      controller.paused = true;
      _pausedByMenu = true;
    }
    overlays.add('settings');
  }

  void closeSettingsOverlay() {
    overlays.remove('settings');
    if (_pausedByMenu) {
      _pausedByMenu = false;
      controller.paused = false;
    }
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    // Auto-pause when the app leaves the foreground (the mobile analog
    // of the original's boss key).
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      if (controller.isGameActive && !controller.paused) {
        controller.paused = true;
        _pausedByLifecycle = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      // Resume only what we paused ourselves, and never under a dialog
      if (_pausedByLifecycle &&
          !overlays.isActive('nameEntry') &&
          !overlays.isActive('settings')) {
        controller.paused = false;
      }
      _pausedByLifecycle = false;
    }
  }

  // --- Input -------------------------------------------------------

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (controller.paused) {
      if (!overlays.isActive('nameEntry') && !overlays.isActive('settings')) {
        controller.paused = false;
      }
    } else if (controller.isGameActive) {
      togglePause();
    } else {
      startNewGame();
    }
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    super.onLongTapDown(event);
    openSettingsOverlay();
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
    // The original ignored key repeats (nFlags & 0x4000)
    if (event is! KeyDownEvent) {
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
      startNewGame();
    } else if (key == LogicalKeyboardKey.f3 ||
        key == LogicalKeyboardKey.pause ||
        key == LogicalKeyboardKey.keyP) {
      togglePause();
    } else if (key == LogicalKeyboardKey.f4) {
      if (controller.isGameActive) controller.endGame();
    } else if (key == LogicalKeyboardKey.f5 ||
        key == LogicalKeyboardKey.f6) {
      openSettingsOverlay();
    } else if (key == LogicalKeyboardKey.f7) {
      overlays.isActive('scores')
          ? overlays.remove('scores')
          : overlays.add('scores');
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }
}
