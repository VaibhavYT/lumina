import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lumina/core/data/lumina_models.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_motion.dart';
import 'package:lumina/core/theme/app_radius.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/features/mentor/data/repositories/mentor_repository.dart';
import 'package:lumina/shared/widgets/lumina_button.dart';
import 'package:lumina/shared/widgets/lumina_card.dart';
import 'package:lumina/shared/widgets/lumina_tag.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MentorHeader extends StatefulWidget {
  const MentorHeader({super.key});

  @override
  State<MentorHeader> createState() => _MentorHeaderState();
}

class _MentorHeaderState extends State<MentorHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RotationTransition(
              turns: _controller,
              child: CustomPaint(
                painter: _MandalaPainter(
                  amber: colors.primaryAccent,
                  indigo: colors.secondaryAccent,
                ),
                child: const SizedBox(width: 72, height: 72),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lumina', style: context.textTheme.headlineLarge),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _PulseDot(color: colors.successColor),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Your AI Growth Mentor',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              LuminaTag(
                label: 'Energy',
                textColor: colors.primaryAccent,
                color: colors.primaryAccentSoft,
              ),
              const SizedBox(width: AppSpacing.sm),
              LuminaTag(label: 'Focus'),
              const SizedBox(width: AppSpacing.sm),
              LuminaTag(
                label: 'Sleep',
                textColor: colors.successColor,
                color: colors.successSoft,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MandalaPainter extends CustomPainter {
  const _MandalaPainter({required this.amber, required this.indigo});

  final Color amber;
  final Color indigo;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final basePaint = Paint()
      ..shader = RadialGradient(
        colors: [amber, indigo],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(center, radius, basePaint);
    final petalPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 6; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * math.pi / 3);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -radius * 0.24),
          width: 18,
          height: 42,
        ),
        petalPaint,
      );
      canvas.restore();
    }
    canvas.drawCircle(
      center,
      10,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _MandalaPainter oldDelegate) {
    return amber != oldDelegate.amber || indigo != oldDelegate.indigo;
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 1 - value),
                blurRadius: 12,
              ),
            ],
          ),
        );
      },
    );
  }
}

class DailyReflectionCard extends StatelessWidget {
  const DailyReflectionCard({super.key, required this.insight});

  final MentorInsight insight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Reflection",
            style: context.textTheme.labelSmall?.copyWith(
              color: colors.primaryAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TypewriterText(text: insight.body),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('Save to Journal'),
              ),
              TextButton(onPressed: () {}, child: const Text('Go Deeper ->')),
            ],
          ),
        ],
      ),
    );
  }
}

class TypewriterText extends StatefulWidget {
  const TypewriterText({super.key, required this.text});

  final String text;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  var _visible = 0;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  Future<void> _tick() async {
    while (mounted && _visible < widget.text.length) {
      await Future<void>.delayed(const Duration(milliseconds: 18));
      if (mounted) {
        setState(() => _visible++);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text.substring(0, _visible.clamp(0, widget.text.length)),
      style: context.textTheme.bodyLarge?.copyWith(height: 1.55),
    );
  }
}

class CoachingCard extends StatelessWidget {
  const CoachingCard({
    super.key,
    required this.mission,
    required this.onToggleDone,
  });

  final CoachingMission mission;
  final VoidCallback onToggleDone;

  @override
  Widget build(BuildContext context) {
    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: context.colors.primaryAccent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.radiusXl),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Current Focus',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.colors.primaryAccent,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Day ${mission.dayIndex + 1}/7',
                          style: context.textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      mission.title,
                      style: context.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      mission.reason,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Today’s Action:',
                      style: context.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mission.todayAction,
                      style: context.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LuminaButton(
                      label: mission.doneToday
                          ? 'Done Today ✓'
                          : 'Done for Today',
                      outlined: mission.doneToday,
                      onPressed: onToggleDone,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeeklyPlanSection extends StatefulWidget {
  const WeeklyPlanSection({super.key, required this.plan});

  final List<WeeklyPlanDay> plan;

  @override
  State<WeeklyPlanSection> createState() => _WeeklyPlanSectionState();
}

class _WeeklyPlanSectionState extends State<WeeklyPlanSection> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Week Ahead',
                      style: context.textTheme.headlineMedium,
                    ),
                    Text(
                      'Tap to see your personalized weekly plan',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                duration: AppMotion.fast,
                turns: _expanded ? 0.5 : 0,
                child: Icon(
                  PhosphorIcons.caretDown(),
                  color: context.colors.textTertiary,
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: AppMotion.standard,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                for (final item in widget.plan)
                  _PlanRow(item: item, isToday: item.day == _todayName()),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }

  String _todayName() {
    return const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][DateTime.now().weekday - 1];
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.item, required this.isToday});

  final WeeklyPlanDay item;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isToday
                ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                : PhosphorIcons.circle(),
            color: isToday
                ? context.colors.primaryAccent
                : context.colors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 72,
            child: Text(item.day, style: context.textTheme.labelLarge),
          ),
          Expanded(
            child: Text(
              '${item.theme}: ${item.action}',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InsightFeed extends StatelessWidget {
  const InsightFeed({
    super.key,
    required this.insights,
    required this.onDismiss,
  });

  final List<MentorInsight> insights;
  final ValueChanged<String> onDismiss;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Insight Feed', style: context.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        for (final insight in insights)
          Dismissible(
            key: ValueKey(insight.id),
            direction: DismissDirection.startToEnd,
            onDismissed: (_) => onDismiss(insight.id),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _InsightCard(insight: insight, onDismiss: onDismiss),
            ),
          ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, required this.onDismiss});

  final MentorInsight insight;
  final ValueChanged<String> onDismiss;

  bool get _isBurnoutWarning => insight.insightType == 'burnout_warning';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _isBurnoutWarning ? colors.errorColor : colors.primaryAccent;
    final immediateAction = insight.metadata['immediateAction'] as String?;

    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.radiusXl),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isBurnoutWarning) ...[
                          _PulseDot(color: colors.errorColor),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        LuminaTag(
                          label: _isBurnoutWarning
                              ? 'Mentor Insight'
                              : _tagFor(insight),
                          color: _isBurnoutWarning
                              ? colors.errorSoft
                              : colors.primaryAccentSoft,
                          textColor: accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(insight.headline, style: context.textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text(
                      insight.body,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    if (_isBurnoutWarning && immediateAction != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.primaryAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppRadius.radiusMd,
                          ),
                        ),
                        child: Text(
                          immediateAction,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LuminaButton(
                        label: 'Done - feeling better',
                        outlined: true,
                        onPressed: () => onDismiss(insight.id),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tagFor(MentorInsight insight) {
    if (insight.insightType == 'weekly_debrief') {
      return 'Weekly Debrief';
    }
    if (insight.insightType == 'morning_brief') {
      return 'Morning Brief';
    }
    if (insight.insightType == 'goal_created') {
      return 'Goal';
    }
    final lower = insight.headline.toLowerCase();
    if (lower.contains('strength')) {
      return 'Strength';
    }
    if (lower.contains('challenge')) {
      return 'Challenge';
    }
    return 'Pattern';
  }
}

class AskMentorComposer extends StatefulWidget {
  const AskMentorComposer({
    super.key,
    required this.isLoading,
    required this.onSend,
  });

  final bool isLoading;
  final ValueChanged<String> onSend;

  @override
  State<AskMentorComposer> createState() => _AskMentorComposerState();
}

class _AskMentorComposerState extends State<AskMentorComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: context.colors.backgroundCard,
        borderRadius: BorderRadius.circular(AppRadius.radiusXl),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: context.colors.primaryAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              style: context.textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Ask your mentor anything...',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.isLoading
                ? null
                : () {
                    widget.onSend(_controller.text);
                    _controller.clear();
                  },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.colors.primaryAccent,
                shape: BoxShape.circle,
              ),
              child: widget.isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.isDark
                            ? context.colors.backgroundPrimary
                            : Colors.white,
                      ),
                    )
                  : Icon(
                      PhosphorIcons.arrowUpRight(PhosphorIconsStyle.bold),
                      color: context.isDark
                          ? context.colors.backgroundPrimary
                          : Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientCard extends StatelessWidget {
  const _GradientCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.radiusXl),
        gradient: LinearGradient(
          colors: [
            context.colors.primaryAccent.withValues(alpha: 0.45),
            context.colors.secondaryAccent.withValues(alpha: 0.25),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.colors.backgroundCard,
          borderRadius: BorderRadius.circular(AppRadius.radiusXl - 1),
        ),
        child: child,
      ),
    );
  }
}
