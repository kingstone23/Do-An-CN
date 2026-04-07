import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../core/simulated_clock.dart';
import '../providers/app_provider.dart';
import '../services/expiry_reminder_service.dart';

/// Debug: always on. Release: on unless `.env` sets `ENABLE_TIME_SIMULATOR` to `false`, `0`, or `no`.
bool isTimeSimulatorFabVisible() {
  if (kDebugMode) return true;
  final v = dotenv.env['ENABLE_TIME_SIMULATOR']?.toLowerCase().trim();
  if (v == 'false' || v == '0' || v == 'no') return false;
  return true;
}

class TimeSimulatorFab extends StatelessWidget {
  const TimeSimulatorFab({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppProvider>().t;
    return FloatingActionButton.small(
      heroTag: 'time_simulator_fab',
      tooltip: t('time_simulator_tooltip'),
      onPressed: () => _openConsole(context),
      child: const Icon(Icons.more_time_rounded),
    );
  }

  static void _openConsole(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Consumer<AppProvider>(
              builder: (context, p, _) {
                final t = p.t;
                final cs = Theme.of(context).colorScheme;
                final expiring = p.expiringSoonItems.length;
                final expired = p.expiredItems.length;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t('time_simulator_title'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      SimulatedClock.describeOffset(p.language),
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DayChip(
                          label: t('time_simulator_p1'),
                          onPressed: () {
                            SimulatedClock.addDays(1);
                            p.applySimulatedTime();
                          },
                        ),
                        _DayChip(
                          label: t('time_simulator_p3'),
                          onPressed: () {
                            SimulatedClock.addDays(3);
                            p.applySimulatedTime();
                          },
                        ),
                        _DayChip(
                          label: t('time_simulator_p7'),
                          onPressed: () {
                            SimulatedClock.addDays(7);
                            p.applySimulatedTime();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        SimulatedClock.reset();
                        p.applySimulatedTime();
                      },
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(t('time_simulator_reset')),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        final ok =
                            await ExpiryReminderService.instance
                                .showImmediateTestSummary(
                          expiring: expiring,
                          expired: expired,
                          language: p.language,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? t('time_simulator_test_sent')
                                  : t('time_simulator_test_notif_denied'),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: Text(t('time_simulator_test_notif')),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('time_simulator_hint'),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
