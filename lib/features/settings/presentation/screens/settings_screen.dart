import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_motion.dart';
import 'package:lumina/core/theme/app_radius.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/core/theme/theme_provider.dart';
import 'package:lumina/core/utils/haptic_utils.dart';
import 'package:lumina/shared/widgets/lumina_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode != ThemeMode.light;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.lg,
            AppSpacing.pagePadding,
            120,
          ),
          children: [
            Text('Settings', style: context.textTheme.displayMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tune Lumina to the way your day feels.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            LuminaCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primaryAccentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDark
                          ? PhosphorIcons.moon(PhosphorIconsStyle.fill)
                          : PhosphorIcons.sun(PhosphorIconsStyle.fill),
                      color: colors.primaryAccent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Theme', style: context.textTheme.headlineMedium),
                        const SizedBox(height: 2),
                        Text(
                          isDark
                              ? 'Obsidian clarity'
                              : 'Parchment intelligence',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ThemeToggle(
                    value: isDark,
                    onChanged: (_) {
                      HapticUtils.selection();
                      ref.read(themeProvider.notifier).toggle();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        width: 62,
        height: 34,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value ? colors.primaryAccentSoft : colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppRadius.radiusFull),
          border: Border.all(color: colors.divider),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: AppMotion.fast,
              curve: AppMotion.enter,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: colors.primaryAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  value ? PhosphorIcons.moon() : PhosphorIcons.sun(),
                  size: 14,
                  color: context.isDark
                      ? colors.backgroundPrimary
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
