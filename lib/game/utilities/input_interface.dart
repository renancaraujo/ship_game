import 'package:demo_2/game/game.dart';
import 'package:demo_2/game/utilities/game_perspective.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

class InputInterface extends Component with HasGameReference<SomeShipGame> {
  Vector2? _startDragPosition;

  void onHorizontalDragDown(DragDownInfo info) {
    _startDragPosition = info.eventPosition.widget;
  }

  void onHorizontalDragStart(DragStartInfo info) {
    _startDragPosition = info.eventPosition.widget;
  }

  void onHorizontalDragUpdate(DragUpdateInfo info) {
    if (_startDragPosition != null) {
      final delta = info.eventPosition.widget - _startDragPosition!;
      final xAbs = delta.x.abs();
      final xSign = delta.x.sign.toInt();
      final changeUnits = xAbs ~/ 50;

      if (changeUnits > 0) {
        _startDragPosition = info.eventPosition.widget;
        game.gameValues.perspective = GamePerspective.fromVal(
          (game.gameValues.perspective.val + changeUnits * xSign).clamp(
            -18,
            18,
          ),
        );
      }
    }
  }

  void onHorizontalDragEnd(DragEndInfo info) {
    _startDragPosition = null;
  }

  void onHorizontalDragCancel() {
    _startDragPosition = null;
  }
}
