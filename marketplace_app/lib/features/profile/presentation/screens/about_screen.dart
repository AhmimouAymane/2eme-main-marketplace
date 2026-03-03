import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'legal_screen.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';

/// Écran À propos — présentation de Clovi
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.cloviGreen),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.profile),
        ),
        title: const Text(
          'À propos',
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
            // App Logo & Version
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.only(bottom: 24),
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
                    Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Clovi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cloviGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'La marketplace marocaine de vêtements de seconde main. '
                      'Achetez, vendez et donnez une seconde vie à vos articles préférés.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Features Section
            _sectionTitle('Ce que nous offrons'),
            _buildCard(
              child: Column(
                children: const [
                  _FeatureTile(
                    icon: Icons.recycling_rounded,
                    title: 'Mode durable',
                    subtitle: 'Contribuez à la mode circulaire en donnant une seconde vie aux vêtements.',
                  ),
                  Divider(height: 1, indent: 56),
                  _FeatureTile(
                    icon: Icons.verified_user_outlined,
                    title: 'Transactions sécurisées',
                    subtitle: 'Politique de retour de 48h et paiements protégés.',
                  ),
                  Divider(height: 1, indent: 56),
                  _FeatureTile(
                    icon: Icons.people_outline,
                    title: 'Communauté',
                    subtitle: 'Rejoignez des milliers de passionnés de mode au Maroc.',
                  ),
                  Divider(height: 1, indent: 56),
                  _FeatureTile(
                    icon: Icons.local_shipping_outlined,
                    title: 'Livraison nationale',
                    subtitle: 'Envoi dans tout le Maroc avec suivi de colis.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Legal Section
            _sectionTitle('Informations légales'),
            _buildCard(
              child: Column(
                children: [
                  _buildLegalTile(
                    icon: Icons.description_outlined,
                    title: 'Conditions générales d\'utilisation',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CguScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildLegalTile(
                    icon: Icons.assignment_return_outlined,
                    title: 'Politique de remboursement',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RefundPolicyScreen()),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildLegalTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Politique de confidentialité',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LegalScreen(
                          title: 'Politique de confidentialité',
                          sections: const [
                            LegalSection(
                              title: 'Collecte et utilisation des données',
                              intro: 'Nous collectons vos données personnelles pour :',
                              bullets: [
                                'La gestion de votre compte',
                                'L\'exécution des transactions',
                                'La communication entre Utilisateurs',
                                'L\'amélioration de nos services',
                              ],
                              footer:
                                  'Vos données ne sont jamais partagées avec des tiers sans votre consentement explicite.',
                            ),
                            LegalSection(
                              title: 'Vos droits',
                              intro: 'Vous disposez d\'un droit de :',
                              bullets: [
                                'Accès à vos données personnelles',
                                'Rectification des informations inexactes',
                                'Suppression de votre compte et de vos données',
                              ],
                              footer:
                                  'Pour exercer vos droits, rendez-vous dans les paramètres de votre compte ou contactez-nous à support@clovi.ma.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildLegalTile(
                    icon: Icons.gavel_outlined,
                    title: 'Mentions légales',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LegalScreen(
                          title: 'Mentions légales',
                          sections: const [
                            LegalSection(
                              title: 'Éditeur de la Plateforme',
                              bullets: [
                                'Nom : Clovi',
                                'Pays : Maroc',
                                'Email : support@clovi.ma',
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Social Links
            _sectionTitle('Suivez-nous'),
            _buildCard(
              child: const Column(
                children: [
                  _FeatureTile(
                    icon: Icons.camera_alt_outlined,
                    title: 'Instagram',
                    subtitle: '@clovi.ma',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Copyright Footer
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: const Text(
                  '© 2026 Clovi. Tous droits réservés.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),
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

  Widget _buildLegalTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.cloviGreen, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
      onTap: onTap,
    );
  }

}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.cloviGreen, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
      ),
    );
  }
}
