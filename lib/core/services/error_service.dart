import 'package:flutter/foundation.dart';

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  /// Gère les erreurs de manière centralisée
  void handleError(dynamic error, {String? context}) {
    if (kDebugMode) {
      print('❌ Erreur${context != null ? ' dans $context' : ''}: $error');
    }
    
    // Ici tu peux ajouter d'autres logiques comme :
    // - Envoyer l'erreur à un service de monitoring
    // - Afficher une notification à l'utilisateur
    // - Logger l'erreur dans un fichier
  }

  /// Convertit une exception en message utilisateur
  String getUserFriendlyMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      
      if (message.contains('Erreur de connexion réseau')) {
        return 'Vérifiez votre connexion internet et réessayez.';
      } else if (message.contains('Délai d\'attente dépassé')) {
        return 'La requête a pris trop de temps. Veuillez réessayer.';
      } else if (message.contains('Session expirée')) {
        return 'Votre session a expiré. Veuillez vous reconnecter.';
      } else if (message.contains('Accès refusé')) {
        return 'Vous n\'avez pas les permissions nécessaires.';
      } else if (message.contains('Ressource non trouvée')) {
        return 'La ressource demandée n\'existe pas.';
      } else if (message.contains('Erreur serveur')) {
        return 'Le serveur rencontre des difficultés. Veuillez réessayer plus tard.';
      }
    }
    
    return 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
  }

  /// Vérifie si une erreur est récupérable
  bool isRecoverableError(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      return message.contains('Erreur de connexion réseau') ||
             message.contains('Délai d\'attente dépassé') ||
             message.contains('Erreur serveur');
    }
    return false;
  }
} 