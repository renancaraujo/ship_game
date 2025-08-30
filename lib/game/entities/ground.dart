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
import 'package:demo_2/game/post_process/wake_post_process.dart';
import 'package:demo_2/game/utilities/game_perspective.dart';
import 'package:demo_2/game/utilities/isometric_component.dart';
import 'package:flame/components.dart';
import 'package:flame/post_process.dart';

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
            Vector2(size.x / 2, size.y / 2),
            postProcess: WakePostProcess(
              fragmentProgram: game.preloadedPrograms.wake,
              game: game,
            ),
          ),
        ],
      ),
    );
  }
}

class ShipWake extends PostProcessComponent
    with HasGameReference<SomeShipGame> {
  ShipWake(Vector2 position, {required super.postProcess}) {
    this.position = position;
    size = Vector2(860, 1460);
    anchor = Anchor.topCenter;
    priority = -1;
    this.position.translate(0, -230);
    add(OuterWakeShapeComponent()..position = Vector2(size.x / 2, 0));
    add(InnerWakeShapeComponent()..position = Vector2(size.x / 2, 0));
  }
}

class OuterWakeShapeComponent extends ShapeComponent {
  OuterWakeShapeComponent()
    : super(anchor: Anchor.topCenter, position: Vector2(0, -10)) {
    size = Vector2(900, 1760);
    paint = Paint()
      ..shader = Gradient.linear(
        Offset(0, size.y / 2),
        Offset(size.x, size.y / 2),
        [
          const Color(0xFF00FF00),
          const Color(0x0000FF00),
          const Color(0x0000FF00),
          const Color(0xFF00FF00),
        ],
        [0.0, 0.01, 0.99, 1.0],
      );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
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

    paint = Paint()..color = const Color(0xFF00FF00);

    final spaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..imageFilter = ImageFilter.blur(sigmaX: 100, sigmaY: 200);

    canvas.saveLayer(
      Offset.zero & size.toSize(),
      Paint()..imageFilter = ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    );

    canvas.drawPath(path, paint);

    canvas.save();
    canvas.translate(0, 30);
    canvas.drawPath(path, spaint);
    canvas.restore();
    canvas.restore();
  }
}

class InnerWakeShapeComponent extends ShapeComponent {
  InnerWakeShapeComponent()
    : super(anchor: Anchor.topCenter, position: Vector2(0, 10)) {
    size = Vector2(100, 2000);
    paint = Paint()..color = const Color(0xFFFF0000);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

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

    final spaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..imageFilter = ImageFilter.blur(sigmaX: 30, sigmaY: 200);

    canvas.saveLayer(
      Offset.zero & size.toSize(),
      Paint()
        ..imageFilter = ImageFilter.blur(sigmaX: 5, sigmaY: 5)
        ..blendMode = BlendMode.screen,
    );
    canvas.drawPath(path, paint);
    canvas.drawPath(path, spaint);

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.x / 2, 10),
        width: 10,
        height: 500, //
      ),
      Paint()..color = const Color(0xFFFF0000),
      // ..shader = Gradient.linear(
      //   Offset(0, 0),
      //   Offset(0, 400),
      //   [
      //     const Color(0xFFFF0000),
      //     const Color(0x00FF0000), //
      //   ],
      //   [0.0, 1.0],
      // ),
    );
    canvas.restore();
  }
}
