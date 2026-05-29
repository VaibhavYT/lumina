import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/features/insights/data/repositories/insights_repository.dart';
import 'package:lumina/features/insights/presentation/providers/insights_notifier.dart';
import 'package:lumina/features/insights/presentation/widgets/insights_widgets.dart';
import 'package:lumina/features/insights/presentation/widgets/monthly_constellations.dart';
import 'package:lumina/features/goals/presentation/providers/goal_notifier.dart';
import 'package:lumina/features/goals/presentation/widgets/goal_widgets.dart';
import 'package:lumina/shared/widgets/shimmer_loader.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(insightsNotifierProvider);
    final goalState = ref.watch(goalNotifierProvider).valueOrNull;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: asyncState.when(
        loading: () => const _InsightsLoading(),
        error: (error, stackTrace) => Center(
          child: Text(
            'Insights could not load.',
            style: context.textTheme.bodyLarge,
          ),
        ),
        data: (state) {
          final repository = ref.read(insightsRepositoryProvider);
          final burnout = repository.analyzeBurnout(
            state.days,
            AppColorsShim(
              success: colors.successColor,
              warning: colors.warningColor,
              error: colors.errorColor,
            ),
          );

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 152,
                backgroundColor: colors.backgroundPrimary,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: context.livingCanvas.heroGradient(colors),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        AppSpacing.lg,
                        AppSpacing.pagePadding,
                        0,
                      ),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Patterns',
                              style: context.textTheme.displayMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Insights from the last ${state.range.days} days',
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TimeRangeFilter(
                              selected: state.range,
                              onChanged: (range) => ref
                                  .read(insightsNotifierProvider.notifier)
                                  .setRange(range),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.md,
                  AppSpacing.pagePadding,
                  AppSpacing.sectionGap,
                ),
                sliver: SliverList.list(
                  children: [
                    MonthlyConstellationsCard(
                      retrospective: state.retrospective,
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    MoodJourneyCard(days: state.days),
                    const SizedBox(height: AppSpacing.sectionGap),
                    EnergyPatternsCard(days: state.days),
                    const SizedBox(height: AppSpacing.sectionGap),
                    BurnoutRiskCard(analysis: burnout),
                    const SizedBox(height: AppSpacing.sectionGap),
                    HabitHeatmapCard(days: state.days),
                    if (goalState?.snapshot.hasActiveGoal ?? false) ...[
                      const SizedBox(height: AppSpacing.sectionGap),
                      GoalProgressCard(snapshot: goalState!.snapshot),
                    ],
                    const SizedBox(height: AppSpacing.sectionGap),
                    ProductivityPatternsCard(summary: state.productivity),
                    const SizedBox(height: AppSpacing.sectionGap),
                    EmotionalTriggersCard(triggers: state.triggers),
                    const SizedBox(height: AppSpacing.sectionGap),
                    Text(
                      'Notable Streaks',
                      style: context.textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(child: NotableStreaksRow(days: state.days)),
              const SliverToBoxAdapter(child: SizedBox(height: 128)),
            ],
          );
        },
      ),
    );
  }
}

class _InsightsLoading extends StatelessWidget {
  const _InsightsLoading();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerLoader(width: 180, height: 34),
            SizedBox(height: AppSpacing.sectionGap),
            ShimmerLoader(height: 230),
            SizedBox(height: AppSpacing.md),
            ShimmerLoader(height: 190),
            SizedBox(height: AppSpacing.md),
            ShimmerLoader(height: 220),
          ],
        ),
      ),
    );
  }
}
