import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/constants/app_constants.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_motion.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/features/dashboard/presentation/providers/dashboard_notifier.dart';
import 'package:lumina/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:lumina/features/dashboard/services/dashboard_greeting_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardNotifierProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: dashboard.when(
        loading: () =>
            const CustomScrollView(slivers: [DashboardLoadingSliver()]),
        error: (error, stackTrace) => DashboardErrorState(
          onRetry: () => ref.read(dashboardNotifierProvider.notifier).refresh(),
        ),
        data: (state) => RefreshIndicator(
          color: colors.primaryAccent,
          backgroundColor: colors.backgroundElevated,
          onRefresh: () async {
            await ref.read(dashboardNotifierProvider.notifier).refresh();
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Updated')));
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _DashboardHeader(state: state),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                sliver: SliverList.list(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    SnapshotRow(state: state),
                    const SizedBox(height: AppSpacing.sectionGap),
                    DashboardMentorCard(insight: state.mentorInsight),
                    const SizedBox(height: AppSpacing.sectionGap),
                    TodaysFocusSection(
                      tasks: state.tasks,
                      onToggleTask: (taskId) => ref
                          .read(dashboardNotifierProvider.notifier)
                          .toggleTask(taskId),
                    ),
                    if (!state.hasLoggedMood) ...[
                      const SizedBox(height: AppSpacing.sectionGap),
                      const MoodCheckInBanner(),
                    ],
                    const SizedBox(height: AppSpacing.sectionGap),
                    const SectionTitle('Habit Rhythm'),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: HabitRingsRow(habits: state.habits),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.sectionGap,
                  AppSpacing.pagePadding,
                  128,
                ),
                sliver: SliverList.list(children: const [RecentPatternsCard()]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final greetingService = const DashboardGreetingService();
    final greeting = greetingService.greeting();
    final subtitle = greetingService.subtitle(
      moodEntry: state.moodEntry,
      completedTasks: state.completedTasks,
      totalTasks: state.tasks.length,
    );

    return SliverAppBar(
      pinned: true,
      expandedHeight: 160,
      backgroundColor: colors.backgroundSecondary.withValues(alpha: 0.88),
      surfaceTintColor: Colors.transparent,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
            color: colors.primaryAccent,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              '$greeting, ${AppConstants.defaultDisplayName}',
              style: context.textTheme.headlineMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final topPadding = MediaQuery.paddingOf(context).top;
          final currentHeight = constraints.maxHeight - topPadding;
          final expandedFraction =
              ((currentHeight - kToolbarHeight) / (160 - kToolbarHeight)).clamp(
                0.0,
                1.0,
              );

          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.2,
                colors: [
                  colors.primaryAccent.withValues(
                    alpha: context.isDark ? 0.04 : 0.06,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
            child: Opacity(
              opacity: expandedFraction,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: AppSpacing.pagePadding,
                    right: AppSpacing.pagePadding,
                    bottom: AppSpacing.md,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Row(
                      children: [
                        Expanded(
                          child:
                              Text(
                                    greeting,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.displayLarge,
                                  )
                                  .animate()
                                  .fadeIn(duration: AppMotion.slow)
                                  .slideY(begin: 0.16, end: 0),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/settings'),
                          child: Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.primaryAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              AppConstants.defaultDisplayName.substring(0, 1),
                              style: context.textTheme.labelLarge?.copyWith(
                                color: context.isDark
                                    ? colors.backgroundPrimary
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        )
                        .animate(delay: 100.ms)
                        .fadeIn(duration: AppMotion.slow)
                        .slideY(begin: 0.16, end: 0),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      greetingService.formattedDate(),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
        },
      ),
    );
  }
}
