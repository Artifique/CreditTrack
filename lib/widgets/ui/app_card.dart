import 'package:flutter/material.dart';
import '../../core/tokens.dart';

enum AppCardVariant {
  elevated,
  outlined,
  filled,
  gradient,
  glass,
}

/// Standardized Card component with variants, interactive hover elevation,
/// smooth rounded corners, and theme awareness.
class AppCard extends StatefulWidget {
  final Widget child;
  final AppCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Gradient? customGradient;
  final Color? customBgColor;
  final bool enableHover;

  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.elevated,
    this.onTap,
    this.padding = const EdgeInsets.all(AppTokens.space20),
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.customGradient,
    this.customBgColor,
    this.enableHover = true,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = widget.borderRadius ?? BorderRadius.circular(AppTokens.radiusXl);

    Color bgColor;
    BorderSide borderSide = BorderSide.none;
    List<BoxShadow> shadows = [];
    Gradient? gradient = widget.customGradient;

    switch (widget.variant) {
      case AppCardVariant.elevated:
        bgColor = widget.customBgColor ?? (isDark ? AppTokens.darkSurface : AppTokens.lightSurface);
        borderSide = BorderSide(
          color: isDark ? AppTokens.darkBorder : AppTokens.lightBorder,
          width: 1,
        );
        shadows = _isHovered && widget.enableHover
            ? AppTokens.shadowLg(isDark)
            : AppTokens.shadowSm(isDark);
        break;

      case AppCardVariant.outlined:
        bgColor = widget.customBgColor ?? (isDark ? AppTokens.darkBgSubtle : AppTokens.lightSurface);
        borderSide = BorderSide(
          color: _isHovered && widget.enableHover
              ? (isDark ? AppTokens.primary400 : AppTokens.primary500)
              : (isDark ? AppTokens.darkBorder : AppTokens.lightBorder),
          width: 1.2,
        );
        break;

      case AppCardVariant.filled:
        bgColor = widget.customBgColor ?? (isDark ? AppTokens.darkBgSubtle : AppTokens.lightBgSubtle);
        break;

      case AppCardVariant.gradient:
        bgColor = Colors.transparent;
        gradient ??= AppTokens.primaryGradient;
        shadows = AppTokens.shadowMd(isDark);
        break;

      case AppCardVariant.glass:
        bgColor = isDark ? const Color(0x331E293B) : const Color(0x99FFFFFF);
        borderSide = BorderSide(
          color: isDark ? const Color(0x33FFFFFF) : const Color(0x80FFFFFF),
          width: 1,
        );
        shadows = AppTokens.shadowSm(isDark);
        break;
    }

    final isClickable = widget.onTap != null;

    Widget cardContent = AnimatedContainer(
      duration: AppTokens.durationFast,
      curve: AppTokens.curveStandard,
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bgColor,
        gradient: gradient,
        borderRadius: radius,
        border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
        boxShadow: shadows,
      ),
      child: widget.child,
    );

    if (isClickable) {
      cardContent = Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          splashColor: (isDark ? Colors.white : AppTokens.primary500).withValues(alpha: 0.08),
          highlightColor: (isDark ? Colors.white : AppTokens.primary500).withValues(alpha: 0.04),
          child: cardContent,
        ),
      );
    }

    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (widget.enableHover) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (widget.enableHover) setState(() => _isHovered = false);
      },
      child: AnimatedScale(
        scale: _isHovered && widget.enableHover && isClickable ? 1.01 : 1.0,
        duration: AppTokens.durationFast,
        curve: AppTokens.curveStandard,
        child: Container(
          margin: widget.margin,
          child: cardContent,
        ),
      ),
    );
  }
}
