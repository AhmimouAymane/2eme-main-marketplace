import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/shared/widgets/clovi_bottom_nav.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';

/// Shell persistant avec la barre de navigation du bas.
/// La barre reste fixe pendant la navigation entre les onglets.
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  // Mapping: index dans la barre → branche du shell
  Future<void> _onItemTapped(BuildContext context, WidgetRef ref, int index) async {
    if (index == 2) {
      // Le bouton "+" ouvre une page modale, pas un onglet
      
      // 1. Forcer un rafraîchissement du profil pour avoir le statut réel (évite le cache périmé)
      // On affiche un loader discret si besoin, ou on attend simplement la réponse
      try {
        final profile = await ref.refresh(userProfileProvider.future);
        
        if (profile == null || !profile.isSellerVerified) {
          // Si non vérifié, on bloque et on redirige
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vous devez faire vérifier votre compte pour vendre des articles.'),
                backgroundColor: AppColors.cloviDarkGreen,
              ),
            );
            context.push(AppRoutes.sellerVerification);
          }
          return;
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de vérification : $e')),
          );
        }
        return;
      }

      if (context.mounted) {
        context.push(AppRoutes.createProduct);
      }
      return;
    }

    // Convertit l'index barre (0,1,3,4) → branche shell (0,1,2,3)
    final branchIndex = index < 2 ? index : index - 1;

    // SCROLL TO TOP FEATURE
    // Si on clique sur l'onglet Accueil alors qu'on y est déjà, on envoie un signal pour scroller en haut
    if (branchIndex == 0 && navigationShell.currentIndex == 0) {
      ref.read(homeScrollSignalProvider.notifier).state++;
    }

    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  // Branche shell (0,1,2,3) → index affiché dans la barre (0,1,3,4)
  int get _selectedBarIndex {
    final i = navigationShell.currentIndex;
    return i < 2 ? i : i + 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('DEBUG: AppShell Build - currentIndex: ${navigationShell.currentIndex}');
    return PopScope(
      canPop: false, // On intercepte tout pour gérer le retour inter-onglets
      onPopInvokedWithResult: (didPop, result) {
        final currentIndex = navigationShell.currentIndex;
        
        // Même si didPop est vrai (ce qui ne devrait pas arriver avec canPop: false), 
        // on essaie quand même de gérer la navigation si on est dans le shell.
        
        if (currentIndex != 0) {
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Retour à l'onglet Accueil..."),
                duration: Duration(seconds: 1),
                backgroundColor: Colors.black87,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          
          navigationShell.goBranch(0);
        } else {
          // On est sur l'accueil, on vérifie si on est en haut (avec petite marge de 20px)
          final isAtTop = ref.read(isHomeAtTopProvider);
          
          if (!isAtTop) {
            ref.read(homeScrollSignalProvider.notifier).state++;
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Retour en haut de page..."),
                  duration: Duration(seconds: 1),
                  backgroundColor: Colors.black87,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: CloviBottomNav(
          selectedIndex: _selectedBarIndex,
          onItemTapped: (index) => _onItemTapped(context, ref, index),
        ),
      ),
    );
  }
}
