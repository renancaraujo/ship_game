import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/post_process.dart';

class VignettePostProcess extends PostProcess {
  VignettePostProcess({required this.fragmentProgram, super.pixelRatio});

  final FragmentProgram fragmentProgram;
  late final shader = fragmentProgram.fragmentShader();

  @override
  void postProcess(Vector2 size, Canvas canvas) {
    renderSubtree(canvas);

    shader.setFloatUniforms((value) {
      value
        ..setVector(size)
        ..setVector(Vector2(0.5, 0.4))
        ..setVector(Vector4(0.24, 0.20, 0.0, 0.2)) // sepia color
        ;
    });

    canvas.drawRect(
      Offset.zero & size.toSize(),
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.multiply,
    );
  }
}
