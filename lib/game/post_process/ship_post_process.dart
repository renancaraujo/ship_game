import 'dart:ui';

import 'package:demo_2/game/game.dart';
import 'package:flame/game.dart';
import 'package:flame/post_process.dart';

class ShipPostProcess extends PostProcess {
  ShipPostProcess({
    required this.fragmentProgram,
    required this.game,
    super.pixelRatio,
  });

  final SomeShipGame game;
  final FragmentProgram fragmentProgram;
  late final shader = fragmentProgram.fragmentShader();

  @override
  void postProcess(Vector2 size, Canvas canvas) {
    final shipRendered = rasterizeSubtree();

    shader.setFloatUniforms((value) {
      value
        ..setVector(size)
        ..setFloat(pixelRatio);
    });
    shader.setImageSampler(0, shipRendered);

    canvas
      ..save()
      ..drawRect(
        Offset.zero & size.toSize(),
        Paint()..shader = shader,
      )
      ..restore();
  }
}
