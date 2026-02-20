import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

/// Écran Aide & Support — FAQ + contact
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.cloviGreen),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Aide & Support',
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
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cloviGreen,
                    AppColors.cloviGreen.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent_rounded, size: 56, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Comment pouvons-nous vous aider ?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Consultez notre FAQ ou contactez-nous directement.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // FAQ Section
            _sectionTitle('Questions fréquentes'),
            _buildFaqCard([
              _FaqItem(
                question: 'Comment passer une commande ?',
                answer:
                    'Parcourez les articles, sélectionnez celui qui vous plaît, puis appuyez sur "Acheter" ou "Faire une offre". Renseignez votre adresse de livraison et confirmez.',
              ),
              _FaqItem(
                question: 'Puis-je retourner un article ?',
                answer:
                    'Oui, vous disposez d\'un délai de 48 heures après la livraison pour demander un retour. Rendez-vous dans le détail de la commande et cliquez sur "Demander un retour".',
              ),
              _FaqItem(
                question: 'Comment publier une annonce ?',
                answer:
                    'Appuyez sur le bouton "+" en bas de l\'écran, ajoutez vos photos, remplissez les détails (titre, description, catégorie, taille, prix) et publiez !',
              ),
              _FaqItem(
                question: 'Comment contacter un vendeur ?',
                answer:
                    'Sur la page d\'un produit, appuyez sur l\'icône de messagerie pour ouvrir une conversation directe avec le vendeur.',
              ),
              _FaqItem(
                question: 'Quand est-ce que je reçois mon paiement ?',
                answer:
                    'Le paiement est libéré après l\'expiration du délai de retour de 48 heures suivant la confirmation de livraison par l\'acheteur.',
              ),
              _FaqItem(
                question: 'Comment supprimer mon compte ?',
                answer:
                    'Allez dans votre profil, puis faites défiler vers le bas et appuyez sur "Supprimer mon compte". Cette action est irréversible.',
              ),
            ]),
            const SizedBox(height: 24),

            // Contact Section
            _sectionTitle('Contactez-nous'),
            _buildCard(
              child: Column(
                children: [
                  _buildContactTile(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: 'support@clovi.ma',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildContactTile(
                    icon: Icons.phone_outlined,
                    title: 'Téléphone',
                    subtitle: '+212 5XX-XXXXXX',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildContactTile(
                    icon: Icons.chat_outlined,
                    title: 'WhatsApp',
                    subtitle: 'Discutez avec notre équipe',
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

  Widget _buildFaqCard(List<_FaqItem> items) {
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionPanelList.radio(
          elevation: 0,
          expandedHeaderPadding: EdgeInsets.zero,
          children: items.asMap().entries.map((entry) {
            final item = entry.value;
            return ExpansionPanelRadio(
              value: entry.key,
              canTapOnHeader: true,
              headerBuilder: (context, isExpanded) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Icon(
                    Icons.help_outline,
                    color: isExpanded ? AppColors.cloviGreen : AppColors.textSecondaryLight,
                    size: 22,
                  ),
                  title: Text(
                    item.question,
                    style: TextStyle(
                      fontWeight: isExpanded ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                );
              },
              body: Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                child: Text(
                  item.answer,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                    height: 1.5,
                  ),
                ),
              ),
            );
          }).toList(),
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

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.cloviGreen, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}
