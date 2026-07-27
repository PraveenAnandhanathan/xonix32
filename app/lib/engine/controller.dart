// Port of the CGameWnd mode machine (MainLoop + DoSplash/DoDemo/
// DoSuccess/DoNewLevel/DoDeath/DoGameOver from GameWnd.cpp).
//
// The original ran non-play modes on a 50ms Sleep and play mode on the
// game-speed delay. Here the shell calls step() once per tick and reads
// tickDelayMs to know when the next tick is due.

import 'constants.dart';
import 'game.dart';

class GameController {
  final Game game;

  Mode mode = Mode.splash;
  int _modeTime = 0;
  bool _newLevelClear = true;

  /// Game speed, 10..50 (the F5 setting). Non-play modes always run at
  /// the fixed 50ms cadence, like the original.
  int fps = nomFps;

  /// Pause (the F3 setting): the original stopped the game timer, which
  /// froze whatever mode was on screen. step() is a no-op while paused.
  bool paused = false;

  /// Fired once per game over, at the same moment the original scanned
  /// the high-score table (2 seconds into the game-over screen).
  void Function(int score)? onGameOverScore;

  GameController(this.game);

  int get tickDelayMs => mode == Mode.play ? 1000 ~/ fps : 50;

  bool get isGameActive => switch (mode) {
        Mode.play ||
        Mode.playNewLevel ||
        Mode.playSuccess ||
        Mode.playDeath ||
        Mode.playTimeout ||
        Mode.playGameOver =>
          true,
        _ => false,
      };

  /// The message bitmap to overlay this frame (DoBitBlt's switch).
  MessageOverlay? get overlay => switch (mode) {
        Mode.playNewLevel => MessageOverlay.ready,
        Mode.play when game.timer < 31 => MessageOverlay.lowTime,
        Mode.playSuccess => MessageOverlay.levelComplete,
        Mode.playDeath => MessageOverlay.crash,
        Mode.playTimeout => MessageOverlay.outOfTime,
        Mode.playGameOver => MessageOverlay.gameOver,
        _ => null,
      };

  /// Menu: Game > New (OnGameNew).
  void startGame(int initLevel) {
    game.initGame(initLevel);
    _newLevelClear = true;
    mode = Mode.playNewLevel;
    _modeTime = 0;
  }

  /// Menu: Game > End (OnGameEnd).
  void endGame() {
    mode = Mode.playGameOver;
    _modeTime = 0;
  }

  /// One tick of MainLoop's mode switch.
  void step() {
    if (paused) return;
    switch (mode) {
      case Mode.splash:
        _doSplash();
      case Mode.demo:
        _doDemo();
      case Mode.play:
        switch (game.runGame()) {
          case RetCode.okay:
            break;
          case RetCode.newLevel:
            mode = Mode.playSuccess;
            _newLevelClear = true;
          case RetCode.death:
            mode = Mode.playDeath;
            _newLevelClear = false;
          case RetCode.timeout:
            mode = Mode.playTimeout;
            _newLevelClear = false;
        }
        _modeTime = 0;
      case Mode.playSuccess:
        _doSuccess();
      case Mode.playNewLevel:
        _doNewLevel();
      case Mode.playDeath || Mode.playTimeout:
        _doDeath();
      case Mode.playGameOver:
        _doGameOver();
    }
  }

  void _doSplash() {
    if (_modeTime == 0) {
      _modeTime = 5000 ~/ 50;
      game.initSplash();
      return;
    }
    if (_modeTime == 1) mode = Mode.demo;
    game.splash();
    _modeTime--;
  }

  void _doDemo() {
    if (_modeTime == 0) {
      _modeTime = 15000 ~/ 50;
      game.initDemo();
      return;
    }
    if (_modeTime == 1) mode = Mode.splash;
    game.demo();
    _modeTime--;
  }

  void _doSuccess() {
    if (_modeTime == 0) {
      _modeTime = 3000 ~/ 50;
    }
    if (_modeTime == 1) mode = Mode.playNewLevel;
    _modeTime--;
  }

  void _doNewLevel() {
    if (_modeTime == 0) {
      _modeTime = 2000 ~/ 50;
      game.initLevel(_newLevelClear);
    }
    if (_modeTime == 1) mode = Mode.play;
    _modeTime--;
  }

  void _doDeath() {
    if (_modeTime == 0) _modeTime = 2000 ~/ 50;
    if (_modeTime == 1) {
      mode = game.lives > 0 ? Mode.playNewLevel : Mode.playGameOver;
    }
    _modeTime--;
  }

  void _doGameOver() {
    if (_modeTime == 0) {
      _modeTime = 4000 ~/ 50;
      game.gameOver();
      return;
    }
    if (_modeTime == 1) mode = Mode.splash;
    if (_modeTime == 2000 ~/ 50) onGameOverScore?.call(game.score);
    _modeTime--;
  }
}
