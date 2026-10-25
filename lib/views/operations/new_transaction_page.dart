import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/operation_phone_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/sim_card_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../core/app_logger.dart';
import '../../core/tokens.dart';
import '../../core/user_feedback.dart';
import '../../models/commission_rates_model.dart';
import '../../models/new_transaction_route_args.dart';
import '../../models/operation_phone_wallet_model.dart';
import '../../models/sim_card_model.dart';
import '../../models/transaction_model.dart';
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
  bool _hidePhoneSuggestions = false;
  List<ClientHistorySuggestion> _historySuggestions = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showOmBalance = true;
  bool _showCreditBalance = true;
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

    _transactionController.getRecentClientHistorySuggestions().then((suggestions) {
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

  double get _omBalance => _selectedSim != null ? _selectedSim!.soldeUv : _wallet.soldeUv;
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
    final com = TransactionModel.calculateCommission(_selectedType!, amount, rates: _commissionRates);
    _amountNotifier.value = amount;
    _commissionNotifier.value = com;
  }

  double get _estimatedCommission => _commissionNotifier.value;

  double get _enteredAmount {
    final raw = _amountController.text.trim().replaceAll(' ', '');
    return double.tryParse(raw) ?? 0.0;
  }

  bool get _isProfitTransfer => _selectedType == TransactionType.transfertProfitUv;

  double get _currentSimBalance {
    if (_selectedSim == null) return _selectedCategory == 'CREDIT' ? _wallet.profitUv : _wallet.soldeUv;
    return _selectedCategory == 'CREDIT' ? _selectedSim!.soldeCredit : _selectedSim!.soldeUv;
  }

  String _formatAmount(double amount) => NumberFormat('#,##0', 'fr_FR').format(amount);

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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => OperationCustomizeSheet(
          showOmBalance: _showOmBalance,
          showCreditBalance: _showCreditBalance,
          onToggleOm: (v) {
            setMState(() => _showOmBalance = v);
            setState(() => _showOmBalance = v);
          },
          onToggleCredit: (v) {
            setMState(() => _showCreditBalance = v);
            setState(() => _showCreditBalance = v);
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const OperationNotificationsSheet(),
    );
  }

  void _validateFormBeforeConfirm() {
    if (_enteredAmount <= 0) {
      UserFeedback.showToast(context, 'Veuillez saisir un montant supérieur à 0.', type: AppToastType.warning);
      return;
    }

    if (!_isProfitTransfer) {
      final phone = _clientPhoneController.text.trim();
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 8) {
        UserFeedback.showToast(context, 'Le numéro client doit comporter au moins 8 chiffres.', type: AppToastType.warning);
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
    final phone = _isProfitTransfer ? (activePhone ?? 'Interne') : _clientPhoneController.text.trim();
    final name = _clientNameController.text.trim().isNotEmpty ? _clientNameController.text.trim() : 'Client direct';

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
      UserFeedback.showToast(context, 'Session expirée. Veuillez vous reconnecter.', type: AppToastType.error);
      return;
    }

    final amount = _enteredAmount;
    final activePhone = _selectedSim?.phone ??
        OperationPhoneController.instance.selectedForFilter ??
        OperationPhoneController.instance.registeredPhones.firstOrNull;
    final phone = _isProfitTransfer ? (activePhone ?? 'Interne') : _clientPhoneController.text.trim();
    final name = _clientNameController.text.trim().isNotEmpty ? _clientNameController.text.trim() : 'Client direct';

    final tx = TransactionModel(
      userId: userId,
      type: _selectedType!,
      category: _selectedCategory == 'CREDIT' ? TransactionCategory.CREDIT : TransactionCategory.UV,
      clientName: name,
      clientPhone: phone,
      merchantPhone: activePhone,
      amount: amount,
      commission: _estimatedCommission,
      soldeApres: 0,
      createdAt: DateTime.now(),
    );

    try {
      final savedTx = await _transactionController.addTransaction(tx);
      await SimCardController.instance.loadSimCards();

      if (!mounted) return;
      Navigator.pop(dialogCtx);

      setState(() {
        _completedTransaction = savedTx;
        _currentStep = 3;
        _isSubmitting = false;
      });
    } catch (e, st) {
      AppLogger.error('Erreur exécution transaction', e, st);
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(dialogCtx);
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
            ? IconButton(
                icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : Colors.black87, size: 26),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                tooltip: 'Menu',
              )
            : IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  size: 24,
                ),
                onPressed: () => setState(() => _currentStep = 1),
                tooltip: 'Retour aux opérations',
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
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white : Colors.black87, size: 24),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTokens.primary500,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: _showNotificationsSheet,
              tooltip: 'Notifications',
            ),
            const SizedBox(width: 4),
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
            OperationBalanceCard(
              title: 'Solde Orange Money',
              amount: _omBalance,
              isVisible: _showOmBalance,
              onToggleVisibility: () => setState(() => _showOmBalance = !_showOmBalance),
              logo: const OrangeMoneyLogo(size: 38),
            ),
            const SizedBox(height: 10),
            OperationBalanceCard(
              title: 'Solde Crédit',
              amount: _creditBalance,
              isVisible: _showCreditBalance,
              onToggleVisibility: () => setState(() => _showCreditBalance = !_showCreditBalance),
              logo: const CreditBalanceLogo(size: 38),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: _showCustomizeModal,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: AppTokens.primary500, size: 15),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OperationCategoryTabs(
              selectedCategory: _selectedCategory,
              onSelectCategory: (cat) => setState(() => _selectedCategory = cat),
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
                  if (_amountController.text.isEmpty && suggestion.lastAmount > 0) {
                    _amountController.text = suggestion.lastAmount.round().toString();
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
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
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
