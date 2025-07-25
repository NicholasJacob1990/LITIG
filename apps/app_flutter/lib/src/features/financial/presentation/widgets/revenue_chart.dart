import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/financial_data.dart';

class RevenueChart extends StatelessWidget {
  final List<MonthlyTrend> monthlyTrend;

  const RevenueChart({
    super.key,
    required this.monthlyTrend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolução da Receita',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildChart(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    if (monthlyTrend.isEmpty) {
      return const Center(
        child: Text('Nenhum dado disponível'),
      );
    }

    final maxEarnings = monthlyTrend
        .map((trend) => trend.earnings)
        .reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: monthlyTrend.map((trend) {
        final height = (trend.earnings / maxEarnings) * 150;
        final currencyFormat = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
        );

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 30,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Tooltip(
                  message: currencyFormat.format(trend.earnings),
                  child: Container(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                trend.month,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
} 