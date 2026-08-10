import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../models/wallet_chart_point.dart';

class BalanceChartWidget extends StatelessWidget {
  const BalanceChartWidget({required this.points, super.key});

  final List<BalanceChartPoint> points;

  static const int _targetLabelCount = 5;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No chart data yet',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final chartPoints = points;
    final minY =
        chartPoints.map((item) => item.balance).reduce((a, b) => a < b ? a : b);
    final maxY =
        chartPoints.map((item) => item.balance).reduce((a, b) => a > b ? a : b);
    final normalizedMin = minY == maxY ? minY - 1 : minY - 0.2;
    final normalizedMax = minY == maxY ? maxY + 1 : maxY + 0.2;

    final double bottomInterval = points.length <= _targetLabelCount
        ? 1
        : (points.length.toDouble() / (_targetLabelCount - 1));
    final chartSpots = chartPoints
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.balance))
        .toList(growable: false);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        child: SizedBox(
          height: 230,
          child: LineChart(
            LineChartData(
              minY: normalizedMin,
              maxY: normalizedMax,
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final index = spot.x.toInt();
                      if (index < 0 || index >= chartPoints.length) {
                        return null;
                      }
                      final point = chartPoints[index];
                      return LineTooltipItem(
                        '${DateFormat('dd/MM HH:mm').format(
                          point.timestamp.toLocal(),
                        )}\n',
                        TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: '${point.balance.toStringAsFixed(4)} ALPH',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor),
                  left: BorderSide(color: theme.dividerColor),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(value.abs() >= 1 ? 2 : 4),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.left,
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: bottomInterval,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= chartPoints.length) {
                        return const SizedBox.shrink();
                      }
                      if (index != 0 &&
                          index != chartPoints.length - 1 &&
                          index % bottomInterval.toInt() != 0) {
                        return const SizedBox.shrink();
                      }
                      return Transform.translate(
                        offset: const Offset(-2, 0),
                        child: Text(
                          DateFormat('dd/MM')
                              .format(chartPoints[index].timestamp.toLocal()),
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  barWidth: 2.8,
                  color: theme.colorScheme.primary,
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  ),
                  dotData: const FlDotData(show: false),
                  spots: chartSpots,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
