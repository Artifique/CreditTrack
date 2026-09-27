import 'package:flutter/material.dart';
import '../widgets/ui/app_button.dart';
import '../widgets/ui/app_toast.dart';
import 'tokens.dart';

class UserFeedback {
  /// Shows a modern floating toast message with slide-in micro-animation
  static void showToast(
    BuildContext context,
    String message, {
    String? title,
    AppToastType type = AppToastType.info,
  }) {
    AppToast.show(context, message: message, title: title, type: type);
  }

  static void showSuccessToast(BuildContext context, String message, {String? title}) {
    AppToast.show(context, message: message, title: title, type: AppToastType.success);
  }

  static void showErrorToast(BuildContext context, Object error, {String? title}) {
    final message = toReadableMessage(error);
    AppToast.show(context, message: message, title: title, type: AppToastType.error);
  }

  /// Modern modal dialog with consistent design system tokens
  static Future<void> showErrorModal(BuildContext context, Object error) {
    final message = toReadableMessage(error);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppTokens.darkSurface : AppTokens.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusXl)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppTokens.darkErrorBg : AppTokens.errorBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: AppTokens.error, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Erreur',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
          ),
        ),
        actions: [
          AppButton(
            label: 'Compris',
            size: AppButtonSize.sm,
            variant: AppButtonVariant.primary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  static Future<void> showSuccessModal(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppTokens.darkSurface : AppTokens.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusXl)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppTokens.darkSuccessBg : AppTokens.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: AppTokens.success, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Succès',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
          ),
        ),
        actions: [
          AppButton(
            label: 'OK',
            size: AppButtonSize.sm,
            variant: AppButtonVariant.primary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  static String toReadableMessage(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();

    if (lower.contains('socketexception') || lower.contains('failed host lookup') || lower.contains('network')) {
      return "Connexion internet indisponible. Vérifie ton réseau puis réessaie.";
    }
    if (lower.contains('invalid login credentials') || lower.contains('invalid_credentials')) {
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
