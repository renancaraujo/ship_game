import 'dart:math' as math;

import 'package:demo_2/game/game.dart';
import 'package:flame/components.dart';

enum GamePerspective {
  starboard18(-18),
  starboard17(-17),
  starboard16(-16),
  starboard15(-15),
  starboard14(-14),
  starboard13(-13),
  starboard12(-12),
  starboard11(-11),
  starboard10(-10),
  starboard9(-9),
  starboard8(-8),
  starboard7(-7),
  starboard6(-6),
  starboard5(-5),
  starboard4(-4),
  starboard3(-3),
  starboard2(-2),
  starboard1(-1),
  deadAhead(0),
  port1(1),
  port2(2),
  port3(3),
  port4(4),
  port5(5),
  port6(6),
  port7(7),
  port8(8),
  port9(9),
  port10(10),
  port11(11),
  port12(12),
  port13(13),
  port14(14),
  port15(15),
  port16(16),
  port17(17),
  port18(18);

  const GamePerspective(this.val);

  static GamePerspective fromVal(int val) {
    return GamePerspective.values[val + 18];
  }

  final int val;

  double get angle {
    return (val / -18.0) * (math.pi / 2);
  }
}

class GameValues extends Component with HasGameReference<SomeShipGame> {
  GamePerspective perspective = GamePerspective.deadAhead;
}
