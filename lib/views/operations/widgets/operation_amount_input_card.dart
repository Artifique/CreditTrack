import 'package:flutter/material.dart';
import '../../../core/tokens.dart';

/// Carte de saisie du montant de l'opération en CFA.
class OperationAmountInputCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final VoidCallback onClear;

  const OperationAmountInputCard({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montant (CFA)',
          style: TextStyle(
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
            border: Border(
              bottom: BorderSide(
                color: AppTokens.primary500,
                width: 2.2,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.payments_outlined,
                color:
                    isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Entrer le montant',
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      fontSize: 16.5,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (controller.text.isNotEmpty && controller.text != '0') ...[
                IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      size: 18, color: Color(0xFF94A3B8)),
                  onPressed: onClear,
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                'CFA',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
