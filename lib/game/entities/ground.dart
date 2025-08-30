import 'dart:async';

import 'package:demo_2/game/game.dart';
import 'package:demo_2/game/utilities/game_perspective.dart';
import 'package:demo_2/game/utilities/isometric_component.dart';
import 'package:flame/components.dart';

class Ground extends PositionComponent with HasGameReference<SomeShipGame> {
  Ground({super.children}) {
    anchor = Anchor.center;
  }

  GamePerspective? appliedPerspective;

  @override
  Future<void> onLoad() async {
    add(
      IsometricPlaneComponent(
        plane: IsometricPlane.ground,
        children: [],
      ),
    );
  }
}
