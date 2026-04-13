import 'package:flutter/material.dart';

import 'glass_card.dart';

class SparklineCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final List<double> data;

  const SparklineCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      enableBlur: false,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withOpacity(0.62),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 54,
            child: data.length < 2
                ? Center(
                    child: Text(
                      'Collecting...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : CustomPaint(
                    painter: _SparklinePainter(
                      data: List<double>.of(data),
                      color: color,
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  const _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) {
      return;
    }

    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final span = (maxY - minY).abs() < 0.0001 ? 1.0 : (maxY - minY);

    final linePath = Path();
    for (var i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalized = (data[i] - minY) / span;
      final y = size.height - normalized * size.height;

      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.22), color.withOpacity(0.02)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawPath(linePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}
