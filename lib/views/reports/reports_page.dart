import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            _buildTotalProfitCard(),
            const SizedBox(height: 32),
            _buildSectionTitle("Répartition des Bénéfices"),
            const SizedBox(height: 16),
            _buildCategoryDistribution(),
            const SizedBox(height: 32),
            _buildSectionTitle("Performance Hebdomadaire"),
            const SizedBox(height: 16),
            _buildWeeklyBarChart(),
            const SizedBox(height: 32),
            _buildExportSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary));
  }

  Widget _buildTotalProfitCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: const Column(
        children: [
          Text("Bénéfice Total (Mensuel)", style: TextStyle(color: Colors.white70, fontSize: 14)),
          SizedBox(height: 8),
          Text("125 750 CFA", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Row(
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

  Widget _buildCategoryDistribution() {
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
                  PieChartSectionData(color: AppColors.primary, value: 65, title: '65%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(color: AppColors.secondary, value: 35, title: '35%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildWeeklyBarChart() {
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
            _makeGroupData(0, 12),
            _makeGroupData(1, 18),
            _makeGroupData(2, 8),
            _makeGroupData(3, 25),
            _makeGroupData(4, 15),
            _makeGroupData(5, 22),
            _makeGroupData(6, 19),
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
