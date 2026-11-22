import 'package:flutter/material.dart';
import '../../../core/app_formatters.dart';
import '../../../core/tokens.dart';
import '../../../models/transaction_model.dart';
import '../../../widgets/ui/app_badge.dart';
import '../../../widgets/ui/app_card.dart';
import 'dotted_divider.dart';
import 'receipt_info_line.dart';
import 'transaction_balance_flow.dart';

/// Carte ticket complète affichant tous les détails d'une transaction.
class TransactionDetailTicket extends StatelessWidget {
  final TransactionModel transaction;
  final String businessName;
  final String dateFormatted;
  final String amountFormatted;
  final String soldeAvantFormatted;
  final String soldeApresFormatted;
  final String commissionFormatted;
  final Color amountColor;
  final bool isDark;
  final void Function(String text, String label) onCopy;

  const TransactionDetailTicket({
    super.key,
    required this.transaction,
    required this.businessName,
    required this.dateFormatted,
    required this.amountFormatted,
    required this.soldeAvantFormatted,
    required this.soldeApresFormatted,
    required this.commissionFormatted,
    required this.amountColor,
    required this.isDark,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final isCredit = tx.category == TransactionCategory.CREDIT;

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Nom du commerce & N° Journal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  businessName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isDark
                        ? AppTokens.darkTextPrimary
                        : AppTokens.lightTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tx.journalSeq != null)
                AppBadge(
                  label: '#${tx.journalSeq}',
                  variant: AppBadgeVariant.primary,
                  fontSize: 12,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            dateFormatted,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppTokens.darkTextTertiary
                  : AppTokens.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 16),
          DottedDivider(
              color: isDark ? AppTokens.darkBorder : AppTokens.lightBorder),
          const SizedBox(height: 16),

          // Montant principal en hero
          Center(
            child: Column(
              children: [
                Text(
                  'MONTANT OPÉRATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppTokens.darkTextTertiary
                        : AppTokens.lightTextTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amountFormatted,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: amountColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                AppBadge(
                  label:
                      TransactionModel.typeDisplayName(tx.type).toUpperCase(),
                  variant:
                      isCredit ? AppBadgeVariant.info : AppBadgeVariant.neutral,
                  fontSize: 11,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Évolution du solde SIM / Compte
          TransactionBalanceFlow(
            title: 'Évolution du solde ${tx.category.name}',
            soldeAvantFormatted: soldeAvantFormatted,
            soldeApresFormatted: soldeApresFormatted,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // Évolution du solde Espèce
          TransactionBalanceFlow(
            title: 'Évolution du solde Espèce (Caisse)',
            icon: Icons.payments_rounded,
            accentColor: const Color(0xFF10B981),
            soldeAvantFormatted:
                '${AppFormatters.formatAmount(tx.soldeEspeceAvant)} CFA',
            soldeApresFormatted:
                '${AppFormatters.formatAmount(tx.soldeEspeceApres)} CFA',
            isDark: isDark,
          ),
          const SizedBox(height: 18),
          DottedDivider(
              color: isDark ? AppTokens.darkBorder : AppTokens.lightBorder),
          const SizedBox(height: 14),

          // Détails de l'opération
          ReceiptInfoLine(
            icon: Icons.tag_rounded,
            label: 'ID Système',
            value: tx.id?.substring(0, 8).toUpperCase() ?? 'N/A',
            onCopy: tx.id != null ? () => onCopy(tx.id!, 'ID') : null,
          ),
          ReceiptInfoLine(
            icon: Icons.category_outlined,
            label: 'Catégorie',
            value: tx.category.name,
          ),
          ReceiptInfoLine(
            icon: Icons.savings_outlined,
            label: 'Commission caisse',
            value: '+$commissionFormatted',
            valueColor: AppTokens.success,
            isBold: true,
          ),
          ReceiptInfoLine(
            icon: Icons.history_rounded,
            label: 'Solde Espèce avant',
            value: '${AppFormatters.formatAmount(tx.soldeEspeceAvant)} CFA',
          ),
          ReceiptInfoLine(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Solde Espèce après',
            value: '${AppFormatters.formatAmount(tx.soldeEspeceApres)} CFA',
            valueColor: const Color(0xFF10B981),
            isBold: true,
          ),
          if (tx.category == TransactionCategory.UV)
            ReceiptInfoLine(
              icon: Icons.payments_rounded,
              label: 'Impact Caisse Espèce',
              value: [
                TransactionType.depot,
                TransactionType.nafama,
                TransactionType.transfertC2c
              ].contains(tx.type)
                  ? '+$amountFormatted (Espèces reçues)'
                  : ([TransactionType.retrait, TransactionType.transfertUv]
                          .contains(tx.type)
                      ? '-$amountFormatted (Espèces remises)'
                      : '0 CFA (Interne)'),
              valueColor: [
                TransactionType.depot,
                TransactionType.nafama,
                TransactionType.transfertC2c
              ].contains(tx.type)
                  ? AppTokens.success
                  : ([TransactionType.retrait, TransactionType.transfertUv]
                          .contains(tx.type)
                      ? AppTokens.error
                      : null),
              isBold: true,
            ),
          ReceiptInfoLine(
            icon: Icons.phone_android_rounded,
            label: 'Numéro client',
            value: tx.clientPhone,
            onCopy: () => onCopy(tx.clientPhone, 'Numéro client'),
          ),
          if (tx.merchantPhone != null && tx.merchantPhone!.isNotEmpty)
            ReceiptInfoLine(
              icon: Icons.sim_card_outlined,
              label: 'Ligne / Compte SIM',
              value: tx.merchantPhone!,
              onCopy: () => onCopy(tx.merchantPhone!, 'Numéro SIM'),
            ),
          if (tx.note != null && tx.note!.isNotEmpty)
            ReceiptInfoLine(
              icon: Icons.notes_rounded,
              label: 'Note / Observation',
              value: tx.note!,
            ),
          const SizedBox(height: 12),
          DottedDivider(
              color: isDark ? AppTokens.darkBorder : AppTokens.lightBorder),
          const SizedBox(height: 12),

          // Pied de ticket
          Center(
            child: Text(
              'Ticket généré par CreditTrack Pro',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? AppTokens.darkTextTertiary
                    : AppTokens.lightTextTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
