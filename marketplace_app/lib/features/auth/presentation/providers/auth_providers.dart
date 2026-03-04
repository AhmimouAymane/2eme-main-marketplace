import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'package:marketplace_app/shared/services/api_client.dart';
import 'package:marketplace_app/features/auth/data/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marketplace_app/shared/models/user_model.dart';
import 'package:marketplace_app/features/users/data/users_service.dart';

/// Provider pour le token (synchrone pour l'intercepteur)
final authTokenProvider = StateProvider<String?>((ref) => null);

/// Provider pour le client Dio
final dioProvider = Provider<Dio>((ref) {
  // On ne regarde pas le token ici pour éviter de recréer Dio à chaque fois
  // L'intercepteur s'en chargera avec ref.read
  return ApiClient.getInstance(ref);
});

/// Provider pour le service d'authentification
final authServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AuthService(dio, ref);
});

/// État de l'authentification
final isAuthenticatedProvider = Provider<bool>((ref) {
  final token = ref.watch(authTokenProvider);
  return token != null && token.isNotEmpty;
});

/// Provider pour initialiser le token au démarrage
final authInitializerProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString(AppConstants.keyAuthToken);
  
  if (savedToken != null) {
    ref.read(authTokenProvider.notifier).state = savedToken;
    // On synchronise le token FCM au démarrage si on est connecté
    ref.read(authServiceProvider).syncFcmToken(savedToken);
  }

  // Écouter les changements d'auth Firebase pour une synchronisation automatique
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      final currentToken = ref.read(authTokenProvider);
      // Si on a un utilisateur Firebase mais pas de token backend (ou potentiellement expiré)
      if (currentToken == null || currentToken.isEmpty) {
        try {
          final idToken = await user.getIdToken();
          if (idToken != null) {
            await ref.read(authServiceProvider).syncWithBackend(idToken);
          }
        } catch (e) {
          print('Auto-sync error: $e');
        }
      }
    } else {
      // Firebase déconnecté -> Nettoyer le backend token
      ref.read(authTokenProvider.notifier).state = null;
    }
  });
});

/// Provider pour gérer l'état de chargement et les erreurs d'auth
final authStateProvider = StateProvider<AsyncValue<void>>((ref) => const AsyncValue.data(null));

/// Provider pour récupérer l'email de l'utilisateur stocké
final userEmailProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(AppConstants.keyUserEmail);
});

/// Provider pour récupérer l'ID de l'utilisateur stocké
final userIdProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(AppConstants.keyUserId);
});

/// Provider pour récupérer l'URL de l'avatar de l'utilisateur stocké
final userAvatarUrlProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(AppConstants.keyUserAvatarUrl);
});

/// Provider pour le service des utilisateurs
final usersServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return UsersService(dio);
});

/// Provider pour récupérer le profil de l'utilisateur actuel
final userProfileProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  final service = ref.watch(usersServiceProvider);
  final userId = await ref.watch(userIdProvider.future);
  if (userId == null) return null;

  return service.getMe();
});
