import 'package:flutter/material.dart';

import '../../core/constants/spacing.dart';
import '../../core/theme/theme_controller.dart';
import '../../services/storage_service.dart';
import '../../shared/widgets/glass_card.dart';
import '../dashboard/dashboard_controller.dart';
import '../session/session_controller.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeController themeController;
  final DashboardController dashboardController;
  final SessionController sessionController;

  const SettingsScreen({
    super.key,
    required this.themeController,
    required this.dashboardController,
    required this.sessionController,
  });

  Future<void> _clearData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          backgroundColor: scheme.surface.withOpacity(0.96),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Clear data?'),
          content: const Text(
            'This removes cached readings and session history from local storage.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await StorageService.clearAll();
    dashboardController.clear();
    await sessionController.resetAll();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 122),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              gradientColors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.18),
                Theme.of(context).colorScheme.secondary.withOpacity(0.12),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Refine the interface and manage locally stored data.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.68),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.lg),
            AnimatedBuilder(
              animation: themeController,
              builder: (_, __) {
                final scheme = Theme.of(context).colorScheme;

                return GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: themeController.isDark
                              ? scheme.primary.withOpacity(0.2)
                              : scheme.tertiary.withOpacity(0.2),
                        ),
                        child: Icon(
                          themeController.isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: themeController.isDark
                              ? scheme.primary
                              : scheme.tertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dark mode',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              themeController.isDark
                                  ? 'Deep contrast for night focus'
                                  : 'Bright contrast for daytime',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurface.withOpacity(0.62),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: themeController.isDark,
                        onChanged: themeController.setDark,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: Spacing.lg),
            AnimatedBuilder(
              animation: Listenable.merge([
                dashboardController,
                sessionController,
              ]),
              builder: (_, __) {
                final scheme = Theme.of(context).colorScheme;

                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Storage overview',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Cached reading',
                        value: dashboardController.time == '--'
                            ? 'Empty'
                            : dashboardController.time,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Session count',
                        value: '${sessionController.history.length}',
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Theme value',
                        value: (themeController.value * 100).round().toString(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () => _clearData(context),
                              child: const Text('Clear data'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      sessionController.isActive
                                          ? 'Session active for ${sessionController.durationLabel}'
                                          : 'No active session',
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Status'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        dashboardController.isStale
                            ? 'Cached data is currently visible because the device is offline.'
                            : 'Live data will keep updating every 20 seconds when connected.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(0.62),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.68),
            ),
          ),
        ),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
