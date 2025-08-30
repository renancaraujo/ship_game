import 'dart:ui';

import 'package:demo_2/game/game.dart';
import 'package:flame/game.dart';
import 'package:flame/post_process.dart';

class WakePostProcess extends PostProcess {
  WakePostProcess({
    required this.fragmentProgram,
    required this.game,
    super.pixelRatio,
  });

  final FragmentProgram fragmentProgram;
  final SomeShipGame game;
  late final shader = fragmentProgram.fragmentShader();

  double time = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;
  }

  @override
  void postProcess(Vector2 size, Canvas canvas) {
    final normals = rasterizeSubtree();

    shader.setFloatUniforms((value) {
      value
        ..setVector(size)
        ..setFloat(time)
        ..setFloat(pixelRatio);
    });

    shader.setImageSampler(0, normals);

    canvas
      ..save()
      ..drawRect(Offset.zero & size.toSize(), Paint()..shader = shader)
      ..restore();
  }
}
