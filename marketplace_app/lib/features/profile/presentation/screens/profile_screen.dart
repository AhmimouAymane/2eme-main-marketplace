import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../shared/providers/shop_providers.dart';

/// Écran de profil utilisateur
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Ouvrir les paramètres
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Utilisateur non trouvé'));
          }
          return ListView(
            children: [
              // Header avec avatar et info
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary,
                      backgroundImage: user.avatarUrl != null 
                          ? NetworkImage(user.avatarUrl!) 
                          : null,
                      child: user.avatarUrl == null 
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          user.bio!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.editProfile),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier le profil'),
                    ),
                  ],
                ),
              ),

          // Statistiques
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Achats',
                    value: '12',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.sell_outlined,
                    label: 'Ventes',
                    value: '8',
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.favorites),
                    child: _buildStatCard(
                      icon: Icons.favorite_outline,
                      label: 'Favoris',
                      value: '24',
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Menu
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.message_outlined,
            title: 'Messages',
            onTap: () => context.push(AppRoutes.conversations),
          ),
          _buildMenuItem(
            icon: Icons.inventory_2_outlined,
            title: 'Mes annonces',
            onTap: () => context.push(AppRoutes.myProducts),
          ),
          _buildMenuItem(
            icon: Icons.favorite_outline,
            title: 'Mes favoris',
            onTap: () => context.push(AppRoutes.favorites),
          ),
          _buildMenuItem(
            icon: Icons.receipt_long_outlined,
            title: 'Mes commandes',
            onTap: () => context.push(AppRoutes.orders),
          ),
          _buildMenuItem(
            icon: Icons.payment_outlined,
            title: 'Moyens de paiement',
            onTap: () {
              // TODO: Naviguer vers moyens de paiement
            },
          ),
          _buildMenuItem(
            icon: Icons.location_on_outlined,
            title: 'Adresses',
            onTap: () {
              // TODO: Naviguer vers adresses
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Aide & Support',
            onTap: () {
              // TODO: Naviguer vers aide
            },
          ),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'À propos',
            onTap: () {
              // TODO: Naviguer vers à propos
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Se déconnecter',
            textColor: AppColors.error,
            onTap: () {
              _showLogoutDialog(context, ref);
            },
          ),
          const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur : $e')),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authServiceProvider).logout();
              
              // Réinitialiser les providers
              ref.read(authTokenProvider.notifier).state = null;
              ref.invalidate(userEmailProvider);
              ref.invalidate(userIdProvider);
              ref.invalidate(isAuthenticatedProvider);
              
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
