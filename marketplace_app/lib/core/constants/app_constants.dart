import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Constantes de l'application marketplace
class AppConstants {

  // API Configuration
  static String get apiBaseUrl {
    // Android Emulator
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1/';
    }

    // Web ou Desktop
    return 'http://localhost:8080/api/v1/';
  }

  static String get mediaBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080/';
    }

    return 'http://localhost:8080/';
  }

  static const Duration apiTimeout = Duration(seconds: 60);

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserAvatarUrl = 'user_avatar_url';
  static const String keyThemeMode = 'theme_mode';

  // Pagination
  static const int itemsPerPage = 20;
  static const int maxImageUpload = 5;

  // Image
  static const double maxImageSizeMB = 5.0;
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  // Validation
  static const int minPasswordLength = 8;
  static const int maxProductTitleLength = 100;
  static const int maxProductDescriptionLength = 1000;

  // Currency
  static const String currencySymbol = 'DH';
  static const String currencyCode = 'MAD';

  // App Info
  static const String appName = 'Marketplace';
  static const String appVersion = '1.0.0';
} 