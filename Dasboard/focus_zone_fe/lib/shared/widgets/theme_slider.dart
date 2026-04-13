import 'package:flutter/material.dart';

import '../../core/theme/theme_controller.dart';

class ThemeSlider extends StatelessWidget {
  final ThemeController controller;

  const ThemeSlider({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theme', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'Slide between light and dark without a hard switch.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withOpacity(0.66),
          ),
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            activeTrackColor: scheme.primary,
            inactiveTrackColor: scheme.onSurface.withOpacity(0.15),
            thumbColor: scheme.primary,
            overlayColor: scheme.primary.withOpacity(0.14),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
          ),
          child: Slider(
            value: controller.value,
            onChanged: controller.update,
            divisions: 100,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Light', style: Theme.of(context).textTheme.bodySmall),
            Text(
              '${(controller.value * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text('Dark', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
