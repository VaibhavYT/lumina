import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/features/mentor/presentation/providers/mentor_notifier.dart';
import 'package:lumina/features/mentor/presentation/widgets/mentor_widgets.dart';
import 'package:lumina/shared/widgets/shimmer_loader.dart';

class MentorScreen extends ConsumerWidget {
  const MentorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(mentorNotifierProvider);

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      body: asyncState.when(
        loading: () => const _MentorLoading(),
        error: (error, stackTrace) => Center(
          child: Text(
            'Mentor could not load.',
            style: context.textTheme.bodyLarge,
          ),
        ),
        data: (state) {
          final notifier = ref.read(mentorNotifierProvider.notifier);
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverSafeArea(
                bottom: false,
                sliver: SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.lg,
                    AppSpacing.pagePadding,
                    128,
                  ),
                  sliver: SliverList.list(
                    children: [
                      const MentorHeader(),
                      const SizedBox(height: AppSpacing.sectionGap),
                      DailyReflectionCard(insight: state.dailyReflection),
                      const SizedBox(height: AppSpacing.sectionGap),
                      CoachingCard(
                        mission: state.coachingMission,
                        onToggleDone: notifier.toggleCoachingDone,
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      WeeklyPlanSection(plan: state.weeklyPlan),
                      const SizedBox(height: AppSpacing.sectionGap),
                      InsightFeed(
                        insights: state.insightFeed,
                        onDismiss: notifier.dismiss,
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      AskMentorComposer(
                        isLoading: state.isAsking,
                        onSend: notifier.ask,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MentorLoading extends StatelessWidget {
  const _MentorLoading();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerLoader(width: 180, height: 72),
            SizedBox(height: AppSpacing.sectionGap),
            ShimmerLoader(height: 220),
            SizedBox(height: AppSpacing.md),
            ShimmerLoader(height: 180),
            SizedBox(height: AppSpacing.md),
            ShimmerLoader(height: 140),
          ],
        ),
      ),
    );
  }
}
