import 'package:flutter/material.dart';
import '../../controllers/operation_phone_controller.dart';
import '../../controllers/sim_card_controller.dart';
import '../../core/app_formatters.dart';
import '../../core/tokens.dart';
import '../../core/user_feedback.dart';
import '../../models/new_transaction_route_args.dart';
import '../../models/sim_card_model.dart';
import '../../models/transaction_model.dart';
import '../../widgets/sim_card_editor_sheet.dart';
import '../../widgets/ui/ui.dart';

class SimCardsSettingsPage extends StatefulWidget {
  const SimCardsSettingsPage({super.key});

  @override
  State<SimCardsSettingsPage> createState() => _SimCardsSettingsPageState();
}

class _SimCardsSettingsPageState extends State<SimCardsSettingsPage> {
  @override
  void initState() {
    super.initState();
    SimCardController.instance.loadSimCards();
  }

  String _formatAmount(double amount) => AppFormatters.formatAmount(amount);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des SIMs",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            tooltip: "Ajouter une SIM",
            onPressed: () => _openAddOrEditSimModal(context, isDark: isDark),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: SimCardController.instance,
        builder: (context, _) {
          final sims = SimCardController.instance.simCards;
          final isLoading = SimCardController.instance.isLoading;

          if (isLoading && sims.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalUv = sims.fold(0.0, (acc, s) => acc + s.soldeUv);
          final totalCredit = sims.fold(0.0, (acc, s) => acc + s.soldeCredit);

          return SingleChildScrollView(
            child: ResponsiveContainer(
              maxWidth: 760,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI synthétiques
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: "SIMs Actives",
                          value: "${sims.length}",
                          icon: Icons.sim_card_rounded,
                          color: AppTokens.primary500,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryCard(
                          title: "Total UV",
                          value: "${_formatAmount(totalUv)} F",
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppTokens.primary500,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryCard(
                          title: "Total Crédit",
                          value: "${_formatAmount(totalCredit)} F",
                          icon: Icons.phone_android_rounded,
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space24),

                  // En-tête de section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Comptes SIM enregistrés",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTokens.darkTextPrimary
                              : AppTokens.lightTextPrimary,
                        ),
                      ),
                      Text(
                        "${sims.length} SIM${sims.length > 1 ? 's' : ''}",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? AppTokens.darkTextTertiary
                              : AppTokens.lightTextTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (sims.isEmpty) ...[
                    AppCard(
                      variant: AppCardVariant.outlined,
                      padding: const EdgeInsets.symmetric(
                          vertical: 40, horizontal: 20),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTokens.darkBgSubtle
                                    : AppTokens.lightBgSubtle,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.sim_card_outlined,
                                size: 36,
                                color: isDark
                                    ? AppTokens.darkTextTertiary
                                    : AppTokens.lightTextTertiary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "Aucun compte SIM configuré",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppTokens.darkTextPrimary
                                    : AppTokens.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Ajoutez autant de SIMs que vous souhaitez pour gérer vos opérations.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark
                                    ? AppTokens.darkTextTertiary
                                    : AppTokens.lightTextTertiary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            AppButton(
                              label: "+ Ajouter une SIM",
                              icon: Icons.add_rounded,
                              size: AppButtonSize.md,
                              onPressed: () => _openAddOrEditSimModal(context,
                                  isDark: isDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sims.length,
                      itemBuilder: (context, index) {
                        final sim = sims[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildSimItemCard(context, sim, isDark),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: AppTokens.space24),
                  AppButton(
                    label: "+ AJOUTER UNE SIM",
                    icon: Icons.add_circle_outline_rounded,
                    isFullWidth: true,
                    size: AppButtonSize.lg,
                    onPressed: () =>
                        _openAddOrEditSimModal(context, isDark: isDark),
                  ),
                  const SizedBox(height: AppTokens.space32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTokens.darkSurface : AppTokens.lightSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
            color: isDark ? AppTokens.darkBorder : AppTokens.lightBorder),
        boxShadow: AppTokens.shadowSm(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTokens.darkTextTertiary
                        : AppTokens.lightTextTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppTokens.darkTextPrimary
                  : AppTokens.lightTextPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSimItemCard(
      BuildContext context, SimCardModel sim, bool isDark) {
    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x336366F1) : AppTokens.primary50,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: Icon(Icons.sim_card_rounded,
                color: AppTokens.primary500, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sim.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: isDark
                        ? AppTokens.darkTextPrimary
                        : AppTokens.lightTextPrimary,
                  ),
                ),
                Text(
                  sim.phone,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? AppTokens.darkTextTertiary
                        : AppTokens.lightTextTertiary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0x336366F1)
                            : AppTokens.primary50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "UV: ${_formatAmount(sim.soldeUv)} F",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTokens.primary300
                              : AppTokens.primary600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0x3310B981)
                            : AppTokens.successBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Crédit: ${_formatAmount(sim.soldeCredit)} F",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTokens.secondary300
                              : AppTokens.secondary600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: "Modifier la SIM",
            color: isDark
                ? AppTokens.darkTextSecondary
                : AppTokens.lightTextSecondary,
            onPressed: () => _openAddOrEditSimModal(context,
                existingSim: sim, isDark: isDark),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            tooltip: "Supprimer la SIM",
            color: AppTokens.error,
            onPressed: () => _confirmDeleteSim(context, sim, isDark),
          ),
        ],
      ),
    );
  }

  void _openAddOrEditSimModal(BuildContext context,
      {SimCardModel? existingSim, required bool isDark}) {
    SimCardEditorSheet.show(
      context,
      existingSim: existingSim,
      isDark: isDark,
      onSaved: () => SimCardController.instance.loadSimCards(),
    );
  }

  void _confirmDeleteSim(BuildContext context, SimCardModel sim, bool isDark) {
    if (sim.hasMoney) {
      _showBlockedDeleteSimModal(context, sim, isDark);
      return;
    }

    _showEmptySimDeleteDialog(context, sim, isDark);
  }

  void _showBlockedDeleteSimModal(
      BuildContext context, SimCardModel sim, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusXl)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTokens.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppTokens.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Suppression refusée",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5,
                    color: isDark
                        ? AppTokens.darkTextPrimary
                        : AppTokens.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Impossible de supprimer la SIM « ${sim.displayName} » car elle contient encore des fonds :",
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: isDark
                      ? AppTokens.darkTextSecondary
                      : AppTokens.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Column(
                  children: [
                    if (sim.soldeUv > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Solde Orange Money UV :",
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            "${_formatAmount(sim.soldeUv)} CFA",
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFF6600),
                            ),
                          ),
                        ],
                      ),
                    if (sim.soldeUv > 0 && sim.soldeCredit > 0)
                      const SizedBox(height: 8),
                    if (sim.soldeCredit > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Solde Crédit téléphonique :",
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            "${_formatAmount(sim.soldeCredit)} CFA",
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total restant sur la SIM :",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "${_formatAmount(sim.totalBalance)} CFA",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppTokens.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Pour protéger votre caisse, vous devez d'abord retirer ou transférer l'argent de cette SIM avant de pouvoir la supprimer.",
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("COMPRIS"),
            ),
            AppButton(
              label: "RETIRER LES FONDS",
              icon: Icons.payments_outlined,
              size: AppButtonSize.sm,
              onPressed: () {
                Navigator.pop(dialogCtx);
                OperationPhoneController.instance.selectPhone(sim.phone);
                Navigator.pushNamed(
                  context,
                  '/new-transaction',
                  arguments: NewTransactionRouteArgs(
                    initialType: sim.soldeUv > 0
                        ? TransactionType.retrait
                        : TransactionType.transfertCredit,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showEmptySimDeleteDialog(
      BuildContext context, SimCardModel sim, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppTokens.darkSurface : AppTokens.lightSurface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusXl)),
          title: Text(
            "Supprimer cette SIM ?",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isDark
                  ? AppTokens.darkTextPrimary
                  : AppTokens.lightTextPrimary,
            ),
          ),
          content: Text(
            "Cette SIM ne contient aucun fond (0 CFA). Êtes-vous sûr de vouloir retirer la SIM « ${sim.displayName} » (${sim.phone}) des paramètres ? Vos transactions historiques resteront conservées.",
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppTokens.darkTextSecondary
                  : AppTokens.lightTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("ANNULER",
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            AppButton(
              label: "SUPPRIMER",
              variant: AppButtonVariant.danger,
              size: AppButtonSize.sm,
              onPressed: () async {
                Navigator.pop(dialogCtx);
                try {
                  await SimCardController.instance.deleteSimCard(sim.phone);
                  if (context.mounted) {
                    UserFeedback.showSuccessToast(
                        context, "SIM « ${sim.displayName} » supprimée.");
                  }
                } catch (e) {
                  if (context.mounted) {
                    UserFeedback.showErrorModal(context, e);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
