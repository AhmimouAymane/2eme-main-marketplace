import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'package:marketplace_app/shared/services/api_client.dart';
import 'package:marketplace_app/shared/widgets/clovi_logo.dart';

class CloviDrawer extends ConsumerWidget {
  const CloviDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userEmail = ref.watch(userEmailProvider);
    
    return Drawer(
      backgroundColor: AppColors.cloviBeige,
      child: Column(
        children: [
          _buildHeader(context, userEmail.maybeWhen(data: (email) => email, orElse: () => null)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'Mon Profil',
                  onTap: () {
                    context.pop(); // Fermer le drawer
                    context.push(AppRoutes.profile);
                  },
                ),
                _buildMenuItem(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Mes Commandes',
                  onTap: () {
                    context.pop();
                    context.push(AppRoutes.orders);
                  },
                ),
                _buildMenuItem(
                  icon: Icons.favorite_border,
                  title: 'Mes Favoris',
                  onTap: () {
                    context.pop();
                    context.push(AppRoutes.favorites);
                  },
                ),
                _buildMenuItem(
                  icon: Icons.chat_bubble_outline,
                  title: 'Messages',
                  onTap: () {
                    context.pop();
                    context.push(AppRoutes.conversations);
                  },
                ),
                const Divider(height: 32, indent: 20, endIndent: 20),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'Aide & Support',
                  onTap: () {
                    // TODO
                    context.pop();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Paramètres',
                  onTap: () {
                    context.pop();
                    context.pushNamed('settings');
                  },
                ),
              ],
            ),
          ),
          _buildLogoutButton(context, ref),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String? email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
      decoration: const BoxDecoration(
        color: AppColors.cloviGreen,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CloviLogo(size: 40, showText: true, color: Colors.white, fontSize: 28),
          const SizedBox(height: 24),
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: AppColors.cloviGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bienvenue',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      email ?? 'Utilisateur',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.cloviGreen),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.cloviGreen,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: OutlinedButton.icon(
        onPressed: () => _handleLogout(context, ref),
        icon: const Icon(Icons.logout, color: Colors.redAccent),
        label: const Text(
          'Déconnexion',
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    
    ref.read(authTokenProvider.notifier).state = null;
    ref.invalidate(isAuthenticatedProvider);
    ref.invalidate(userEmailProvider);
    ref.invalidate(userIdProvider);
    
    ApiClient.reset();
    
    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }
}
