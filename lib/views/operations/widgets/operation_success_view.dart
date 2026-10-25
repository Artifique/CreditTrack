import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/app_logger.dart';
import '../../../core/tokens.dart';
import '../../../core/user_feedback.dart';
import '../../../models/transaction_model.dart';
import '../../../services/export_share_service.dart';
import '../../../services/pdf_service.dart';
import '../receipt_page.dart';
import 'receipt_info_line.dart';

/// Vue affichée après la validation réussie d'une transaction (Étape 3).
class OperationSuccessView extends StatelessWidget {
  final TransactionModel transaction;
  final String businessName;
  final bool isDark;
  final VoidCallback onNewOperation;
  final VoidCallback onSameClient;

  const OperationSuccessView({
    super.key,
    required this.transaction,
    required this.businessName,
    required this.isDark,
    required this.onNewOperation,
    required this.onSameClient,
  });

  String _formatAmount(double amt) => NumberFormat('#,##0', 'fr_FR').format(amt);

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final dateStr = DateFormat('dd/MM/yyyy à HH:mm').format(tx.createdAt);
    final ref = tx.journalSeq != null ? '#${tx.journalSeq}' : (tx.id?.substring(0, 8).toUpperCase() ?? 'OP-RÉUSSIE');

    return SingleChildScrollView(
      key: const ValueKey('part_3_success'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F8F0),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF10B981), width: 2),
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'OPÉRATION RÉUSSIE',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Réf. journal $ref • $dateStr',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),

          // Reçu visuel synthétique
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                ReceiptInfoLine(label: 'Type', value: TransactionModel.typeDisplayName(tx.type)),
                ReceiptInfoLine(label: 'Montant', value: '${_formatAmount(tx.amount)} FCFA', isBold: true),
                ReceiptInfoLine(label: 'Commission', value: '+${_formatAmount(tx.commission)} FCFA', valueColor: AppTokens.success),
                ReceiptInfoLine(label: 'Compte SIM', value: tx.merchantPhone ?? 'SIM Principale'),
                ReceiptInfoLine(label: 'Client', value: tx.clientPhone),
                const SizedBox(height: 12),
                Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ReceiptPage(transaction: tx, businessName: businessName),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: const Text('Voir le Reçu', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          final file = await PdfService().generateReceipt(tx, businessName);
                          await ExportShareService.sharePdf(file);
                        } catch (e, st) {
                          AppLogger.error('Erreur partage PDF succès', e, st);
                          if (context.mounted) UserFeedback.showErrorModal(context, e);
                        }
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Partager Reçu', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Boutons post-opération
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('NOUVELLE OPÉRATION', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onNewOperation,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('MÊME CLIENT', style: TextStyle(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
                side: const BorderSide(color: Color(0xFF4F46E5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onSameClient,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.home_rounded),
            label: const Text('ACCUEIL'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
