import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TransactionController();
    return StreamBuilder<List<TransactionModel>>(
      stream: controller.transactionStream,
      builder: (context, snapshot) {
        final txs = snapshot.data ?? [];
        return Scaffold(
          appBar: AppBar(
            title: const Text("Analyses & Rapports", style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTotalProfitCard(txs),
                const SizedBox(height: 32),
                _buildSectionTitle("Répartition des Bénéfices"),
                const SizedBox(height: 16),
                _buildCategoryDistribution(txs),
                const SizedBox(height: 32),
                _buildSectionTitle("Performance Hebdomadaire"),
                const SizedBox(height: 16),
                _buildWeeklyBarChart(txs),
                const SizedBox(height: 32),
                _buildExportSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary));
  }

  Widget _buildTotalProfitCard(List<TransactionModel> txs) {
    final total = txs.fold<double>(0, (sum, tx) => sum + tx.commission);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Text("Bénéfice Total", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text("${total.toStringAsFixed(0)} CFA",
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up_rounded, color: AppColors.secondary, size: 20),
              SizedBox(width: 4),
              Text("+12% par rapport au mois dernier", style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution(List<TransactionModel> txs) {
    final credit = txs.where((tx) => tx.category == TransactionCategory.CREDIT).fold<double>(0, (s, tx) => s + tx.commission);
    final uv = txs.where((tx) => tx.category == TransactionCategory.UV).fold<double>(0, (s, tx) => s + tx.commission);
    final total = (credit + uv) == 0 ? 1 : (credit + uv);
    final creditPct = (credit / total) * 100;
    final uvPct = (uv / total) * 100;
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(color: AppColors.primary, value: creditPct, title: '${creditPct.toStringAsFixed(0)}%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(color: AppColors.secondary, value: uvPct, title: '${uvPct.toStringAsFixed(0)}%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendItem(color: AppColors.primary, label: "Crédit"),
                SizedBox(height: 12),
                _LegendItem(color: AppColors.secondary, label: "UV (MM)"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(List<TransactionModel> txs) {
    final now = DateTime.now();
    final weekDays = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
    final values = weekDays.map((day) {
      return txs
          .where((tx) =>
              tx.createdAt.year == day.year && tx.createdAt.month == day.month && tx.createdAt.day == day.day)
          .fold<double>(0, (sum, tx) => sum + tx.commission);
    }).toList();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            _makeGroupData(0, values[0]),
            _makeGroupData(1, values[1]),
            _makeGroupData(2, values[2]),
            _makeGroupData(3, values[3]),
            _makeGroupData(4, values[4]),
            _makeGroupData(5, values[5]),
            _makeGroupData(6, values[6]),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: AppColors.primaryGradient,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildExportSection() {
    return Row(
      children: [
        Expanded(
          child: _ExportButton(icon: Icons.picture_as_pdf_rounded, label: "Export PDF", color: Colors.red.shade50, iconColor: Colors.red),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ExportButton(icon: Icons.table_chart_rounded, label: "Export CSV", color: Colors.green.shade50, iconColor: Colors.green),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;

  const _ExportButton({required this.icon, required this.label, required this.color, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
