import 'package:flutter/material.dart';
import '../../core/tokens.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  danger,
}

enum AppButtonSize {
  sm,
  md,
  lg,
}

/// Standardized Design System Button with variants, sizes, micro-interactions,
/// loading state and accessibility compliance (min 44x44px target).
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final bool minTouchTarget;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.minTouchTarget = true,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    // Heights & Font sizes according to size tokens
    final double height;
    final double fontSize;
    final double horizontalPadding;
    final double iconSize;

    switch (widget.size) {
      case AppButtonSize.sm:
        height = 36.0;
        fontSize = 13.0;
        horizontalPadding = 12.0;
        iconSize = 16.0;
        break;
      case AppButtonSize.md:
        height = 44.0;
        fontSize = 14.5;
        horizontalPadding = 18.0;
        iconSize = 18.0;
        break;
      case AppButtonSize.lg:
        height = 52.0;
        fontSize = 16.0;
        horizontalPadding = 24.0;
        iconSize = 20.0;
        break;
    }

    // Colors per variant and state
    Color bgColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;
    List<BoxShadow> shadows = [];

    switch (widget.variant) {
      case AppButtonVariant.primary:
        if (!isEnabled) {
          bgColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
          textColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
        } else {
          bgColor = _isPressed
              ? AppTokens.primary700
              : (_isHovered ? AppTokens.primary600 : AppTokens.primary500);
          textColor = Colors.white;
          if (_isHovered && !_isPressed) {
            shadows = AppTokens.shadowGlow(AppTokens.primary500);
          }
        }
        break;

      case AppButtonVariant.secondary:
        if (!isEnabled) {
          bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
          textColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
        } else {
          bgColor = _isPressed
              ? AppTokens.secondary700
              : (_isHovered ? AppTokens.secondary600 : AppTokens.secondary500);
          textColor = Colors.white;
          if (_isHovered && !_isPressed) {
            shadows = AppTokens.shadowGlow(AppTokens.secondary500);
          }
        }
        break;

      case AppButtonVariant.outline:
        bgColor = _isHovered
            ? (isDark ? const Color(0x1AFFFFFF) : const Color(0x0F6366F1))
            : Colors.transparent;
        if (!isEnabled) {
          textColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
          borderSide = BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.2,
          );
        } else {
          textColor = isDark ? AppTokens.primary300 : AppTokens.primary600;
          borderSide = BorderSide(
            color: _isHovered ? AppTokens.primary500 : (isDark ? AppTokens.darkBorder : AppTokens.lightBorder),
            width: 1.5,
          );
        }
        break;

      case AppButtonVariant.ghost:
        bgColor = _isHovered
            ? (isDark ? const Color(0x1AFFFFFF) : const Color(0x100F172A))
            : Colors.transparent;
        textColor = !isEnabled
            ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
            : (isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary);
        break;

      case AppButtonVariant.danger:
        if (!isEnabled) {
          bgColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
          textColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
        } else {
          bgColor = _isPressed
              ? const Color(0xFFB91C1C)
              : (_isHovered ? const Color(0xFFDC2626) : AppTokens.error);
          textColor = Colors.white;
          if (_isHovered && !_isPressed) {
            shadows = AppTokens.shadowGlow(AppTokens.error);
          }
        }
        break;
    }

    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: iconSize, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: 0.1,
          ),
        ),
        if (widget.trailingIcon != null && !widget.isLoading) ...[
          const SizedBox(width: 8),
          Icon(widget.trailingIcon, size: iconSize, color: textColor),
        ],
      ],
    );

    Widget button = MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (isEnabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (isEnabled) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (isEnabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (isEnabled) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (isEnabled) setState(() => _isPressed = false);
        },
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : (_isHovered ? 1.01 : 1.0),
          duration: AppTokens.durationFast,
          curve: AppTokens.curveStandard,
          child: AnimatedContainer(
            duration: AppTokens.durationFast,
            height: height,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
              boxShadow: shadows,
            ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );

    // Ensure min touch target of 44x44
    if (widget.minTouchTarget && height < AppTokens.minTouchTarget) {
      button = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTokens.minTouchTarget),
        child: Center(child: button),
      );
    }

    if (widget.isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
