import 'package:flutter/material.dart';

class GlassNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const GlassNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          color: scheme.surface.withOpacity(0.78),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.09),
              blurRadius: 7,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const itemCount = 3;
            const indicatorPadding = 8.0;
            final slotWidth = constraints.maxWidth / itemCount;
            final indicatorWidth = slotWidth - indicatorPadding * 2;
            final left = (slotWidth * currentIndex) + indicatorPadding;

            return Stack(
              alignment: Alignment.center,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 170),
                  curve: Curves.easeOutCubic,
                  left: left,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: indicatorWidth,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary.withOpacity(0.95),
                          scheme.tertiary.withOpacity(0.9),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withOpacity(0.18),
                          blurRadius: 5,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _item(
                        context,
                        Icons.dashboard_rounded,
                        'Dashboard',
                        0,
                      ),
                    ),
                    Expanded(
                      child: _item(
                        context,
                        Icons.play_circle_rounded,
                        'Session',
                        1,
                      ),
                    ),
                    Expanded(
                      child: _item(context, Icons.tune_rounded, 'Settings', 2),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, int index) {
    final scheme = Theme.of(context).colorScheme;
    final active = currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: SizedBox(
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: active ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                color: active
                    ? scheme.onPrimary
                    : scheme.onSurface.withOpacity(0.72),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: active
                    ? scheme.onPrimary
                    : scheme.onSurface.withOpacity(0.6),
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
