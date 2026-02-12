import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'package:marketplace_app/shared/services/api_client.dart';
import 'package:marketplace_app/features/auth/data/auth_service.dart';

/// Provider pour le token (synchrone pour l'intercepteur)
final authTokenProvider = StateProvider<String?>((ref) => null);

/// Provider pour le client Dio
final dioProvider = Provider<Dio>((ref) {
  // On ne regarde pas le token ici pour éviter de recréer Dio à chaque fois
  // L'intercepteur s'en chargera
  return ApiClient.instance;
});

/// Provider pour le service d'authentification
final authServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AuthService(dio);
});

/// État de l'authentification
final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  return ref.watch(authServiceProvider).isAuthenticated();
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
