import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'package:marketplace_app/shared/services/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';


/// Service gérant l'authentification côté frontend
class AuthService {
  final Dio _dio;
  final Ref _ref;

  AuthService(this._dio, this._ref);

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _dio.post('auth/register', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  /// Connexion de l'utilisateur via notre backend
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('auth/login', data: {
        'email': email,
        'password': password,
      });
      
      final data = response.data;
      if (data['accessToken'] != null) {
        await _saveAuthData(data);
      }
      
      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  /// Mot de passe oublié (Envoi de code OTP via notre backend)
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post('auth/forgot-password', data: {
        'email': email,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  /// Vérification du code OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
    required String type, // 'REGISTRATION' ou 'PASSWORD_RESET'
  }) async {
    try {
      final response = await _dio.post('auth/verify-otp', data: {
        'email': email,
        'code': code,
        'type': type,
      });
      
      final data = response.data;
      
      // Si c'est une vérification d'inscription, on reçoit les tokens
      if (type == 'REGISTRATION' && data['accessToken'] != null) {
        await _saveAuthData(data);
      }
      
      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  /// Réinitialisation du mot de passe
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post('auth/reset-password', data: {
        'email': email,
        'code': code,
        'newPassword': newPassword,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  /// Connexion via Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // 0. Déconnexion préalable pour forcer le choix du compte
      await GoogleSignIn().signOut();

      // 1. Déclencher le flux d'authentification Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) throw 'Connexion annulée par l\'utilisateur';

      // 2. Obtenir les détails d'authentification de la demande
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Créer une nouvelle référence
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Une fois connecté, renvoyer l'UserCredential
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) throw 'Impossible d\'obtenir le token Firebase';

      // 5. Extraire le nom pour la synchronisation
      String? firstName;
      String? lastName;
      
      if (googleUser.displayName != null) {
        final parts = googleUser.displayName!.split(' ');
        firstName = parts[0];
        if (parts.length > 1) {
          lastName = parts.sublist(1).join(' ');
        }
      }

      // 6. Synchroniser avec notre backend
      return await syncWithBackend(
        idToken,
        firstName: firstName,
        lastName: lastName,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Connexion via Apple
  Future<Map<String, dynamic>> signInWithApple() async {
    try {
      String? idToken;
      String? firstName;
      String? lastName;

      if (defaultTargetPlatform == TargetPlatform.android) {
        // Flux NATIF Firebase pour Android (évite l'erreur "missing initial state")
        final appleProvider = AppleAuthProvider();
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithProvider(appleProvider);
        idToken = await userCredential.user?.getIdToken();
        
        // Extraire le nom s'il est disponible (Firebase concatène souvent en displayName)
        final displayName = userCredential.user?.displayName;
        if (displayName != null && displayName.contains(' ')) {
          final parts = displayName.split(' ');
          firstName = parts.first;
          lastName = parts.last;
        } else {
          firstName = displayName;
        }
      } else {
        // Flux natif iOS via le package sign_in_with_apple
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
        final AuthCredential credential = oAuthProvider.credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
        );

        final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        idToken = await userCredential.user?.getIdToken();
        firstName = appleCredential.givenName;
        lastName = appleCredential.familyName;
      }

      if (idToken == null) throw 'Impossible d\'obtenir le token Firebase';

      return await syncWithBackend(
        idToken,
        firstName: firstName,
        lastName: lastName,
      );
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      // On ignore l'erreur si l'utilisateur a juste annulé le processus
      if (errorStr.contains('7003') || errorStr.contains('canceled') || errorStr.contains('1001') || errorStr.contains('cancel')) {
        throw 'canceled';
      }
      rethrow;
    }
  }

  /// Synchronisation du token Firebase avec notre backend JWT
  Future<Map<String, dynamic>> syncWithBackend(
    String fbToken, {
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _dio.post('auth/firebase', data: {
        'token': fbToken,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
      });
      final data = response.data;
      
      final token = data['accessToken'];
      final user = data['user'];
      
      if (token != null) {
        await _saveAuthData(data);
      }
      
      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Sauvegarde les données d'authentification localement
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final token = data['accessToken'];
    final refreshToken = data['refreshToken'];
    final user = data['user'];
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAuthToken, token);
    
    if (refreshToken != null) {
      await prefs.setString(AppConstants.keyRefreshToken, refreshToken);
    }
    
    // Update Riverpod state immediately
    _ref.read(authTokenProvider.notifier).state = token;
    
    if (user != null) {
      await prefs.setString(AppConstants.keyUserId, user['id']);
      await prefs.setString(AppConstants.keyUserEmail, user['email']);
      
      final String fullName = '${user['firstName']} ${user['lastName']}';
      await prefs.setString(AppConstants.keyUserName, fullName);

      if (user['avatarUrl'] != null) {
        await prefs.setString(AppConstants.keyUserAvatarUrl, user['avatarUrl']);
      }
    }
    
    // Invalidate user-related providers to force refresh everywhere
    _ref.invalidate(userEmailProvider);
    _ref.invalidate(userIdProvider);
    _ref.invalidate(userNameProvider);
    _ref.invalidate(userAvatarUrlProvider);
    _ref.invalidate(userProfileProvider);
    
    // Synchroniser le token FCM
    await syncFcmToken();
  }

  /// Synchroniser le token FCM avec le backend
  Future<void> syncFcmToken({String? fcmTokenOverride, int retryCount = 0}) async {
    try {
      final String? sessionToken = _ref.read(authTokenProvider);
      if (sessionToken == null || sessionToken.isEmpty) return;

      // Sur iOS, le token APNS peut mettre quelques secondes à arriver (surtout au 1er lancement)
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null && retryCount < 5) {
          print('DEBUG: [FCM] APNS token non prêt, nouvel essai dans 3s... (Essai ${retryCount + 1}/5)');
          await Future.delayed(const Duration(seconds: 3));
          return syncFcmToken(fcmTokenOverride: fcmTokenOverride, retryCount: retryCount + 1);
        }
      }

      final String? fcmToken = fcmTokenOverride ?? await FirebaseMessaging.instance.getToken();
      if (fcmToken == null && fcmTokenOverride == null) return;
      
      print('DEBUG: [FCM] Syncing token with backend: ${fcmToken?.substring(0, 8)}...');
      
      await _dio.post(
        'auth/fcm-token', 
        data: {'token': fcmToken ?? ''},
        options: Options(headers: {'Authorization': 'Bearer $sessionToken'}),
      );
      print('DEBUG: [FCM] Token synced successfully');
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('apns-token-not-set')) {
        if (retryCount < 3) {
          await Future.delayed(const Duration(seconds: 3));
          return syncFcmToken(fcmTokenOverride: fcmTokenOverride, retryCount: retryCount + 1);
        }
        print('DEBUG: [FCM] Échec définitif : APNS non configuré.');
      } else {
        print('DEBUG: [FCM] Erreur synchronisation : $e');
      }
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      // 1. Informer d'abord le backend d'effacer le token FCM
      // On utilise le sessionToken actuel AVANT de vider le state
      await syncFcmToken(fcmTokenOverride: '');
      
      // 2. Supprimer le token localement auprès de Firebase
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
       print('Erreur lors du nettoyage du token FCM: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyRefreshToken);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(AppConstants.keyUserEmail);
    await prefs.remove(AppConstants.keyUserAvatarUrl);
    
    // Clear Riverpod state
    _ref.read(authTokenProvider.notifier).state = null;
    _ref.invalidate(userEmailProvider);
    _ref.invalidate(userIdProvider);
    _ref.invalidate(userNameProvider);
    _ref.invalidate(userAvatarUrlProvider);
    _ref.invalidate(userProfileProvider);
    _ref.invalidate(isAuthenticatedProvider);
    
    ApiClient.reset();
  }

  /// Vérifier si l'utilisateur est connecté
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAuthToken);
    return token != null && token.isNotEmpty;
  }

  /// Renouveler le token d'accès via le refresh token
  Future<String?> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedRefreshToken = prefs.getString(AppConstants.keyRefreshToken);
      
      if (storedRefreshToken == null || storedRefreshToken.isEmpty) return null;

      final response = await _dio.post('auth/refresh', data: {
        'refreshToken': storedRefreshToken,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final newToken = data['accessToken'];
        final newRefreshToken = data['refreshToken'];

        if (newToken != null) {
          await prefs.setString(AppConstants.keyAuthToken, newToken);
          _ref.read(authTokenProvider.notifier).state = newToken;
        }
        
        if (newRefreshToken != null) {
          await prefs.setString(AppConstants.keyRefreshToken, newRefreshToken);
        }

        return newToken;
      }
      return null;
    } catch (e) {
      print('DEBUG: Refresh token error: $e');
      return null;
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['message'];
      if (message is List) return message.join(', ');
      return message ?? 'Une erreur est survenue';
    }
    return 'Impossible de contacter le serveur';
  }

  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé par un autre compte.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      case 'invalid-email':
        return 'L\'adresse email n\'est pas valide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives infructueuses. Réessayez plus tard.';
      default:
        return e.message ?? 'Une erreur d\'authentification est survenue.';
    }
  }
}
