import 'package:flutter/material.dart';
import '../../../../controllers/transaction_controller.dart';
import '../../../../core/app_formatters.dart';
import '../../../../core/tokens.dart';
import '../../../../core/user_feedback.dart';
import '../../../../widgets/ui/app_toast.dart';

/// Carte de saisie du numéro client avec autocomplétion intelligente
/// basée sur l'historique complet des transactions.
class OperationPhoneInputCard extends StatefulWidget {
  final TextEditingController controller;
  final List<ClientHistorySuggestion> recentSuggestions;
  final bool isDark;
  final ValueChanged<ClientHistorySuggestion>? onSelectedSuggestion;
  final VoidCallback? onClear;

  const OperationPhoneInputCard({
    super.key,
    required this.controller,
    required this.recentSuggestions,
    required this.isDark,
    this.onSelectedSuggestion,
    this.onClear,
  });

  @override
  State<OperationPhoneInputCard> createState() =>
      _OperationPhoneInputCardState();
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

  String _formatPhoneDisplay(String phone) => AppFormatters.formatPhone(phone);

  String _formatAmount(double amt) => AppFormatters.formatAmount(amt);

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTokens.primary500;
    final queryDigits = widget.controller.text.replaceAll(RegExp(r'\D'), '');

    // Filtrage des suggestions selon l'historique
    final List<ClientHistorySuggestion> filteredSuggestions;
    if (_hideSuggestions) {
      filteredSuggestions = [];
    } else if (queryDigits.isEmpty) {
      // Si le champ est vide : proposer les 3 derniers clients récents
      filteredSuggestions = widget.recentSuggestions.take(3).toList();
    } else {
      // Si on commence à taper : filtrer par préfixe ou contenu
      filteredSuggestions = widget.recentSuggestions
          .where((s) {
            final pDigits = s.phone.replaceAll(RegExp(r'\D'), '');
            final nameLower = s.clientName.toLowerCase();
            return pDigits.startsWith(queryDigits) ||
                pDigits.contains(queryDigits) ||
                nameLower.contains(widget.controller.text.toLowerCase().trim());
          })
          .take(4)
          .toList();
    }

    final bool showDropdown = !_hideSuggestions &&
        queryDigits.isNotEmpty &&
        filteredSuggestions.isNotEmpty &&
        !(filteredSuggestions.length == 1 &&
            filteredSuggestions.first.phone.replaceAll(RegExp(r'\D'), '') ==
                queryDigits);

    final bool showRecentChips = !_hideSuggestions &&
        queryDigits.isEmpty &&
        widget.recentSuggestions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Numéro client',
              style: TextStyle(
                color: widget.isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF334155),
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (widget.recentSuggestions.isNotEmpty && queryDigits.isEmpty)
              Text(
                '${widget.recentSuggestions.length} clients dans l\'historique',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppTokens.primary500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: widget.isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF8FAFC),
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
                Icons.sim_card_outlined,
                color: widget.isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF475569),
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    color:
                        widget.isDark ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Entrer le numéro',
                    hintStyle: TextStyle(
                      color: widget.isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      fontSize: 16.5,
                      fontWeight: FontWeight.w400,
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
              if (widget.controller.text.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    widget.controller.clear();
                    setState(() => _hideSuggestions = false);
                    widget.onClear?.call();
                  },
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 10),
              ],
              IconButton(
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
                tooltip: 'Scanner le numéro',
                onPressed: () {
                  UserFeedback.showToast(
                    context,
                    'Scanner de numéro caméra bientôt disponible',
                    type: AppToastType.info,
                  );
                },
                splashRadius: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // 1. Suggestions sous forme de Chips rapides quand le champ est vide
        if (showRecentChips) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.recentSuggestions.take(4).map<Widget>((s) {
                final displayPhone = _formatPhoneDisplay(s.phone);
                final displayName =
                    s.clientName != 'Client direct' ? ' (${s.clientName})' : '';
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(Icons.history_rounded,
                        size: 14, color: primaryColor),
                    label: Text(
                      '$displayPhone$displayName',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark
                            ? Colors.white
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    backgroundColor: widget.isDark
                        ? const Color(0xFF1E293B)
                        : AppTokens.primary50,
                    side: BorderSide(
                      color: widget.isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFFFEDD5),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    onPressed: () {
                      final formatted = _formatPhoneDisplay(s.phone);
                      widget.controller.text = formatted;
                      widget.controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: formatted.length),
                      );
                      setState(() => _hideSuggestions = true);
                      widget.onSelectedSuggestion?.call(s);
                      FocusScope.of(context).unfocus();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // 2. Suggestions enrichies sous forme de liste déroulante lors de la frappe
        if (showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 10,
                    offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: filteredSuggestions.map<Widget>((s) {
                final formatted = _formatPhoneDisplay(s.phone);
                final hasName =
                    s.clientName.isNotEmpty && s.clientName != 'Client direct';

                return InkWell(
                  onTap: () {
                    widget.controller.text = formatted;
                    widget.controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: formatted.length),
                    );
                    setState(() => _hideSuggestions = true);
                    widget.onSelectedSuggestion?.call(s);
                    FocusScope.of(context).unfocus();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? const Color(0x33FF6600)
                                : AppTokens.primary50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.person_rounded,
                              size: 16, color: primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatted,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              if (hasName)
                                Text(
                                  s.clientName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: widget.isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (s.lastAmount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: widget.isDark
                                  ? const Color(0x3310B981)
                                  : AppTokens.secondary50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_formatAmount(s.lastAmount)} F',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: widget.isDark
                                    ? AppTokens.secondary300
                                    : AppTokens.secondary500,
                              ),
                            ),
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
