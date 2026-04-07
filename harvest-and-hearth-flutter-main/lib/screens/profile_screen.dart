import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    final user = provider.user!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('profile_title'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Avatar card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Preferences section
          _SectionLabel(title: t('profile_preferences')),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                // Language
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(t('profile_language')),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'VIE', label: Text('VIE')),
                      ButtonSegment(value: 'ENG', label: Text('ENG')),
                    ],
                    selected: {provider.language},
                    onSelectionChanged: (s) =>
                        provider.setLanguage(s.first),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                // Dark mode
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: Text(t('profile_dark_mode')),
                  value: provider.isDark,
                  onChanged: (_) => provider.toggleTheme(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Settings section
          _SectionLabel(title: t('profile_settings')),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: Text(t('profile_expiry_reminders')),
                  subtitle: Text(
                    t('profile_expiry_reminders_sub'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: provider.expiryRemindersEnabled,
                  onChanged: (v) => provider.setExpiryRemindersEnabled(v),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: Text(t('profile_security')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: Text(t('profile_help')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Inventory stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    value: '${provider.inventory.length}',
                    label: t('dashboard_items'),
                    icon: Icons.kitchen_rounded,
                  ),
                  _StatItem(
                    value: '${provider.savedRecipes.length}',
                    label: t('recipes_saved'),
                    icon: Icons.bookmark_rounded,
                  ),
                  _StatItem(
                    value: '${provider.expiredItems.length}',
                    label: t('dashboard_expired'),
                    icon: Icons.warning_amber_rounded,
                    isAlert: provider.expiredItems.isNotEmpty,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Logout
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, provider),
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            label: Text(t('profile_logout'),
                style: const TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppProvider provider) {
    final t = provider.t;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('profile_logout')),
        content: Text(t('profile_logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('common_cancel')),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final auth = ClerkAuth.of(context, listen: false);
              await provider.logout(auth);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t('profile_logout')),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isAlert;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAlert ? Colors.red : Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
