import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/wallet_chart_point.dart';
import '../theme/app_colors.dart';

class ExplorerBalanceChart extends StatelessWidget {
  const ExplorerBalanceChart({required this.points, super.key});

  final List<BalanceChartPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 190,
        child: Center(
          child: Text(
            'Balance history will appear after synchronization.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final balances = points.map((point) => point.balance).toList(growable: false);
    final minValue = balances.reduce((a, b) => a < b ? a : b);
    final maxValue = balances.reduce((a, b) => a > b ? a : b);
    final spread = (maxValue - minValue).abs();
    final padding = spread == 0 ? 1.0 : spread * 0.12;
    final spots = points
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.balance))
        .toList(growable: false);

    return SizedBox(
      height: 210,
      child: LineChart(
        LineChartData(
          minY: minValue - padding,
          maxY: maxValue + padding,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: spread == 0 ? 1 : spread / 3,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.borderSoft,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: points.length <= 4 ? 1 : (points.length / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('dd MMM').format(points[index].timestamp.toLocal()),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceElevated,
              getTooltipItems: (touched) => touched.map((spot) {
                final index = spot.x.round();
                if (index < 0 || index >= points.length) {
                  return null;
                }
                final point = points[index];
                return LineTooltipItem(
                  '${point.balance.toStringAsFixed(6)} ALPH\n${DateFormat('dd MMM yyyy, HH:mm').format(point.timestamp.toLocal())}',
                  const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: AppColors.primary,
              barWidth: 2.2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x5024D2C5), Color(0x0024D2C5)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
