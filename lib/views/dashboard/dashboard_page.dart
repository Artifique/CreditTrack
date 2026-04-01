import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'widgets/activity_chart.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCards(),
                  const SizedBox(height: 32),
                  const ActivityChart(), // Nouveau : Affichage du graphique d'activité
                  const SizedBox(height: 32),
                  _buildSectionTitle("Opérations Rapides"),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Transactions Récentes"),
                  const SizedBox(height: 16),
                  _buildRecentTransactions(),
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
  }

  Widget _buildAppBar() {
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
                Text("Aly Toure", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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

  Widget _buildBalanceCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _BalanceCard(
            title: "Solde UV",
            amount: "450 000",
            gradient: AppColors.cardGradientUV,
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(width: 16),
          _BalanceCard(
            title: "Solde Crédit",
            amount: "75 500",
            gradient: AppColors.cardGradientCredit,
            icon: Icons.phone_android_outlined,
          ),
          const SizedBox(width: 16),
          _BalanceCard(
            title: "Bénéfice Total", // NOUVEAU v1.1
            amount: "12 450",
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

  Widget _buildRecentTransactions() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
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
                child: Icon(Icons.arrow_upward_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dépôt Orange Money", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Client: Moussa Diop", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Text("- 5 000 F", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            ],
          ),
        );
      },
    );
  }

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
