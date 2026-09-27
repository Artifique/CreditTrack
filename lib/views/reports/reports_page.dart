import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/tokens.dart';
import '../../core/user_feedback.dart';
import '../../controllers/operation_phone_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../services/export_share_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/operation_phone_selector.dart';
import '../../widgets/ui/ui.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _transactionController = TransactionController();
  bool _exportingPdf = false;

  Future<void> _exportPdf(List<TransactionModel> txs) async {
    if (txs.isEmpty) {
      if (!mounted) return;
      UserFeedback.showToast(context, 'Aucune donnée à exporter.', type: AppToastType.warning);
      return;
    }
    setState(() => _exportingPdf = true);
    try {
      final built = await PdfService().buildHistoryPdf(
        transactions: txs,
        filters: HistoryReportFilters(
          periodLabel: 'Période analysée',
          categoryLabel: 'Toutes',
          typeLabel: 'Tous les types',
          merchantPhone: OperationPhoneController.instance.selectedForFilter,
        ),
      );
      if (!mounted) return;
      await ExportShareService.sharePdfBytes(built.bytes, filename: built.filename);
      if (!mounted) return;
      UserFeedback.showSuccessToast(context, 'Rapport exporté avec succès !');
    } catch (e) {
      if (!mounted) return;
      await UserFeedback.showErrorModal(context, e);
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                title: const Text("Analyses & Rapports", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: _exportingPdf 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.picture_as_pdf_rounded),
                    tooltip: 'Exporter en PDF',
                    onPressed: _exportingPdf ? null : () => _exportPdf(txs),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: SingleChildScrollView(
                child: ResponsiveContainer(
                  maxWidth: 960,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FadeInUp(
                        delay: Duration(milliseconds: 50),
                        child: OperationPhoneSelector(),
                      ),
                      const SizedBox(height: AppTokens.space20),
                      FadeInUp(
                        delay: const Duration(milliseconds: 100),
                        child: _buildTotalProfitCard(txs),
                      ),
                      const SizedBox(height: AppTokens.space16),
                      FadeInUp(
                        delay: const Duration(milliseconds: 150),
                        child: _buildKpiRow(context, txs, isDark),
                      ),
                      const SizedBox(height: AppTokens.space32),
                      _buildSectionTitle(context, "Répartition des Bénéfices"),
                      const SizedBox(height: AppTokens.space16),
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: _buildCategoryDistribution(context, txs, isDark),
                      ),
                      const SizedBox(height: AppTokens.space32),
                      _buildSectionTitle(context, "Performance sur 7 Jours"),
                      const SizedBox(height: AppTokens.space16),
                      FadeInUp(
                        delay: const Duration(milliseconds: 250),
                        child: _buildWeeklyBarChart(context, txs, isDark),
                      ),
                      const SizedBox(height: AppTokens.space40),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

  Widget _buildTotalProfitCard(List<TransactionModel> txs) {
    final total = txs.fold<double>(0, (sum, tx) => sum + tx.commission);
    final money = NumberFormat('#,##0', 'fr_FR');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.space24),
      decoration: BoxDecoration(
        gradient: AppTokens.primaryGradient,
        borderRadius: BorderRadius.circular(AppTokens.radius2Xl),
        boxShadow: [
          BoxShadow(
            color: AppTokens.primary500.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            ),
            child: const Text(
              "Commissions Totales Générées",
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                money.format(total.round()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "CFA",
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_graph_rounded, color: AppTokens.secondary, size: 16),
                const SizedBox(width: 6),
                Text(
                  "${txs.length} transactions analysées",
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution(BuildContext context, List<TransactionModel> txs, bool isDark) {
    final credit = txs.where((tx) => tx.category == TransactionCategory.CREDIT).fold<double>(0, (s, tx) => s + tx.commission);
    final uv = txs.where((tx) => tx.category == TransactionCategory.UV).fold<double>(0, (s, tx) => s + tx.commission);
    final total = (credit + uv) == 0 ? 1 : (credit + uv);
    final creditPct = (credit / total) * 100;
    final uvPct = (uv / total) * 100;
    final money = NumberFormat('#,##0', 'fr_FR');

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.all(AppTokens.space20),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 170,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 36,
                  sections: [
                    PieChartSectionData(
                      color: AppTokens.primary500,
                      value: creditPct > 0 ? creditPct : 0.01,
                      title: '${creditPct.toStringAsFixed(0)}%',
                      radius: 46,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    PieChartSectionData(
                      color: AppTokens.secondary500,
                      value: uvPct > 0 ? uvPct : 0.01,
                      title: '${uvPct.toStringAsFixed(0)}%',
                      radius: 46,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendItem(
                  color: AppTokens.primary500,
                  label: "Crédit",
                  value: "${money.format(credit.round())} F",
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _LegendItem(
                  color: AppTokens.secondary500,
                  label: "UV (MM)",
                  value: "${money.format(uv.round())} F",
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, List<TransactionModel> txs, bool isDark) {
    final uvProfit = txs
        .where((tx) => tx.category == TransactionCategory.UV)
        .fold<double>(0, (sum, tx) => sum + tx.commission);
    final creditProfit = txs
        .where((tx) => tx.category == TransactionCategory.CREDIT)
        .fold<double>(0, (sum, tx) => sum + tx.commission);
    final money = NumberFormat('#,##0', 'fr_FR');

    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            title: "Bénéfice UV",
            value: "${money.format(uvProfit.round())} F",
            icon: Icons.account_balance_wallet_rounded,
            color: AppTokens.secondary500,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            title: "Bénéfice Crédit",
            value: "${money.format(creditProfit.round())} F",
            icon: Icons.phone_android_rounded,
            color: AppTokens.primary500,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            title: "Transactions",
            value: "${txs.length}",
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyBarChart(BuildContext context, List<TransactionModel> txs, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekDays = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final values = weekDays.map((day) {
      return txs
          .where((tx) =>
              tx.createdAt.year == day.year &&
              tx.createdAt.month == day.month &&
              tx.createdAt.day == day.day)
          .fold<double>(0, (sum, tx) => sum + tx.commission);
    }).toList();

    final maxVal = values.fold<double>(0, (m, v) => v > m ? v : m);
    final double maxY = maxVal == 0 ? 500 : (maxVal * 1.35);
    final money = NumberFormat('#,##0', 'fr_FR');

    // Total cette semaine
    final weekTotal = values.fold<double>(0, (s, v) => s + v);
    // Meilleur jour
    final bestIdx = values.indexOf(maxVal);

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.all(AppTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Commissions journalières",
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "7 derniers jours",
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                    ),
                  ),
                ],
              ),
              // Total semaine
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTokens.primary50,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  border: Border.all(color: AppTokens.primary200, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, size: 14, color: AppTokens.primary600),
                    const SizedBox(width: 5),
                    Text(
                      "${money.format(weekTotal.round())} F",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.primary600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Barres + labels valeurs
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: isDark ? AppTokens.darkSurface : Colors.white,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = weekDays[group.x];
                      final label = DateFormat('EEE d MMM', 'fr_FR').format(day);
                      final val = rod.toY;
                      return BarTooltipItem(
                        "$label\n",
                        TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: "${money.format(val.round())} F",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTokens.primary500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? AppTokens.darkBorder.withValues(alpha: 0.6)
                        : AppTokens.lightBorder.withValues(alpha: 0.8),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= values.length) return const SizedBox.shrink();
                        final v = values[idx];
                        if (v == 0) return const SizedBox.shrink();
                        // Afficher valeur compacte au-dessus de la barre
                        final compact = v >= 1000
                            ? "${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k"
                            : v.toInt().toString();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            compact,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: idx == bestIdx && maxVal > 0
                                  ? AppTokens.primary500
                                  : (isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == maxY) return const SizedBox.shrink();
                        final label = value >= 1000
                            ? "${(value / 1000).toStringAsFixed(0)}k"
                            : value.toInt().toString();
                        return Text(
                          label,
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary,
                          ),
                          textAlign: TextAlign.right,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= weekDays.length) return const SizedBox.shrink();
                        final d = weekDays[idx];
                        final isToday = d.isAtSameMomentAs(today);
                        final label = DateFormat('E', 'fr_FR').format(d).substring(0, 1).toUpperCase();
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                                color: isToday
                                    ? AppTokens.primary500
                                    : (isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary),
                              ),
                            ),
                            if (isToday)
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: AppTokens.primary500,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) => _makeGroupData(i, values[i], i == bestIdx && maxVal > 0, weekDays[i].isAtSameMomentAs(today))),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Légende bas
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(gradient: AppTokens.primaryGradient, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Text(
                "Commissions CFA",
                style: TextStyle(fontSize: 11, color: isDark ? AppTokens.darkTextTertiary : AppTokens.lightTextTertiary),
              ),
              const Spacer(),
              if (maxVal > 0) ...[
                const Icon(Icons.emoji_events_rounded, size: 13, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text(
                  "Meilleur jour: ${DateFormat('E d MMM', 'fr_FR').format(weekDays[bestIdx])} — ${money.format(maxVal.round())} F",
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, bool isBest, bool isToday) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y == 0 ? 0.01 : y,
          gradient: isBest || isToday
              ? const LinearGradient(
                  colors: [AppTokens.primary500, AppTokens.primary600],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                )
              : LinearGradient(
                  colors: [
                    AppTokens.primary300.withValues(alpha: 0.6),
                    AppTokens.primary400.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
          width: 18,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(5),
            topRight: Radius.circular(5),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final bool isDark;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.all(AppTokens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTokens.darkTextSecondary : AppTokens.lightTextSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: isDark ? AppTokens.darkTextPrimary : AppTokens.lightTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


