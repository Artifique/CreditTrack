import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/tokens.dart';
import '../../controllers/operation_phone_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/theme_mode_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/new_transaction_route_args.dart';
import '../../models/operation_phone_wallet_model.dart';
import '../../models/profile_model.dart';
import '../../models/transaction_model.dart';
import '../../widgets/operation_phone_selector.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/ui/ui.dart';
import '../operations/transaction_detail_page.dart';
import 'widgets/activity_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _transactionController = TransactionController();
  late Future<ProfileModel?> _profileFuture;
  OperationPhoneWalletModel _wallet = OperationPhoneWalletModel.empty;
  Timer? _walletDebounce;
  String _lastTxSigForWallet = '';

  @override
  void initState() {
    super.initState();
    OperationPhoneController.instance.addListener(_scheduleWalletRefresh);
    _profileFuture = _transactionController.getProfileData();
    _profileFuture.then((p) {
      if (p != null) {
        OperationPhoneController.instance.syncFromProfile(p.operationPhones);
      }
    });
    SettingsController().getBusinessSettings().then((s) {
      if (mounted) ThemeModeController.instance.applyFromRemote(s.darkMode);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _pullWallet());
  }

  @override
  void dispose() {
    OperationPhoneController.instance.removeListener(_scheduleWalletRefresh);
    _walletDebounce?.cancel();
    super.dispose();
  }

  void _scheduleWalletRefresh() {
    _walletDebounce?.cancel();
    _walletDebounce = Timer(const Duration(milliseconds: 200), _pullWallet);
  }

  Future<void> _pullWallet() async {
    final w = await _transactionController.getWalletViewForFilter(
      merchantPhone: OperationPhoneController.instance.selectedForFilter,
    );
    if (mounted) setState(() => _wallet = w);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<ProfileModel?>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        return ListenableBuilder(
          listenable: OperationPhoneController.instance,
          builder: (context, _) {
            return StreamBuilder<List<TransactionModel>>(
              stream: _transactionController.watchTransactions(
                merchantPhone: OperationPhoneController.instance.selectedForFilter,
              ),
              builder: (context, txSnapshot) {
                final transactions = txSnapshot.data ?? [];
                final txSig = transactions.map((e) => '${e.id}_${e.amount}_${e.merchantPhone}').join('|');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || txSig == _lastTxSigForWallet) return;
                  _lastTxSigForWallet = txSig;
                  _scheduleWalletRefresh();
                });

                final sel = OperationPhoneController.instance.selectedForFilter;
                final lowUv = sel != null && _wallet.soldeUv > 0 && _wallet.soldeUv < 10000;

                return Scaffold(
                  body: CustomScrollView(
                    slivers: [
                      _buildAppBar(profile, isDark),
                      SliverToBoxAdapter(
                        child: ResponsiveContainer(
                          maxWidth: 1080,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FadeInUp(
                                delay: Duration(milliseconds: 50),
                                child: OperationPhoneSelector(),
                              ),
                              if (sel == null && _wallet.profitUv > 0) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Sélectionne un numéro de transfert pour utiliser « Transférer profit UV ».',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
                                  ),
                                ),
                              ],
                              if (lowUv) ...[
                                const SizedBox(height: 14),
                                FadeInUp(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTokens.darkWarningBg : AppTokens.warningBg,
                                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                      border: Border.all(
                                        color: isDark ? const Color(0x66F59E0B) : const Color(0xFFFDE68A),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning_amber_rounded, color: AppTokens.warning, size: 22),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Solde UV faible sur ce numéro — vérifiez avant vos transferts sortants.',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppTokens.space20),
                              FadeInUp(
                                delay: const Duration(milliseconds: 100),
                                child: _buildBalanceCards(_wallet),
                              ),
                              if (sel != null && _wallet.profitUv > 0) ...[
                                const SizedBox(height: AppTokens.space16),
                                AppButton(
                                  label: 'Transférer profit UV (${_formatAmount(_wallet.profitUv)} CFA)',
                                  icon: Icons.savings_outlined,
                                  variant: AppButtonVariant.secondary,
                                  isFullWidth: true,
                                  size: AppButtonSize.md,
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/new-transaction',
                                      arguments: NewTransactionRouteArgs(
                                        initialType: TransactionType.transfertProfitUv,
                                        suggestedProfitUvAmount: _wallet.profitUv,
                                      ),
                                    );
                                  },
                                ),
                              ],
                              const SizedBox(height: AppTokens.space32),
                              FadeInUp(
                                delay: const Duration(milliseconds: 150),
                                child: AppCard(
                                  variant: AppCardVariant.elevated,
                                  padding: const EdgeInsets.all(AppTokens.space20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Activité des 7 derniers jours",
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                                            ),
                                          ),
                                          const AppBadge(
                                            label: "Temps réel",
                                            variant: AppBadgeVariant.success,
                                            showDot: true,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      ActivityChart(transactions: transactions),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTokens.space32),
                              _buildSectionTitle(context, "Opérations Rapides"),
                              const SizedBox(height: AppTokens.space16),
                              FadeInUp(
                                delay: const Duration(milliseconds: 200),
                                child: _buildQuickActions(context, isDark),
                              ),
                              const SizedBox(height: AppTokens.space32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSectionTitle(context, "Transactions Récentes"),
                                  InkWell(
                                    onTap: () => Navigator.pushNamed(context, '/history'),
                                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Row(
                                        children: [
                                          Text(
                                            "Voir tout",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppTokens.primary300 : AppTokens.primary600,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 14,
                                            color: isDark ? AppTokens.primary300 : AppTokens.primary600,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTokens.space16),
                              FadeInUp(
                                delay: const Duration(milliseconds: 250),
                                child: _buildRecentTransactions(
                                  context,
                                  transactions,
                                  profile?.businessName ?? 'Mon Commerce',
                                  isDark,
                                ),
                              ),
                              const SizedBox(height: 80), // Padding for bottom bar
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: _buildBottomNav(context, isDark),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () => Navigator.pushNamed(context, '/new-transaction'),
                    backgroundColor: AppTokens.primary500,
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                  ),
                  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAppBar(ProfileModel? profile, bool isDark) {
    return SliverAppBar(
      expandedHeight: 90,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? AppTokens.darkBg : AppTokens.lightBg,
      elevation: 0,
      scrolledUnderElevation: 2,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bonjour 👋",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
                  ),
                ),
                Text(
                  profile?.ownerName ?? profile?.businessName ?? "Commerçant",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Theme Mode Switch button
                IconButton(
                  icon: Icon(
                    ThemeModeController.instance.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 20,
                    color: isDark ? const Color(0xFFFBBF24) : AppTokens.lightTextSecondary,
                  ),
                  tooltip: ThemeModeController.instance.isDark ? "Mode clair" : "Mode sombre",
                  onPressed: () {
                    ThemeModeController.instance.setDarkMode(!ThemeModeController.instance.isDark);
                  },
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                  child: ProfileAvatar(profile: profile, radius: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCards(OperationPhoneWalletModel w) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _BalanceCard(
            title: 'Solde UV',
            amount: _formatAmount(w.soldeUv),
            gradient: AppTokens.cardGradientUV,
            icon: Icons.account_balance_wallet_rounded,
            tag: "Transferts",
          ),
          const SizedBox(width: 14),
          _BalanceCard(
            title: 'Solde Crédit',
            amount: _formatAmount(w.soldeCredit),
            gradient: AppTokens.cardGradientCredit,
            icon: Icons.phone_android_rounded,
            tag: "Recharges",
          ),
          const SizedBox(width: 14),
          _BalanceCard(
            title: 'Bénéfice UV',
            amount: _formatAmount(w.profitUv),
            gradient: const LinearGradient(
              colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            icon: Icons.trending_up_rounded,
            tag: "Commissions",
          ),
          const SizedBox(width: 14),
          _BalanceCard(
            title: 'Bénéfice Crédit',
            amount: _formatAmount(w.profitCredit),
            gradient: const LinearGradient(
              colors: [Color(0xFF7C2D12), AppTokens.primary500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            icon: Icons.stacked_line_chart_rounded,
            tag: "Commissions",
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.5,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.arrow_downward_rounded,
            label: "Dépôt",
            color: AppTokens.primary500,
            onTap: () => Navigator.pushNamed(
              context,
              '/new-transaction',
              arguments: const NewTransactionRouteArgs(initialType: TransactionType.depot),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.arrow_upward_rounded,
            label: "Retrait",
            color: const Color(0xFF10B981),
            onTap: () => Navigator.pushNamed(
              context,
              '/new-transaction',
              arguments: const NewTransactionRouteArgs(initialType: TransactionType.retrait),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.swap_horiz_rounded,
            label: "Transfert",
            color: AppTokens.primary600,
            onTap: () => Navigator.pushNamed(
              context,
              '/new-transaction',
              arguments: const NewTransactionRouteArgs(initialType: TransactionType.transfertUv),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.phone_android_rounded,
            label: "Crédit",
            color: const Color(0xFFF59E0B),
            onTap: () => Navigator.pushNamed(
              context,
              '/new-transaction',
              arguments: const NewTransactionRouteArgs(initialType: TransactionType.achat),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    List<TransactionModel> transactions,
    String businessName,
    bool isDark,
  ) {
    if (transactions.isEmpty) {
      return AppCard(
        variant: AppCardVariant.outlined,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
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
                  Icons.receipt_long_outlined,
                  size: 36,
                  color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Aucune transaction récente",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Vos prochaines opérations s'afficheront ici en direct.",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = [...transactions]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent = sorted.take(4).toList();

    return Column(
      children: List.generate(recent.length, (index) {
        final tx = recent[index];
        final t = tx.type;
        final isDepot = t == TransactionType.depot;
        final isRetrait = t == TransactionType.retrait;

        final AppBadgeVariant badgeVariant;
        final IconData iconData;
        final Color iconColor;
        final Color iconBg;

        if (isDepot) {
          badgeVariant = AppBadgeVariant.error;
          iconData = Icons.arrow_downward_rounded;
          iconColor = AppTokens.error;
          iconBg = isDark ? AppTokens.darkErrorBg : AppTokens.errorBg;
        } else if (isRetrait) {
          badgeVariant = AppBadgeVariant.success;
          iconData = Icons.arrow_upward_rounded;
          iconColor = AppTokens.success;
          iconBg = isDark ? AppTokens.darkSuccessBg : AppTokens.successBg;
        } else {
          badgeVariant = AppBadgeVariant.info;
          iconData = Icons.sync_alt_rounded;
          iconColor = AppTokens.info;
          iconBg = isDark ? AppTokens.darkInfoBg : AppTokens.infoBg;
        }

        final amountColor = t.amountDisplayColor(
          isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
        );

        final dateFormatted = DateFormat('dd/MM • HH:mm').format(tx.createdAt);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            variant: AppCardVariant.elevated,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => TransactionDetailPage(transaction: tx, businessName: businessName),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: Icon(iconData, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              tx.clientName.isNotEmpty ? tx.clientName : "Client direct",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppBadge(
                            label: TransactionModel.typeDisplayName(tx.type),
                            variant: badgeVariant,
                            fontSize: 10.5,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${tx.clientPhone.isNotEmpty ? '${tx.clientPhone} • ' : ''}$dateFormatted",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${_formatAmount(tx.amount)} F",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _formatAmount(double amount) => NumberFormat('#,##0', 'fr_FR').format(amount);

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    return BottomAppBar(
      height: 68,
      notchMargin: 8,
      color: isDark ? AppTokens.darkSurface : AppTokens.lightSurface,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.home_rounded,
            label: "Accueil",
            isActive: true,
            onTap: () {},
          ),
          _BottomNavItem(
            icon: Icons.history_rounded,
            label: "Historique",
            isActive: false,
            onTap: () => Navigator.pushNamed(context, '/history'),
          ),
          const SizedBox(width: 48), // Gap for FAB
          _BottomNavItem(
            icon: Icons.bar_chart_rounded,
            label: "Rapports",
            isActive: false,
            onTap: () => Navigator.pushNamed(context, '/reports'),
          ),
          _BottomNavItem(
            icon: Icons.settings_rounded,
            label: "Paramètres",
            isActive: false,
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isActive
        ? (isDark ? AppTokens.primary300 : AppTokens.primary600)
        : (isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatefulWidget {
  final String title;
  final String amount;
  final Gradient gradient;
  final IconData icon;
  final String tag;

  const _BalanceCard({
    required this.title,
    required this.amount,
    required this.gradient,
    required this.icon,
    required this.tag,
  });

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: AppTokens.durationFast,
        curve: AppTokens.curveStandard,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(AppTokens.space20),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(AppTokens.radius2Xl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    ),
                    child: Text(
                      widget.tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    widget.amount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    "CFA",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.03 : 1.0,
          duration: AppTokens.durationFast,
          curve: AppTokens.curveStandard,
          child: AppCard(
            variant: AppCardVariant.elevated,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


