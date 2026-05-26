import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  static const double pagePadding = 20;
  static const double cardPadding = 16;
  static const double sectionGap = 28;
  static const double bottomNavHeight = 72;

  static const EdgeInsets pageInsets = EdgeInsets.symmetric(
    horizontal: pagePadding,
  );
  static const EdgeInsets cardInsets = EdgeInsets.all(cardPadding);
}
