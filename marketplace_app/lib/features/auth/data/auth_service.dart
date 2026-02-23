import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'package:marketplace_app/shared/services/api_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';


/// Service gérant l'authentification côté frontend
class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
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
      final response = await _dio.post('/auth/login', data: {
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
      final response = await _dio.post('/auth/forgot-password', data: {
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
      final response = await _dio.post('/auth/verify-otp', data: {
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
      final response = await _dio.post('/auth/reset-password', data: {
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
      throw e.toString();
    }
  }

  /// Connexion via Apple
  Future<Map<String, dynamic>> signInWithApple() async {
    try {
      // Sur Android, Apple Sign-in nécessite une configuration web (Service ID, Redirect URI)
      // Si non configuré, SignInWithApple.getAppleIDCredential lèvera une exception brute.
      // On peut ajouter un check préalable ou un catch spécifique.
      
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
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) throw 'Impossible d\'obtenir le token Firebase';

      return await syncWithBackend(
        idToken,
        firstName: appleCredential.givenName,
        lastName: appleCredential.familyName,
      );
    } catch (e) {
      if (e.toString().contains('webAuthenticationOptions') || e.toString().contains('Android')) {
        throw 'La connexion Apple n\'est pas encore configurée pour Android. Veuillez utiliser Google ou votre email.';
      }
      throw e.toString();
    }
  }

  /// Synchronisation du token Firebase avec notre backend JWT
  Future<Map<String, dynamic>> syncWithBackend(
    String fbToken, {
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _dio.post('/auth/firebase', data: {
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
    final user = data['user'];
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAuthToken, token);
    if (user != null) {
      await prefs.setString(AppConstants.keyUserId, user['id']);
      await prefs.setString(AppConstants.keyUserEmail, user['email']);
      if (user['avatarUrl'] != null) {
        await prefs.setString(AppConstants.keyUserAvatarUrl, user['avatarUrl']);
      }
    }
    
    // Synchroniser le token FCM
    await syncFcmToken(token);
  }

  /// Synchroniser le token FCM avec le backend
  Future<void> syncFcmToken([String? token]) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await _dio.post(
          '/auth/fcm-token', 
          data: {'token': fcmToken},
          options: token != null 
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
        );
      }
    } catch (e) {
      print('Erreur synchronisation FCM: $e');
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserEmail);
    await prefs.remove(AppConstants.keyUserAvatarUrl);
    ApiClient.reset();
  }

  /// Vérifier si l'utilisateur est connecté
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAuthToken);
    return token != null && token.isNotEmpty;
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
