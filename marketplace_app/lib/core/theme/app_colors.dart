import 'package:flutter/material.dart';

/// Définition des couleurs de l'application marketplace
class AppColors {
  // Couleurs principales (Clovie Theme)
  static const Color cloviGreen = Color(0xFF1B4332);
  static const Color cloviDarkGreen = Color(0xFF1B4332);
  static const Color cloviBeige = Color(0xFFF5F5F0);
  
  // Aliases pour le thème global
  static const Color primary = cloviGreen;
  static const Color primaryLight = Color(0xFF4B8573);
  static const Color primaryDark = cloviDarkGreen;

  
  static const Color secondary = cloviDarkGreen;
  static const Color secondaryLight = cloviGreen;
  static const Color secondaryDark = Color(0xFF0D281D);
  
  // Couleurs de fond
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // Couleurs de texte
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  
  // Couleurs de statut
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);
  
  // Couleurs supplémentaires
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1F000000);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
