import 'package:flame/game.dart';
import 'package:flutter/animation.dart' show Cubic, Curves;

final kResolution = Vector2(1279, 801);
const kSmokeRadiusCurve = Curves.easeOutQuart;
const kSmokeOpacityCurve = Cubic(.38, 0, 1, .05);
