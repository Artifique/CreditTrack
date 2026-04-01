import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/profile_model.dart';
import '../../models/transaction_model.dart';
import 'widgets/activity_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _transactionController = TransactionController();
  late Future<ProfileModel?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _transactionController.getProfileData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileModel?>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        return StreamBuilder<List<TransactionModel>>(
          stream: _transactionController.transactionStream,
          builder: (context, txSnapshot) {
            final transactions = txSnapshot.data ?? [];
            final totalProfit = transactions.fold<double>(0, (sum, tx) => sum + tx.commission);

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
                          _buildBalanceCards(profile, totalProfit),
                          const SizedBox(height: 32),
                          ActivityChart(transactions: transactions),
                          const SizedBox(height: 32),
                          _buildSectionTitle("Opérations Rapides"),
                          const SizedBox(height: 16),
                          _buildQuickActions(context),
                          const SizedBox(height: 32),
                          _buildSectionTitle("Transactions Récentes"),
                          const SizedBox(height: 16),
                          _buildRecentTransactions(transactions),
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
  }

  Widget _buildAppBar(ProfileModel? profile) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bonjour,", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                Text(profile?.ownerName ?? profile?.businessName ?? "Commerçant",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
            GestureDetector(
              onTap: () {}, // Accès rapide au profil
              child: const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCards(ProfileModel? profile, double totalProfit) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _BalanceCard(
            title: "Solde UV",
            amount: _formatAmount(profile?.soldeUv ?? 0),
            gradient: AppColors.cardGradientUV,
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(width: 16),
          _BalanceCard(
            title: "Solde Crédit",
            amount: _formatAmount(profile?.soldeCredit ?? 0),
            gradient: AppColors.cardGradientCredit,
            icon: Icons.phone_android_outlined,
          ),
          const SizedBox(width: 16),
          _BalanceCard(
            title: "Bénéfice Total", // NOUVEAU v1.1
            amount: _formatAmount(totalProfit),
            gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]), // Orange Ambre
            icon: Icons.trending_up_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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

  Widget _buildRecentTransactions(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return const Text("Aucune transaction pour le moment.");
    }

    final recent = transactions.take(3).toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      itemBuilder: (context, index) {
        final tx = recent[index];
        final isPositive = tx.type == TransactionType.retrait || tx.type == TransactionType.achat;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: Icon(isPositive ? Icons.add_rounded : Icons.remove_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.type.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Client: ${tx.clientName}",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                "${isPositive ? '+' : '-'} ${_formatAmount(tx.amount)} F",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : Colors.redAccent,
                ),
              ),
            ],
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
