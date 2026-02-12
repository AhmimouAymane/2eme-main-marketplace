import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import 'api_interceptor.dart';

/// Client HTTP Dio configuré pour l'API
class ApiClient {
  static Dio? _dio;
  
  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }
  
  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    // Ajouter les intercepteurs
    dio.interceptors.add(ApiInterceptor());
    
    // Intercepteur de logs en mode debug
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: false,
      ),
    );
    
    return dio;
  }
  
  // Réinitialiser le client (utile après déconnexion)
  static void reset() {
    _dio = null;
  }
}
