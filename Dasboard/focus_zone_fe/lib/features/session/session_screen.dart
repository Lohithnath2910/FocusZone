import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../dashboard/dashboard_controller.dart';
import 'session_controller.dart';
import 'session_detail_screen.dart';

class SessionScreen extends StatefulWidget {
  final SessionController controller;
  final DashboardController dashboardController;

  const SessionScreen({
    super.key,
    required this.controller,
    required this.dashboardController,
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  Timer? _insightAutoDismissTimer;

  SessionController get controller => widget.controller;
  DashboardController get dashboardController => widget.dashboardController;

  Future<int?> _askForRating(BuildContext context) async {
    var selected = 7.0;

    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              decoration: BoxDecoration(
                color: scheme.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate this session',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set your focus score from 1 to 10.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: scheme.primary,
                      thumbColor: scheme.primary,
                      inactiveTrackColor: scheme.primary.withOpacity(0.18),
                      valueIndicatorColor: scheme.primary,
                    ),
                    child: Slider(
                      value: selected,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '${selected.round()}',
                      onChanged: (value) => setState(() => selected = value),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1', style: Theme.of(context).textTheme.bodySmall),
                      Text('10', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        'Focus score: ${selected.round()}/10',
                        key: ValueKey<int>(selected.round()),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: scheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(null),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(selected.round()),
                          child: const Text('Save rating'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startSession(BuildContext context) async {
    await controller.startSession(snapshot: dashboardController.snapshot);
  }

  Future<void> _stopSession(BuildContext context) async {
    final rating = await _askForRating(context);
    if (rating == null) {
      return;
    }

    final record = await controller.stopSession(
      rating: rating,
      snapshot: dashboardController.snapshot,
    );

    final insightText = record?.snapshot['insight']?.toString().trim();
    if (insightText != null && insightText.isNotEmpty) {
      _showInsight(insightText);
    }
  }

  void _showInsight(String message) {
    _insightAutoDismissTimer?.cancel();
    if (!mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Center(
          child: SingleChildScrollView(
            child: _InsightMessageCard(
              message: message,
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    ).then((_) {
      _insightAutoDismissTimer?.cancel();
    });

    _insightAutoDismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _openSessionDetails(
    BuildContext context,
    SessionRecord selected,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionDetailScreen(
          selectedRecord: selected,
          history: controller.history,
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Reset sessions?'),
          content: const Text(
            'This clears active and historical session data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      await controller.resetAll();
    }
  }

  String _durationLabel(Duration elapsed) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final scheme = Theme.of(context).colorScheme;

        return SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 92),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  enableBlur: false,
                  gradientColors: [
                    scheme.secondary.withOpacity(0.18),
                    scheme.primary.withOpacity(0.12),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Session control',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Track focused work, capture productivity feedback, and store it locally.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: scheme.onSurface.withOpacity(
                                          0.72,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          _SessionBadge(
                            label: controller.statusLabel,
                            active: controller.isActive,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: ValueListenableBuilder<Duration>(
                          valueListenable: controller.elapsedNotifier,
                          builder: (context, elapsed, _) {
                            return Column(
                              children: [
                                Text(
                                  _durationLabel(elapsed),
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  controller.isActive
                                      ? 'Session running'
                                      : 'No active session',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: scheme.onSurface.withOpacity(
                                          0.68,
                                        ),
                                      ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: controller.isActive
                                  ? null
                                  : () => _startSession(context),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Start session'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: controller.isActive
                                  ? () => _stopSession(context)
                                  : null,
                              icon: const Icon(Icons.stop_rounded),
                              label: const Text('Stop session'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _confirmReset(context),
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('Reset sessions'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                GlassCard(
                  enableBlur: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session trends',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _TrendBlock(
                        title: 'Productivity trend',
                        subtitle: 'Last ratings (1-10)',
                        color: scheme.primary,
                        values: controller.history
                            .take(8)
                            .toList()
                            .reversed
                            .map((record) => record.rating.toDouble())
                            .toList(),
                        maxY: 10,
                      ),
                      const SizedBox(height: 14),
                      _TrendBlock(
                        title: 'Duration trend',
                        subtitle: 'Session length in minutes',
                        color: scheme.tertiary,
                        values: controller.history
                            .take(8)
                            .toList()
                            .reversed
                            .map((record) {
                              final minutes = record.duration.inMinutes;
                              return (minutes <= 0 ? 1 : minutes).toDouble();
                            })
                            .toList(),
                        maxY: null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: GlassCard(
                    enableBlur: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live snapshot',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _SnapshotChip(
                              label: 'Temp',
                              value: dashboardController.temperature,
                            ),
                            _SnapshotChip(
                              label: 'Humidity',
                              value: dashboardController.humidity,
                            ),
                            _SnapshotChip(
                              label: 'Light',
                              value: dashboardController.light,
                            ),
                            _SnapshotChip(
                              label: 'Noise',
                              value: dashboardController.noise,
                            ),
                            _SnapshotChip(
                              label: 'Source',
                              value: dashboardController.isConnected
                                  ? 'Live'
                                  : 'Cached',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Recent sessions',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(
                            '${controller.history.length}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: scheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (controller.history.isEmpty)
                        Text(
                          'No sessions stored yet. Start a focus run to build your history.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: scheme.onSurface.withOpacity(0.68),
                              ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.history.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final record = controller.history[index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () =>
                                    _openSessionDetails(context, record),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: scheme.surface.withOpacity(0.42),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: scheme.onSurface.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _formatDate(record.startedAt),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleSmall,
                                            ),
                                          ),
                                          Text(
                                            record.durationLabel,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  color: scheme.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Productivity rating: ${record.rating}/10',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Snapshot: ${_snapshotSummary(record.snapshot)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurface
                                                  .withOpacity(0.62),
                                            ),
                                      ),
                                      if ((record.snapshot['insight']
                                              ?.toString()
                                              .trim()
                                              .isNotEmpty ??
                                          false)) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Insight: ${record.snapshot['insight']}',
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: scheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
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
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$day/$month/${local.year} · $hour:$minute';
  }

  String _snapshotSummary(Map<String, dynamic> snapshot) {
    if (snapshot.isEmpty) {
      return 'No snapshot captured';
    }

    final values = <String>[];
    if (snapshot['temperature'] != null) {
      values.add('T ${snapshot['temperature']}');
    }
    if (snapshot['humidity'] != null) {
      values.add('H ${snapshot['humidity']}');
    }
    if (snapshot['light'] != null) {
      values.add('L ${snapshot['light']}');
    }
    if (snapshot['noise'] != null) {
      values.add('N ${snapshot['noise']}');
    }

    return values.isEmpty ? 'Captured' : values.join(' · ');
  }

  @override
  void dispose() {
    _insightAutoDismissTimer?.cancel();
    super.dispose();
  }
}

class _SessionBadge extends StatelessWidget {
  final String label;
  final bool active;

  const _SessionBadge({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active
        ? Colors.greenAccent
        : scheme.onSurface.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InsightMessageCard extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _InsightMessageCard({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.all(24),
      child: GlassCard(
        enableBlur: true,
        gradientColors: [
          scheme.primary.withOpacity(0.12),
          scheme.tertiary.withOpacity(0.08),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tips_and_updates_rounded,
                    color: scheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Insight',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: scheme.onSurface.withOpacity(0.6),
                  ),
                  tooltip: 'Dismiss',
                  onPressed: onClose,
                  iconSize: 22,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surface.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: scheme.primary.withOpacity(0.08),
                ),
              ),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.88),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onClose,
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapshotChip extends StatelessWidget {
  final String label;
  final String value;

  const _SnapshotChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.48),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withOpacity(0.62),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TrendBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final List<double> values;
  final double? maxY;

  const _TrendBlock({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.values,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasData = values.length >= 2;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surface.withOpacity(0.4),
        border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withOpacity(0.62),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: hasData
                ? CustomPaint(
                    painter: _LineGraphPainter(
                      values: values,
                      lineColor: color,
                      maxY: maxY,
                    ),
                    child: const SizedBox.expand(),
                  )
                : Center(
                    child: Text(
                      'Need at least 2 sessions to show trend',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LineGraphPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final double? maxY;

  const _LineGraphPainter({
    required this.values,
    required this.lineColor,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      return;
    }

    final computedMax = maxY ?? values.reduce((a, b) => a > b ? a : b);
    final chartMax = computedMax <= 0 ? 1.0 : computedMax;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height - (values[i] / chartMax) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.24), lineColor.withOpacity(0.02)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = lineColor;
    canvas.drawPath(path, strokePaint);

    final pointPaint = Paint()..color = lineColor;
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height - (values[i] / chartMax) * size.height;
      canvas.drawCircle(Offset(x, y), 2.8, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineGraphPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.maxY != maxY;
  }
}
