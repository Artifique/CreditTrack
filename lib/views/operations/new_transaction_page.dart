import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/cash_balance_controller.dart';
import '../../controllers/operation_phone_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/sim_card_controller.dart';
import '../../controllers/theme_mode_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../core/app_formatters.dart';
import '../../core/app_logger.dart';
import '../../core/tokens.dart';
import '../../core/user_feedback.dart';
import '../../models/commission_rates_model.dart';
import '../../models/new_transaction_route_args.dart';
import '../../models/operation_phone_wallet_model.dart';
import '../../models/sim_card_model.dart';
import '../../models/transaction_model.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/app_toast.dart';
import '../../widgets/ui/responsive_layout.dart';
import 'widgets/operation_amount_input_card.dart';
import 'widgets/operation_balance_card.dart';
import 'widgets/operation_banners_carousel.dart';
import 'widgets/operation_bottom_nav_bar.dart';
import 'widgets/operation_category_tabs.dart';
import 'widgets/operation_confirm_dialog.dart';
import 'widgets/operation_drawer.dart';
import 'widgets/operation_estimated_commission_card.dart';
import 'widgets/operation_phone_input_card.dart';
import 'widgets/operation_quick_amounts_grid.dart';
import 'widgets/operation_sheets.dart';
import 'widgets/operation_success_view.dart';
import 'widgets/operations_grid.dart';

/// Page principale de saisie et de passage d'opérations (Caisse).
class NewTransactionPage extends StatefulWidget {
  final NewTransactionRouteArgs? routeArgs;

  const NewTransactionPage({super.key, this.routeArgs});

  @override
  State<NewTransactionPage> createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends State<NewTransactionPage> {
  // Navigation: 1 = Choix Opération, 2 = Saisie Opération (Screenshot), 3 = Opération Réussie
  int _currentStep = 1;

  final _transactionController = TransactionController();
  final _clientPhoneController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _focusAmountNode = FocusNode();

  String _selectedCategory = 'UV'; // 'UV' ou 'CREDIT'
  TransactionType? _selectedType;
  SimCardModel? _selectedSim;
  List<ClientHistorySuggestion> _historySuggestions = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showOmBalance = true;
  bool _showCreditBalance = true;
  bool _showCashBalance = true;
  OperationPhoneWalletModel _wallet = OperationPhoneWalletModel.empty;

  CommissionRates _commissionRates = CommissionRates.defaults;
  final ValueNotifier<double> _commissionNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<double> _amountNotifier = ValueNotifier<double>(0.0);
  String _businessName = 'ALY TOURE SERVICE';
  bool _isSubmitting = false;

  TransactionModel? _completedTransaction;

  static const _creditTypes = [
    TransactionType.achat,
    TransactionType.forfait,
    TransactionType.sewa,
    TransactionType.transfertCredit,
  ];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculateCommission);
    _pullWallet();

    SettingsController().getBusinessSettings().then((s) {
      if (mounted) {
        setState(() => _commissionRates = s.commissionRates);
        _calculateCommission();
      }
    });

    _transactionController.getProfileData().then((p) {
      if (p != null && mounted) {
        setState(() => _businessName = p.businessName);
      }
    });

    _transactionController
        .getRecentClientHistorySuggestions()
        .then((suggestions) {
      if (mounted) {
        setState(() => _historySuggestions = suggestions);
      }
    });

    _autoSelectActiveSim();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final a = widget.routeArgs;
      if (a?.initialType != null && mounted) {
        final t = a!.initialType!;
        final isCredit = _creditTypes.contains(t);
        setState(() {
          _selectedCategory = isCredit ? 'CREDIT' : 'UV';
          _selectedType = t;
          _currentStep = 2;
          final hint = a.suggestedProfitUvAmount;
          if (hint != null && hint > 0) {
            _amountController.text = hint.floor().toString();
          }
        });
        _calculateCommission();
      }
    });
  }

  Future<void> _pullWallet() async {
    final w = await _transactionController.getWalletViewForFilter(
      merchantPhone: OperationPhoneController.instance.selectedForFilter,
    );
    if (mounted) setState(() => _wallet = w);
  }

  Future<void> _autoSelectActiveSim() async {
    final sims = await SimCardController.instance.loadSimCards();
    if (!mounted || sims.isEmpty) return;

    final dashPhone = OperationPhoneController.instance.selectedForFilter;
    if (dashPhone != null && dashPhone.isNotEmpty) {
      final match = sims.where((s) => s.phone == dashPhone).firstOrNull;
      if (match != null) {
        setState(() => _selectedSim = match);
        return;
      }
    }

    setState(() => _selectedSim = sims.first);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _clientPhoneController.dispose();
    _clientNameController.dispose();
    _focusAmountNode.dispose();
    _commissionNotifier.dispose();
    _amountNotifier.dispose();
    super.dispose();
  }

  double get _omBalance =>
      _selectedSim != null ? _selectedSim!.soldeUv : _wallet.soldeUv;
  double get _creditBalance => _selectedSim != null
      ? _selectedSim!.soldeCredit
      : (_wallet.profitUv > 0 ? _wallet.profitUv : 124500.0);

  void _calculateCommission() {
    if (_selectedType == null) {
      _amountNotifier.value = 0.0;
      _commissionNotifier.value = 0.0;
      return;
    }
    final raw = _amountController.text.trim().replaceAll(' ', '');
    final amount = double.tryParse(raw) ?? 0.0;
    final com = TransactionModel.calculateCommission(_selectedType!, amount,
        rates: _commissionRates);
    _amountNotifier.value = amount;
    _commissionNotifier.value = com;
  }

  double get _estimatedCommission => _commissionNotifier.value;

  double get _enteredAmount {
    final raw = _amountController.text.trim().replaceAll(' ', '');
    return double.tryParse(raw) ?? 0.0;
  }

  bool get _isProfitTransfer =>
      _selectedType == TransactionType.transfertProfitUv;

  double get _currentSimBalance {
    if (_selectedSim == null) {
      return _selectedCategory == 'CREDIT' ? _wallet.profitUv : _wallet.soldeUv;
    }
    return _selectedCategory == 'CREDIT'
        ? _selectedSim!.soldeCredit
        : _selectedSim!.soldeUv;
  }

  String _formatAmount(double amount) => AppFormatters.formatAmount(amount);

  void _onSelectOperation(TransactionType type) {
    final isCredit = _creditTypes.contains(type);
    setState(() {
      _selectedCategory = isCredit ? 'CREDIT' : 'UV';
      _selectedType = type;
      _currentStep = 2;
    });
    _calculateCommission();
  }

  void _showCustomizeModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => OperationCustomizeSheet(
          showOmBalance: _showOmBalance,
          showCreditBalance: _showCreditBalance,
          showCashBalance: _showCashBalance,
          onToggleOm: (v) {
            setMState(() => _showOmBalance = v);
            setState(() => _showOmBalance = v);
          },
          onToggleCredit: (v) {
            setMState(() => _showCreditBalance = v);
            setState(() => _showCreditBalance = v);
          },
          onToggleCash: (v) {
            setMState(() => _showCashBalance = v);
            setState(() => _showCashBalance = v);
          },
          onManageSims: () {
            Navigator.pop(ctx);
            Navigator.pushNamed(context, '/settings-sims');
          },
        ),
      ),
    );
  }

  void _showNotificationsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const OperationNotificationsSheet(),
    );
  }

  Future<void> _showCashDrawerModal(BuildContext context) async {
    final cashCtrl = CashBalanceController.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Solde Espèce – Caisse Universelle",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppTokens.darkTextPrimary
                                  : AppTokens.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Commun à toutes les SIM • Équilibre temps réel",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: ThemeModeController
                        .instance.activePalette.cardGradientCash,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Espèces disponibles en caisse",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${AppFormatters.formatAmount(cashCtrl.soldeEspece)} CFA",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Fond de caisse initial :",
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF94A3B8)),
                          ),
                          Text(
                            "${AppFormatters.formatAmount(cashCtrl.initialCash)} CFA",
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTokens.darkTextPrimary
                                  : AppTokens.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Flux net des opérations UV :",
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF94A3B8)),
                          ),
                          Text(
                            "${cashCtrl.transactionsNetCash >= 0 ? '+' : ''}${AppFormatters.formatAmount(cashCtrl.transactionsNetCash)} CFA",
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: cashCtrl.transactionsNetCash >= 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "ℹ️ Règle d'or : Lorsque votre solde UV diminue (Dépôt), votre solde Espèce augmente du même montant. Lorsque votre solde UV augmente (Retrait), votre solde Espèce diminue du même montant.",
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: "Modifier fond initial",
                        variant: AppButtonVariant.secondary,
                        icon: Icons.edit_rounded,
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _openEditInitialCashDialog(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: "Fermer",
                        variant: AppButtonVariant.primary,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditInitialCashDialog(BuildContext context) async {
    final cashCtrl = CashBalanceController.instance;
    final ctrl = TextEditingController(
      text: cashCtrl.initialCash.toStringAsFixed(0),
    );

    final newAmount = await showDialog<double>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Fond de caisse initial"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Définissez le montant en espèces physiquement disponible dans votre tiroir-caisse au début :",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Montant Espèces (CFA)",
                hintText: "Ex: 200000",
                suffixText: "CFA",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Annuler"),
          ),
          AppButton(
            label: "Enregistrer",
            size: AppButtonSize.sm,
            onPressed: () {
              final val = double.tryParse(ctrl.text.trim()) ?? 0;
              Navigator.pop(dialogCtx, val);
            },
          ),
        ],
      ),
    );

    if (newAmount != null) {
      await cashCtrl.setInitialCash(newAmount);
      if (context.mounted) {
        UserFeedback.showSuccessToast(
          context,
          "Fond de caisse mis à jour : ${AppFormatters.formatAmount(newAmount)} CFA",
        );
      }
    }
  }

  void _validateFormBeforeConfirm() {
    if (_enteredAmount <= 0) {
      UserFeedback.showToast(
          context, 'Veuillez saisir un montant supérieur à 0.',
          type: AppToastType.warning);
      return;
    }

    if (!_isProfitTransfer) {
      final phone = _clientPhoneController.text.trim();
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 8) {
        UserFeedback.showToast(
            context, 'Le numéro client doit comporter au moins 8 chiffres.',
            type: AppToastType.warning);
        return;
      }
    }

    // Protection du solde Espèce universel
    final isCashOutOperation = _selectedCategory == 'UV' &&
        (_selectedType == TransactionType.retrait ||
            _selectedType == TransactionType.transfertUv);

    if (isCashOutOperation) {
      final cashAvailable = CashBalanceController.instance.soldeEspece;
      if (_enteredAmount > cashAvailable) {
        UserFeedback.showToast(
          context,
          'Solde Espèce insuffisant',
          type: AppToastType.error,
        );
        return;
      }
    }

    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    final amount = _enteredAmount;
    final activePhone = _selectedSim?.phone ??
        OperationPhoneController.instance.selectedForFilter ??
        OperationPhoneController.instance.registeredPhones.firstOrNull;
    final phone = _isProfitTransfer
        ? (activePhone ?? 'Interne')
        : _clientPhoneController.text.trim();
    final name = _clientNameController.text.trim().isNotEmpty
        ? _clientNameController.text.trim()
        : 'Client direct';

    showDialog<void>(
      context: context,
      barrierDismissible: !_isSubmitting,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => OperationConfirmDialog(
          type: _selectedType!,
          simDisplayName: _selectedSim?.displayName,
          simPhone: _selectedSim?.phone,
          simBalanceFormatted: '${_formatAmount(_currentSimBalance)} F',
          clientPhone: phone,
          clientName: name,
          amountFormatted: '${_formatAmount(amount)} FCFA',
          commissionFormatted: '${_formatAmount(_estimatedCommission)} F',
          isSubmitting: _isSubmitting,
          onCancel: () => Navigator.pop(dialogCtx),
          onConfirm: () async {
            setDialogState(() => _isSubmitting = true);
            await _executeTransaction(dialogCtx);
          },
        ),
      ),
    );
  }

  Future<void> _executeTransaction(BuildContext dialogCtx) async {
    setState(() => _isSubmitting = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      Navigator.pop(dialogCtx);
      UserFeedback.showToast(
          context, 'Session expirée. Veuillez vous reconnecter.',
          type: AppToastType.error);
      return;
    }

    final amount = _enteredAmount;
    final activePhone = _selectedSim?.phone ??
        OperationPhoneController.instance.selectedForFilter ??
        OperationPhoneController.instance.registeredPhones.firstOrNull;
    final phone = _isProfitTransfer
        ? (activePhone ?? 'Interne')
        : _clientPhoneController.text.trim();
    final name = _clientNameController.text.trim().isNotEmpty
        ? _clientNameController.text.trim()
        : 'Client direct';

    final tx = TransactionModel(
      userId: userId,
      type: _selectedType!,
      category: _selectedCategory == 'CREDIT'
          ? TransactionCategory.CREDIT
          : TransactionCategory.UV,
      clientName: name,
      clientPhone: phone,
      merchantPhone: activePhone,
      amount: amount,
      commission: _estimatedCommission,
      soldeApres: 0,
      createdAt: DateTime.now(),
    );

    // Vérification de sécurité Caisse Espèce
    final cashDelta = CashBalanceController.getCashDeltaForTransaction(tx);
    if (cashDelta < 0 && amount > CashBalanceController.instance.soldeEspece) {
      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
      setState(() => _isSubmitting = false);
      UserFeedback.showToast(context, 'Solde Espèce insuffisant',
          type: AppToastType.error);
      return;
    }

    try {
      final savedTx = await _transactionController.addTransaction(tx);
      await SimCardController.instance.loadSimCards();

      if (dialogCtx.mounted) {
        Navigator.pop(dialogCtx);
      }

      if (!mounted) return;
      setState(() {
        _completedTransaction = savedTx;
        _currentStep = 3;
        _isSubmitting = false;
      });
    } catch (e, st) {
      AppLogger.error('Erreur exécution transaction', e, st);
      if (dialogCtx.mounted) {
        Navigator.pop(dialogCtx);
      }
      if (mounted) {
        setState(() => _isSubmitting = false);
        await UserFeedback.showErrorModal(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _currentStep == 2
          ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FE))
          : (isDark ? const Color(0xFF0F172A) : Colors.white),
      drawer: _currentStep == 1
          ? OperationDrawer(
              businessName: _businessName,
              activePhone: _selectedSim?.phone ?? '',
              onHomeTap: () => setState(() => _currentStep = 1),
            )
          : null,
      appBar: AppBar(
        backgroundColor: _currentStep == 2
            ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FE))
            : (isDark ? const Color(0xFF0F172A) : Colors.white),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: _currentStep == 1
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.menu_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    tooltip: 'Menu',
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _currentStep = 1),
                    tooltip: 'Retour aux opérations',
                  ),
                ),
              ),
        title: Text(
          _currentStep == 3 ? 'Opération Réussie' : 'Nouvelle Opération',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_currentStep == 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        size: 20,
                      ),
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTokens.primary500,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: _showNotificationsSheet,
                  tooltip: 'Notifications',
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 720,
          padding: EdgeInsets.zero,
          child: AnimatedSwitcher(
            duration: AppTokens.durationNormal,
            switchInCurve: AppTokens.curveStandard,
            switchOutCurve: AppTokens.curveStandard,
            child: _buildCurrentStep(isDark),
          ),
        ),
      ),
      bottomNavigationBar: _currentStep == 1
          ? OperationBottomNavBar(
              isHomeSelected: true,
              onHomeTap: () => setState(() => _currentStep = 1),
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              onReportingTap: () => Navigator.pushNamed(context, '/reports'),
            )
          : null,
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    switch (_currentStep) {
      case 1:
        return _buildStepOneOperations(isDark);
      case 2:
        return _buildStepTwoForm(isDark);
      case 3:
        return OperationSuccessView(
          transaction: _completedTransaction!,
          businessName: _businessName,
          isDark: isDark,
          onNewOperation: () {
            setState(() {
              _clientPhoneController.clear();
              _clientNameController.clear();
              _amountController.clear();
              _selectedType = null;
              _completedTransaction = null;
              _currentStep = 1;
            });
          },
          onSameClient: () {
            setState(() {
              _amountController.clear();
              _completedTransaction = null;
              _currentStep = 2;
            });
          },
        );
      default:
        return _buildStepOneOperations(isDark);
    }
  }

  Widget _buildStepOneOperations(bool isDark) {
    return RepaintBoundary(
      child: SingleChildScrollView(
        key: const ValueKey('part_1_operations'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OperationBannersCarousel(),
            const SizedBox(height: 18),
            if (_showOmBalance) ...[
              OperationBalanceCard(
                title: 'Solde Orange Money',
                amount: _omBalance,
                isVisible: _showOmBalance,
                onToggleVisibility: () =>
                    setState(() => _showOmBalance = !_showOmBalance),
                logo: const OrangeMoneyLogo(size: 38),
              ),
              const SizedBox(height: 10),
            ],
            if (_showCreditBalance) ...[
              OperationBalanceCard(
                title: 'Solde Crédit',
                amount: _creditBalance,
                isVisible: _showCreditBalance,
                onToggleVisibility: () =>
                    setState(() => _showCreditBalance = !_showCreditBalance),
                logo: const CreditBalanceLogo(size: 38),
              ),
              const SizedBox(height: 10),
            ],
            if (_showCashBalance) ...[
              ListenableBuilder(
                listenable: CashBalanceController.instance,
                builder: (context, _) {
                  return OperationBalanceCard(
                    title: 'Solde Espèce',
                    amount: CashBalanceController.instance.soldeEspece,
                    isVisible: _showCashBalance,
                    onToggleVisibility: () =>
                        setState(() => _showCashBalance = !_showCashBalance),
                    logo: const CashBalanceLogo(size: 38),
                    onTap: () => _showCashDrawerModal(context),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: _showCustomizeModal,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Personnaliser',
                        style: TextStyle(
                          color: AppTokens.primary500,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          color: AppTokens.primary500, size: 15),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OperationCategoryTabs(
              selectedCategory: _selectedCategory,
              onSelectCategory: (cat) =>
                  setState(() => _selectedCategory = cat),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            OperationsGrid(
              category: _selectedCategory,
              onSelectOperation: _onSelectOperation,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTwoForm(bool isDark) {
    final primaryColor = AppTokens.primary500;

    return RepaintBoundary(
      child: SingleChildScrollView(
        key: const ValueKey('part_2_form'),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isProfitTransfer) ...[
              OperationPhoneInputCard(
                controller: _clientPhoneController,
                recentSuggestions: _historySuggestions,
                isDark: isDark,
                onSelectedSuggestion: (suggestion) {
                  _clientNameController.text = suggestion.clientName;
                  if (_amountController.text.isEmpty &&
                      suggestion.lastAmount > 0) {
                    _amountController.text =
                        suggestion.lastAmount.round().toString();
                    _calculateCommission();
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
            OperationAmountInputCard(
              controller: _amountController,
              focusNode: _focusAmountNode,
              isDark: isDark,
              onClear: () {
                _amountController.clear();
                _calculateCommission();
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Montants rapides',
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<double>(
              valueListenable: _amountNotifier,
              builder: (context, currentAmount, _) {
                return OperationQuickAmountsGrid(
                  currentAmount: currentAmount,
                  onSelectAmount: (amt) {
                    _amountController.text = amt.toString();
                    _calculateCommission();
                  },
                  isDark: isDark,
                );
              },
            ),
            const SizedBox(height: 28),
            ValueListenableBuilder<double>(
              valueListenable: _commissionNotifier,
              builder: (context, estCommission, _) {
                return OperationEstimatedCommissionCard(
                  estimatedCommission: estCommission,
                  isDark: isDark,
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _validateFormBeforeConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: primaryColor.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Valider l\'Opération',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
