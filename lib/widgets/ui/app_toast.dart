import 'package:flutter/material.dart';
import '../../core/tokens.dart';

enum AppToastType {
  success,
  error,
  warning,
  info,
}

/// Animated floating Toast with slide-in animation, progress indicator, and semantic icons.
class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        title: title,
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String? title;
  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    this.title,
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: AppTokens.curveStandard));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color iconColor;
    Color borderColor;
    Color bgColor;
    IconData icon;

    switch (widget.type) {
      case AppToastType.success:
        icon = Icons.check_circle_rounded;
        iconColor = AppTokens.success;
        borderColor = isDark ? const Color(0x6610B981) : AppTokens.successBorder;
        bgColor = isDark ? const Color(0xFF132E24) : Colors.white;
        break;
      case AppToastType.error:
        icon = Icons.error_rounded;
        iconColor = AppTokens.error;
        borderColor = isDark ? const Color(0x66EF4444) : AppTokens.errorBorder;
        bgColor = isDark ? const Color(0xFF2E1515) : Colors.white;
        break;
      case AppToastType.warning:
        icon = Icons.warning_rounded;
        iconColor = AppTokens.warning;
        borderColor = isDark ? const Color(0x66F59E0B) : AppTokens.warningBorder;
        bgColor = isDark ? const Color(0xFF2E2215) : Colors.white;
        break;
      case AppToastType.info:
        icon = Icons.info_rounded;
        iconColor = AppTokens.info;
        borderColor = isDark ? const Color(0x663B82F6) : AppTokens.infoBorder;
        bgColor = isDark ? const Color(0xFF15222E) : Colors.white;
        break;
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            color: Colors.transparent,
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: AppTokens.shadowLg(isDark),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: iconColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.title != null) ...[
                              Text(
                                widget.title!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              widget.message,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _dismiss,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

