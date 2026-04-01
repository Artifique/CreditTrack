import 'dart:io';

import 'package:flutter/material.dart';

class UserFeedback {
  static Future<void> showErrorModal(BuildContext context, Object error) {
    final message = toReadableMessage(error);
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> showSuccessModal(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Succès'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static String toReadableMessage(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();

    if (error is SocketException || lower.contains('failed host lookup')) {
      return "Connexion internet indisponible. Vérifie ton réseau puis réessaie.";
    }
    if (lower.contains('invalid login credentials')) {
      return "Email ou mot de passe incorrect.";
    }
    if (lower.contains('user already registered')) {
      return "Cet email est déjà utilisé. Connecte-toi ou change d'email.";
    }
    if (lower.contains('permission denied') || lower.contains('row-level security')) {
      return "Action non autorisée. Vérifie les permissions de ton compte.";
    }
    if (lower.contains('timeout')) {
      return "Le serveur met trop de temps à répondre. Réessaie dans un instant.";
    }
    return "Une erreur est survenue. Détail: $raw";
  }
}
