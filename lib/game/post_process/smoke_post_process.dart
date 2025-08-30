import 'dart:math' as math;
import 'dart:ui';

import 'package:demo_2/game/game.dart';
import 'package:flame/components.dart';
import 'package:flame/post_process.dart';

class SmokePostProcess extends PostProcess {
  SmokePostProcess({
    required this.fragmentProgram,
    required this.game,
    super.pixelRatio,
  });

  final FragmentProgram fragmentProgram;
  final SomeShipGame game;
  late final shader = fragmentProgram.fragmentShader();

  final List<Vector3> sphereCenters = List.filled(
    20,
    Vector3.zero(),
  );
  final List<double> sphereRadii = List.filled(20, 0.0);
  final List<double> sphereOpacities = List.filled(20, 0.0);

  @override
  void postProcess(Vector2 size, Canvas canvas) {
    final particles = game.world.smokeParticles.currentSmokeParticles
        .toList()
        .reversed;

    for (var i = 0; i < 20; i++) {
      final particle = particles.elementAtOrNull(i);

      if (particle == null) {
        sphereCenters[i] = Vector3(0, 0, 0);
        sphereRadii[i] = 0.0;
        continue;
      }

      sphereRadii[i] = particle.smokeRadius;
      sphereOpacities[i] = particle.smokeOpacity;

      // Translate the isometric position to the one in the shader.
      final og = particle.position3;
      sphereCenters[i] = Vector3(
        og.x * -0.0155,
        og.z * (4 / 215),
        og.y * 0.01635,
      );
    }

    shader.setFloatUniforms((value) {
      value
        ..setVector(size)
        ..setFloat(game.gameValues.perspective.angle * -180 / math.pi)
        ..setVectors(sphereCenters)
        ..setFloats(sphereRadii)
        ..setFloats(sphereOpacities);
    });

    renderSubtree(canvas);

    canvas
      ..save()
      ..drawRect(Offset.zero & size.toSize(), Paint()..shader = shader)
      ..restore();
  }
}
