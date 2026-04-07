import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/food_item.dart';
import '../constants/categories.dart';
import '../utils/date_helper.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;

    final expired = provider.expiredItems;
    final expiringSoon = provider.expiringSoonItems;
    final recent = provider.inventory.take(3).toList();
    final hasAlerts = expired.isNotEmpty || expiringSoon.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.eco_rounded, color: cs.primary, size: 28),
            const SizedBox(width: 8),
            Text(
              'Harvest & Hearth',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: cs.primary),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Welcome Banner
          _WelcomeBanner(provider: provider),
          const SizedBox(height: 16),

          // Alerts
          if (hasAlerts) ...[
            _SectionHeader(title: t('dashboard_alerts')),
            const SizedBox(height: 8),
            _AlertsCard(
              expired: expired,
              expiringSoon: expiringSoon,
              t: t,
              language: provider.language,
            ),
            const SizedBox(height: 16),
          ],

          // Recent items
          _SectionHeader(title: t('dashboard_recent')),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            _EmptyCard(message: t('dashboard_no_items'))
          else
            ...recent.map((item) => _RecentItemRow(
                  item: item,
                  t: t,
                  language: provider.language,
                )),

          const SizedBox(height: 16),

          // Daily tip
          _TipCard(t: t),
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final AppProvider provider;
  const _WelcomeBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final t = provider.t;
    final cs = Theme.of(context).colorScheme;
    final name = provider.user?.name ?? '';
    final count = provider.inventory.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${t('dashboard_welcome')}, $name! 👋',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            t('dashboard_subtitle'),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                icon: Icons.kitchen_rounded,
                value: '$count',
                label: t('dashboard_items'),
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.warning_amber_rounded,
                value: '${provider.expiredItems.length + provider.expiringSoonItems.length}',
                label: t('dashboard_expiring'),
                isAlert: provider.expiredItems.isNotEmpty,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isAlert;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isAlert ? Colors.amber : Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  final List<FoodItem> expired;
  final List<FoodItem> expiringSoon;
  final String Function(String) t;
  final String language;

  const _AlertsCard({
    required this.expired,
    required this.expiringSoon,
    required this.t,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ...expired.map((item) => _AlertRow(
                item: item,
                isExpired: true,
                t: t,
                language: language,
              )),
          ...expiringSoon.take(3).map((item) => _AlertRow(
                item: item,
                isExpired: false,
                t: t,
                language: language,
              )),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final FoodItem item;
  final bool isExpired;
  final String Function(String) t;
  final String language;

  const _AlertRow({
    required this.item,
    required this.isExpired,
    required this.t,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpired ? Colors.red : Colors.orange;
    final info = AppCategories.forCategory(item.category);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: info.color.withAlpha(26),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(info.icon, color: info.color, size: 20),
      ),
      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        DateHelper.relativeLabel(item.daysUntilExpiry, language),
        style: TextStyle(color: color, fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isExpired ? t('inventory_expired_badge') : t('inventory_expiring_badge'),
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _RecentItemRow extends StatelessWidget {
  final FoodItem item;
  final String Function(String) t;
  final String language;

  const _RecentItemRow({
    required this.item,
    required this.t,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final info = AppCategories.forCategory(item.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: info.color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(info.icon, color: info.color, size: 22),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${item.quantity} ${item.unit}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: item.daysUntilExpiry != null
            ? Text(
                DateHelper.relativeLabel(item.daysUntilExpiry, language),
                style: TextStyle(
                  fontSize: 12,
                  color: item.isExpired
                      ? Colors.red
                      : item.isExpiringSoon
                          ? Colors.orange
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String Function(String) t;
  const _TipCard({required this.t});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.lightbulb_rounded,
                color: cs.onSecondaryContainer, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('dashboard_tip'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('dashboard_tip_text'),
                    style: TextStyle(
                        color: cs.onSecondaryContainer, fontSize: 13),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
