import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
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
                      _buildAppBar(profile),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const OperationPhoneSelector(),
                              if (sel == null && _wallet.profitUv > 0) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Sélectionne un numéro d’opération pour utiliser « Transférer profit UV ».',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              if (lowUv) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Solde UV faible sur ce numéro — vérifie avant dépôts / transferts sortants.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              _buildBalanceCards(_wallet),
                              if (sel != null && _wallet.profitUv > 0) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonalIcon(
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
                                    icon: const Icon(Icons.savings_outlined),
                                    label: const Text('Transférer profit UV'),
                                  ),
                                ),
                              ],
                          const SizedBox(height: 32),
                          ActivityChart(transactions: transactions),
                          const SizedBox(height: 32),
                          _buildSectionTitle("Opérations Rapides"),
                          const SizedBox(height: 16),
                          _buildQuickActions(context),
                          const SizedBox(height: 32),
                          _buildSectionTitle("Transactions Récentes"),
                          const SizedBox(height: 16),
                          _buildRecentTransactions(
                            context,
                            transactions,
                            profile?.businessName ?? 'Mon Commerce',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: _buildBottomNav(context),
              floatingActionButton: FloatingActionButton(
                onPressed: () => Navigator.pushNamed(context, '/new-transaction'),
                backgroundColor: AppColors.primary,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
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

  Widget _buildAppBar(ProfileModel? profile) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bonjour,", style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                Text(profile?.ownerName ?? profile?.businessName ?? "Commerçant",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
              ],
            ),
            GestureDetector(
              onTap: () {}, // Accès rapide au profil
              child: ProfileAvatar(profile: profile, radius: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCards(OperationPhoneWalletModel w) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _BalanceCard(
            title: 'Solde UV',
            amount: _formatAmount(w.soldeUv),
            gradient: AppColors.cardGradientUV,
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(width: 16),
          _BalanceCard(
            title: 'Solde crédit',
            amount: _formatAmount(w.soldeCredit),
            gradient: AppColors.cardGradientCredit,
            icon: Icons.phone_android_outlined,
          ),
          const SizedBox(width: 16),
          _BalanceCard(
            title: 'Bénéfice UV',
            amount: _formatAmount(w.profitUv),
            gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
            icon: Icons.trending_up_rounded,
          ),
          const SizedBox(width: 16),
          _BalanceCard(
            title: 'Bénéfice crédit',
            amount: _formatAmount(w.profitCredit),
            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
            icon: Icons.stacked_line_chart_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickAction(
          icon: Icons.send_rounded, 
          label: "Transfert", 
          color: Colors.blue.shade100,
          onTap: () => Navigator.pushNamed(context, '/new-transaction'),
        ),
        _QuickAction(
          icon: Icons.call_received_rounded, 
          label: "Retrait", 
          color: Colors.green.shade100,
          onTap: () => Navigator.pushNamed(context, '/new-transaction'),
        ),
        _QuickAction(
          icon: Icons.shopping_bag_rounded, 
          label: "Achat", 
          color: Colors.orange.shade100,
          onTap: () => Navigator.pushNamed(context, '/new-transaction'),
        ),
        _QuickAction(
          icon: Icons.more_horiz_rounded, 
          label: "Plus", 
          color: Colors.purple.shade100,
          onTap: () => Navigator.pushNamed(context, '/history'),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    List<TransactionModel> transactions,
    String businessName,
  ) {
    if (transactions.isEmpty) {
      return const Text("Aucune transaction pour le moment.");
    }

    final sorted = [...transactions]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent = sorted.take(3).toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      itemBuilder: (context, index) {
        final tx = recent[index];
        final isPositive = tx.type == TransactionType.retrait ||
            tx.type == TransactionType.achat ||
            tx.type == TransactionType.transfertUv ||
            tx.type == TransactionType.transfertProfitUv;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => TransactionDetailPage(transaction: tx, businessName: businessName),
                ),
              );
            },
            child: Ink(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(isPositive ? Icons.add_rounded : Icons.remove_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            TransactionModel.typeDisplayName(tx.type),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Client: ${tx.clientName}",
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          Text(
                            'Détail & reçu',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${isPositive ? '+' : '-'} ${_formatAmount(tx.amount)} F",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.green : Colors.redAccent,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatAmount(double amount) => NumberFormat('#,##0', 'fr_FR').format(amount);

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      height: 70,
      notchMargin: 10,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: AppColors.primary), 
            onPressed: () {}, // Déjà sur Home
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.textSecondary), 
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          const SizedBox(width: 40),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: AppColors.textSecondary), 
            onPressed: () => Navigator.pushNamed(context, '/reports'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.textSecondary), 
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final String amount;
  final Gradient gradient;
  final IconData icon;

  const _BalanceCard({required this.title, required this.amount, required this.gradient, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 32),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const Padding(
                padding: EdgeInsets.only(bottom: 4, left: 4),
                child: Text("CFA", style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
