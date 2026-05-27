import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_motion.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/core/utils/haptic_utils.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

typedef PhosphorIconFactory = IconData Function([PhosphorIconsStyle style]);

class NavDestination {
  const NavDestination({
    required this.label,
    required this.path,
    required this.icon,
  });

  final String label;
  final String path;
  final PhosphorIconFactory icon;
}

const luminaDestinations = [
  NavDestination(
    label: 'Dashboard',
    path: '/dashboard',
    icon: PhosphorIcons.house,
  ),
  NavDestination(label: 'Log', path: '/log', icon: PhosphorIcons.pencilLine),
  NavDestination(
    label: 'Insights',
    path: '/insights',
    icon: PhosphorIcons.chartLineUp,
  ),
  NavDestination(label: 'Mentor', path: '/mentor', icon: PhosphorIcons.sparkle),
  NavDestination(label: 'Agents', path: '/agents', icon: PhosphorIcons.sparkle),
  NavDestination(
    label: 'Settings',
    path: '/settings',
    icon: PhosphorIcons.gear,
  ),
];

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final height = AppSpacing.bottomNavHeight + bottomInset;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height,
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(
            color: context.isDark
                ? colors.backgroundPrimary.withValues(alpha: 0.85)
                : colors.backgroundCard.withValues(alpha: 0.90),
            border: Border(
              top: BorderSide(
                color: context.isDark ? colors.divider : Colors.transparent,
              ),
            ),
            boxShadow: context.isDark
                ? const []
                : const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 20,
                      offset: Offset(0, -6),
                    ),
                  ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth =
                  constraints.maxWidth / luminaDestinations.length;
              const indicatorWidth = 30.0;
              final indicatorLeft =
                  itemWidth * currentIndex + itemWidth / 2 - indicatorWidth / 2;

              return Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedPositioned(
                    duration: AppMotion.fast,
                    curve: AppMotion.enter,
                    left: indicatorLeft,
                    top: 7,
                    child: Container(
                      width: indicatorWidth,
                      height: 3,
                      decoration: BoxDecoration(
                        color: colors.primaryAccent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < luminaDestinations.length; i++)
                        Expanded(
                          child: _BottomNavItem(
                            item: luminaDestinations[i],
                            isActive: i == currentIndex,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatefulWidget {
  const _BottomNavItem({required this.item, required this.isActive});

  final NavDestination item;
  final bool isActive;

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconColor = widget.isActive
        ? colors.primaryAccent
        : colors.textTertiary;
    final icon = widget.item.icon(
      widget.isActive ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () {
        HapticUtils.selection();
        if (!widget.isActive) {
          context.go(widget.item.path);
        }
      },
      child: AnimatedScale(
        duration: AppMotion.fast,
        curve: AppMotion.spring,
        scale: _pressed ? 0.85 : 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            AnimatedSwitcher(
              duration: AppMotion.fast,
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.exit,
              child: widget.isActive
                  ? Padding(
                      key: ValueKey(widget.item.label),
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.primaryAccent,
                        ),
                      ),
                    )
                  : const SizedBox(key: ValueKey('hidden'), height: 18),
            ),
          ],
        ),
      ),
    );
  }
}
