import 'package:flutter/material.dart';
import '../../core/tokens.dart';

enum AppBadgeVariant {
  primary,
  secondary,
  success,
  warning,
  error,
  info,
  neutral,
}

enum AppBadgeStyle {
  subtle,
  solid,
  outline,
}

/// Standardized Badge component for tags, status indicators, and transaction types.
class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;
  final AppBadgeStyle style;
  final IconData? icon;
  final bool showDot;
  final double fontSize;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.primary,
    this.style = AppBadgeStyle.subtle,
    this.icon,
    this.showDot = false,
    this.fontSize = 11.5,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color color;
    Color bg;
    Color border;

    switch (variant) {
      case AppBadgeVariant.primary:
        color = isDark ? AppTokens.primary300 : AppTokens.primary600;
        bg = isDark ? const Color(0x336366F1) : AppTokens.primary50;
        border = isDark ? const Color(0x666366F1) : AppTokens.primary200;
        break;

      case AppBadgeVariant.secondary:
        color = isDark ? AppTokens.secondary300 : AppTokens.secondary600;
        bg = isDark ? const Color(0x3310B981) : AppTokens.secondary50;
        border = isDark ? const Color(0x6610B981) : AppTokens.secondary200;
        break;

      case AppBadgeVariant.success:
        color = isDark ? AppTokens.darkSuccessText : AppTokens.successText;
        bg = isDark ? AppTokens.darkSuccessBg : AppTokens.successBg;
        border = isDark ? const Color(0x4D10B981) : const Color(0xFFA7F3D0);
        break;

      case AppBadgeVariant.warning:
        color = isDark ? AppTokens.darkWarningText : AppTokens.warningText;
        bg = isDark ? AppTokens.darkWarningBg : AppTokens.warningBg;
        border = isDark ? const Color(0x4DF59E0B) : const Color(0xFFFDE68A);
        break;

      case AppBadgeVariant.error:
        color = isDark ? AppTokens.darkErrorText : AppTokens.errorText;
        bg = isDark ? AppTokens.darkErrorBg : AppTokens.errorBg;
        border = isDark ? const Color(0x4DEF4444) : const Color(0xFFFECACA);
        break;

      case AppBadgeVariant.info:
        color = isDark ? AppTokens.darkInfoText : AppTokens.infoText;
        bg = isDark ? AppTokens.darkInfoBg : AppTokens.infoBg;
        border = isDark ? const Color(0x4D3B82F6) : const Color(0xFFBFDBFE);
        break;

      case AppBadgeVariant.neutral:
        color = isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary;
        bg = isDark ? AppTokens.darkBgSubtle : AppTokens.lightBgSubtle;
        border = isDark ? AppTokens.darkBorder : AppTokens.lightBorder;
        break;
    }

    Color effectiveBg;
    Color effectiveText;
    Border? effectiveBorder;

    switch (style) {
      case AppBadgeStyle.subtle:
        effectiveBg = bg;
        effectiveText = color;
        effectiveBorder = Border.all(color: border, width: 0.8);
        break;

      case AppBadgeStyle.solid:
        effectiveBg = color;
        effectiveText = Colors.white;
        break;

      case AppBadgeStyle.outline:
        effectiveBg = Colors.transparent;
        effectiveText = color;
        effectiveBorder = Border.all(color: border, width: 1.2);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: effectiveBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: effectiveText,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: effectiveText),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: effectiveText,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
