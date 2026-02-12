import '../constants/app_constants.dart';

/// Fonctions de validation pour les formulaires
class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }
    
    return null;
  }
  
  // Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    
    if (value.length < AppConstants.minPasswordLength) {
      return 'Le mot de passe doit contenir au moins ${AppConstants.minPasswordLength} caractères';
    }
    
    return null;
  }
  
  // Required field validation
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    return null;
  }
  
  // Price validation
  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le prix est requis';
    }
    
    final price = double.tryParse(value);
    if (price == null) {
      return 'Prix invalide';
    }
    
    if (price <= 0) {
      return 'Le prix doit être supérieur à 0';
    }
    
    return null;
  }
  
  // Phone validation
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\s+'), ''))) {
      return 'Numéro de téléphone invalide';
    }
    
    return null;
  }
  
  // Product title validation
  static String? productTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le titre est requis';
    }
    
    if (value.length > AppConstants.maxProductTitleLength) {
      return 'Le titre ne peut pas dépasser ${AppConstants.maxProductTitleLength} caractères';
    }
    
    return null;
  }
  
  // Product description validation
  static String? productDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'La description est requise';
    }
    
    if (value.length > AppConstants.maxProductDescriptionLength) {
      return 'La description ne peut pas dépasser ${AppConstants.maxProductDescriptionLength} caractères';
    }
    
    return null;
  }
}
