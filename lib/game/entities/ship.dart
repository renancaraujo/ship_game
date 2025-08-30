import 'dart:ui' show Image;

import 'package:demo_2/game/game.dart';
import 'package:demo_2/game/post_process/ship_post_process.dart';
import 'package:demo_2/game/utilities/game_perspective.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/layout.dart';
import 'package:flame/post_process.dart';
import 'package:flame/sprite.dart';

class Ship extends PositionComponent
    with CollisionCallbacks, HasGameReference<SomeShipGame> {
  Ship();

  @override
  Future<void> onLoad() async {
    add(
      AlignComponent(
        alignment: Anchor.center,
        child: SpriteShip(),
      ),
    );
  }
}

class SpriteShip extends SpriteComponent
    with CollisionCallbacks, HasGameReference<SomeShipGame> {
  SpriteShip() : super(size: Vector2(480, 264));

  late ShipSpriteSheet spriteSheet;

  GamePerspective _currentDirection = GamePerspective.deadAhead;

  @override
  Future<void> onLoad() async {
    spriteSheet = ShipSpriteSheet(game.spriteImage);
    sprite = spriteSheet.getShipSprite(_currentDirection);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final perspective = game.gameValues.perspective;
    if (perspective != _currentDirection) {
      _currentDirection = perspective;
      sprite = spriteSheet.getShipSprite(_currentDirection);
      final val = _currentDirection.val;
      // There are some errors in how the sprite was projected by blender,
      // these lines correct them (kind of)
      double angleCorrectionX;
      final absVal = val.abs();
      if (val == 0) {
        angleCorrectionX = 0;
      } else if (absVal <= 9) {
        angleCorrectionX = val.sign * (absVal / 9) * 10; // 0 to ±10
      } else {
        angleCorrectionX =
            val.sign * (10 + ((absVal - 9) / 9) * -5); // ±10 to ±5
      }
      final angleCorrectionY = -10 + (10 * (_currentDirection.val.abs() / 18));
      position = Vector2(angleCorrectionX * -2, angleCorrectionY);
    }
  }
}

class ShipSpriteSheet extends SpriteSheet {
  ShipSpriteSheet(Image image)
    : super.fromColumnsAndRows(image: image, columns: 6, rows: 7);

  Sprite getShipSprite(GamePerspective direction) {
    return getSpriteById(direction.val + 18);
  }
}
