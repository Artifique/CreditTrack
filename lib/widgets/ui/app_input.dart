import 'package:flutter/material.dart';
import '../../core/tokens.dart';

/// Standardized Input field with labels, validation, focus/hover states,
/// password toggle, and accessibility compliance.
class AppInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool isRequired;
  final bool isPassword;
  final bool enabled;
  final bool autofocus;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final int? maxLines;
  final int? minLines;
  final FocusNode? focusNode;

  const AppInput({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.isPassword = false,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.prefixIcon,
    this.prefix,
    this.suffix,
    this.suffixIcon,
    this.onSuffixTap,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late bool _obscureText;
  bool _isHovered = false;
  late final FocusNode _effectiveFocusNode;
  bool _isInternalFocusNode = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    if (widget.focusNode != null) {
      _effectiveFocusNode = widget.focusNode!;
    } else {
      _effectiveFocusNode = FocusNode();
      _isInternalFocusNode = true;
    }
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = _effectiveFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    if (_isInternalFocusNode) {
      _effectiveFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    // Label widget
    Widget? labelWidget;
    if (widget.label != null) {
      labelWidget = Padding(
        padding: const EdgeInsets.only(bottom: AppTokens.space8),
        child: Row(
          children: [
            Text(
              widget.label!,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
              ),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: AppTokens.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Determine border color
    Color borderColor;
    double borderWidth = 1.2;
    if (hasError) {
      borderColor = AppTokens.error;
      borderWidth = 1.8;
    } else if (_isFocused) {
      borderColor = isDark ? AppTokens.primary400 : AppTokens.primary500;
      borderWidth = 2.0;
    } else if (_isHovered && widget.enabled) {
      borderColor = isDark ? AppTokens.darkBorderHover : AppTokens.lightBorderHover;
    } else {
      borderColor = isDark ? AppTokens.darkBorder : AppTokens.lightBorder;
    }

    // Suffix widget handling
    Widget? effectiveSuffix = widget.suffix;
    if (widget.isPassword) {
      effectiveSuffix = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
        splashRadius: 20,
      );
    } else if (widget.suffixIcon != null) {
      effectiveSuffix = IconButton(
        icon: Icon(
          widget.suffixIcon,
          size: 20,
          color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
        ),
        onPressed: widget.onSuffixTap,
        splashRadius: 20,
      );
    }

    final inputContainer = MouseRegion(
      onEnter: (_) {
        if (widget.enabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (widget.enabled) setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        decoration: BoxDecoration(
          color: widget.enabled
              ? (isDark ? AppTokens.darkBgSubtle : AppTokens.lightSurface)
              : (isDark ? const Color(0xFF161F2E) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: _isFocused && !hasError
              ? [
                  BoxShadow(
                    color: (isDark ? AppTokens.primary400 : AppTokens.primary500).withValues(alpha: 0.15),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _effectiveFocusNode,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          minLines: widget.minLines,
          style: TextStyle(
            fontSize: 14.5,
            color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
            fontWeight: FontWeight.w400,
          ),
          cursorColor: isDark ? AppTokens.primary400 : AppTokens.primary500,
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hintText,
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: _isFocused
                        ? (isDark ? AppTokens.primary400 : AppTokens.primary500)
                        : (isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary),
                  )
                : widget.prefix,
            suffixIcon: effectiveSuffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            fillColor: Colors.transparent,
            filled: false,
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelWidget != null) labelWidget,
        inputContainer,
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, size: 14, color: AppTokens.error),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: const TextStyle(
                    color: AppTokens.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helperText!,
            style: TextStyle(
              color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
