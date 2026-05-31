import 'package:flutter/material.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_radius.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class GoalTaskTag extends StatelessWidget {
  const GoalTaskTag({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primaryAccentSoft,
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.target(PhosphorIconsStyle.fill),
            color: colors.primaryAccent,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            'Goal',
            style: context.textTheme.labelSmall?.copyWith(
              color: colors.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }
}
