import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/spacing.dart';
import '../../shared/widgets/glass_card.dart';
import 'session_controller.dart';

class SessionDetailScreen extends StatelessWidget {
  final SessionRecord selectedRecord;
  final List<SessionRecord> history;

  const SessionDetailScreen({
    super.key,
    required this.selectedRecord,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ordered = history.toList().reversed.toList();
    final selectedIndex = math.max(
      0,
      ordered.indexWhere((record) => record.id == selectedRecord.id),
    );

    final temperatureSeries = _seriesFromSnapshot(ordered, 'temperature');
    final humiditySeries = _seriesFromSnapshot(ordered, 'humidity');
    final lightSeries = _seriesFromSnapshot(ordered, 'light');
    final noiseSeries = _seriesFromSnapshot(ordered, 'noise');
    final ratingSeries = ordered
        .map((record) => record.rating.clamp(1, 5).toDouble())
        .toList();
    final durationSeries = ordered.map((record) {
      final minutes = record.duration.inMinutes;
      return (minutes <= 0 ? 1 : minutes).toDouble();
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Session analytics')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                enableBlur: false,
                gradientColors: [
                  scheme.primary.withOpacity(0.18),
                  scheme.tertiary.withOpacity(0.12),
                ],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(selectedRecord.startedAt),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Detailed view of stored session snapshot, duration, and trends across your session history.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetricPill(
                          label: 'Duration',
                          value: selectedRecord.durationLabel,
                        ),
                        _MetricPill(
                          label: 'Rating',
                          value: '${selectedRecord.rating}/10',
                        ),
                        _MetricPill(
                          label: 'Temp',
                          value:
                              selectedRecord.snapshot['temperature']
                                  ?.toString() ??
                              '--',
                        ),
                        _MetricPill(
                          label: 'Humidity',
                          value:
                              selectedRecord.snapshot['humidity']?.toString() ??
                              '--',
                        ),
                        _MetricPill(
                          label: 'Light',
                          value:
                              selectedRecord.snapshot['light']?.toString() ??
                              '--',
                        ),
                        _MetricPill(
                          label: 'Noise',
                          value:
                              selectedRecord.snapshot['noise']?.toString() ??
                              '--',
                        ),
                      ],
                    ),
                    if ((selectedRecord.snapshot['insight']
                            ?.toString()
                            .trim()
                            .isNotEmpty ??
                        false)) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surface.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: scheme.onSurface.withOpacity(0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stored insight',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              selectedRecord.snapshot['insight'].toString(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),
              _AxisTrendCard(
                title: 'Temperature across sessions',
                yLabel: 'C',
                lineColor: scheme.primary,
                values: temperatureSeries,
                selectedIndex: selectedIndex,
                minY: null,
                maxY: null,
              ),
              const SizedBox(height: 12),
              _AxisTrendCard(
                title: 'Humidity across sessions',
                yLabel: '%',
                lineColor: scheme.tertiary,
                values: humiditySeries,
                selectedIndex: selectedIndex,
                minY: 0,
                maxY: 100,
              ),
              const SizedBox(height: 12),
              _AxisTrendCard(
                title: 'Light across sessions',
                yLabel: 'lux',
                lineColor: scheme.secondary,
                values: lightSeries,
                selectedIndex: selectedIndex,
                minY: null,
                maxY: null,
              ),
              const SizedBox(height: 12),
              _AxisTrendCard(
                title: 'Noise across sessions',
                yLabel: 'dB',
                lineColor: scheme.error,
                values: noiseSeries,
                selectedIndex: selectedIndex,
                minY: null,
                maxY: null,
              ),
              const SizedBox(height: 12),
              _AxisTrendCard(
                title: 'Productivity rating',
                yLabel: 'score',
                lineColor: scheme.primary,
                values: ratingSeries,
                selectedIndex: selectedIndex,
                minY: 1,
                maxY: 10,
              ),
              const SizedBox(height: 12),
              _AxisTrendCard(
                title: 'Duration trend',
                yLabel: 'min',
                lineColor: scheme.onSurface,
                values: durationSeries,
                selectedIndex: selectedIndex,
                minY: 0,
                maxY: null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<double> _seriesFromSnapshot(List<SessionRecord> ordered, String key) {
    final result = <double>[];
    var fallback = 0.0;

    for (final record in ordered) {
      final parsed = _extractNumber(record.snapshot[key]);
      if (parsed != null) {
        fallback = parsed;
      }
      result.add(fallback);
    }

    return result;
  }

  double? _extractNumber(Object? raw) {
    if (raw == null) {
      return null;
    }

    if (raw is num) {
      return raw.toDouble();
    }

    final text = raw.toString();
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(text);
    if (match == null) {
      return null;
    }

    return double.tryParse(match.group(0)!);
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$day/$month/${local.year} · $hour:$minute';
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

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
              color: scheme.onSurface.withOpacity(0.66),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AxisTrendCard extends StatelessWidget {
  final String title;
  final String yLabel;
  final Color lineColor;
  final List<double> values;
  final int selectedIndex;
  final double? minY;
  final double? maxY;

  const _AxisTrendCard({
    required this.title,
    required this.yLabel,
    required this.lineColor,
    required this.values,
    required this.selectedIndex,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final hasEnoughData = values.length >= 2;

    return GlassCard(
      enableBlur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: hasEnoughData
                ? CustomPaint(
                    painter: _AxisLineChartPainter(
                      values: values,
                      lineColor: lineColor,
                      selectedIndex: selectedIndex,
                      yLabel: yLabel,
                      minY: minY,
                      maxY: maxY,
                    ),
                    child: const SizedBox.expand(),
                  )
                : Center(
                    child: Text(
                      'Need at least 2 sessions for charting.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AxisLineChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final int selectedIndex;
  final String yLabel;
  final double? minY;
  final double? maxY;

  const _AxisLineChartPainter({
    required this.values,
    required this.lineColor,
    required this.selectedIndex,
    required this.yLabel,
    required this.minY,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      return;
    }

    const leftPad = 40.0;
    const rightPad = 8.0;
    const topPad = 8.0;
    const bottomPad = 28.0;
    final chartRect = Rect.fromLTWH(
      leftPad,
      topPad,
      size.width - leftPad - rightPad,
      size.height - topPad - bottomPad,
    );

    if (chartRect.width <= 0 || chartRect.height <= 0) {
      return;
    }

    final localMin = minY ?? values.reduce((a, b) => a < b ? a : b);
    final localMax = maxY ?? values.reduce((a, b) => a > b ? a : b);
    final span = (localMax - localMin).abs() < 0.0001
        ? 1.0
        : (localMax - localMin);

    final axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(chartRect.left, chartRect.top),
      Offset(chartRect.left, chartRect.bottom),
      axisPaint,
    );
    canvas.drawLine(
      Offset(chartRect.left, chartRect.bottom),
      Offset(chartRect.right, chartRect.bottom),
      axisPaint,
    );

    for (var i = 1; i <= 4; i++) {
      final y = chartRect.top + (chartRect.height * i / 4);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = chartRect.left + (chartRect.width * i / (values.length - 1));
      final normalized = (values[i] - localMin) / span;
      final y = chartRect.bottom - (normalized * chartRect.height);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(chartRect.right, chartRect.bottom)
      ..lineTo(chartRect.left, chartRect.bottom)
      ..close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.2), lineColor.withOpacity(0.02)],
      ).createShader(chartRect);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = lineColor;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = lineColor;
    for (var i = 0; i < points.length; i++) {
      final radius = i == selectedIndex ? 4.2 : 2.8;
      canvas.drawCircle(points[i], radius, dotPaint);
    }

    final selected = selectedIndex.clamp(0, points.length - 1);
    final selectedPoint = points[selected];
    final markerPaint = Paint()..color = lineColor.withOpacity(0.2);
    canvas.drawLine(
      Offset(selectedPoint.dx, chartRect.top),
      Offset(selectedPoint.dx, chartRect.bottom),
      markerPaint,
    );

    _drawText(
      canvas,
      text: '${localMax.toStringAsFixed(1)} $yLabel',
      offset: Offset(2, chartRect.top - 8),
      fontSize: 10,
    );
    _drawText(
      canvas,
      text: '${localMin.toStringAsFixed(1)} $yLabel',
      offset: Offset(2, chartRect.bottom - 10),
      fontSize: 10,
    );
    _drawText(
      canvas,
      text: '1',
      offset: Offset(chartRect.left - 2, chartRect.bottom + 8),
      fontSize: 10,
      alignRight: false,
    );
    _drawText(
      canvas,
      text: '${values.length}',
      offset: Offset(chartRect.right - 8, chartRect.bottom + 8),
      fontSize: 10,
      alignRight: true,
    );
    _drawText(
      canvas,
      text: 'sessions',
      offset: Offset(chartRect.center.dx - 26, chartRect.bottom + 8),
      fontSize: 10,
    );
  }

  void _drawText(
    Canvas canvas, {
    required String text,
    required Offset offset,
    required double fontSize,
    bool alignRight = false,
  }) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.72),
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
    final painter = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout();

    final drawOffset = alignRight
        ? Offset(offset.dx - painter.width, offset.dy)
        : offset;
    painter.paint(canvas, drawOffset);
  }

  @override
  bool shouldRepaint(covariant _AxisLineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY ||
        oldDelegate.yLabel != yLabel;
  }
}
