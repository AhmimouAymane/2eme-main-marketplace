import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'package:marketplace_app/shared/models/user_model.dart';

/// Écran de profil utilisateur — design aligné avec le reste de l'app (Clovi)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      // backgroundColor: AppColors.cloviBeige, // Inherited from theme
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
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(userProfileProvider);
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          _buildProfileCard(context, user),
                          const SizedBox(height: 24),
                          _buildMenuSection(context, ref, user),
                          const SizedBox(height: 100),
                        ],
                      ),
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
            backgroundColor: Colors.grey[200],
            backgroundImage:
                user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                ? const Icon(Icons.person, size: 48, color: Colors.grey)
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStat(user.salesCount.toString(), 'Ventes'),
              _buildVerticalDivider(),
              _buildStat(user.products?.length.toString() ?? '0', 'Articles'),
              _buildVerticalDivider(),
              _buildStat(
                user.averageRating == 0 ? '—' : user.averageRating.toStringAsFixed(1), 
                'Note',
                isRating: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
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

  Widget _buildStat(String value, String label, {bool isRating = false}) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cloviGreen,
                ),
              ),
              if (isRating && value != '—') ...[
                const SizedBox(width: 4),
                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref, UserModel user) {
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
          /*_buildMenuTile(
            icon: Icons.chat_bubble_outline,
            title: 'Messages',
            onTap: () => context.push(AppRoutes.conversations),
          ),*/
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
            icon: Icons.account_balance_wallet_outlined,
            title: 'Mon portefeuille',
            onTap: () => context.push(AppRoutes.wallet),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.verified_user_outlined,
            title: 'Vérification du compte',
            onTap: () => context.push(AppRoutes.sellerVerification),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.location_on_outlined,
            title: 'Adresses',
            onTap: () => context.push(AppRoutes.addresses),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.star_outline_rounded,
            title: 'Mes avis',
            onTap: () => _showReviewsBottomSheet(context, ref, user),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.help_outline,
            title: 'Aide & Support',
            onTap: () => context.push(AppRoutes.helpSupport),
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.info_outline,
            title: 'À propos',
            onTap: () => context.push(AppRoutes.about),
          ),
          _buildDivider(),
          /*_buildMenuTile(
            icon: Icons.delete_forever_outlined,
            title: 'Supprimer mon compte',
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () => _showDeleteAccountDialog(context, ref),
          ),*/
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
              ref.invalidate(userAvatarUrlProvider);
              ref.invalidate(userProfileProvider);
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

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Cette action est irréversible. Votre compte sera supprimé de Clovi et de Firebase. Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // 1. Delete on backend (syncs with Firebase)
                await ref.read(usersServiceProvider).deleteAccount();

                // 2. Local logout
                await ref.read(authServiceProvider).logout();
                ref.read(authTokenProvider.notifier).state = null;
                ref.invalidate(userEmailProvider);
                ref.invalidate(userIdProvider);
                ref.invalidate(isAuthenticatedProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Compte supprimé avec succès'),
                      backgroundColor: AppColors.cloviGreen,
                    ),
                  );
                  context.go(AppRoutes.login);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la suppression : $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }

  void _showReviewsBottomSheet(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.cloviBeige,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Mes avis reçus',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
              Expanded(
                child: user.receivedReviews == null || user.receivedReviews!.isEmpty
                    ? const Center(
                        child: Text(
                          'Vous n\'avez pas encore reçu d\'avis.',
                          style: TextStyle(color: AppColors.textSecondaryLight),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: user.receivedReviews!.length,
                        itemBuilder: (context, index) {
                          final review = user.receivedReviews![index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      review.reviewer?.fullName ?? 'Utilisateur Clovi',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Row(
                                      children: List.generate(5, (starIndex) {
                                        return Icon(
                                          starIndex < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                          color: starIndex < review.rating ? Colors.amber : Colors.grey[300],
                                          size: 16,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                if (review.comment != null && review.comment!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    review.comment!,
                                    style: TextStyle(color: Colors.grey[800], fontSize: 13),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  Formatters.date(review.createdAt),
                                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
