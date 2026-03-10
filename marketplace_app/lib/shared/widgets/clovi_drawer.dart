import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:marketplace_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:marketplace_app/shared/widgets/clovi_logo.dart';

class CloviDrawer extends ConsumerWidget {
  const CloviDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // IMPROVEMENT: Watch all user data in one place at the top
    final email = ref.watch(userEmailProvider).valueOrNull;
    final avatarUrl = ref.watch(userAvatarUrlProvider).valueOrNull;
    final userName = ref.watch(userNameProvider).valueOrNull; // show name if available
    final unreadCount = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;

    return Drawer(
      // IMPROVEMENT: Slightly wider for better readability on large phones
      width: MediaQuery.of(context).size.width * 0.82,
      child: Column(
        children: [
          _DrawerHeader(
            email: email,
            avatarUrl: avatarUrl,
            userName: userName,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerSection(
                  items: [
                    _DrawerItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Mon Profil',
                      onTap: () => _navigate(context, AppRoutes.profile),
                    ),
                    _DrawerItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      // IMPROVEMENT: Show actual count badge, not just a dot
                      badgeCount: unreadCount,
                      onTap: () => _navigate(context, AppRoutes.notifications),
                    ),
                    _DrawerItem(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Mes Commandes',
                      onTap: () => _navigate(context, AppRoutes.orders),
                    ),
                    _DrawerItem(
                      icon: Icons.favorite_border_rounded,
                      title: 'Mes Favoris',
                      onTap: () => _navigate(context, AppRoutes.favorites),
                    ),
                    _DrawerItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Messages',
                      onTap: () => _navigate(context, AppRoutes.conversations),
                    ),
                  ],
                ),
                // IMPROVEMENT: Visual section separator with label
                _DrawerSectionDivider(label: 'Aide'),
                _DrawerSection(
                  items: [
                    _DrawerItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Aide & Support',
                      onTap: () => _navigate(context, AppRoutes.helpSupport),
                    ),
                    _DrawerItem(
                      icon: Icons.settings_outlined,
                      title: 'Paramètres',
                      onTap: () => _navigate(context, 'settings', named: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // IMPROVEMENT: Logout shows a confirmation dialog before acting
          _LogoutButton(onTap: () => _handleLogout(context, ref)),
          // IMPROVEMENT: Respect system bottom padding (notch phones etc.)
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  /// IMPROVEMENT: Centralised nav helper — closes drawer then pushes
  void _navigate(BuildContext context, String route, {bool named = false}) {
    context.pop();
    
    // Si c'est une route de branche (Home, Search, Messages, Profile), on utilise .go
    final isBranch = [
      AppRoutes.home,
      AppRoutes.search,
      AppRoutes.conversations,
      AppRoutes.profile
    ].contains(route);

    if (named) {
      context.pushNamed(route);
    } else if (isBranch) {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // IMPROVEMENT: Confirm before logging out — prevents accidental taps
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(authServiceProvider).logout();
      if (context.mounted) context.go(AppRoutes.login);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final String? email;
  final String? avatarUrl;
  final String? userName;

  const _DrawerHeader({this.email, this.avatarUrl, this.userName});

  @override
  Widget build(BuildContext context) {
    // IMPROVEMENT: First letter of name/email as avatar fallback (not a generic icon)
    final initials = _getInitials(userName ?? email);

    return Container(
      width: double.infinity,
      // IMPROVEMENT: Use safe area top padding so header doesn't clash with status bar
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 28,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cloviGreen,
        // IMPROVEMENT: Both corners rounded for a softer, more modern look
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CloviLogo(
              size: 36, showText: false, color: Colors.white, fontSize: 28),
          const SizedBox(height: 28),
          Row(
            children: [
              // IMPROVEMENT: Avatar with gradient ring
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 2),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      (avatarUrl?.isNotEmpty ?? false) ? NetworkImage(avatarUrl!) : null,
                  child: (avatarUrl?.isEmpty ?? true)
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // IMPROVEMENT: Show display name if available
                    if (userName != null)
                      Text(
                        userName!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      email ?? 'Utilisateur',
                      style: TextStyle(
                        color: userName != null
                            ? Colors.white70
                            : Colors.white,
                        fontSize: userName != null ? 12 : 15,
                        fontWeight: userName != null
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // IMPROVEMENT: Quick profile edit shortcut
              IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go(AppRoutes.profile);
                },
                icon: const Icon(Icons.edit_outlined,
                    color: Colors.white70, size: 20),
                tooltip: 'Modifier le profil',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInitials(String? value) {
    if (value == null || value.isEmpty) return '?';
    final parts = value.trim().split(RegExp(r'[\s@.]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return value[0].toUpperCase();
  }
}

// ─── Section divider with label ───────────────────────────────────────────────

class _DrawerSectionDivider extends StatelessWidget {
  final String label;
  const _DrawerSectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: Colors.grey.shade200, height: 1)),
        ],
      ),
    );
  }
}

// ─── Section wrapper ──────────────────────────────────────────────────────────

class _DrawerSection extends StatelessWidget {
  final List<_DrawerItem> items;
  const _DrawerSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(children: items),
    );
  }
}

// ─── Item ─────────────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int badgeCount; // IMPROVEMENT: numeric badge instead of just a dot

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: AppColors.cloviGreen, size: 22),
          // IMPROVEMENT: Badge sits on top-right of the icon, not inline with title text
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.cloviGreen,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      // IMPROVEMENT: Chevron hint for navigation
      trailing: Icon(Icons.chevron_right_rounded,
          size: 18, color: Colors.grey[350]),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // IMPROVEMENT: Subtle green tint on hover/splash
      hoverColor: AppColors.cloviGreen.withOpacity(0.05),
      splashColor: AppColors.cloviGreen.withOpacity(0.08),
    );
  }
}

// ─── Logout ───────────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Déconnexion',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withOpacity(0.5)),
          minimumSize: const Size(double.infinity, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          // IMPROVEMENT: Light red tint background on the button
          backgroundColor: AppColors.error.withOpacity(0.04),
        ),
      ),
    );
  }
}