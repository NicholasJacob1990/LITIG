import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FinancialMetricsGrid extends StatelessWidget {
  final Map<String, double> earningsByType;

  const FinancialMetricsGrid({
    super.key,
    required this.earningsByType,
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
              'Receita por Tipo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: earningsByType.length,
              itemBuilder: (context, index) {
                final entry = earningsByType.entries.elementAt(index);
                return _buildMetricCard(
                  context,
                  entry.key,
                  entry.value,
                  _getIconForType(entry.key),
                  _getColorForType(entry.key),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String type,
    double value,
    IconData icon,
    Color color,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            _getTypeLabel(type),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(value),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'fixed':
        return Icons.attach_money;
      case 'hourly':
        return Icons.schedule;
      case 'success':
        return Icons.trending_up;
      case 'consultation':
        return Icons.question_answer;
      default:
        return Icons.money;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'fixed':
        return Colors.blue;
      case 'hourly':
        return Colors.green;
      case 'success':
        return Colors.purple;
      case 'consultation':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'fixed':
        return 'Fixo';
      case 'hourly':
        return 'Por Hora';
      case 'success':
        return 'Êxito';
      case 'consultation':
        return 'Consulta';
      default:
        return type;
    }
  }
} 