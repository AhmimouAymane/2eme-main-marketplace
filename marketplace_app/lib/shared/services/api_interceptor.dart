import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

/// Intercepteur pour ajouter le token d'authentification aux requêtes
class ApiInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Récupérer le token depuis le stockage local
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAuthToken);
    
    // Ajouter le token aux headers si disponible
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    return handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Gestion des erreurs globales
    if (err.response?.statusCode == 401) {
      // Token expiré ou invalide, rediriger vers login
      _handleUnauthorized();
    }
    
    return handler.next(err);
  }
  
  Future<void> _handleUnauthorized() async {
    // Nettoyer le token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyUserId);
    
    // TODO: Rediriger vers l'écran de login
    // Cette logique sera implémentée avec la navigation
  }
}
