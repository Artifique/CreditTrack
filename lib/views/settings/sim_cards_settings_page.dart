import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/tokens.dart';
import '../../core/user_feedback.dart';
import '../../controllers/sim_card_controller.dart';
import '../../models/sim_card_model.dart';
import '../../widgets/ui/ui.dart';

class SimCardsSettingsPage extends StatefulWidget {
  const SimCardsSettingsPage({super.key});

  @override
  State<SimCardsSettingsPage> createState() => _SimCardsSettingsPageState();
}

class _SimCardsSettingsPageState extends State<SimCardsSettingsPage> {
  final _currencyFormat = NumberFormat('#,##0', 'fr_FR');

  @override
  void initState() {
    super.initState();
    SimCardController.instance.loadSimCards();
  }

  String _formatAmount(double amount) => _currencyFormat.format(amount);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des SIMs", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
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
                          color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                        ),
                      ),
                      Text(
                        "${sims.length} SIM${sims.length > 1 ? 's' : ''}",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (sims.isEmpty) ...[
                    AppCard(
                      variant: AppCardVariant.outlined,
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? AppTokens.darkBgSubtle : AppTokens.lightBgSubtle,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.sim_card_outlined,
                                size: 36,
                                color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "Aucun compte SIM configuré",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Ajoutez autant de SIMs que vous souhaitez pour gérer vos opérations.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            AppButton(
                              label: "+ Ajouter une SIM",
                              icon: Icons.add_rounded,
                              size: AppButtonSize.md,
                              onPressed: () => _openAddOrEditSimModal(context, isDark: isDark),
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
                    onPressed: () => _openAddOrEditSimModal(context, isDark: isDark),
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
        border: Border.all(color: isDark ? AppTokens.darkBorder : AppTokens.lightBorder),
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
                    color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
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
              color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSimItemCard(BuildContext context, SimCardModel sim, bool isDark) {
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
            child: const Icon(Icons.sim_card_rounded, color: AppTokens.primary500, size: 22),
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
                    color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                  ),
                ),
                Text(
                  sim.phone,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x336366F1) : AppTokens.primary50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "UV: ${_formatAmount(sim.soldeUv)} F",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTokens.primary300 : AppTokens.primary600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x3310B981) : AppTokens.successBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Crédit: ${_formatAmount(sim.soldeCredit)} F",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTokens.secondary300 : AppTokens.secondary600,
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
            color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
            onPressed: () => _openAddOrEditSimModal(context, existingSim: sim, isDark: isDark),
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

  void _openAddOrEditSimModal(BuildContext context, {SimCardModel? existingSim, required bool isDark}) {
    final isEditing = existingSim != null;
    final nameCtrl = TextEditingController(text: isEditing ? existingSim.name : "");
    final phoneCtrl = TextEditingController(text: isEditing ? existingSim.phone : "");
    final uvCtrl = TextEditingController(text: isEditing ? existingSim.soldeUv.toStringAsFixed(0) : "0");
    final crCtrl = TextEditingController(text: isEditing ? existingSim.soldeCredit.toStringAsFixed(0) : "0");
    bool isSaving = false;
    final parentContext = context;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTokens.darkSurface : AppTokens.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radius2Xl)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? "Modifier le Compte SIM" : "+ Ajouter un Compte SIM",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppInput(
                    controller: nameCtrl,
                    label: "Nom personnalisé de la SIM",
                    hintText: "ex: Orange Money Caisse 01",
                    isRequired: true,
                    prefixIcon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 12),
                  AppInput(
                    controller: phoneCtrl,
                    label: "Numéro de la SIM / Agent",
                    hintText: "ex: 77 123 45 67",
                    isRequired: true,
                    enabled: !isEditing, // Le numéro sert d'identifiant principal
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_rounded,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppInput(
                          controller: uvCtrl,
                          label: "Solde UV (FCFA)",
                          hintText: "0",
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppInput(
                          controller: crCtrl,
                          label: "Solde Crédit (FCFA)",
                          hintText: "0",
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.phone_android_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: isEditing ? "METTRE À JOUR" : "ENREGISTRER LA SIM",
                    icon: Icons.check_circle_rounded,
                    isFullWidth: true,
                    size: AppButtonSize.lg,
                    isLoading: isSaving,
                    onPressed: () async {
                      final p = phoneCtrl.text.trim();
                      final n = nameCtrl.text.trim();
                      if (p.isEmpty) {
                        UserFeedback.showToast(ctx, "Le numéro est obligatoire.", type: AppToastType.warning);
                        return;
                      }

                      final uv = double.tryParse(uvCtrl.text.trim().replaceAll(' ', '')) ?? 0.0;
                      final cr = double.tryParse(crCtrl.text.trim().replaceAll(' ', '')) ?? 0.0;

                      setModalState(() => isSaving = true);
                      try {
                        if (isEditing) {
                          await SimCardController.instance.updateSimCard(
                            phone: existingSim.phone,
                            newName: n,
                            soldeUv: uv,
                            soldeCredit: cr,
                          );
                        } else {
                          await SimCardController.instance.addSimCard(
                            phone: p,
                            name: n,
                            initialUv: uv,
                            initialCredit: cr,
                          );
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (parentContext.mounted) {
                          UserFeedback.showSuccessToast(
                            parentContext,
                            isEditing ? "SIM « $n » mise à jour avec succès !" : "SIM « $n » ajoutée avec succès !",
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          setModalState(() => isSaving = false);
                          UserFeedback.showErrorModal(ctx, e);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteSim(BuildContext context, SimCardModel sim, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark ? AppTokens.darkSurface : AppTokens.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusXl)),
          title: Text(
            "Supprimer cette SIM ?",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
            ),
          ),
          content: Text(
            "Êtes-vous sûr de vouloir retirer la SIM « ${sim.displayName} » (${sim.phone}) des paramètres ? Vos transactions historiques resteront conservées.",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("ANNULER", style: TextStyle(fontWeight: FontWeight.w700)),
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
                    UserFeedback.showSuccessToast(context, "SIM « ${sim.displayName} » supprimée.");
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
