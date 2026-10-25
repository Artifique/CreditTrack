import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import 'receipt_info_line.dart';

/// Boîte de dialogue de confirmation d'une opération avant soumission.
class OperationConfirmDialog extends StatelessWidget {
  final TransactionType type;
  final String? simDisplayName;
  final String? simPhone;
  final String simBalanceFormatted;
  final String clientPhone;
  final String clientName;
  final String amountFormatted;
  final String commissionFormatted;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const OperationConfirmDialog({
    super.key,
    required this.type,
    this.simDisplayName,
    this.simPhone,
    required this.simBalanceFormatted,
    required this.clientPhone,
    required this.clientName,
    required this.amountFormatted,
    required this.commissionFormatted,
    required this.isSubmitting,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline_rounded, color: Color(0xFF4F46E5), size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Confirmer l’opération',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReceiptInfoLine(label: 'Opération', value: TransactionModel.typeDisplayName(type), isBold: true),
          if (simDisplayName != null && simPhone != null)
            ReceiptInfoLine(label: 'Compte / SIM', value: '$simDisplayName ($simPhone) • Solde: $simBalanceFormatted'),
          ReceiptInfoLine(label: 'Numéro Client', value: '$clientPhone ($clientName)'),
          ReceiptInfoLine(label: 'Montant', value: amountFormatted, valueColor: const Color(0xFF4F46E5), isBold: true),
          const ReceiptInfoLine(label: 'Frais', value: '0 F'),
          ReceiptInfoLine(label: 'Commission estimée', value: '+$commissionFormatted', valueColor: const Color(0xFF10B981), isBold: true),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : onCancel,
          child: const Text('MODIFIER', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('CONFIRMER', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
