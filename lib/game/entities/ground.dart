import 'dart:async';
import 'dart:ui'
    show
        Paint,
        Color,
        Canvas,
        Path,
        Gradient,
        Offset,
        Rect,
        ImageFilter,
        BlendMode;

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
        children: [
          ShipWake(
            position: Vector2(size.x / 2, size.y / 2),
          ),
        ],
      ),
    );
  }
}

class ShipWake extends PositionComponent with HasGameReference<SomeShipGame> {
  ShipWake({super.position}) {
    size = Vector2(860, 1460);
    anchor = Anchor.topCenter;
    priority = -1;
    position.translate(0, -230);
    add(OuterWakeShapeComponent()..position = Vector2(size.x / 2, 0));
    add(InnerWakeShapeComponent()..position = Vector2(size.x / 2, 0));
  }
}

class OuterWakeShapeComponent extends ShapeComponent {
  OuterWakeShapeComponent()
    : super(anchor: Anchor.topCenter, position: Vector2(0, -10)) {
    size = Vector2(900, 1760);
    paint = Paint()..color = const Color(0xFF00FF00);
  }

  /// Draws a parabolic shape
  late final shapePath = () {
    final path = Path();
    final current = Vector2(size.x / 2, 0);
    path.moveTo(current.x, current.y);
    final desloc = Vector2(size.x / 2, size.y);
    final curve = Vector4(.21, 0.0, .39, .16);
    path.relativeCubicTo(
      curve.x * desloc.x,
      curve.y * desloc.y,
      curve.z * desloc.x,
      curve.w * desloc.y,
      desloc.x,
      desloc.y,
    );
    current.add(desloc);

    path.lineTo(0, size.y);
    current.setValues(0, size.y);

    path.relativeCubicTo(
      (1 - curve.z) * desloc.x,
      -(1 - curve.w) * desloc.y,
      (1 - curve.x) * desloc.x,
      -(1 - curve.y) * desloc.y,
      desloc.x,
      -desloc.y,
    );
    current.add(Vector2(desloc.x, -desloc.y));

    return path;
  }();

  late final blurPaint = Paint()
    ..imageFilter = ImageFilter.blur(sigmaX: 10, sigmaY: 10);
  late final excludePaint = Paint()
    ..blendMode = BlendMode.dstOut
    ..imageFilter = ImageFilter.blur(sigmaX: 100, sigmaY: 200);

  @override
  void render(Canvas canvas) {
    canvas.saveLayer(Offset.zero & size.toSize(), blurPaint);
    {
      canvas.drawPath(shapePath, paint);
      canvas.save();
      {
        canvas.translate(0, 30);
        canvas.drawPath(shapePath, excludePaint);
      }
      canvas.restore();
    }
    canvas.restore();
  }
}

class InnerWakeShapeComponent extends ShapeComponent {
  InnerWakeShapeComponent()
    : super(anchor: Anchor.topCenter, position: Vector2(0, 10)) {
    size = Vector2(100, 2000);
    paint = Paint()..color = const Color(0xFFFF0000);
  }

  /// Draws a parabolic shape
  late final shapePath = () {
    final path = Path();
    final current = Vector2(size.x / 2, 0);
    path.moveTo(current.x, current.y);

    final desloc = Vector2(size.x / 2, 400);
    final curve = Vector4(.19, 0, .98, .25);
    path.relativeCubicTo(
      curve.x * desloc.x,
      curve.y * desloc.y,
      curve.z * desloc.x,
      curve.w * desloc.y,
      desloc.x,
      desloc.y,
    );
    current.add(desloc);

    path.lineTo(current.x, size.y);
    current.setValues(current.x, size.y);

    path.lineTo(0, size.y);
    current.setValues(0, size.y);

    path.lineTo(0, desloc.y);
    current.setValues(0, desloc.y);

    path.relativeCubicTo(
      (1 - curve.z) * desloc.x,
      -(1 - curve.w) * desloc.y,
      (1 - curve.x) * desloc.x,
      -(1 - curve.y) * desloc.y,
      desloc.x,
      -desloc.y,
    );
    current.add(Vector2(desloc.x, -desloc.y));
    return path;
  }();

  late final blurPaint = Paint()
    ..imageFilter = ImageFilter.blur(sigmaX: 5, sigmaY: 5)
    ..blendMode = BlendMode.screen;
  late final excludePaint = Paint()
    ..blendMode = BlendMode.dstOut
    ..imageFilter = ImageFilter.blur(sigmaX: 30, sigmaY: 200);

  @override
  void render(Canvas canvas) {
    canvas.saveLayer(Offset.zero & size.toSize(), blurPaint);
    {
      canvas.drawPath(shapePath, paint);
      canvas.drawPath(shapePath, excludePaint);
    }
    canvas.restore();
  }
}
