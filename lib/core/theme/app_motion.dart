import 'package:flutter/material.dart';

class AppMotion {
  const AppMotion._();

  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration xSlow = Duration(milliseconds: 800);

  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve decelerate = Curves.decelerate;

  static const double springStiffnessSoft = 100;
  static const double springStiffnessNormal = 200;
  static const double springStiffnessSnappy = 400;
  static const double springDampingNormal = 16;
  static const double springDampingHeavy = 24;

  static const double pressedScale = 0.97;
}
