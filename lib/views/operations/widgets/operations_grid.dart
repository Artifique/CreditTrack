import 'package:flutter/material.dart';
import '../../../core/tokens.dart';
import '../../../models/transaction_model.dart';

/// Carte représentant un service/opération dans la grille.
class OperationGridCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const OperationGridCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppTokens.primary500.withValues(alpha: 0.05),
        splashColor: AppTokens.primary500.withValues(alpha: 0.10),
        child: Container(
          height: 104,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppTokens.primary500,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    isDark ? const Color(0x18000000) : const Color(0x06000000),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x33FF6600)
                      : const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 24,
                    color: AppTokens.primary500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grille des opérations optimisée en passes de layout linéaires (sans shrinkWrap coûteux).
class OperationsGrid extends StatelessWidget {
  final String category;
  final ValueChanged<TransactionType> onSelectOperation;

  const OperationsGrid({
    super.key,
    required this.category,
    required this.onSelectOperation,
  });

  @override
  Widget build(BuildContext context) {
    if (category == 'CREDIT') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OperationGridCard(
                  key: const ValueKey('op_achat'),
                  title: 'ACHAT CRÉDIT',
                  icon: Icons.phone_android_rounded,
                  onTap: () => onSelectOperation(TransactionType.achat),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OperationGridCard(
                  key: const ValueKey('op_forfait'),
                  title: 'FORFAIT',
                  icon: Icons.card_giftcard_rounded,
                  onTap: () => onSelectOperation(TransactionType.forfait),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OperationGridCard(
                  key: const ValueKey('op_sewa'),
                  title: 'SEWA',
                  icon: Icons.flash_on_rounded,
                  onTap: () => onSelectOperation(TransactionType.sewa),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OperationGridCard(
                  key: const ValueKey('op_transfert_credit'),
                  title: 'TRANSFERT',
                  icon: Icons.send_rounded,
                  onTap: () =>
                      onSelectOperation(TransactionType.transfertCredit),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(child: SizedBox.shrink()),
              const SizedBox(width: 10),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OperationGridCard(
                key: const ValueKey('op_depot'),
                title: 'DEPOT',
                icon: Icons.arrow_downward_rounded,
                onTap: () => onSelectOperation(TransactionType.depot),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OperationGridCard(
                key: const ValueKey('op_retrait'),
                title: 'RETRAIT',
                icon: Icons.arrow_upward_rounded,
                onTap: () => onSelectOperation(TransactionType.retrait),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OperationGridCard(
                key: const ValueKey('op_nafama'),
                title: 'NAFAMA',
                icon: Icons.savings_rounded,
                onTap: () => onSelectOperation(TransactionType.nafama),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OperationGridCard(
                key: const ValueKey('op_transfert_uv'),
                title: 'TRANSFERT UV',
                icon: Icons.sync_alt_rounded,
                onTap: () => onSelectOperation(TransactionType.transfertUv),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OperationGridCard(
                key: const ValueKey('op_transfert_c2c'),
                title: 'TRANSFERT C2C',
                icon: Icons.swap_horiz_rounded,
                onTap: () => onSelectOperation(TransactionType.transfertC2c),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OperationGridCard(
                key: const ValueKey('op_transfert_profit'),
                title: 'TRANSFERT PROFIT',
                icon: Icons.trending_up_rounded,
                onTap: () =>
                    onSelectOperation(TransactionType.transfertProfitUv),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
