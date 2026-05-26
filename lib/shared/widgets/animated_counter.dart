import 'package:flutter/material.dart';
import 'package:lumina/core/theme/app_motion.dart';

class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = AppMotion.standard,
    this.textStyle,
    this.suffix = '',
  });

  final int value;
  final Duration duration;
  final TextStyle? textStyle;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(end: value),
      duration: duration,
      curve: AppMotion.enter,
      builder: (context, animatedValue, child) {
        return Text('$animatedValue$suffix', style: textStyle);
      },
    );
  }
}
