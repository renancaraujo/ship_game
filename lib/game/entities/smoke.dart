import 'dart:async';
import 'dart:math' as math;

import 'package:demo_2/game/game.dart';
import 'package:demo_2/game/utilities/isometric_component.dart';
import 'package:demo_2/game/utilities/konstants.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class SmokeParticles extends PositionComponent
    with HasGameReference<SomeShipGame> {
  SmokeParticles() {
    anchor = Anchor.center;
  }

  late final random = math.Random();

  late Timer timer;

  Timer get initialTimer => Timer(1, onTick: onTick, autoStart: false);

  Iterable<SmokeParticle> get currentSmokeParticles =>
      children.query<SmokeParticle>();

  @override
  FutureOr<void> onLoad() {
    timer = initialTimer..start();
    children.register<SmokeParticle>();
  }

  void onTick() {
    final nextInterval = 0.8 + random.nextDouble() * 0.2;
    timer = Timer(nextInterval, onTick: onTick);

    var xDeviation = (random.nextDouble() - 0.5) * 200;
    var yDeviation = (random.nextDouble() - 0.5) * 50;

    add(
      SmokeParticle(
        position3: Vector3(0, -60, -86),
        toX: xDeviation,
        toY: yDeviation,
      ),
    );

    xDeviation = (random.nextDouble() - 0.5) * 400;
    yDeviation = (random.nextDouble() - 0.5) * 150;

    add(
      SmokeParticle(
        position3: Vector3(0, 0, -86),
        toX: xDeviation,
        toY: yDeviation,
      ),
    );
  }

  @override
  void update(double dt) {
    timer.update(dt);
  }
}

class SmokeParticle extends PositionComponent {
  SmokeParticle({
    required this.position3,
    required this.toX,
    required this.toY,
  });

  Vector3 position3;
  final double toX;
  final double toY;

  late final innerPos = PositionComponent(
    children: [],
  )..position = position3.xy;
  late final IsometricPlaneComponent plane = IsometricPlaneComponent(
    plane: IsometricPlane.ground,
    planDisplacement: position3.z,
    children: [innerPos],
  );

  double get progress => effect._progress;
  double get smokeRadius => 2.9 * kSmokeRadiusCurve.transform(progress) + 0.3;
  double get smokeOpacity {
    final acceleratedProgress = (progress * 1.4).clamp(0.0, 1.0);
    return (1.0 - kSmokeOpacityCurve.transform(acceleratedProgress)) * 0.5;
  }

  @override
  Future<void> onLoad() async {
    add(plane);
    await add(effect);
  }

  late IsometricSmokeEffect effect = IsometricSmokeEffect(
    Vector3(toX, 1000, -300 + toY),
    LinearEffectController(10),
    this,
    onComplete: removeFromParent,
  );

  @override
  void update(double dt) {
    innerPos.position = position3.xy;
    plane.planDisplacement = position3.z;

    super.update(dt);
  }
}

class IsometricSmokeEffect extends Effect with EffectTarget<SmokeParticle> {
  IsometricSmokeEffect(
    Vector3 offset,
    super.controller,
    SmokeParticle? target, {
    super.onComplete,
    super.key,
  }) : _offset = offset {
    this.target = target;
  }

  final Vector3 _offset;

  double lastCurvedProgress = 0;

  double _progress = 0;

  @override
  void apply(double progress) {
    _progress = progress;
    final curvedProgress = Curves.easeOutCirc.transform(progress);

    target.position3.xy += _offset.xy * (progress - previousProgress);
    target.position3.z += _offset.z * (curvedProgress - lastCurvedProgress);
    lastCurvedProgress = curvedProgress;
  }
}
