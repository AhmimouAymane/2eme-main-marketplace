import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthErrorFormatter {
  static String format(Object e) {
    // Si c'est une annulation volontaire, on renvoie une chaîne spéciale pour l'ignorer
    if (e.toString().contains('canceled') || 
        e.toString().contains('canceled-by-user') ||
        e.toString().contains('error-code-7003') || // Apple Cancel
        e.toString().contains('error-code-1001')) { // Apple Cancel on some platforms
      return 'canceled';
    }

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'Aucun utilisateur trouvé avec cet email.';
        case 'wrong-password':
          return 'Mot de passe incorrect.';
        case 'email-already-in-use':
          return 'Cet email est déjà utilisé par un autre compte.';
        case 'invalid-email':
          return 'L\'adresse email n\'est pas valide.';
        case 'weak-password':
          return 'Le mot de passe est trop faible (8 caractères minimum).';
        case 'user-disabled':
          return 'Ce compte a été désactivé.';
        case 'operation-not-allowed':
          return 'Cette opération n\'est pas autorisée.';
        case 'network-request-failed':
          return 'Erreur réseau. Vérifiez votre connexion internet.';
        case 'too-many-requests':
          return 'Trop de tentatives échouées. Réessayez plus tard.';
        default:
          return 'Une erreur de connexion est survenue (${e.code}).';
      }
    }

    if (e is SignInWithAppleAuthorizationException) {
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          return 'canceled';
        case AuthorizationErrorCode.failed:
          return 'L\'authentification Apple a échoué.';
        case AuthorizationErrorCode.invalidResponse:
          return 'Réponse invalide reçue d\'Apple.';
        case AuthorizationErrorCode.notHandled:
          return 'La demande n\'a pas pu être traitée par le système.';
        case AuthorizationErrorCode.unknown:
          return 'Une erreur inconnue est survenue avec Apple.';
        case AuthorizationErrorCode.notInteractive:
          return 'L\'authentification n\'a pas pu être lancée.';
      }
    }

    // Nettoyage des préfixes d'exception Dart standards
    final message = e.toString().replaceAll('Exception: ', '').replaceAll('Error: ', '');
    
    // Fallback pour les erreurs génériques
    if (message.contains('Invalid credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    
    return message;
  }
}
