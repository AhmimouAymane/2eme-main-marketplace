import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

/// Écran affichant un document légal (CGU, Politique de remboursement, etc.)
class LegalScreen extends StatelessWidget {
  final String title;
  final List<LegalSection> sections;

  const LegalScreen({
    super.key,
    required this.title,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.cloviGreen),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.cloviGreen,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        itemCount: sections.length,
        itemBuilder: (context, i) {
          final section = sections[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cloviGreen.withOpacity(0.08),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cloviDarkGreen,
                    ),
                  ),
                ),
                // Section body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (section.intro != null) ...[
                        Text(
                          section.intro!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryLight,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      ...section.bullets.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 7),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.cloviGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  b,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondaryLight,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (section.footer != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          section.footer!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondaryLight,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class LegalSection {
  final String title;
  final String? intro;
  final List<String> bullets;
  final String? footer;

  const LegalSection({
    required this.title,
    this.intro,
    this.bullets = const [],
    this.footer,
  });
}

// ─────────────────────────────────────────────────────────────
// CGU Screen
// ─────────────────────────────────────────────────────────────
class CguScreen extends StatelessWidget {
  const CguScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalScreen(
      title: 'Conditions générales d\'utilisation',
      sections: const [
        LegalSection(
          title: 'Article 1 – Rôle de la plateforme',
          intro:
              'La Plateforme agit exclusivement en qualité d\'intermédiaire technique de mise en relation entre des vendeurs et des acheteurs pour la vente d\'articles de seconde main.',
          bullets: [
            'N\'est ni vendeur ni acheteur des articles proposés',
            'N\'est jamais propriétaire des biens mis en vente',
            'N\'intervient pas dans la négociation entre les Utilisateurs',
            'N\'est pas partie au contrat de vente conclu entre l\'acheteur et le vendeur',
          ],
          footer: 'Le contrat de vente est conclu directement et exclusivement entre les Utilisateurs.',
        ),
        LegalSection(
          title: 'Article 2 – Absence de garantie sur les articles',
          intro: 'La Plateforme ne garantit :',
          bullets: [
            'Ni l\'authenticité des articles',
            'Ni leur conformité',
            'Ni leur qualité',
            'Ni leur état',
            'Ni l\'exactitude des descriptions publiées',
          ],
          footer:
              'Les informations relatives aux articles sont fournies sous la responsabilité exclusive du vendeur. La Plateforme ne procède à aucune vérification physique, expertise ou authentification.',
        ),
        LegalSection(
          title: 'Article 3 – Responsabilité des utilisateurs',
          intro: 'Chaque Utilisateur est seul et entièrement responsable de l\'utilisation de la Plateforme. Chaque Utilisateur garantit :',
          bullets: [
            'L\'exactitude, la sincérité et la licéité des informations publiées',
            'La conformité des articles mis en vente à la réglementation en vigueur',
            'La légitimité de disposer des articles proposés à la vente',
            'L\'absence de violation de droits de tiers (marque, propriété intellectuelle, contrefaçon)',
          ],
          footer: 'La Plateforme ne saurait être tenue responsable des déclarations inexactes, des articles contrefaits, des vices cachés ou des litiges résultant d\'une transaction.',
        ),
        LegalSection(
          title: 'Article 4 – Authentification des articles',
          intro: 'L\'authentification des articles relève exclusivement de la responsabilité de l\'acheteur. Il lui appartient de :',
          bullets: [
            'Vérifier l\'authenticité',
            'Vérifier l\'état général',
            'Vérifier l\'absence de défaut ou de dommage',
            'Vérifier la conformité à la description',
          ],
          footer: 'La Plateforme ne fournit aucun service d\'authentification et ne pourra être tenue responsable d\'un défaut d\'authenticité.',
        ),
        LegalSection(
          title: 'Article 5 – Délai de vérification (48h)',
          intro:
              'À compter de la confirmation de livraison, l\'acheteur dispose d\'un délai strict de 48 heures pour :',
          bullets: [
            'Vérifier l\'article reçu',
            'Signaler toute non-conformité via la Plateforme',
            'Fournir des preuves (photos, vidéos, description détaillée)',
          ],
          footer:
              'Passé ce délai, la transaction est automatiquement considérée comme validée, les fonds sont libérés au vendeur et aucun remboursement ne pourra être exigé. L\'absence de réclamation vaut acceptation définitive.',
        ),
        LegalSection(
          title: 'Article 6 – Réclamations',
          intro: 'Toute réclamation doit :',
          bullets: [
            'Être effectuée exclusivement via la Plateforme',
            'Être soumise dans un délai de 48 heures suivant la livraison',
            'Être accompagnée de preuves suffisantes',
          ],
          footer: 'Toute réclamation tardive, incomplète ou insuffisamment justifiée sera rejetée. La Plateforme se réserve le droit d\'apprécier la validité des éléments fournis.',
        ),
        LegalSection(
          title: 'Article 7 – Fraude et comportements illicites',
          intro:
              'La Plateforme met en œuvre des moyens techniques raisonnables afin de sécuriser les transactions. Toutefois, elle ne pourra être tenue responsable :',
          bullets: [
            'Des comportements frauduleux des Utilisateurs',
            'Des fausses déclarations',
            'De la mise en vente d\'articles contrefaits',
            'Des dommages résultant de l\'utilisation d\'un article acheté',
          ],
          footer: 'Les Utilisateurs reconnaissent utiliser la Plateforme à leurs propres risques.',
        ),
        LegalSection(
          title: 'Article 8 – Frais de service et paiement',
          intro: 'La Plateforme perçoit une commission sur chaque transaction. Le montant de cette commission est :',
          bullets: [
            'Affiché de manière transparente avant validation de la vente',
            'Prélevé automatiquement sur le montant de la transaction',
            'Non remboursable en cas d\'annulation ou de litige',
          ],
          footer:
              'Les frais de livraison sont à la charge de l\'acheteur, sauf mention contraire dans l\'annonce. Le montant net vendeur correspond au prix diminué de la commission et des frais éventuels.',
        ),
        LegalSection(
          title: 'Article 9 – Compte utilisateur',
          intro: 'L\'Utilisateur est seul responsable de la confidentialité de ses identifiants. La Plateforme se réserve le droit de suspendre ou supprimer tout compte en cas de :',
          bullets: [
            'Violation des présentes CGU',
            'Comportement frauduleux ou abusif',
            'Inactivité prolongée (supérieure à 2 ans)',
          ],
        ),
        LegalSection(
          title: 'Article 10 – Propriété intellectuelle',
          intro: 'L\'Utilisateur garantit détenir tous les droits sur les contenus qu\'il publie (photos, descriptions). Il concède à la Plateforme une licence non exclusive pour :',
          bullets: [
            'Reproduire et afficher ces contenus sur la Plateforme',
            'Les utiliser à des fins promotionnelles (avec accord préalable)',
          ],
          footer: 'Toute atteinte aux droits de tiers engage la responsabilité exclusive du vendeur.',
        ),
        LegalSection(
          title: 'Article 11 – Données personnelles',
          intro: 'La Plateforme collecte et traite les données personnelles conformément à sa Politique de Confidentialité. Les données sont utilisées pour :',
          bullets: [
            'La gestion des comptes',
            'L\'exécution des transactions',
            'La communication entre Utilisateurs',
            'L\'amélioration des services',
          ],
          footer: 'L\'Utilisateur dispose d\'un droit d\'accès, de rectification et de suppression de ses données, à exercer via son compte ou par email.',
        ),
        LegalSection(
          title: 'Article 12 – Disponibilité et modifications',
          intro: 'La Plateforme s\'efforce de maintenir un accès continu, sans garantie d\'absence d\'interruption. Elle se réserve le droit de modifier les présentes CGU à tout moment. Les Utilisateurs seront informés par :',
          bullets: [
            'Notification sur la Plateforme',
            'Email',
          ],
          footer: 'L\'utilisation continue après modification vaut acceptation des nouvelles conditions.',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Politique de remboursement Screen
// ─────────────────────────────────────────────────────────────
class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalScreen(
      title: 'Politique de remboursement',
      sections: const [
        LegalSection(
          title: 'Article 1 – Conditions de remboursement',
          intro: 'Un remboursement ne pourra être envisagé que si :',
          bullets: [
            'Une réclamation est déposée dans le délai de 48 heures',
            'L\'article reçu est manifestement non conforme à la description',
            'Les preuves fournies sont jugées suffisantes par la Plateforme',
          ],
        ),
        LegalSection(
          title: 'Article 2 – Exclusions de remboursement',
          intro: 'Aucun remboursement ne sera accordé si :',
          bullets: [
            'Le délai de 48 heures est dépassé',
            'L\'acheteur change d\'avis',
            'Le défaut était visible sur les photos de l\'annonce',
            'L\'article correspond à la description publiée',
          ],
          footer: 'La Plateforme se réserve le droit de trancher tout litige sur la base des éléments fournis.',
        ),
      ],
    );
  }
}
