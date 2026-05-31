import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_motion.dart';
import 'package:lumina/core/theme/app_radius.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/features/agents/data/repositories/agents_repository.dart';
import 'package:lumina/features/agents/presentation/providers/agents_notifier.dart';
import 'package:lumina/shared/widgets/lumina_card.dart';
import 'package:lumina/shared/widgets/shimmer_loader.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AgentsScreen extends ConsumerWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(agentsNotifierProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: asyncState.when(
        loading: () => const _AgentsLoading(),
        error: (error, stackTrace) => _AgentsError(
          onRetry: () => ref.read(agentsNotifierProvider.notifier).refresh(),
        ),
        data: (state) => RefreshIndicator(
          color: colors.primaryAccent,
          backgroundColor: colors.backgroundElevated,
          onRefresh: () => ref.read(agentsNotifierProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
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
                      _AgentsHeader(state: state),
                      const SizedBox(height: AppSpacing.sectionGap),
                      _CrewStudioPanel(state: state),
                      const SizedBox(height: AppSpacing.md),
                      _LiveOperationsPanel(state: state),
                      const SizedBox(height: AppSpacing.sectionGap),
                      Text(
                        'Meet the crew',
                        style: context.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (var index = 0; index < state.agents.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _AgentCard(agent: state.agents[index])
                              .animate(delay: (60 * index).ms)
                              .fadeIn(duration: AppMotion.slow)
                              .slideY(begin: 0.08, end: 0),
                        ),
                    ],
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

class _AgentsHeader extends StatelessWidget {
  const _AgentsHeader({required this.state});

  final AgentsState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final synced = DateFormat('h:mm a').format(state.lastSyncedAt.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Agents', style: context.textTheme.displayMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'A small crew keeping watch over the patterns you care about.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _SignalPill(
              icon: Icons.sync,
              label: 'Synced $synced',
              color: colors.primaryAccent,
            ),
            _SignalPill(
              icon: Icons.bolt,
              label: '${state.signalCount} notes and signals',
              color: colors.secondaryAccent,
            ),
            if (state.activeGoalTitle != null)
              _SignalPill(
                icon: Icons.flag_outlined,
                label: state.activeGoalTitle!,
                color: colors.successColor,
              ),
          ],
        ),
      ],
    );
  }
}

class _CrewStudioPanel extends StatefulWidget {
  const _CrewStudioPanel({required this.state});

  final AgentsState state;

  @override
  State<_CrewStudioPanel> createState() => _CrewStudioPanelState();
}

class _CrewStudioPanelState extends State<_CrewStudioPanel> {
  var _selectedIndex = 0;

  LuminaAgent get _selectedAgent {
    return widget.state.agents[_selectedIndex.clamp(
      0,
      widget.state.agents.length - 1,
    )];
  }

  @override
  void didUpdateWidget(covariant _CrewStudioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= widget.state.agents.length) {
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final agent = _selectedAgent;
    final notes = widget.state.agents
        .where((item) => item.latestResult != null)
        .length;

    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      backgroundColor: colors.backgroundElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lumina studio', style: context.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$notes fresh notes waiting for you',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: agent.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.state.agents.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = widget.state.agents[index];
                return _CrewMateButton(
                  agent: item,
                  selected: index == _selectedIndex,
                  onTap: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: AppMotion.standard,
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.exit,
            child: _AgentNotePreview(
              key: ValueKey('${agent.id}-${agent.latestResult?.createdAt}'),
              agent: agent,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrewMateButton extends StatelessWidget {
  const _CrewMateButton({
    required this.agent,
    required this.selected,
    required this.onTap,
  });

  final LuminaAgent agent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standardCurve,
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? colors.primaryAccentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
          border: Border.all(
            color: selected ? colors.primaryAccent : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AgentSprite(agent: agent, size: 56, selected: selected),
            const SizedBox(height: AppSpacing.xs),
            Text(
              agent.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(
                color: selected
                    ? colors.primaryAccent
                    : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentNotePreview extends StatelessWidget {
  const _AgentNotePreview({super.key, required this.agent});

  final LuminaAgent agent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final result = agent.latestResult;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: result == null
          ? Column(
              key: const ValueKey('quiet'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${agent.name} is listening quietly.',
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  agent.nextRunLabel,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            )
          : Column(
              key: const ValueKey('note'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.notePencil(PhosphorIconsStyle.fill),
                      color: colors.primaryAccent,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        result.label,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.primaryAccent,
                        ),
                      ),
                    ),
                    Text(
                      _relativeTime(result.createdAt),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  result.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  result.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
    );
  }
}

class _LiveOperationsPanel extends StatelessWidget {
  const _LiveOperationsPanel({required this.state});

  final AgentsState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final next = state.nextScheduledAgent;

    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      backgroundColor: colors.backgroundElevated,
      child: Row(
        children: [
          _RadarPulse(
            color: colors.primaryAccent,
            secondaryColor: colors.secondaryAccent,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Studio pulse',
                  style: context.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${state.recentlyActiveCount} helpers checked in recently. The studio listens for your logs, goals, and questions.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (next != null)
                  _OperationLine(
                    icon: Icons.schedule,
                    label: 'Next',
                    value: '${next.name} - ${_formatNextRun(next.nextRunAt!)}',
                  )
                else
                  const _OperationLine(
                    icon: Icons.sensors,
                    label: 'Next',
                    value: 'Waiting for a user signal',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentCard extends StatefulWidget {
  const _AgentCard({required this.agent});

  final LuminaAgent agent;

  @override
  State<_AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends State<_AgentCard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final agent = widget.agent;
    final tone = _statusColor(context, agent.status);

    return LuminaCard(
      borderRadius: AppRadius.radiusXl,
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AgentSprite(agent: agent, size: 58),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            agent.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'About ${agent.name}',
                          onPressed: () => _showAgentInfo(
                            context,
                            agent,
                          ),
                          icon: Icon(
                            PhosphorIcons.info(),
                            size: 20,
                          ),
                          color: colors.textSecondary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      agent.role,
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
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _StatusChip(status: agent.status),
              _FunctionChip(
                label: agent.latestResult == null
                    ? 'Quiet for now'
                    : '${agent.resultCount} ${agent.resultCount == 1 ? 'note' : 'notes'}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            agent.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _OperationLine(
            icon: PhosphorIcons.clockCounterClockwise(),
            label: 'Last run',
            value: _relativeTime(agent.lastRunAt),
          ),
          const SizedBox(height: AppSpacing.sm),
          _OperationLine(
            icon: PhosphorIcons.waveform(),
            label: 'Next',
            value: agent.nextRunAt == null
                ? agent.nextRunLabel
                : '${agent.nextRunLabel} - ${_formatNextRun(agent.nextRunAt!)}',
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                agent.latestResult == null
                    ? PhosphorIcons.ear()
                    : PhosphorIcons.notePencil(),
                color: tone,
                size: 17,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  agent.latestResult == null
                      ? 'Listening for a useful signal'
                      : '${agent.resultCount} ${agent.resultCount == 1 ? 'note' : 'notes'} ready',
                  style: context.textTheme.labelSmall?.copyWith(color: tone),
                ),
              ),
              AnimatedRotation(
                duration: AppMotion.fast,
                turns: _expanded ? 0.5 : 0,
                child: Icon(
                  PhosphorIcons.caretDown(),
                  color: colors.textTertiary,
                  size: 18,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: AppMotion.standard,
            curve: AppMotion.standardCurve,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: _AgentResultReveal(agent: agent),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _AgentResultReveal extends StatelessWidget {
  const _AgentResultReveal({required this.agent});

  final LuminaAgent agent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final result = agent.latestResult;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: result == null
          ? Text(
              '${agent.name} has not left a note yet. ${agent.nextRunLabel}.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      result.label,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.primaryAccent,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _relativeTime(result.createdAt),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(result.headline, style: context.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  result.body,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
    );
  }
}

class _AgentSprite extends StatefulWidget {
  const _AgentSprite({
    required this.agent,
    required this.size,
    this.selected = false,
  });

  final LuminaAgent agent;
  final double size;
  final bool selected;

  @override
  State<_AgentSprite> createState() => _AgentSpriteState();
}

class _AgentSpriteState extends State<_AgentSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2100 + widget.agent.id.length * 90),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = _agentTone(context, widget.agent.id);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final lift = math.sin(_controller.value * math.pi) * 3.2;
          final blink = _controller.value > 0.94 ? 0.28 : 1.0;
          return Transform.translate(
            offset: Offset(0, -lift),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(
                          widget.size * 0.36,
                        ),
                        border: Border.all(
                          color: tone.withValues(
                            alpha: widget.selected ? 0.92 : 0.34,
                          ),
                          width: widget.selected ? 1.6 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: tone.withValues(
                              alpha: widget.selected ? 0.20 : 0.08,
                            ),
                            blurRadius: widget.selected ? 18 : 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, -0.30),
                    child: Icon(
                      _agentIcon(widget.agent.id),
                      color: tone,
                      size: widget.size * 0.38,
                    ),
                  ),
                  Positioned(
                    left: widget.size * 0.31,
                    bottom: widget.size * 0.20,
                    child: _SpriteEye(tone: tone, blink: blink),
                  ),
                  Positioned(
                    right: widget.size * 0.31,
                    bottom: widget.size * 0.20,
                    child: _SpriteEye(tone: tone, blink: blink),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: widget.size * 0.24,
                      height: widget.size * 0.24,
                      decoration: BoxDecoration(
                        color: colors.backgroundCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.backgroundCard),
                      ),
                      alignment: Alignment.center,
                      child: _StatusDot(
                        color: _statusColor(context, widget.agent.status),
                        animate: widget.agent.status != AgentStatus.waiting,
                      ),
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

class _SpriteEye extends StatelessWidget {
  const _SpriteEye({required this.tone, required this.blink});

  final Color tone;
  final double blink;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3.4,
      height: 4.6 * blink,
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AgentStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = _statusColor(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusDot(color: tone, animate: status != AgentStatus.waiting),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _statusLabel(status),
            style: context.textTheme.labelSmall?.copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}

class _FunctionChip extends StatelessWidget {
  const _FunctionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
        border: Border.all(color: colors.divider),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationLine extends StatelessWidget {
  const _OperationLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Icon(icon, size: 17, color: colors.primaryAccent),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label:',
          style: context.textTheme.labelSmall?.copyWith(
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: context.textTheme.labelSmall?.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.color, required this.animate});

  final Color color;
  final bool animate;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.animate ? 1 + (_controller.value * 0.45) : 1.0;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RadarPulse extends StatefulWidget {
  const _RadarPulse({required this.color, required this.secondaryColor});

  final Color color;
  final Color secondaryColor;

  @override
  State<_RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<_RadarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _RadarPainter(
              progress: _controller.value,
              color: widget.color,
              secondaryColor: widget.secondaryColor,
              isDark: context.isDark,
            ),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({
    required this.progress,
    required this.color,
    required this.secondaryColor,
    required this.isDark,
  });

  final double progress;
  final Color color;
  final Color secondaryColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: isDark ? 0.18 : 0.22);

    for (var index = 1; index <= 3; index++) {
      final ringProgress = (progress + index / 3) % 1;
      canvas.drawCircle(
        center,
        radius * (0.25 + ringProgress * 0.66),
        base..color = color.withValues(alpha: (1 - ringProgress) * 0.22),
      );
    }

    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = secondaryColor.withValues(alpha: 0.75);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.72),
      progress * math.pi * 2,
      math.pi * 0.54,
      false,
      sweep,
    );

    final dotAngle = progress * math.pi * 2;
    final dot = Offset(
      center.dx + math.cos(dotAngle) * radius * 0.58,
      center.dy + math.sin(dotAngle) * radius * 0.58,
    );
    canvas.drawCircle(
      center,
      radius * 0.22,
      Paint()..color = color.withValues(alpha: 0.18),
    );
    canvas.drawCircle(center, radius * 0.11, Paint()..color = color);
    canvas.drawCircle(dot, 4.5, Paint()..color = secondaryColor);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isDark != isDark;
  }
}

class _AgentsLoading extends StatelessWidget {
  const _AgentsLoading();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerLoader(width: 160, height: 38),
            SizedBox(height: AppSpacing.md),
            ShimmerLoader(width: 300, height: 18),
            SizedBox(height: AppSpacing.sectionGap),
            ShimmerLoader(height: 138),
            SizedBox(height: AppSpacing.sectionGap),
            ShimmerLoader(height: 194),
            SizedBox(height: AppSpacing.md),
            ShimmerLoader(height: 194),
            SizedBox(height: AppSpacing.md),
            ShimmerLoader(height: 194),
          ],
        ),
      ),
    );
  }
}

class _AgentsError extends StatelessWidget {
  const _AgentsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: colors.errorColor,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Agents could not load.',
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Check your session and Supabase function status.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showAgentInfo(BuildContext context, LuminaAgent agent) {
  final colors = context.colors;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.backgroundElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.radiusXl),
      ),
    ),
    builder: (context) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textTertiary,
                    borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  _AgentSprite(agent: agent, size: 54, selected: true),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      agent.name,
                      style: context.textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                agent.functionName,
                style: context.textTheme.labelLarge?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _InfoRow(label: 'What it does', value: agent.description),
              _InfoRow(label: 'Trigger', value: agent.trigger),
              _InfoRow(label: 'Data used', value: agent.dataUsed),
              _InfoRow(
                label: 'Next',
                value: agent.nextRunAt == null
                    ? agent.nextRunLabel
                    : _formatNextRun(agent.nextRunAt!),
              ),
              if (agent.latestResult != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Latest note',
                  style: context.textTheme.labelLarge?.copyWith(
                    color: colors.primaryAccent,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _AgentResultReveal(agent: agent),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.labelLarge?.copyWith(
              color: colors.primaryAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(BuildContext context, AgentStatus status) {
  final colors = context.colors;
  return switch (status) {
    AgentStatus.recent => colors.successColor,
    AgentStatus.scheduled => colors.primaryAccent,
    AgentStatus.listening => colors.secondaryAccent,
    AgentStatus.waiting => colors.textTertiary,
  };
}

String _statusLabel(AgentStatus status) {
  return switch (status) {
    AgentStatus.recent => 'Ran recently',
    AgentStatus.scheduled => 'Scheduled',
    AgentStatus.listening => 'Listening',
    AgentStatus.waiting => 'Needs data',
  };
}

IconData _agentIcon(String id) {
  return switch (id) {
    'morning' => PhosphorIcons.sunHorizon(PhosphorIconsStyle.duotone),
    'burnout' => PhosphorIcons.shieldCheck(PhosphorIconsStyle.duotone),
    'patterns' => PhosphorIcons.sparkle(PhosphorIconsStyle.duotone),
    'goal' => PhosphorIcons.mapTrifold(PhosphorIconsStyle.duotone),
    'mentor' => PhosphorIcons.chatCircleDots(PhosphorIconsStyle.duotone),
    'reflection' => PhosphorIcons.notebook(PhosphorIconsStyle.duotone),
    'weekly' => PhosphorIcons.calendarCheck(PhosphorIconsStyle.duotone),
    _ => PhosphorIcons.calendarDots(PhosphorIconsStyle.duotone),
  };
}

Color _agentTone(BuildContext context, String id) {
  final colors = context.colors;
  return switch (id) {
    'morning' => colors.primaryAccent,
    'burnout' => colors.errorColor,
    'patterns' => colors.secondaryAccent,
    'goal' => colors.successColor,
    'mentor' => colors.primaryAccent,
    'reflection' => colors.secondaryAccent,
    'weekly' => colors.successColor,
    _ => colors.primaryAccent,
  };
}

String _relativeTime(DateTime? value) {
  if (value == null) {
    return 'No run recorded yet';
  }
  final local = value.toLocal();
  final diff = DateTime.now().difference(local);
  if (diff.inMinutes < 1) {
    return 'Just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  }
  return DateFormat('d MMM, h:mm a').format(local);
}

String _formatNextRun(DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(local.year, local.month, local.day);
  final dayLabel = target == today
      ? 'Today'
      : target == today.add(const Duration(days: 1))
      ? 'Tomorrow'
      : DateFormat('EEE, d MMM').format(local);
  return '$dayLabel ${DateFormat('h:mm a').format(local)}';
}
