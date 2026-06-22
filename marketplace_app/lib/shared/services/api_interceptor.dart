import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

/// Routes qui ne doivent pas recevoir le token (authentification en cours)
const _publicPaths = ['/auth/register', '/auth/login', '/auth/refresh'];

/// Intercepteur pour ajouter le token d'authentification aux requêtes
class ApiInterceptor extends Interceptor {
  final Ref _ref;
  bool _isRefreshing = false; // Pour éviter les boucles infinies

  ApiInterceptor(this._ref);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.uri.path;
    final isPublic = _publicPaths.any((p) => path.endsWith(p) || path.contains(p));
    if (isPublic) {
      // Même pour les routes publiques, on vérifie la connexion
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            error: 'Pas de connexion internet',
          ),
        );
      }
      return handler.next(options);
    }

    // Vérifier la connexion internet avant de continuer
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'Pas de connexion internet',
        ),
      );
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
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_isRefreshing) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 401) {
      _isRefreshing = true;
      String? newToken;

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final idToken = await user.getIdToken(true);
          if (idToken != null) {
            final result = await _ref.read(authServiceProvider).syncWithBackend(idToken);
            newToken = result['accessToken'];
          }
        } 
        
        if (newToken == null) {
          newToken = await _ref.read(authServiceProvider).refreshToken();
        }

        if (newToken != null) {
          _ref.read(authTokenProvider.notifier).state = newToken;
          
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          
          final dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl)); 
          try {
            final response = await dio.request(
              options.path,
              data: options.data,
              queryParameters: options.queryParameters,
              options: Options(
                method: options.method,
                headers: options.headers,
                contentType: options.contentType,
              ),
            );
            _isRefreshing = false;
            return handler.resolve(response);
          } catch (_) {
            _isRefreshing = false;
            return handler.next(err);
          }
        }
      } catch (e) {
        print('DEBUG: Auto refresh failed: $e');
      } finally {
        _isRefreshing = false;
      }
      
      _handleUnauthorized();
    }
    
    return handler.next(err);
  }
  
  Future<void> _handleUnauthorized() async {
    // 1. Nettoyer le stockage local complet
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyRefreshToken);
    await prefs.remove(AppConstants.keyUserId);
    
    // 2. Mettre à jour le provider d'auth pour déclencher la redirection GoRouter
    _ref.read(authTokenProvider.notifier).state = null;
    
    // 3. Réinitialiser également l'auth state si nécessaire
    _ref.invalidate(isAuthenticatedProvider);
  }
}
