// Flutter overlays standing in for the original dialogs: new-high-score
// entry (CNewHighScoreDialog), the scores table (F7 / OnViewScores), and
// settings covering the speed slider (F5, 10..50) and starting level
// (F6, 1..20). Styled in the game's own six colors.

import 'package:flutter/material.dart';

import '../engine.dart' as engine;
import '../game_shell.dart';

const Color _yellow = Color(0xFFFFFF00); // RGB_YTEXT
const Color _teal = Color(0xFF008484); // XBC_BLUEGRN
const Color _black = Color(0xFF000000);

const TextStyle _text = TextStyle(
  color: _yellow,
  fontFamily: 'XonixMono',
  fontSize: 16,
);
const TextStyle _small = TextStyle(
  color: _yellow,
  fontFamily: 'XonixMono',
  fontSize: 13,
);

class _RetroPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _RetroPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _black,
          border: Border.all(color: _teal, width: 3),
        ),
        child: Material(
          color: _black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: _text, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _RetroButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _RetroButton(this.label, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _teal, width: 2),
        shape: const RoundedRectangleBorder(),
      ),
      child: Text(label, style: _small),
    );
  }
}

/// CNewHighScoreDialog: shown when the final score places in the table.
class NameEntryOverlay extends StatefulWidget {
  final XonixFlameGame game;

  const NameEntryOverlay({super.key, required this.game});

  @override
  State<NameEntryOverlay> createState() => _NameEntryOverlayState();
}

class _NameEntryOverlayState extends State<NameEntryOverlay> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.game.highScoreDefaultName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _RetroPanel(
      title: 'NEW HIGH SCORE!  ${widget.game.pendingHighScore}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: engine.ScoreList.nameLen - 1,
            style: _text,
            cursorColor: _yellow,
            decoration: const InputDecoration(
              counterStyle: _small,
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _teal, width: 2)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _yellow, width: 2)),
              hintText: 'your name',
              hintStyle: TextStyle(color: _teal, fontFamily: 'XonixMono'),
            ),
            onSubmitted: (_) => _ok(),
          ),
          const SizedBox(height: 8),
          _RetroButton('OK', _ok),
        ],
      ),
    );
  }

  void _ok() => widget.game.submitHighScoreName(_name.text.trim());
}

/// The F7 scores table (OnViewScores).
class ScoresOverlay extends StatelessWidget {
  final XonixFlameGame game;

  const ScoresOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final list = game.scores.list;
    return _RetroPanel(
      title: 'HIGH SCORES',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < engine.ScoreList.slots; i++)
            Row(
              children: [
                SizedBox(
                    width: 36,
                    child: Text('${i + 1}.',
                        style: _small, textAlign: TextAlign.right)),
                const SizedBox(width: 8),
                Expanded(child: Text(list.getName(i), style: _small)),
                Text('${list.getScore(i)}', style: _small),
              ],
            ),
          const SizedBox(height: 8),
          _RetroButton('CLOSE', () => game.overlays.remove('scores')),
        ],
      ),
    );
  }
}

/// Speed (F5) and starting level (F6) in one panel, original ranges.
class SettingsOverlay extends StatefulWidget {
  final XonixFlameGame game;

  const SettingsOverlay({super.key, required this.game});

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return _RetroPanel(
      title: 'OPTIONS',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GAME SPEED: ${game.controller.fps} FPS', style: _small),
          Slider(
            value: game.controller.fps.toDouble(),
            min: engine.minFps.toDouble(),
            max: engine.maxFps.toDouble(),
            divisions: (engine.maxFps - engine.minFps) ~/ 5,
            activeColor: _yellow,
            inactiveColor: _teal,
            onChanged: (v) =>
                setState(() => game.controller.fps = v.round()),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('STARTING LEVEL: ${game.startLevel}', style: _small),
              const Spacer(),
              _RetroButton('-', () {
                setState(() {
                  if (game.startLevel > 1) game.startLevel--;
                });
              }),
              const SizedBox(width: 8),
              _RetroButton('+', () {
                setState(() {
                  if (game.startLevel < 20) game.startLevel++;
                });
              }),
            ],
          ),
          const SizedBox(height: 12),
          Center(
              child:
                  _RetroButton('CLOSE', () => game.closeSettingsOverlay())),
        ],
      ),
    );
  }
}
