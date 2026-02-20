import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/shared/widgets/clovi_bottom_nav.dart';

/// Shell persistant avec la barre de navigation du bas.
/// La barre reste fixe pendant la navigation entre les onglets.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  // Mapping: index dans la barre → branche du shell
  void _onItemTapped(BuildContext context, int index) {
    if (index == 2) {
      // Le bouton "+" ouvre une page modale, pas un onglet
      context.push(AppRoutes.createProduct);
      return;
    }

    // Convertit l'index barre (0,1,3,4) → branche shell (0,1,2,3)
    final branchIndex = index < 2 ? index : index - 1;
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CloviBottomNav(
        selectedIndex: _selectedBarIndex,
        onItemTapped: (index) => _onItemTapped(context, index),
      ),
    );
  }
}
