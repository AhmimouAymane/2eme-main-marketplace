import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/shared/providers/settings_providers.dart';

/// Écran Paramètres : thème, notifications, à propos
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      backgroundColor: AppColors.cloviBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.cloviGreen),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Paramètres',
          style: TextStyle(
            color: AppColors.cloviGreen,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Apparence'),
            _buildCard(
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Thème',
                    subtitle: _themeLabel(themeMode),
                  ),
                  const Divider(height: 1, indent: 56),
                  _themeOptions(ref, themeMode),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Notifications'),
            _buildCard(
              child: _buildSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications push',
                subtitle: 'Messages et mises à jour',
                value: notificationsEnabled,
                onChanged: (v) => ref.read(notificationsEnabledProvider.notifier).setEnabled(v),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Application'),
            _buildCard(
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.info_outline,
                    title: 'À propos',
                    subtitle: '${AppConstants.appName} v${AppConstants.appVersion}',
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.cloviGreen, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
            )
          : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight) : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Icon(icon, color: AppColors.cloviGreen, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.cloviGreen,
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Système';
    }
  }

  Widget _themeOptions(WidgetRef ref, ThemeMode current) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _themeChip(
            label: 'Clair',
            selected: current == ThemeMode.light,
            onTap: () => ref.read(currentThemeProvider.notifier).setTheme(ThemeMode.light),
          ),
          const SizedBox(width: 8),
          _themeChip(
            label: 'Sombre',
            selected: current == ThemeMode.dark,
            onTap: () => ref.read(currentThemeProvider.notifier).setTheme(ThemeMode.dark),
          ),
          const SizedBox(width: 8),
          _themeChip(
            label: 'Système',
            selected: current == ThemeMode.system,
            onTap: () => ref.read(currentThemeProvider.notifier).setTheme(ThemeMode.system),
          ),
        ],
      ),
    );
  }

  Widget _themeChip({required String label, required bool selected, required VoidCallback onTap}) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.cloviGreen : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppConstants.appName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version ${AppConstants.appVersion}'),
            const SizedBox(height: 12),
            const Text(
              'Marketplace de vêtements de seconde main.',
              style: TextStyle(color: AppColors.textSecondaryLight),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
