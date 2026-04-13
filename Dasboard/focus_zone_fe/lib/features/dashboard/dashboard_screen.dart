import 'package:flutter/material.dart';

import '../../core/constants/spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/sparkline_card.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatefulWidget {
  final DashboardController controller;

  const DashboardScreen({super.key, required this.controller});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final TextEditingController urlController;

  DashboardController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    urlController = TextEditingController(text: controller.baseUrl);
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final input = urlController.text.trim();
    if (input.isEmpty) {
      return;
    }

    controller.connect(input);
    setState(() {
      urlController.text = controller.baseUrl;
    });
  }

  Future<void> _refresh() async {
    await controller.refresh();
  }

  Future<void> _quickReconnect() async {
    if (controller.baseUrl.isEmpty) {
      return;
    }

    controller.connect(controller.baseUrl);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final scheme = Theme.of(context).colorScheme;

        return SafeArea(
          child: RefreshIndicator(
            color: scheme.primary,
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 92),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Focus Zone',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      _StatusChip(
                        color: controller.isConnected
                            ? Colors.greenAccent
                            : controller.isStale
                            ? Colors.orangeAccent
                            : scheme.onSurface.withOpacity(0.75),
                        label: controller.isConnected
                            ? 'LIVE'
                            : controller.isStale
                            ? 'STALE'
                            : 'IDLE',
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  GlassCard(
                    enableBlur: false,
                    gradientColors: [
                      scheme.primary.withOpacity(0.16),
                      scheme.tertiary.withOpacity(0.12),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device connection',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: urlController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _connect(),
                          decoration: InputDecoration(
                            hintText: 'ESP32 IP or backend URL',
                            suffixIcon: controller.savedBaseUrls.isEmpty
                                ? null
                                : PopupMenuButton<String>(
                                    tooltip: 'Choose saved URL',
                                    icon: const Icon(Icons.history_rounded),
                                    onSelected: (selected) {
                                      setState(() {
                                        urlController.text = selected;
                                      });
                                      controller.connect(selected);
                                    },
                                    itemBuilder: (context) {
                                      return controller.savedBaseUrls
                                          .map(
                                            (savedUrl) => PopupMenuItem<String>(
                                              value: savedUrl,
                                              child: Text(
                                                savedUrl,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList();
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: _connect,
                                child: const Text('Connect'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: controller.isLoading
                                    ? null
                                    : _refresh,
                                child: const Text('Refresh'),
                              ),
                            ),
                          ],
                        ),
                        if (controller.baseUrl.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _quickReconnect,
                              icon: const Icon(Icons.link_rounded),
                              label: const Text('Reconnect saved device'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = (constraints.maxWidth - 14) / 2;
                      final ratio = cardWidth / 178;

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: ratio.clamp(0.72, 1.05),
                        children: [
                          _MetricCard(
                            title: 'Temperature',
                            value: controller.temperature,
                            icon: Icons.thermostat_rounded,
                            accent: scheme.primary,
                          ),
                          _MetricCard(
                            title: 'Humidity',
                            value: controller.humidity,
                            icon: Icons.water_drop_rounded,
                            accent: scheme.tertiary,
                          ),
                          _MetricCard(
                            title: 'Light',
                            value: controller.light,
                            icon: Icons.wb_sunny_rounded,
                            accent: scheme.secondary,
                          ),
                          _MetricCard(
                            title: 'Noise',
                            value: controller.noise,
                            icon: Icons.graphic_eq_rounded,
                            accent: scheme.error,
                          ),
                          _MetricCard(
                            title: 'Timestamp',
                            value: controller.time,
                            icon: Icons.schedule_rounded,
                            accent: scheme.onSurface,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    'Live trends',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  SparklineCard(
                    title: 'Temperature',
                    value: controller.temperature,
                    subtitle: 'Recent readings',
                    color: scheme.primary,
                    data: controller.temperatureHistory,
                  ),
                  const SizedBox(height: 12),
                  SparklineCard(
                    title: 'Humidity',
                    value: controller.humidity,
                    subtitle: 'Recent readings',
                    color: scheme.tertiary,
                    data: controller.humidityHistory,
                  ),
                  const SizedBox(height: 12),
                  SparklineCard(
                    title: 'Light',
                    value: controller.light,
                    subtitle: 'Recent readings',
                    color: scheme.secondary,
                    data: controller.lightHistory,
                  ),
                  const SizedBox(height: 12),
                  SparklineCard(
                    title: 'Noise',
                    value: controller.noise,
                    subtitle: 'Recent readings',
                    color: scheme.error,
                    data: controller.noiseHistory,
                  ),
                  const SizedBox(height: Spacing.lg),
                  GlassCard(
                    child: Row(
                      children: [
                        Icon(
                          controller.isConnected
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          color: controller.isConnected
                              ? Colors.greenAccent
                              : scheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.statusMessage ?? 'Ready',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                controller.isStale
                                    ? 'Cached snapshot shown while reconnecting.'
                                    : controller.lastUpdated == null
                                    ? 'No reading yet. Connect to start polling.'
                                    : 'Last update: ${controller.lastUpdated}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: scheme.onSurface.withOpacity(0.68),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      enableBlur: false,
      gradientColors: [
        accent.withOpacity(0.18),
        scheme.surface.withOpacity(0.36),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: accent.withOpacity(0.16),
                ),
                child: Icon(icon, color: accent),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: FittedBox(
                  key: ValueKey<String>(value),
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
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
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
