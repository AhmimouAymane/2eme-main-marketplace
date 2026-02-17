import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../shared/providers/shop_providers.dart';
import '../../../../shared/widgets/clovi_bottom_nav.dart';

/// Écran de profil utilisateur — design aligné avec le reste de l'app (Clovi)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.cloviBeige,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: userAsync.when(
                data: (user) {
                  if (user == null) {
                    return const Center(
                      child: Text(
                        'Utilisateur non trouvé',
                        style: TextStyle(color: AppColors.textSecondaryLight),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        _buildProfileCard(context, user),
                        const SizedBox(height: 24),
                        _buildMenuSection(context, ref),
                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.cloviGreen),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Erreur : $e',
                    style: const TextStyle(color: AppColors.textSecondaryLight),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CloviBottomNav(
        selectedIndex: 4,
        onItemTapped: (index) {
          if (index == 4) return;
          switch (index) {
            case 0:
              context.go(AppRoutes.home);
              break;
            case 1:
              context.go(AppRoutes.search);
              break;
            case 2:
              context.push(AppRoutes.createProduct);
              break;
            case 3:
              context.go(AppRoutes.conversations);
              break;
          }
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 22,
              color: AppColors.cloviGreen,
            ),
            onPressed: () => context.go(AppRoutes.home),
          ),
          const Text(
            'Mon profil',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.cloviGreen,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              size: 24,
              color: AppColors.cloviGreen,
            ),
            onPressed: () => context.pushNamed('settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.cloviGreen,
            backgroundImage:
                user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                ? const Icon(Icons.person, size: 48, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.cloviGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryLight,
            ),
          ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              user.bio!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.editProfile),
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Modifier le profil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cloviDarkGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.chat_bubble_outline,
            title: 'Messages',
            onTap: () => context.push(AppRoutes.conversations),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.inventory_2_outlined,
            title: 'Mes annonces',
            onTap: () => context.push(AppRoutes.myProducts),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.favorite_outline,
            title: 'Mes favoris',
            onTap: () => context.push(AppRoutes.favorites),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.receipt_long_outlined,
            title: 'Mes commandes',
            onTap: () => context.push(AppRoutes.orders),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.payment_outlined,
            title: 'Moyens de paiement',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.location_on_outlined,
            title: 'Adresses',
            onTap: () => context.push(AppRoutes.addresses),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.help_outline,
            title: 'Aide & Support',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.info_outline,
            title: 'À propos',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.logout,
            title: 'Se déconnecter',
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: AppColors.divider.withOpacity(0.5),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    final color = textColor ?? AppColors.textPrimaryLight;
    final iconColorFinal = iconColor ?? AppColors.cloviGreen;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: iconColorFinal, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: textColor ?? AppColors.textSecondaryLight,
        size: 22,
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).logout();
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
