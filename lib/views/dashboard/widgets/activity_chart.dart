import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/transaction_model.dart';
import '../../../core/theme.dart';

class ActivityChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  const ActivityChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekDays = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
    final spots = weekDays.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final day = entry.value;
      final total = transactions
          .where((tx) =>
              tx.createdAt.year == day.year && tx.createdAt.month == day.month && tx.createdAt.day == day.day)
          .fold<double>(0, (sum, tx) => sum + tx.amount);
      return FlSpot(index, total == 0 ? 0.1 : total);
    }).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Activité de la semaine", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.01)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
