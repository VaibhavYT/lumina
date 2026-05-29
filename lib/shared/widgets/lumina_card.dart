import 'package:flutter/material.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_motion.dart';
import 'package:lumina/core/theme/app_radius.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/core/theme/app_theme.dart';
import 'package:lumina/core/utils/haptic_utils.dart';

class LuminaCard extends StatefulWidget {
  const LuminaCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardInsets,
    this.onTap,
    this.borderRadius = AppRadius.radiusLg,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;

  @override
  State<LuminaCard> createState() => _LuminaCardState();
}

class _LuminaCardState extends State<LuminaCard> {
  bool _pressed = false;

  bool get _isInteractive => widget.onTap != null;

  void _setPressed(bool value) {
    if (!_isInteractive || _pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canvas = context.livingCanvas;

    final card = AnimatedScale(
      scale: _pressed ? AppMotion.pressedScale : 1,
      duration: canvas.instant,
      curve: canvas.curve,
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? colors.backgroundCard,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: colors.divider),
          boxShadow: AppTheme.cardShadowFor(context),
        ),
        child: widget.child,
      ),
    );

    if (!_isInteractive) {
      return card;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        HapticUtils.light();
        _setPressed(true);
      },
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: card,
    );
  }
}
