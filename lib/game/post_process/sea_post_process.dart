import 'dart:ui';

import 'package:demo_2/game/game.dart';
import 'package:flame/game.dart';
import 'package:flame/post_process.dart';

class SeaPostProcess extends PostProcess {
  SeaPostProcess({
    required this.fragmentProgram,
    required this.game,
    super.pixelRatio,
  });

  final SomeShipGame game;
  final FragmentProgram fragmentProgram;
  late final shader = fragmentProgram.fragmentShader();

  double time = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;
  }

  @override
  void postProcess(Vector2 size, Canvas canvas) {
    shader.setFloatUniforms((value) {
      value
        ..setVector(size)
        ..setFloat(time)
        ..setFloat(game.gameValues.perspective.angle);
    });

    canvas
      ..save()
      ..drawRect(Offset.zero & size.toSize(), Paint()..shader = shader)
      ..restore();

    renderSubtree(canvas);
  }
}
