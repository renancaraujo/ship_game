import 'dart:async';
import 'dart:ui' show Image, FragmentProgram, Color, Paint;

import 'package:demo_2/game/entities/ground.dart';
import 'package:demo_2/game/entities/ship.dart';
import 'package:demo_2/game/utilities/camera_target.dart';
import 'package:demo_2/game/utilities/game_perspective.dart';
import 'package:demo_2/game/utilities/input_interface.dart';
import 'package:demo_2/game/utilities/konstants.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';

class SomeShipGame extends FlameGame<MyWorld>
    with
        HasKeyboardHandlerComponents,
        HasCollisionDetection,
        SingleGameInstance,
        HorizontalDragDetector {
  SomeShipGame({required this.preloadedPrograms})
    : super(
        camera: CameraComponent(
          backdrop: RectangleComponent(
            size: kResolution,
            paint: Paint()..color = const Color.fromARGB(255, 0, 73, 102),
          ),
          viewport: FixedResolutionViewport(resolution: kResolution),
        ),
        world: MyWorld(),
      );

  final PreloadedPrograms preloadedPrograms;

  late final Image spriteImage;
  late final GameValues gameValues;
  late final InputInterface inputInterface;

  @override
  Future<void> onLoad() async {
    spriteImage = await Flame.images.load('spritesheet.png');
    camera.follow(world.cameraTarget);
    add(gameValues = GameValues());
    add(inputInterface = InputInterface());
  }

  @override
  void update(double dt) {
    camera.viewfinder.visibleGameSize = kResolution / 20;

    super.update(dt);
  }

  @override
  void onHorizontalDragDown(DragDownInfo info) {
    inputInterface.onHorizontalDragDown(info);
  }

  @override
  void onHorizontalDragStart(DragStartInfo info) {
    inputInterface.onHorizontalDragStart(info);
  }

  @override
  void onHorizontalDragUpdate(DragUpdateInfo info) {
    inputInterface.onHorizontalDragUpdate(info);
  }

  @override
  void onHorizontalDragEnd(DragEndInfo info) {
    inputInterface.onHorizontalDragEnd(info);
  }

  @override
  void onHorizontalDragCancel() {
    inputInterface.onHorizontalDragCancel();
  }
}

class MyWorld extends World {
  MyWorld({super.children, super.key}) {
    addAll([
      ground = Ground(children: [cameraTarget = CameraTarget()]),
      ship = Ship(),
    ]);
  }

  late final Ship ship;
  late final CameraTarget cameraTarget;
  late final Ground ground;
}

// Set of fragment programs to be loaded
// at the start of the application, on widget level.
typedef PreloadedPrograms = ({
  FragmentProgram sea,
  FragmentProgram wake,
  FragmentProgram ship,
  FragmentProgram smoke,
  FragmentProgram vignette,
});
