import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

/// Routes qui ne doivent pas recevoir le token (authentification en cours)
const _publicPaths = ['/auth/register', '/auth/login'];

/// Intercepteur pour ajouter le token d'authentification aux requêtes
class ApiInterceptor extends Interceptor {
  final Ref _ref;

  ApiInterceptor(this._ref);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.uri.path;
    final isPublic = _publicPaths.any((p) => path.endsWith(p) || path.contains(p));
    if (isPublic) {
      return handler.next(options);
    }

    // Récupérer le token depuis le stockage local (ou le provider)
    final token = _ref.read(authTokenProvider);

    // Ajouter le token aux headers si disponible
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Gestion des erreurs globales
    if (err.response?.statusCode == 401) {
      // Tenter de rafraîchir le token via Firebase avant de déconnecter
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // 1. Obtenir un nouveau token Firebase ID
          final idToken = await user.getIdToken(true); // true pour forcer le rafraîchissement
          
          if (idToken != null) {
            // 2. Synchroniser avec le backend pour obtenir un nouveau JWT
            final result = await _ref.read(authServiceProvider).syncWithBackend(idToken);
            final newToken = result['accessToken'];
            
            if (newToken != null) {
              // 3. Mettre à jour le provider (ce qui mettra à jour l'intercepteur pour les prochaines requêtes)
              _ref.read(authTokenProvider.notifier).state = newToken;
              
              // 4. Réessayer la requête originale avec le nouveau token
              final options = err.requestOptions;
              options.headers['Authorization'] = 'Bearer $newToken';
              
              final dio = Dio(); // Utiliser une instance propre pour éviter les boucles d'intercepteurs
              final response = await dio.fetch(options);
              return handler.resolve(response);
            }
          }
        } catch (e) {
          print('Token refresh failed: $e');
        }
      }
      
      // Si le rafraîchissement échoue ou pas de user, redirection vers login
      _handleUnauthorized();
    }
    
    return handler.next(err);
  }
  
  Future<void> _handleUnauthorized() async {
    // 1. Nettoyer le stockage local
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyUserId);
    
    // 2. Mettre à jour le provider d'auth pour déclencher la redirection GoRouter
    _ref.read(authTokenProvider.notifier).state = null;
    
    // 3. Réinitialiser également l'auth state si nécessaire
    _ref.invalidate(isAuthenticatedProvider);
  }
}
