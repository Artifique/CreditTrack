import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/tokens.dart';
import '../../core/user_feedback.dart';
import '../../controllers/operation_phone_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/sim_card_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/commission_rates_model.dart';
import '../../models/new_transaction_route_args.dart';
import '../../models/operation_phone_wallet_model.dart';
import '../../models/sim_card_model.dart';
import '../../models/transaction_model.dart';
import '../../services/export_share_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/ui/ui.dart';
import 'receipt_page.dart';

class _BannerItem {
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final List<Color> gradient;
  final IconData icon;

  const _BannerItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.gradient,
    required this.icon,
  });
}

class NewTransactionPage extends StatefulWidget {
  final NewTransactionRouteArgs? routeArgs;

  const NewTransactionPage({super.key, this.routeArgs});

  @override
  State<NewTransactionPage> createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends State<NewTransactionPage> {
  // Navigation: 1 = Choix Opération, 2 = Saisie Opération, 3 = Opération Réussie
  int _currentStep = 1;

  final _transactionController = TransactionController();
  final _clientPhoneController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _focusAmountNode = FocusNode();

  // Selected State
  String _selectedCategory = 'UV'; // 'UV' ou 'CREDIT'
  TransactionType? _selectedType;
  SimCardModel? _selectedSim;
  bool _hidePhoneSuggestions = false;
  List<String> _historyPhones = [];

  String _formatPhoneDisplay(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 9) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7, 9)}';
    } else if (digits.length == 8) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)}';
    }
    return phone;
  }

  // Reference UI State
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;
  bool _showOmBalance = true;
  bool _showNafamaBalance = true;
  OperationPhoneWalletModel _wallet = OperationPhoneWalletModel.empty;

  // Calculation & Rates
  CommissionRates _commissionRates = CommissionRates.defaults;
  double _estimatedCommission = 0.0;
  String _businessName = "ALY TOURE SERVICE";
  bool _isSubmitting = false;

  // Post-Transaction Result
  TransactionModel? _completedTransaction;

  // Quick Amounts
  static const _quickAmounts = [1000, 2000, 3000, 4000, 5000, 10000];


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

    // Load wallet & business settings
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

    _transactionController.getRecentClientPhones().then((phones) {
      if (mounted) {
        setState(() => _historyPhones = phones);
      }
    });

    // Auto-resolve active SIM from dashboard filter or default SIM
    _autoSelectActiveSim();

    // Handle initial route args if passed from dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final a = widget.routeArgs;
      if (a?.initialType != null && mounted) {
        final t = a!.initialType!;
        final isCredit = _creditTypes.contains(t);
        setState(() {
          _selectedCategory = isCredit ? 'CREDIT' : 'UV';
          _selectedType = t;
          _currentStep = 2; // Jump directly to amount entry when type is pre-selected
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
    _bannerController.dispose();
    _amountController.dispose();
    _clientPhoneController.dispose();
    _clientNameController.dispose();
    _focusAmountNode.dispose();
    super.dispose();
  }

  double get _omBalance => _selectedSim != null ? _selectedSim!.soldeUv : _wallet.soldeUv;
  double get _nafamaBalance => _selectedSim != null
      ? _selectedSim!.soldeCredit
      : (_wallet.profitUv > 0 ? _wallet.profitUv : 124500.0);

  void _calculateCommission() {
    if (_selectedType == null) {
      setState(() => _estimatedCommission = 0);
      return;
    }
    final raw = _amountController.text.trim().replaceAll(' ', '');
    final amount = double.tryParse(raw) ?? 0.0;
    final com = TransactionModel.calculateCommission(_selectedType!, amount, rates: _commissionRates);
    setState(() => _estimatedCommission = com);
  }

  double get _enteredAmount {
    final raw = _amountController.text.trim().replaceAll(' ', '');
    return double.tryParse(raw) ?? 0.0;
  }

  bool get _isProfitTransfer => _selectedType == TransactionType.transfertProfitUv;

  double get _currentSimBalance {
    if (_selectedSim == null) return 0.0;
    return _selectedCategory == 'CREDIT' ? _selectedSim!.soldeCredit : _selectedSim!.soldeUv;
  }

  String _formatAmount(double amount) => NumberFormat('#,##0', 'fr_FR').format(amount);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: _currentStep == 1
            ? IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.black87, size: 26),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                tooltip: "Menu",
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
                onPressed: () => setState(() => _currentStep = 1),
                tooltip: "Retour aux opérations",
              ),
        title: Text(
          _currentStep == 1
              ? "Nouvelle Opération"
              : (_currentStep == 2 ? TransactionModel.typeDisplayName(_selectedType!) : "Opération Réussie"),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: Colors.black87, size: 24),
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
            tooltip: "Notifications",
          ),
          const SizedBox(width: 4),
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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    switch (_currentStep) {
      case 1:
        return _buildPartOne(isDark);
      case 2:
        return _buildPartTwo(isDark);
      case 3:
        return _buildPartThreeSuccess(isDark);
      default:
        return _buildPartOne(isDark);
    }
  }

  // ===========================================================================
  // PARTIE 1 — INTERFACE DE RÉFÉRENCE ORANGE MONEY
  // ===========================================================================
  Widget _buildPartOne(bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('part_1_om'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Zone de bannière avec plusieurs images d'information Orange Money
          _buildBannersSection(),
          const SizedBox(height: 18),

          // 2. Deux grandes cartes de solde
          // Carte 1 : Solde Orange Money
          _buildBalanceCard(
            title: "Solde Orange Money",
            amount: _omBalance,
            isVisible: _showOmBalance,
            onToggleVisibility: () => setState(() => _showOmBalance = !_showOmBalance),
            logo: _buildOrangeMoneyLogo(size: 38),
          ),
          const SizedBox(height: 10),

          // Carte 2 : Solde Nafama
          _buildBalanceCard(
            title: "Solde Nafama",
            amount: _nafamaBalance,
            isVisible: _showNafamaBalance,
            onToggleVisibility: () => setState(() => _showNafamaBalance = !_showNafamaBalance),
            logo: _buildNafamaLogo(size: 38),
          ),
          const SizedBox(height: 6),

          // 3. À droite sous les soldes : « Personnaliser → » en orange
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
                      "Personnaliser",
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

          // Tabs
          _buildCategoryTabs(isDark),
          const SizedBox(height: 16),

          // 4. Grille des opérations
          _buildOperationsGrid(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Bannières horizontales d'information
  Widget _buildBannersSection() {
    final banners = [
      const _BannerItem(
        title: "Orange Money Caisse",
        subtitle: "Effectuez vos dépôts et retraits en toute sécurité",
        badge: "SERVICE PRO",
        badgeColor: Color(0xFF1E293B),
        gradient: [AppTokens.primary500, AppTokens.primary600],
        icon: Icons.account_balance_wallet_rounded,
      ),
      const _BannerItem(
        title: "Orange Money Nafama",
        subtitle: "Épargnez et faites fructifier les avoirs de vos clients",
        badge: "ÉPARGNE SÉCURISÉE",
        badgeColor: AppTokens.primary500,
        gradient: [Color(0xFF0F172A), Color(0xFF1E293B)],
        icon: Icons.savings_rounded,
      ),
      const _BannerItem(
        title: "E-Recharge & C2C",
        subtitle: "Rechargez les forfaits et transférez sans attente",
        badge: "INSTANTANÉ",
        badgeColor: Color(0xFF10B981),
        gradient: [Color(0xFFEA580C), Color(0xFFC2410C)],
        icon: Icons.phone_android_rounded,
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 104,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            onPageChanged: (idx) => setState(() => _bannerIndex = idx),
            itemBuilder: (context, index) {
              final b = banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: b.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: b.badgeColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              b.badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            b.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            b.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFFFF7ED),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(b.icon, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _bannerIndex == i ? 18 : 6,
              height: 5,
              decoration: BoxDecoration(
                color: _bannerIndex == i ? AppTokens.primary500 : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Grande carte de solde avec bordure orange fine
  Widget _buildBalanceCard({
    required String title,
    required double amount,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required Widget logo,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTokens.primary500, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          logo,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isVisible ? "${_formatAmount(amount)} CFA" : "•••••••• CFA",
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleVisibility,
            icon: Icon(
              isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: const Color(0xFF6B7280),
              size: 22,
            ),
            splashRadius: 20,
            tooltip: isVisible ? "Masquer le solde" : "Afficher le solde",
          ),
        ],
      ),
    );
  }

  // Logo Orange Money
  Widget _buildOrangeMoneyLogo({double size = 38}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTokens.primary500,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: AppTokens.primary500.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          "om",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.52,
            letterSpacing: -1,
            fontFamily: 'sans-serif',
          ),
        ),
      ),
    );
  }

  // Logo Nafama
  Widget _buildNafamaLogo({double size = 38}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2810B981),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.savings_rounded,
          color: Colors.white,
          size: size * 0.58,
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTokens.darkBgSubtle : AppTokens.lightBgSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = 'UV'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedCategory == 'UV' 
                      ? (isDark ? AppTokens.darkSurface : Colors.white) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedCategory == 'UV'
                      ? [const BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  "Mobile Money",
                  style: TextStyle(
                    fontWeight: _selectedCategory == 'UV' ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13.5,
                    color: _selectedCategory == 'UV' 
                        ? (isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary)
                        : (isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = 'CREDIT'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedCategory == 'CREDIT' 
                      ? (isDark ? AppTokens.darkSurface : Colors.white) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedCategory == 'CREDIT'
                      ? [const BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  "Crédit",
                  style: TextStyle(
                    fontWeight: _selectedCategory == 'CREDIT' ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13.5,
                    color: _selectedCategory == 'CREDIT' 
                        ? (isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary)
                        : (isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Grille d'opérations dynamique selon l'onglet
  Widget _buildOperationsGrid() {
    if (_selectedCategory == 'CREDIT') {
      return GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildOperationCard(
            title: "ACHAT CRÉDIT",
            icon: Icons.phone_android_rounded,
            onTap: () => _onSelectOperation(TransactionType.achat),
          ),
          _buildOperationCard(
            title: "FORFAIT",
            icon: Icons.card_giftcard_rounded,
            onTap: () => _onSelectOperation(TransactionType.forfait),
          ),
          _buildOperationCard(
            title: "SEWA",
            icon: Icons.flash_on_rounded,
            onTap: () => _onSelectOperation(TransactionType.sewa),
          ),
          _buildOperationCard(
            title: "TRANSFERT",
            icon: Icons.send_rounded,
            onTap: () => _onSelectOperation(TransactionType.transfertCredit),
          ),
        ],
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildOperationCard(
          title: "DEPOT",
          icon: Icons.arrow_downward_rounded,
          onTap: () => _onSelectOperation(TransactionType.depot),
        ),
        _buildOperationCard(
          title: "RETRAIT",
          icon: Icons.arrow_upward_rounded,
          onTap: () => _onSelectOperation(TransactionType.retrait),
        ),
        _buildOperationCard(
          title: "NAFAMA",
          icon: Icons.savings_rounded,
          onTap: () => _onSelectOperation(TransactionType.nafama),
        ),
        _buildOperationCard(
          title: "TRANSFERT UV",
          icon: Icons.sync_alt_rounded,
          onTap: () => _onSelectOperation(TransactionType.transfertUv),
        ),
        _buildOperationCard(
          title: "TRANSFERT C2C",
          icon: Icons.swap_horiz_rounded,
          onTap: () => _onSelectOperation(TransactionType.transfertC2c),
        ),
        _buildOperationCard(
          title: "TRANSFERT PROFIT",
          icon: Icons.trending_up_rounded,
          onTap: () => _onSelectOperation(TransactionType.transfertProfitUv),
        ),
      ],
    );
  }

  // Carte d'opération avec bordure orange fine et icône illustrée
  Widget _buildOperationCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppTokens.primary500.withValues(alpha: 0.05),
        splashColor: AppTokens.primary500.withValues(alpha: 0.10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTokens.primary500, width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 2),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7ED),
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
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSelectOperation(TransactionType type) {
    final isCredit = type == TransactionType.achat ||
        type == TransactionType.forfait ||
        type == TransactionType.sewa ||
        type == TransactionType.transfertCredit;
    setState(() {
      _selectedCategory = isCredit ? 'CREDIT' : 'UV';
      _selectedType = type;
      _currentStep = 2;
    });
    _calculateCommission();
  }

  // Barre de navigation fixe (3 éléments)
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Accueil / Nouvelle Opération (sélectionné en orange)
              _buildBottomNavItem(
                icon: Icons.home_rounded,
                label: "Accueil",
                isSelected: _currentStep == 1,
                onTap: () {
                  if (_currentStep != 1) {
                    setState(() => _currentStep = 1);
                  }
                },
              ),
              // Menu (noir)
              _buildBottomNavItem(
                icon: Icons.grid_view_rounded,
                label: "Menu",
                isSelected: false,
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              // Reporting (noir)
              _buildBottomNavItem(
                icon: Icons.bar_chart_rounded,
                label: "Reporting",
                isSelected: false,
                onTap: () => Navigator.pushNamed(context, '/reports'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? AppTokens.primary500 : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Menu Hamburger (Tiroir)
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTokens.primary500, AppTokens.primary600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  _buildOrangeMoneyLogo(size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _businessName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _selectedSim?.phone.isNotEmpty == true
                              ? "Ligne active : ${_selectedSim!.phone}"
                              : "Orange Money Caisse",
                          style: const TextStyle(
                            color: Color(0xFFFFF3E0),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_rounded, color: AppTokens.primary500),
                    title: const Text("Accueil / Nouvelle Opération", style: TextStyle(fontWeight: FontWeight.w700)),
                    onTap: () {
                      Navigator.pop(context);
                      if (_currentStep != 1) setState(() => _currentStep = 1);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history_rounded, color: Colors.black87),
                    title: const Text("Journal des transactions", style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/history');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart_rounded, color: Colors.black87),
                    title: const Text("Reporting & Commissions", style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/reports');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.sim_card_rounded, color: Colors.black87),
                    title: const Text("Gestion des cartes SIM", style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings-sims');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined, color: Colors.black87),
                    title: const Text("Paramètres", style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    title: const Text("Déconnexion", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(context);
                      await Supabase.instance.client.auth.signOut();
                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                      }
                    },
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Orange Money • CreditTrack Pro",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modale Personnaliser
  void _showCustomizeModal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setMState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Personnaliser l'affichage",
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text("Afficher le solde Orange Money", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      value: _showOmBalance,
                      activeThumbColor: AppTokens.primary500,
                      onChanged: (v) {
                        setMState(() => _showOmBalance = v);
                        setState(() => _showOmBalance = v);
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Afficher le solde Nafama", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      value: _showNafamaBalance,
                      activeThumbColor: AppTokens.primary500,
                      onChanged: (v) {
                        setMState(() => _showNafamaBalance = v);
                        setState(() => _showNafamaBalance = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.sim_card_outlined, color: AppTokens.primary500),
                      title: const Text("Gérer les cartes SIM associées", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(context, '/settings-sims');
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Modale Notifications
  void _showNotificationsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Notifications & Alertes",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF7ED),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppTokens.primary500, size: 20),
                  ),
                  title: const Text("Caisse Orange Money connectée", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  subtitle: const Text("Vos soldes sont synchronisés en direct.", style: TextStyle(fontSize: 12)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.savings_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  title: const Text("Compte Nafama actif", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  subtitle: const Text("Opérations d'épargne disponibles à la caisse.", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // PARTIE 2 — SAISIE DE L’OPÉRATION (NUMÉRO & MONTANT)
  // ===========================================================================
  Widget _buildPartTwo(bool isDark) {
    final typeName = TransactionModel.typeDisplayName(_selectedType!);

    return SingleChildScrollView(
      key: const ValueKey('part_2'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Récapitulatif sélectionné avec bouton modifier
          AppCard(
            variant: AppCardVariant.elevated,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x336366F1) : AppTokens.primary50,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: Icon(
                    _iconForType(_selectedType!),
                    color: isDark ? AppTokens.primary300 : AppTokens.primary600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            typeName.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppBadge(
                            label: _selectedCategory,
                            variant: _selectedCategory == 'UV' ? AppBadgeVariant.primary : AppBadgeVariant.success,
                            fontSize: 11,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedSim != null
                            ? "Compte : ${_selectedSim!.displayName} • Solde: ${_formatAmount(_currentSimBalance)} F"
                            : "Opération prête",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _currentStep = 1),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      "Modifier",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTokens.primary300 : AppTokens.primary600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space24),

          // Saisie Numéro Client
          if (!_isProfitTransfer) ...[
            _buildClientPhoneSection(isDark),
            const SizedBox(height: AppTokens.space20),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTokens.darkInfoBg : AppTokens.infoBg,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: isDark ? const Color(0x4D3B82F6) : AppTokens.infoBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppTokens.info, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Transfert interne des bénéfices UV vers le solde de travail de la SIM.",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space20),
          ],

          // Saisie Montant & Boutons rapides
          _buildAmountSection(isDark),
          const SizedBox(height: AppTokens.space24),

          // Récapitulatif live des frais et commissions
          _buildLiveCalculationCard(isDark),
          const SizedBox(height: AppTokens.space28),

          // Grand Bouton Valider
          AppButton(
            label: "VALIDER L’OPÉRATION",
            icon: Icons.check_circle_outline_rounded,
            size: AppButtonSize.lg,
            isFullWidth: true,
            onPressed: _validateFormBeforeConfirm,
          ),
          const SizedBox(height: AppTokens.space32),
        ],
      ),
    );
  }

  Widget _buildClientPhoneSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "NUMÉRO CLIENT",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        AppInput(
          controller: _clientPhoneController,
          hintText: "ex: 77 123 45 67",
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_rounded,
          onChanged: (_) {
            setState(() {
              _hidePhoneSuggestions = false;
            });
          },
        ),
        const SizedBox(height: 4),

        // Autocomplete suggestions (Smart dropdown)
        Builder(
          builder: (context) {
            final query = _clientPhoneController.text.trim();
            
            if (query.isEmpty || _hidePhoneSuggestions) {
              return const SizedBox.shrink();
            }

            final queryClean = query.replaceAll(' ', '');
            final matches = _historyPhones
                .where((phone) => phone.replaceAll(' ', '').startsWith(queryClean))
                .take(5)
                .toList();

            // Check if exact match to hide
            if (matches.length == 1 && matches.first.replaceAll(' ', '') == queryClean) {
              return const SizedBox.shrink();
            }

            if (matches.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(
                  "Aucun numéro récent correspondant",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }

            return Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: isDark ? AppTokens.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: isDark ? AppTokens.darkBorder : AppTokens.lightBorder),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                children: matches.map((matchPhone) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _clientPhoneController.text = _formatPhoneDisplay(matchPhone);
                        _hidePhoneSuggestions = true;
                      });
                      FocusScope.of(context).unfocus();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 18, color: AppTokens.primary500),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _formatPhoneDisplay(matchPhone),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAmountSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "MONTANT (FCFA)",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        AppInput(
          controller: _amountController,
          focusNode: _focusAmountNode,
          hintText: "0",
          keyboardType: TextInputType.number,
          prefix: Padding(
            padding: const EdgeInsets.only(left: 14, right: 8),
            child: Text(
              "FCFA",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: isDark ? AppTokens.primary300 : AppTokens.primary600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Boutons de montants rapides
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._quickAmounts.map((amt) {
              final isSelected = _enteredAmount == amt.toDouble();
              return InkWell(
                onTap: () {
                  _amountController.text = amt.toString();
                  _calculateCommission();
                },
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTokens.primary500
                        : (isDark ? AppTokens.darkSurface : AppTokens.lightSurface),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(
                      color: isSelected
                          ? AppTokens.primary500
                          : (isDark ? AppTokens.darkBorder : AppTokens.lightBorder),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    "${_formatAmount(amt.toDouble())} F",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary),
                    ),
                  ),
                ),
              );
            }),
            InkWell(
              onTap: () {
                _amountController.clear();
                _focusAmountNode.requestFocus();
              },
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isDark ? AppTokens.darkBgSubtle : AppTokens.lightBgSubtle,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(
                    color: isDark ? AppTokens.darkBorder : AppTokens.lightBorder,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  "AUTRE MONTANT",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTokens.primary300 : AppTokens.primary600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveCalculationCard(bool isDark) {
    final amount = _enteredAmount;
    const fees = 0.0;

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Montant de l'opération",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
                ),
              ),
              Text(
                "${_formatAmount(amount)} FCFA",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Frais applicables",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
                ),
              ),
              Text(
                fees == 0 ? "Gratuit (0 F)" : "${_formatAmount(fees)} F",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTokens.secondary300 : AppTokens.secondary600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.savings_rounded, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    "Commission générée",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTokens.secondary300 : AppTokens.secondary600,
                    ),
                  ),
                ],
              ),
              Text(
                "+${_formatAmount(_estimatedCommission)} F",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTokens.secondary300 : AppTokens.secondary600,
                ),
              ),
            ],
          ),
          if (_selectedSim != null) ...[
            Divider(
              height: 20,
              thickness: 1,
              color: isDark ? AppTokens.darkBorder : AppTokens.lightBorder,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Solde disponible",
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                  ),
                ),
                Text(
                  "${_formatAmount(_currentSimBalance)} F",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Validation & Confirmation Modal
  void _validateFormBeforeConfirm() {
    if (_enteredAmount <= 0) {
      UserFeedback.showToast(context, "Veuillez saisir un montant supérieur à 0.", type: AppToastType.warning);
      return;
    }

    if (!_isProfitTransfer) {
      final phone = _clientPhoneController.text.trim();
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 8) {
        UserFeedback.showToast(
          context,
          "Le numéro client doit comporter au moins 8 chiffres.",
          type: AppToastType.warning,
        );
        return;
      }
    }

    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amount = _enteredAmount;
    final activePhone = _selectedSim?.phone ??
        OperationPhoneController.instance.selectedForFilter ??
        OperationPhoneController.instance.registeredPhones.firstOrNull;
    final phone = _isProfitTransfer ? (activePhone ?? "Interne") : _clientPhoneController.text.trim();
    final name = _clientNameController.text.trim().isNotEmpty ? _clientNameController.text.trim() : "Client direct";

    showDialog<void>(
      context: context,
      barrierDismissible: !_isSubmitting,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? AppTokens.darkSurface : AppTokens.lightSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius2Xl)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x336366F1) : AppTokens.primary50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.help_outline_rounded, color: AppTokens.primary500, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  "Confirmer l'opération",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfirmRow("Opération", TransactionModel.typeDisplayName(_selectedType!), isBold: true, isDark: isDark),
                if (_selectedSim != null)
                  _buildConfirmRow("Compte / SIM", "${_selectedSim!.displayName} (${_selectedSim!.phone})", isDark: isDark),
                _buildConfirmRow("Numéro Client", "$phone ($name)", isDark: isDark),
                _buildConfirmRow("Montant", "${_formatAmount(amount)} FCFA", isHighlight: true, isDark: isDark),
                _buildConfirmRow("Frais", "0 F", isDark: isDark),
                _buildConfirmRow("Commission estimée", "+${_formatAmount(_estimatedCommission)} F", isDark: isDark),
              ],
            ),
            actions: [
              TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: const Text("MODIFIER", style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              AppButton(
                label: "CONFIRMER",
                icon: Icons.check_rounded,
                size: AppButtonSize.md,
                isLoading: _isSubmitting,
                onPressed: () async {
                  setDialogState(() => _isSubmitting = true);
                  await _executeTransaction(dialogCtx);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value, {bool isBold = false, bool isHighlight = false, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: isHighlight ? 15 : 13.5,
                fontWeight: isHighlight || isBold ? FontWeight.w800 : FontWeight.w600,
                color: isHighlight
                    ? (isDark ? AppTokens.primary300 : AppTokens.primary600)
                    : (isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeTransaction(BuildContext dialogCtx) async {
    setState(() => _isSubmitting = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      Navigator.pop(dialogCtx);
      UserFeedback.showToast(context, "Session expirée. Veuillez vous reconnecter.", type: AppToastType.error);
      return;
    }

    final amount = _enteredAmount;
    final activePhone = _selectedSim?.phone ??
        OperationPhoneController.instance.selectedForFilter ??
        OperationPhoneController.instance.registeredPhones.firstOrNull;
    final phone = _isProfitTransfer ? (activePhone ?? "Interne") : _clientPhoneController.text.trim();
    final name = _clientNameController.text.trim().isNotEmpty ? _clientNameController.text.trim() : "Client direct";

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

      // Save client in recents if it was a real client
      if (!_isProfitTransfer) {
        // Nothing to do locally anymore, history is fetched from db
      }

      // Refresh SIM balances
      await SimCardController.instance.loadSimCards();

      if (!mounted) return;
      Navigator.pop(dialogCtx);

      setState(() {
        _completedTransaction = savedTx;
        _currentStep = 3;
        _isSubmitting = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(dialogCtx);
        await UserFeedback.showErrorModal(context, e);
      }
    }
  }

  // ===========================================================================
  // PARTIE 3 — ÉCRAN « OPÉRATION RÉUSSIE »
  // ===========================================================================
  Widget _buildPartThreeSuccess(bool isDark) {
    final tx = _completedTransaction;
    if (tx == null) return const SizedBox.shrink();

    final dateStr = DateFormat('dd/MM/yyyy à HH:mm').format(tx.createdAt);
    final ref = tx.journalSeq != null ? "#${tx.journalSeq}" : (tx.id?.substring(0, 8).toUpperCase() ?? "OP-RÉUSSIE");

    return SingleChildScrollView(
      key: const ValueKey('part_3'),
      child: Column(
        children: [
          const SizedBox(height: AppTokens.space16),
          // Icône de succès animée
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? AppTokens.darkSuccessBg : AppTokens.successBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppTokens.success, width: 2),
                boxShadow: AppTokens.shadowGlow(AppTokens.success),
              ),
              child: const Icon(Icons.check_rounded, color: AppTokens.success, size: 40),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "OPÉRATION RÉUSSIE",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Réf. journal $ref • $dateStr",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
            ),
          ),
          const SizedBox(height: AppTokens.space24),

          // Reçu visuel synthétique
          AppCard(
            variant: AppCardVariant.elevated,
            padding: const EdgeInsets.all(AppTokens.space20),
            child: Column(
              children: [
                _buildReceiptRow("Type", TransactionModel.typeDisplayName(tx.type), isDark: isDark),
                _buildReceiptRow("Montant", "${_formatAmount(tx.amount)} FCFA", isBold: true, isDark: isDark),
                _buildReceiptRow("Commission", "+${_formatAmount(tx.commission)} FCFA", isHighlight: true, isDark: isDark),
                _buildReceiptRow("Compte SIM", tx.merchantPhone ?? "SIM Principale", isDark: isDark),
                _buildReceiptRow("Client", "${tx.clientName} (${tx.clientPhone})", isDark: isDark),
                const SizedBox(height: 12),
                Divider(height: 1, color: isDark ? AppTokens.darkBorder : AppTokens.lightBorder),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ReceiptPage(transaction: tx, businessName: _businessName),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: const Text("Voir le Reçu", style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          final file = await PdfService().generateReceipt(tx, _businessName);
                          await ExportShareService.sharePdf(file);
                        } catch (e) {
                          if (context.mounted) UserFeedback.showErrorModal(context, e);
                        }
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text("Partager Reçu", style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space32),

          // Les 3 boutons demandés : NOUVELLE OPÉRATION, MÊME CLIENT, ACCUEIL
          AppButton(
            label: "NOUVELLE OPÉRATION",
            icon: Icons.add_circle_outline_rounded,
            size: AppButtonSize.lg,
            isFullWidth: true,
            onPressed: () {
              setState(() {
                _clientPhoneController.clear();
                _clientNameController.clear();
                _amountController.clear();
                _selectedType = null;
                _completedTransaction = null;
                _currentStep = 1;
              });
            },
          ),
          const SizedBox(height: 12),
          AppButton(
            label: "MÊME CLIENT",
            icon: Icons.person_add_alt_1_rounded,
            variant: AppButtonVariant.outline,
            size: AppButtonSize.lg,
            isFullWidth: true,
            onPressed: () {
              // Keeps the client phone and name, resets amount & step
              setState(() {
                _amountController.clear();
                _selectedType = null;
                _completedTransaction = null;
                _currentStep = 1;
              });
            },
          ),
          const SizedBox(height: 12),
          AppButton(
            label: "ACCUEIL",
            icon: Icons.home_rounded,
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.md,
            isFullWidth: true,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppTokens.space32),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, bool isHighlight = false, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isBold || isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight
                  ? (isDark ? AppTokens.secondary300 : AppTokens.secondary600)
                  : (isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.depot:
        return Icons.arrow_downward_rounded;
      case TransactionType.retrait:
        return Icons.arrow_upward_rounded;
      case TransactionType.nafama:
        return Icons.savings_outlined;
      case TransactionType.transfertUv:
        return Icons.swap_horiz_rounded;
      case TransactionType.transfertC2c:
        return Icons.people_alt_outlined;
      case TransactionType.transfertProfitUv:
        return Icons.trending_up_rounded;
      case TransactionType.achat:
        return Icons.add_card_rounded;
      case TransactionType.forfait:
        return Icons.wifi_rounded;
      case TransactionType.sewa:
        return Icons.phonelink_ring_rounded;
      case TransactionType.transfertCredit:
        return Icons.mobile_screen_share_rounded;
    }
  }
}




