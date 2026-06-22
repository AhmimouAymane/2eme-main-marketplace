import 'dart:io';
import 'package:dio/dio.dart';

String friendlyError(Object e) {
  if (e is DioException) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Le serveur met trop de temps à répondre. Réessayez plus tard.';
      case DioExceptionType.connectionError:
        if (e.error is SocketException) {
          return 'Impossible de joindre le serveur. Vérifiez votre connexion internet.';
        }
        return 'Erreur de connexion. Vérifiez votre connexion internet.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          final msg = data['message'] is List
              ? (data['message'] as List).join(', ')
              : data['message'].toString();
          return msg;
        }
        if (statusCode == 401) return 'Session expirée. Connectez-vous à nouveau.';
        if (statusCode == 403) return 'Accès non autorisé.';
        if (statusCode == 404) return 'Ressource introuvable.';
        if (statusCode == 409) return 'Conflit avec une opération en cours.';
        if (statusCode == 422) return 'Données invalides. Vérifiez les champs.';
        if (statusCode == 429) return 'Trop de requêtes. Réessayez dans quelques instants.';
        if (statusCode != null && statusCode >= 500) return 'Erreur du serveur. Réessayez plus tard.';
        return 'Une erreur est survenue. Réessayez.';
      case DioExceptionType.cancel:
        return '';
      case DioExceptionType.badCertificate:
        return 'Erreur de sécurité. Vérifiez votre connexion.';
      case DioExceptionType.unknown:
      default:
        if (e.error is SocketException) {
          return 'Impossible de joindre le serveur. Vérifiez votre connexion internet.';
        }
        return 'Une erreur réseau est survenue. Vérifiez votre connexion.';
    }
  }

  final msg = e.toString().replaceAll('Exception: ', '').replaceAll('Error: ', '');

  if (msg.contains('SocketException') || msg.contains('Connection refused')) {
    return 'Impossible de joindre le serveur. Vérifiez votre connexion internet.';
  }
  if (msg.contains('TimeoutException') || msg.contains('timed out')) {
    return 'Le serveur met trop de temps à répondre. Réessayez plus tard.';
  }
  if (msg.contains('FormatException') || msg.contains('Invalid argument') || msg.contains('Invalid double')) {
    return 'Données invalides. Vérifiez les champs.';
  }
  if (msg.contains('canceled') || msg.contains('canceled-by-user')) {
    return '';
  }

  return 'Une erreur est survenue. Réessayez.';
}
