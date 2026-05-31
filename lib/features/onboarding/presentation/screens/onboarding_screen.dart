import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_motion.dart';
import 'package:lumina/core/theme/app_radius.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/features/onboarding/data/onboarding_repository.dart';
import 'package:lumina/shared/widgets/lumina_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  late final AnimationController _motion;
  var _page = 0;
  var _finishing = false;

  static const _pageCount = 4;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _motion.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < _pageCount - 1) {
      await _pageController.nextPage(
        duration: AppMotion.standard,
        curve: Curves.easeOutCubic,
      );
      return;
    }
    setState(() => _finishing = true);
    await const OnboardingRepository().complete();
    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _skip() async {
    await const OnboardingRepository().complete();
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.md,
                AppSpacing.pagePadding,
                0,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                    child: Image.asset(
                      'assets/images/lumina_app_icon.png',
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Lumina', style: context.textTheme.headlineMedium),
                  const Spacer(),
                  if (_page < _pageCount - 1)
                    TextButton(
                      onPressed: _skip,
                      child: Text(
                        'Skip',
                        style: context.textTheme.labelLarge?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _WelcomePage(motion: _motion),
                  const _RhythmPage(),
                  _AgentsPage(motion: _motion),
                  const _MentorPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.md,
                AppSpacing.pagePadding,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pageCount,
                      (index) => AnimatedContainer(
                        duration: AppMotion.fast,
                        width: index == _page ? 24 : 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: index == _page
                              ? colors.primaryAccent
                              : colors.divider,
                          borderRadius: BorderRadius.circular(
                            AppRadius.radiusFull,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LuminaButton(
                    label: _page == _pageCount - 1
                        ? 'Begin with Lumina'
                        : 'Continue',
                    icon: _page == _pageCount - 1
                        ? PhosphorIcons.sparkle(PhosphorIconsStyle.fill)
                        : PhosphorIcons.arrowRight(),
                    isLoading: _finishing,
                    onPressed: _finishing ? null : _next,
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

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.motion});

  final Animation<double> motion;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return _OnboardingPageFrame(
      eyebrow: 'A quieter way to grow',
      title: 'Start with what is real today.',
      body:
          'Lumina notices your mood, energy, habits, tasks, and reflections so progress can feel personal instead of performative.',
      visual: AnimatedBuilder(
        animation: motion,
        builder: (context, child) {
          final pulse = 1 + math.sin(motion.value * math.pi * 2) * 0.025;
          return SizedBox(
            width: 250,
            height: 250,
            child: CustomPaint(
              painter: _ConstellationPainter(
                progress: motion.value,
                amber: colors.primaryAccent,
                indigo: colors.secondaryAccent,
                quiet: colors.divider,
              ),
              child: Center(
                child: Transform.scale(
                  scale: pulse,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(44),
                    child: Image.asset(
                      'assets/images/lumina_app_icon.png',
                      width: 148,
                      height: 148,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RhythmPage extends StatelessWidget {
  const _RhythmPage();

  @override
  Widget build(BuildContext context) {
    return _OnboardingPageFrame(
      eyebrow: 'Your daily rhythm',
      title: 'A small check-in becomes a useful map.',
      body:
          'Log what matters in a minute. Lumina turns the pattern into grounded guidance you can revisit.',
      visual: const _RhythmVisual(),
    );
  }
}

class _AgentsPage extends StatelessWidget {
  const _AgentsPage({required this.motion});

  final Animation<double> motion;

  @override
  Widget build(BuildContext context) {
    return _OnboardingPageFrame(
      eyebrow: 'Your agent studio',
      title: 'A small crew keeps watch with you.',
      body:
          'Each helper has a job and a visible note. Open Agents anytime to see what ran, what it noticed, and what is listening next.',
      visual: AnimatedBuilder(
        animation: motion,
        builder: (context, child) => _AgentCrewVisual(progress: motion.value),
      ),
    );
  }
}

class _MentorPage extends StatelessWidget {
  const _MentorPage();

  @override
  Widget build(BuildContext context) {
    return _OnboardingPageFrame(
      eyebrow: 'Focused guidance',
      title: 'Ask for perspective. Untangle the harder thoughts.',
      body:
          'Your mentor stays with your goals, habits, mood, tasks, and reflections. When a thought needs room, Untangle asks one careful question at a time.',
      visual: const _MentorVisual(),
    );
  }
}

class _OnboardingPageFrame extends StatelessWidget {
  const _OnboardingPageFrame({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.visual,
  });

  final String eyebrow;
  final String title;
  final String body;
  final Widget visual;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.lg,
        AppSpacing.pagePadding,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: visual),
          const SizedBox(height: AppSpacing.xl),
          Text(
            eyebrow.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: colors.primaryAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: context.textTheme.displayMedium),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            style: context.textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _RhythmVisual extends StatelessWidget {
  const _RhythmVisual();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = [
      (
        icon: PhosphorIcons.smiley(PhosphorIconsStyle.duotone),
        label: 'Mood',
        value: 'Name it',
        tone: colors.primaryAccent,
      ),
      (
        icon: PhosphorIcons.lightning(PhosphorIconsStyle.duotone),
        label: 'Energy',
        value: 'Notice it',
        tone: colors.secondaryAccent,
      ),
      (
        icon: PhosphorIcons.target(PhosphorIconsStyle.duotone),
        label: 'Goals',
        value: 'Move gently',
        tone: colors.successColor,
      ),
    ];

    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 216,
            height: 216,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.divider),
            ),
          ),
          for (final (index, item) in items.indexed)
            Positioned(
              top: index == 0 ? 0 : index == 1 ? 138 : 122,
              left: index == 0 ? 75 : index == 1 ? 4 : null,
              right: index == 2 ? 0 : null,
              child: _RhythmNote(
                icon: item.icon,
                label: item.label,
                value: item.value,
                tone: item.tone,
              ),
            ),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              shape: BoxShape.circle,
              border: Border.all(color: colors.primaryAccent.withValues(alpha: 0.4)),
            ),
            child: Icon(
              PhosphorIcons.sparkle(PhosphorIconsStyle.duotone),
              color: colors.primaryAccent,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}

class _RhythmNote extends StatelessWidget {
  const _RhythmNote({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 114,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: tone.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: tone, size: 19),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.textTheme.labelSmall),
                Text(
                  value,
                  style: context.textTheme.bodySmall?.copyWith(color: tone),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentCrewVisual extends StatelessWidget {
  const _AgentCrewVisual({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final agents = [
      (
        'Morning',
        PhosphorIcons.sunHorizon(PhosphorIconsStyle.duotone),
        colors.primaryAccent,
      ),
      (
        'Care',
        PhosphorIcons.shieldCheck(PhosphorIconsStyle.duotone),
        colors.errorColor,
      ),
      (
        'Patterns',
        PhosphorIcons.sparkle(PhosphorIconsStyle.duotone),
        colors.secondaryAccent,
      ),
      (
        'Goals',
        PhosphorIcons.mapTrifold(PhosphorIconsStyle.duotone),
        colors.successColor,
      ),
      (
        'Reflect',
        PhosphorIcons.notebook(PhosphorIconsStyle.duotone),
        colors.secondaryAccent,
      ),
    ];

    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(286, 216),
            painter: _CrewLinesPainter(
              progress: progress,
              tone: colors.primaryAccent,
            ),
          ),
          for (final (index, agent) in agents.indexed)
            Positioned(
              left: _crewOffsets[index].dx,
              top: _crewOffsets[index].dy,
              child: Transform.translate(
                offset: Offset(
                  0,
                  -math.sin((progress + index * 0.14) * math.pi * 2) * 5,
                ),
                child: _MiniAgent(
                  label: agent.$1,
                  icon: agent.$2,
                  tone: agent.$3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

const _crewOffsets = [
  Offset(98, 0),
  Offset(8, 64),
  Offset(188, 68),
  Offset(48, 164),
  Offset(150, 166),
];

class _MiniAgent extends StatelessWidget {
  const _MiniAgent({
    required this.label,
    required this.icon,
    required this.tone,
  });

  final String label;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: 88,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tone.withValues(alpha: 0.42)),
              boxShadow: [
                BoxShadow(
                  color: tone.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(child: Icon(icon, color: tone, size: 26)),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors.successColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.backgroundCard),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: context.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _MentorVisual extends StatelessWidget {
  const _MentorVisual();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 10,
            left: 4,
            right: 54,
            child: _ConversationNote(
              icon: PhosphorIcons.chatCircleDots(PhosphorIconsStyle.duotone),
              text: 'What is making this feel heavy today?',
              tone: colors.primaryAccent,
            ),
          ),
          Positioned(
            top: 104,
            left: 54,
            right: 4,
            child: _ConversationNote(
              icon: PhosphorIcons.mapTrifold(PhosphorIconsStyle.duotone),
              text: 'Untangle follows one careful question at a time.',
              tone: colors.secondaryAccent,
            ),
          ),
          Positioned(
            bottom: 4,
            left: 20,
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.lockKey(PhosphorIconsStyle.duotone),
                  color: colors.successColor,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Personal growth questions stay in focus.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationNote extends StatelessWidget {
  const _ConversationNote({
    required this.icon,
    required this.text,
    required this.tone,
  });

  final IconData icon;
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        border: Border.all(color: tone.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Icon(icon, color: tone, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  const _ConstellationPainter({
    required this.progress,
    required this.amber,
    required this.indigo,
    required this.quiet,
  });

  final double progress;
  final Color amber;
  final Color indigo;
  final Color quiet;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final orbit = Paint()
      ..color = quiet
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, size.width * 0.43, orbit);
    canvas.drawCircle(center, size.width * 0.34, orbit);

    for (var index = 0; index < 5; index++) {
      final angle = (progress * 0.35 + index / 5) * math.pi * 2;
      final radius = index.isEven ? size.width * 0.43 : size.width * 0.34;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final color = index == 2 ? indigo : amber;
      canvas.drawCircle(point, index == 2 ? 3 : 4, Paint()..color = color);
      canvas.drawCircle(
        point,
        8,
        Paint()..color = color.withValues(alpha: 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        amber != oldDelegate.amber ||
        indigo != oldDelegate.indigo ||
        quiet != oldDelegate.quiet;
  }
}

class _CrewLinesPainter extends CustomPainter {
  const _CrewLinesPainter({required this.progress, required this.tone});

  final double progress;
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tone.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final center = size.center(Offset.zero);
    for (final point in const [
      Offset(142, 30),
      Offset(52, 92),
      Offset(232, 96),
      Offset(92, 190),
      Offset(194, 192),
    ]) {
      canvas.drawLine(center, point, paint);
    }
    canvas.drawCircle(
      center,
      9 + math.sin(progress * math.pi * 2) * 2,
      Paint()..color = tone.withValues(alpha: 0.16),
    );
    canvas.drawCircle(center, 3, Paint()..color = tone);
  }

  @override
  bool shouldRepaint(covariant _CrewLinesPainter oldDelegate) {
    return progress != oldDelegate.progress || tone != oldDelegate.tone;
  }
}
