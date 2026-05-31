import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_motion.dart';
import 'package:lumina/core/theme/app_radius.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/features/log/presentation/providers/today_log_notifier.dart';
import 'package:lumina/features/mentor/data/repositories/mentor_repository.dart';
import 'package:lumina/features/mentor/domain/mentor_input_policy.dart';
import 'package:lumina/features/mentor/presentation/providers/mentor_notifier.dart';
import 'package:lumina/shared/widgets/lumina_button.dart';
import 'package:lumina/shared/widgets/lumina_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UntangleScreen extends ConsumerStatefulWidget {
  const UntangleScreen({super.key});

  @override
  ConsumerState<UntangleScreen> createState() => _UntangleScreenState();
}

class _UntangleScreenState extends ConsumerState<UntangleScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <MentorChatMessage>[];
  late String _sessionId;
  String? _breakthrough;
  var _isSending = false;
  var _isSynthesizing = false;
  var _isSaving = false;
  var _saved = false;

  @override
  void initState() {
    super.initState();
    _sessionId = _newSessionId();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int get _userReplyCount =>
      _messages.where((message) => message.role == MentorChatRole.user).length;

  bool get _canCreateBreakthrough =>
      _userReplyCount >= 3 && !_isSending && !_isSynthesizing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Column(
        children: [
          _UntangleHeader(onClose: () => Navigator.of(context).pop()),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppMotion.standard,
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.exit,
              child: _breakthrough == null
                  ? _ConversationView(
                      key: const ValueKey('conversation'),
                      messages: _messages,
                      scrollController: _scrollController,
                      isSending: _isSending,
                      onStarterSelected: _useStarter,
                    )
                  : _BreakthroughView(
                      key: const ValueKey('breakthrough'),
                      breakthrough: _breakthrough!,
                      isSaving: _isSaving,
                      saved: _saved,
                      onSave: _saveBreakthrough,
                      onStartNew: _startNew,
                    ),
            ),
          ),
          if (_breakthrough == null)
            _UntangleFooter(
              controller: _inputController,
              isSending: _isSending,
              isSynthesizing: _isSynthesizing,
              canCreateBreakthrough: _canCreateBreakthrough,
              hasStarted: _messages.isNotEmpty,
              onSend: _sendReply,
              onCreateBreakthrough: _createBreakthrough,
            ),
        ],
      ),
    );
  }

  Future<void> _sendReply() async {
    final reply = _inputController.text.trim();
    if (reply.isEmpty || _isSending || _isSynthesizing) {
      return;
    }
    final error = MentorInputPolicy.validate(
      reply,
      maxWords: MentorInputPolicy.untangleReplyMaxWords,
    );
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    _inputController.clear();
    final previous = List<MentorChatMessage>.from(_messages);
    setState(() {
      _messages.add(
        MentorChatMessage(role: MentorChatRole.user, content: reply),
      );
      _isSending = true;
    });
    _scrollToBottom();

    final response = await ref
        .read(mentorRepositoryProvider)
        .sendUntangleReply(
          reply: reply,
          sessionId: _sessionId,
          history: previous,
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _messages.add(response);
      _isSending = false;
    });
    _scrollToBottom();
  }

  Future<void> _createBreakthrough() async {
    if (!_canCreateBreakthrough) {
      return;
    }
    setState(() => _isSynthesizing = true);
    final breakthrough = await ref
        .read(mentorRepositoryProvider)
        .synthesizeBreakthrough(sessionId: _sessionId, history: _messages);
    if (!mounted) {
      return;
    }
    setState(() {
      _breakthrough = breakthrough;
      _isSynthesizing = false;
    });
  }

  Future<void> _saveBreakthrough() async {
    final breakthrough = _breakthrough;
    if (breakthrough == null || _isSaving || _saved) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref
          .read(mentorRepositoryProvider)
          .saveBreakthroughToJournal(breakthrough);
      ref.invalidate(todayLogNotifierProvider);
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _saved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Breakthrough saved to journal.')),
      );
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save breakthrough.')),
      );
    }
  }

  void _startNew() {
    setState(() {
      _sessionId = _newSessionId();
      _messages.clear();
      _breakthrough = null;
      _saved = false;
      _isSending = false;
      _isSynthesizing = false;
    });
  }

  void _useStarter(String value) {
    _inputController.text = value;
    _inputController.selection = TextSelection.collapsed(
      offset: _inputController.text.length,
    );
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

  String _newSessionId() {
    return 'untangle-${DateTime.now().microsecondsSinceEpoch}';
  }
}

class _UntangleHeader extends StatelessWidget {
  const _UntangleHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Close Untangle',
              onPressed: onClose,
              icon: Icon(PhosphorIcons.x()),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.secondaryAccentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.brain(PhosphorIconsStyle.fill),
                color: colors.secondaryAccent,
                size: 21,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Untangle', style: context.textTheme.titleLarge),
                  Text(
                    'One honest question at a time',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
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

class _ConversationView extends StatelessWidget {
  const _ConversationView({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.isSending,
    required this.onStarterSelected,
  });

  final List<MentorChatMessage> messages;
  final ScrollController scrollController;
  final bool isSending;
  final ValueChanged<String> onStarterSelected;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty && !isSending) {
      return _OpeningPane(onStarterSelected: onStarterSelected);
    }

    return ListView.builder(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        AppSpacing.lg,
      ),
      itemCount: messages.length + (isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (isSending && index == messages.length) {
          return const _QuestionLoadingCard();
        }
        return _UntangleMessageBubble(message: messages[index]);
      },
    );
  }
}

class _OpeningPane extends StatefulWidget {
  const _OpeningPane({required this.onStarterSelected});

  final ValueChanged<String> onStarterSelected;

  @override
  State<_OpeningPane> createState() => _OpeningPaneState();
}

class _OpeningPaneState extends State<_OpeningPane>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              width: 168,
              height: 168,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ThreadOrbPainter(
                      progress: _controller.value,
                      amber: colors.primaryAccent,
                      indigo: colors.secondaryAccent,
                      divider: colors.divider,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Name the knot.', style: context.textTheme.displayMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start messy. Lumina will answer with only the next question.',
            style: context.textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _StarterChip(
                label: 'A meeting I keep replaying',
                onSelected: widget.onStarterSelected,
              ),
              _StarterChip(
                label: 'A decision I cannot settle',
                onSelected: widget.onStarterSelected,
              ),
              _StarterChip(
                label: 'A feeling I keep avoiding',
                onSelected: widget.onStarterSelected,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarterChip extends StatelessWidget {
  const _StarterChip({required this.label, required this.onSelected});

  final String label;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => onSelected(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: colors.backgroundCard,
          borderRadius: BorderRadius.circular(AppRadius.radiusFull),
          border: Border.all(color: colors.divider),
        ),
        child: Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _UntangleMessageBubble extends StatelessWidget {
  const _UntangleMessageBubble({required this.message});

  final MentorChatMessage message;

  bool get _isUser => message.role == MentorChatRole.user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final maxWidth = MediaQuery.sizeOf(context).width * (_isUser ? 0.80 : 0.88);

    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
          style:
              (_isUser
                      ? context.textTheme.bodyMedium
                      : context.textTheme.titleLarge)
                  ?.copyWith(
                    height: _isUser ? 1.45 : 1.35,
                    color: _isUser
                        ? (context.isDark
                              ? colors.backgroundPrimary
                              : Colors.white)
                        : colors.textPrimary,
                  ),
        ),
      ),
    );
  }
}

class _QuestionLoadingCard extends StatelessWidget {
  const _QuestionLoadingCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: colors.backgroundCard,
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.secondaryAccent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Finding the next question',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UntangleFooter extends StatelessWidget {
  const _UntangleFooter({
    required this.controller,
    required this.isSending,
    required this.isSynthesizing,
    required this.canCreateBreakthrough,
    required this.hasStarted,
    required this.onSend,
    required this.onCreateBreakthrough,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool isSynthesizing;
  final bool canCreateBreakthrough;
  final bool hasStarted;
  final VoidCallback onSend;
  final VoidCallback onCreateBreakthrough;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 12 + bottomInset),
      decoration: BoxDecoration(
        color: colors.backgroundPrimary.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasStarted)
            AnimatedSwitcher(
              duration: AppMotion.fast,
              child: canCreateBreakthrough || isSynthesizing
                  ? Padding(
                      key: const ValueKey('breakthrough-action'),
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: LuminaButton(
                        label: 'Create Breakthrough',
                        icon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                        isLoading: isSynthesizing,
                        onPressed: canCreateBreakthrough
                            ? onCreateBreakthrough
                            : null,
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-action')),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 4),
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              borderRadius: BorderRadius.circular(AppRadius.radiusXl),
              border: Border.all(color: colors.divider),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 5,
                        enabled: !isSending && !isSynthesizing,
                        inputFormatters: const [
                          MentorWordLimitFormatter(
                            MentorInputPolicy.untangleReplyMaxWords,
                          ),
                        ],
                        textInputAction: TextInputAction.newline,
                        style: context.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: hasStarted
                              ? 'Answer the question...'
                              : 'What feels tangled right now?',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: isSending || isSynthesizing ? null : onSend,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSending || isSynthesizing
                              ? colors.textTertiary
                              : colors.primaryAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill),
                          color: context.isDark
                              ? colors.backgroundPrimary
                              : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${MentorInputPolicy.wordCount(value.text)}/${MentorInputPolicy.untangleReplyMaxWords} words',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakthroughView extends StatelessWidget {
  const _BreakthroughView({
    super.key,
    required this.breakthrough,
    required this.isSaving,
    required this.saved,
    required this.onSave,
    required this.onStartNew,
  });

  final String breakthrough;
  final bool isSaving;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onStartNew;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BreakthroughCard(breakthrough: breakthrough),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: LuminaButton(
                  label: saved ? 'Saved to Journal' : 'Save to Journal',
                  icon: PhosphorIcons.check(PhosphorIconsStyle.bold),
                  isLoading: isSaving,
                  onPressed: saved ? null : onSave,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 58,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                    border: Border.all(color: colors.divider),
                  ),
                  child: IconButton(
                    tooltip: 'Start new Untangle',
                    onPressed: onStartNew,
                    icon: Icon(
                      PhosphorIcons.pencilLine(),
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakthroughCard extends StatelessWidget {
  const _BreakthroughCard({required this.breakthrough});

  final String breakthrough;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryAccent.withValues(alpha: 0.65),
            colors.secondaryAccent.withValues(alpha: 0.45),
            colors.successColor.withValues(alpha: 0.35),
          ],
        ),
      ),
      child: LuminaCard(
        borderRadius: AppRadius.radiusXl - 1,
        backgroundColor: colors.backgroundElevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryAccentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                    color: colors.primaryAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Breakthrough',
                        style: context.textTheme.headlineMedium,
                      ),
                      Text(
                        DateFormat('d MMM, h:mm a').format(DateTime.now()),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              breakthrough,
              style: context.textTheme.bodyLarge?.copyWith(height: 1.65),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadOrbPainter extends CustomPainter {
  const _ThreadOrbPainter({
    required this.progress,
    required this.amber,
    required this.indigo,
    required this.divider,
  });

  final double progress;
  final Color amber;
  final Color indigo;
  final Color divider;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final base = Paint()
      ..shader = RadialGradient(
        colors: [
          amber.withValues(alpha: 0.32),
          indigo.withValues(alpha: 0.18),
          divider.withValues(alpha: 0.05),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(center, radius * 0.84, base);

    final threadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < 5; index++) {
      final phase = progress * math.pi * 2 + index * math.pi / 2.5;
      final path = Path();
      for (var step = 0; step <= 80; step++) {
        final t = step / 80;
        final angle = phase + t * math.pi * 2;
        final wave = math.sin(angle * 2 + index) * 10;
        final x = center.dx + math.cos(angle) * (radius * 0.48 + wave);
        final y = center.dy + math.sin(angle * 1.4) * (radius * 0.36 + wave);
        if (step == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      threadPaint.color = Color.lerp(
        amber,
        indigo,
        index / 4,
      )!.withValues(alpha: 0.35);
      canvas.drawPath(path, threadPaint);
    }

    canvas.drawCircle(
      center,
      radius * 0.16,
      Paint()..color = amber.withValues(alpha: 0.72),
    );
  }

  @override
  bool shouldRepaint(covariant _ThreadOrbPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.amber != amber ||
        oldDelegate.indigo != indigo ||
        oldDelegate.divider != divider;
  }
}
