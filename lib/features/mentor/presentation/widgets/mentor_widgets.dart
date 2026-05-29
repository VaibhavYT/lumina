import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
              TextButton(onPressed: () {}, child: const Text('Go Deeper')),
            ],
          ),
        ],
      ),
    );
  }
}

class UntangleEntryCard extends StatelessWidget {
  const UntangleEntryCard({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onStart,
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.radiusXl),
          gradient: LinearGradient(
            colors: [
              colors.secondaryAccent.withValues(alpha: 0.55),
              colors.primaryAccent.withValues(alpha: 0.35),
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.backgroundCard,
            borderRadius: BorderRadius.circular(AppRadius.radiusXl - 1),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colors.secondaryAccentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.brain(PhosphorIconsStyle.fill),
                  color: colors.secondaryAccent,
                  size: 25,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Untangle', style: context.textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'A Socratic deep dive for thoughts that need space.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primaryAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                  color: context.isDark
                      ? colors.backgroundPrimary
                      : Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
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
                      "Today's Action:",
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
                          ? 'Done Today'
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
    if (widget.plan.isEmpty) {
      return LuminaCard(
        borderRadius: AppRadius.radiusXl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Week Ahead', style: context.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add a few daily logs to generate a real weekly plan.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

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

class MentorDateFilter extends StatelessWidget {
  const MentorDateFilter({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final dates = [
      for (var index = 13; index >= 0; index--)
        today.subtract(Duration(days: index)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Daily Feed',
                style: context.textTheme.headlineMedium,
              ),
            ),
            IconButton(
              tooltip: 'Choose date',
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: today,
                );
                if (picked != null) {
                  onDateSelected(DateUtils.dateOnly(picked));
                }
              },
              icon: Icon(PhosphorIcons.calendarBlank()),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final date = dates[index];
              final selected = DateUtils.isSameDay(date, selectedDate);
              return _DatePill(
                date: date,
                selected: selected,
                onTap: () => onDateSelected(date),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 58,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colors.primaryAccent : colors.backgroundCard,
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
          border: Border.all(
            color: selected ? colors.primaryAccent : colors.divider,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.primaryAccent.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('E').format(date),
              style: context.textTheme.labelSmall?.copyWith(
                color: selected
                    ? (context.isDark ? colors.backgroundPrimary : Colors.white)
                    : colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('d').format(date),
              style: context.textTheme.headlineMedium?.copyWith(
                color: selected
                    ? (context.isDark ? colors.backgroundPrimary : Colors.white)
                    : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InsightFeed extends StatelessWidget {
  const InsightFeed({
    super.key,
    required this.insights,
    required this.selectedDate,
    required this.isLoading,
    required this.onDismiss,
  });

  final List<MentorInsight> insights;
  final DateTime selectedDate;
  final bool isLoading;
  final ValueChanged<String> onDismiss;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateUtils.isSameDay(selectedDate, DateTime.now())
        ? 'Today'
        : DateFormat('EEE, d MMM').format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Insight Feed',
                style: context.textTheme.headlineMedium,
              ),
            ),
            LuminaTag(label: dateLabel),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (isLoading)
          const _FeedLoadingCard()
        else if (insights.isEmpty)
          LuminaCard(
            child: Text(
              'No mentor insights were created for $dateLabel yet.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          )
        else
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

class _FeedLoadingCard extends StatelessWidget {
  const _FeedLoadingCard();

  @override
  Widget build(BuildContext context) {
    return LuminaCard(
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colors.primaryAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Loading daily feed...',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
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
  const AskMentorComposer({super.key, required this.onSubmit});

  final ValueChanged<String> onSubmit;

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
            onTap: () {
              final value = _controller.text;
              widget.onSubmit(value);
              if (value.trim().isNotEmpty) {
                _controller.clear();
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.colors.primaryAccent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.check(PhosphorIconsStyle.bold),
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

class MentorChatSheet extends StatefulWidget {
  const MentorChatSheet({
    super.key,
    required this.initialQuestion,
    required this.repository,
  });

  final String initialQuestion;
  final MentorRepository repository;

  @override
  State<MentorChatSheet> createState() => _MentorChatSheetState();
}

class _MentorChatSheetState extends State<MentorChatSheet> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <MentorChatMessage>[];
  late final String _sessionId;
  var _isSending = false;

  @override
  void initState() {
    super.initState();
    _sessionId = 'chat-${DateTime.now().microsecondsSinceEpoch}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _send(widget.initialQuestion);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: AppMotion.fast,
      curve: AppMotion.standardCurve,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.backgroundPrimary,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.radiusXl),
            ),
            border: Border.all(color: context.colors.divider),
          ),
          child: Column(
            children: [
              _ChatHeader(onClose: () => Navigator.of(context).pop()),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: _messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isSending && index == _messages.length) {
                      return const _TypingBubble();
                    }
                    return _ChatBubble(message: _messages[index]);
                  },
                ),
              ),
              _ChatInput(
                controller: _inputController,
                isSending: _isSending,
                onSend: () => _send(_inputController.text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send(String raw) async {
    final question = raw.trim();
    if (question.isEmpty || _isSending) {
      return;
    }

    _inputController.clear();
    final previous = List<MentorChatMessage>.from(_messages);
    setState(() {
      _messages.add(
        MentorChatMessage(role: MentorChatRole.user, content: question),
      );
      _isSending = true;
    });
    _scrollToBottom();

    final answer = await widget.repository.sendChatMessage(
      question: question,
      sessionId: _sessionId,
      history: previous,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _messages.add(answer);
      _isSending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppMotion.standard,
        curve: AppMotion.enter,
      );
    });
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.colors.primaryAccentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
              color: context.colors.primaryAccent,
              size: 19,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lumina Chat', style: context.textTheme.headlineMedium),
                Text(
                  'Answers use your real logs, tasks, habits, and insights.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close chat',
            onPressed: onClose,
            icon: Icon(PhosphorIcons.x()),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final MentorChatMessage message;

  bool get _isUser => message.role == MentorChatRole.user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: _isUser ? colors.primaryAccent : colors.backgroundCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.radiusLg),
            topRight: const Radius.circular(AppRadius.radiusLg),
            bottomLeft: Radius.circular(
              _isUser ? AppRadius.radiusLg : AppRadius.radiusSm,
            ),
            bottomRight: Radius.circular(
              _isUser ? AppRadius.radiusSm : AppRadius.radiusLg,
            ),
          ),
          border: _isUser ? null : Border.all(color: colors.divider),
        ),
        child: Text(
          message.content,
          style: context.textTheme.bodyMedium?.copyWith(
            height: 1.45,
            color: _isUser
                ? (context.isDark ? colors.backgroundPrimary : Colors.white)
                : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.backgroundCard,
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
          border: Border.all(color: context.colors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colors.primaryAccent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Thinking',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          decoration: BoxDecoration(
            color: context.colors.backgroundCard,
            borderRadius: BorderRadius.circular(AppRadius.radiusXl),
            border: Border.all(color: context.colors.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  enabled: !isSending,
                  textInputAction: TextInputAction.newline,
                  style: context.textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: 'Message Lumina...',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: isSending ? null : onSend,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSending
                        ? context.colors.textTertiary
                        : context.colors.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill),
                    color: context.isDark
                        ? context.colors.backgroundPrimary
                        : Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
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
