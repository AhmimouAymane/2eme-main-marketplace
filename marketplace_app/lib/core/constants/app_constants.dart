import 'dart:io';

/// Constantes de l'application marketplace
class AppConstants {
  // API Configuration
  static String get apiBaseUrl {
    // Note: Utilisation de l'IP locale (192.168.100.118) pour permettre la connexion depuis un téléphone physique
    // Assurez-vous que le téléphone et le PC sont sur le même réseau Wi-Fi.
    if (Platform.isAndroid) {
      return 'http://192.168.100.118:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  static String get mediaBaseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.100.118:8080';
    }
    return 'http://localhost:8080';
  }
  
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyThemeMode = 'theme_mode';
  
  // Pagination
  static const int itemsPerPage = 20;
  static const int maxImageUpload = 5;
  
  // Image
  static const double maxImageSizeMB = 5.0;
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxProductTitleLength = 100;
  static const int maxProductDescriptionLength = 1000;
  
  // Currency
  static const String currencySymbol = '€';
  static const String currencyCode = 'EUR';
  
  // App Info
  static const String appName = 'Marketplace';
  static const String appVersion = '1.0.0';
}
