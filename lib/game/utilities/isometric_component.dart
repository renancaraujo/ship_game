import 'dart:math' as math;
import 'dart:ui';

import 'package:demo_2/game/game.dart';
import 'package:demo_2/game/utilities/game_perspective.dart';
import 'package:flame/components.dart';

enum IsometricPlane {
  // Represent the plane parealel to the ground
  ground,

  // Represent the vertical plane along the ship's length
  verticalAlong,

  // Represent the vertical plane across the ship's width
  verticalAcross,
}

RectangleComponent getS() => RectangleComponent(
  size: Vector2(200, 200),
  paint: Paint()
    ..shader = Gradient.linear(Offset.zero, const Offset(200, 200), [
      const Color(0xFF00FF00),
      const Color(0xFF0000FF),
    ]),

  anchor: Anchor.center,
);

RectangleComponent getS2() => RectangleComponent(
  size: Vector2(200, 200),
  paint: Paint()
    ..shader = Gradient.linear(Offset.zero, const Offset(200, 200), [
      const Color.fromARGB(255, 255, 175, 2),
      const Color(0xFF0000FF),
    ]),

  anchor: Anchor.center,
);

class IsometricPlaneComponent extends PositionComponent
    with HasGameReference<SomeShipGame> {
  IsometricPlaneComponent({
    IsometricPlane? plane,
    this.planDisplacement = 0,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.nativeAngle,
    super.anchor,
    super.children,
    super.priority,
    super.key,
  }) {
    _plane = plane ?? IsometricPlane.ground;
  }

  IsometricPlane? _plane;
  double planDisplacement;

  set plane(IsometricPlane? value) {
    _plane = value;
    _applyIsometricTransformation();
  }

  IsometricPlane? get plane => _plane;

  GamePerspective? appliedPerspective;

  @override
  void update(double dt) {
    super.update(dt);

    // if (appliedPerspective != game.gameValues.perspective) {
    _applyIsometricTransformation();
    // }
  }

  void _applyIsometricTransformation() {
    switch (_plane) {
      case IsometricPlane.ground:
        _applyForGroundPlane();
      case IsometricPlane.verticalAlong:
        _applyForVerticalAlongPlane();
      case IsometricPlane.verticalAcross:
        _applyForVerticalAcrossPlane();
      case null:
        break;
    }
  }

  void _applyForVerticalAlongPlane() {
    final angle = game.gameValues.perspective.angle;
    const rAngle = 90 - 60.5593;
    const radAngle = rAngle * (math.pi / 180);

    final centerX = size.x / 2;
    final centerY = size.y / 2;

    transform.transformMatrix.setIdentity();
    anchor = Anchor.center;

    transform.transformMatrix
      ..translateByVector3(Vector3(centerX, centerY, 0))
      ..rotateX(radAngle)
      ..rotateY(math.pi / 2 + angle)
      ..rotateZ(math.pi / 2)
      ..translateByVector3(Vector3(-centerX, -centerY, 0));

    appliedPerspective = game.gameValues.perspective;
  }

  void _applyForGroundPlane() {
    final angle = game.gameValues.perspective.angle;
    const rAngle = 90 - 60.5593;
    const radAngle = rAngle * (math.pi / 180);
    final scaleY = math.sin(radAngle);

    final centerX = size.x / 2;
    final centerY = size.y / 2;

    transform.transformMatrix.setIdentity();
    anchor = Anchor.center;

    transform.transformMatrix
      ..translateByVector3(Vector3(0, planDisplacement, 0))
      ..translateByVector3(Vector3(centerX, centerY, 0))
      ..setEntry(1, 1, scaleY)
      ..rotateZ(angle)
      ..translateByVector3(Vector3(-centerX, -centerY, 0));

    appliedPerspective = game.gameValues.perspective;
  }

  void _applyForVerticalAcrossPlane() {
    final angle = game.gameValues.perspective.angle;
    const rAngle = 90 - 60.5593;
    const radAngle = rAngle * (math.pi / 180);

    transform.transformMatrix.setIdentity();
    anchor = Anchor.center;

    transform.transformMatrix
      ..rotateX(radAngle)
      ..rotateY(angle)
      ..rotateZ(math.pi / 2);

    appliedPerspective = game.gameValues.perspective;
  }
}
