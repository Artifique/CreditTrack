import 'package:flutter/material.dart';
import '../../../core/tokens.dart';

/// Carte de saisie du numéro client avec autocomplétion réactive des numéros récents.
class OperationPhoneInputCard extends StatefulWidget {
  final TextEditingController controller;
  final List<String> recentPhones;
  final bool isDark;
  final ValueChanged<String>? onSelectedPhone;
  final VoidCallback? onClear;

  const OperationPhoneInputCard({
    super.key,
    required this.controller,
    required this.recentPhones,
    required this.isDark,
    this.onSelectedPhone,
    this.onClear,
  });

  @override
  State<OperationPhoneInputCard> createState() => _OperationPhoneInputCardState();
}

class _OperationPhoneInputCardState extends State<OperationPhoneInputCard> {
  bool _hideSuggestions = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(OperationPhoneInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChange);
      widget.controller.addListener(_handleTextChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleTextChange() {
    if (mounted) {
      setState(() {});
    }
  }

  String _formatPhoneDisplay(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 9) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7, 9)}';
    } else if (digits.length == 8) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTokens.primary500;
    final queryDigits = widget.controller.text.replaceAll(RegExp(r'\D'), '');

    final matches = (!_hideSuggestions && queryDigits.isNotEmpty)
        ? widget.recentPhones.where((p) {
            final pDigits = p.replaceAll(RegExp(r'\D'), '');
            return pDigits.startsWith(queryDigits) ||
                (queryDigits.length >= 2 && pDigits.contains(queryDigits));
          }).take(4).toList()
        : <String>[];

    final shouldShowSuggestions = matches.isNotEmpty &&
        !(matches.length == 1 &&
            matches.first.replaceAll(RegExp(r'\D'), '') == queryDigits);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Numéro client',
          style: TextStyle(
            color: widget.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.phone_android_rounded,
                color: primaryColor,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: '77 000 00 00',
                    hintStyle: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    if (_hideSuggestions) {
                      _hideSuggestions = false;
                    }
                    setState(() {});
                  },
                ),
              ),
              if (widget.controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    widget.controller.clear();
                    setState(() => _hideSuggestions = false);
                    widget.onClear?.call();
                  },
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        if (shouldShowSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: matches.map((matchPhone) {
                return InkWell(
                  onTap: () {
                    final formatted = _formatPhoneDisplay(matchPhone);
                    widget.controller.text = formatted;
                    widget.controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: formatted.length),
                    );
                    setState(() => _hideSuggestions = true);
                    widget.onSelectedPhone?.call(formatted);
                    FocusScope.of(context).unfocus();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded, size: 18, color: primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatPhoneDisplay(matchPhone),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const Text(
                          'Client récent',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
