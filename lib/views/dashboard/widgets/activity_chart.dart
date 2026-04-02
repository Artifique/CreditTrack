import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/transaction_model.dart';

/// Graphique circulaire : part du volume UV vs Crédit sur les 7 derniers jours.
class ActivityChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  const ActivityChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));

    final inWeek = transactions.where((tx) {
      final d = DateTime(tx.createdAt.year, tx.createdAt.month, tx.createdAt.day);
      return !d.isBefore(weekStart) && !d.isAfter(today);
    }).toList();

    final volUv = inWeek.where((t) => t.category == TransactionCategory.UV).fold<double>(0, (s, t) => s + t.amount);
    final volCredit =
        inWeek.where((t) => t.category == TransactionCategory.CREDIT).fold<double>(0, (s, t) => s + t.amount);
    final totalVol = volUv + volCredit;
    final nbOps = inWeek.length;

    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final variant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Volume par catégorie',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Mobile Money (UV) vs Crédit — 7 derniers jours',
            style: TextStyle(fontSize: 12, color: variant),
          ),
          const SizedBox(height: 20),
          if (totalVol <= 0)
            SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Aucun montant sur cette période.\nLes prochaines opérations apparaîtront ici.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: variant, height: 1.4),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 56,
                            sections: [
                              if (volUv > 0)
                                PieChartSectionData(
                                  color: AppColors.secondary,
                                  value: volUv,
                                  title: '${(100 * volUv / totalVol).toStringAsFixed(0)}%',
                                  radius: 52,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              if (volCredit > 0)
                                PieChartSectionData(
                                  color: AppColors.primary,
                                  value: volCredit,
                                  title: '${(100 * volCredit / totalVol).toStringAsFixed(0)}%',
                                  radius: 52,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              NumberFormat.compact(locale: 'fr_FR').format(totalVol),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: onSurface,
                              ),
                            ),
                            Text('CFA', style: TextStyle(fontSize: 11, color: variant)),
                            Text('$nbOps op.', style: TextStyle(fontSize: 10, color: variant)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendDot(
                          color: AppColors.secondary,
                          label: 'UV (Mobile Money)',
                          value: '${NumberFormat('#,##0', 'fr_FR').format(volUv)} F',
                          textColor: onSurface,
                          subColor: variant,
                        ),
                        const SizedBox(height: 14),
                        _LegendDot(
                          color: AppColors.primary,
                          label: 'Crédit',
                          value: '${NumberFormat('#,##0', 'fr_FR').format(volCredit)} F',
                          textColor: onSurface,
                          subColor: variant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final Color textColor;
  final Color subColor;

  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: subColor)),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
            ],
          ),
        ),
      ],
    );
  }
}
