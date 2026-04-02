import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme.dart';
import '../../core/user_feedback.dart';
import '../../controllers/operation_phone_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../services/export_share_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/operation_phone_selector.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _pdfService = PdfService();
  final _transactionController = TransactionController();

  @override
  void initState() {
    super.initState();
    _transactionController.getProfileData().then((p) {
      if (p != null && mounted) {
        OperationPhoneController.instance.syncFromProfile(p.operationPhones);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OperationPhoneController.instance,
      builder: (context, _) {
        return StreamBuilder<List<TransactionModel>>(
          stream: _transactionController.watchTransactions(
            merchantPhone: OperationPhoneController.instance.selectedForFilter,
          ),
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
                    const OperationPhoneSelector(),
                    const SizedBox(height: 20),
                    _buildTotalProfitCard(txs),
                    const SizedBox(height: 16),
                    _buildKpiRow(context, txs),
                    const SizedBox(height: 32),
                    _buildSectionTitle(context, "Répartition des Bénéfices"),
                    const SizedBox(height: 16),
                    _buildCategoryDistribution(context, txs),
                    const SizedBox(height: 32),
                    _buildSectionTitle(context, "Performance Hebdomadaire"),
                    const SizedBox(height: 16),
                    _buildWeeklyBarChart(context, txs),
                    const SizedBox(height: 32),
                    _buildExportSection(txs),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
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

  Widget _buildCategoryDistribution(BuildContext context, List<TransactionModel> txs) {
    final credit = txs.where((tx) => tx.category == TransactionCategory.CREDIT).fold<double>(0, (s, tx) => s + tx.commission);
    final uv = txs.where((tx) => tx.category == TransactionCategory.UV).fold<double>(0, (s, tx) => s + tx.commission);
    final total = (credit + uv) == 0 ? 1 : (credit + uv);
    final creditPct = (credit / total) * 100;
    final uvPct = (uv / total) * 100;
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendItem(
                  color: AppColors.primary,
                  label: "Crédit",
                  textColor: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(height: 12),
                _LegendItem(
                  color: AppColors.secondary,
                  label: "UV (MM)",
                  textColor: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, List<TransactionModel> txs) {
    final uvProfit = txs
        .where((tx) => tx.category == TransactionCategory.UV)
        .fold<double>(0, (sum, tx) => sum + tx.commission);
    final creditProfit = txs
        .where((tx) => tx.category == TransactionCategory.CREDIT)
        .fold<double>(0, (sum, tx) => sum + tx.commission);
    final surface = Theme.of(context).colorScheme.surface;
    return Row(
      children: [
        Expanded(child: _KpiCard(surface: surface, title: "Bénéfice UV", value: "${uvProfit.toStringAsFixed(0)} CFA")),
        const SizedBox(width: 12),
        Expanded(
            child: _KpiCard(
                surface: surface, title: "Bénéfice Crédit", value: "${creditProfit.toStringAsFixed(0)} CFA")),
        const SizedBox(width: 12),
        Expanded(child: _KpiCard(surface: surface, title: "Transactions", value: "${txs.length}")),
      ],
    );
  }

  Widget _buildWeeklyBarChart(BuildContext context, List<TransactionModel> txs) {
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
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

  Future<void> _exportPdf(List<TransactionModel> txs) async {
    if (txs.isEmpty) {
      await UserFeedback.showErrorModal(context, Exception("Aucune transaction à exporter."));
      return;
    }
    final file = await _pdfService.generateReport(txs, "Rapport CreditTrack");
    if (!mounted) return;
    await ExportShareService.sharePdf(file, subject: 'Rapport CreditTrak');
    if (!mounted) return;
    await UserFeedback.showSuccessModal(
      context,
      "PDF généré. Utilise l’app partage Android pour l’enregistrer (Fichiers, Drive, WhatsApp…).",
    );
  }

  Future<void> _exportCsv(List<TransactionModel> txs) async {
    if (txs.isEmpty) {
      await UserFeedback.showErrorModal(context, Exception("Aucune transaction à exporter."));
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/rapport_credit_trak.csv');
    final buffer = StringBuffer('date,type,categorie,telephone_client,numero_operation,montant,commission\n');
    for (final tx in txs) {
      final op = tx.merchantPhone ?? '';
      buffer.writeln(
        '${tx.createdAt.toIso8601String()},${tx.type.name},${tx.category.name},${tx.clientPhone},$op,${tx.amount},${tx.commission}',
      );
    }
    await file.writeAsString(buffer.toString());
    if (!mounted) return;
    await ExportShareService.shareCsv(file, subject: 'Export CreditTrak CSV');
    if (!mounted) return;
    await UserFeedback.showSuccessModal(
      context,
      "CSV généré. Choisis où l’enregistrer via le menu Partager.",
    );
  }

  Widget _buildExportSection(List<TransactionModel> txs) {
    return Row(
      children: [
        Expanded(
          child: _ExportButton(
            icon: Icons.picture_as_pdf_rounded,
            label: "Export PDF",
            color: Colors.red.shade50,
            iconColor: Colors.red,
            onTap: () => _exportPdf(txs),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ExportButton(
            icon: Icons.table_chart_rounded,
            label: "Export CSV",
            color: Colors.green.shade50,
            iconColor: Colors.green,
            onTap: () => _exportCsv(txs),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final Color textColor;
  const _LegendItem({required this.color, required this.label, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: textColor)),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final Color surface;
  final String title;
  final String value;

  const _KpiCard({required this.surface, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
