import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FirmFinancialInfoView extends StatefulWidget {
  final String firmId;

  const FirmFinancialInfoView({
    super.key,
    required this.firmId,
  });

  @override
  State<FirmFinancialInfoView> createState() => _FirmFinancialInfoViewState();
}

class _FirmFinancialInfoViewState extends State<FirmFinancialInfoView> {
  String _selectedPeriod = '2024';
  final Map<String, FinancialData> _financialData = _getMockFinancialData();

  @override
  Widget build(BuildContext context) {
    final currentData = _financialData[_selectedPeriod]!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 24),
          _buildRevenueOverview(currentData),
          const SizedBox(height: 24),
          _buildFinancialMetrics(currentData),
          const SizedBox(height: 24),
          _buildRevenueBreakdown(currentData),
          const SizedBox(height: 24),
          _buildProfitabilityAnalysis(currentData),
          const SizedBox(height: 24),
          _buildExpensesBreakdown(currentData),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(LucideIcons.calendar, size: 20),
            const SizedBox(width: 8),
            Text(
              'Período de Análise',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            DropdownButton<String>(
              value: _selectedPeriod,
              items: _financialData.keys.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueOverview(FinancialData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.dollarSign, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Receita Anual',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildRevenueCard(
                    'Receita Total',
                    _formatCurrency(data.totalRevenue),
                    LucideIcons.trendingUp,
                    Colors.blue,
                    data.revenueGrowth,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueCard(
                    'Receita Recorrente',
                    _formatCurrency(data.recurringRevenue),
                    LucideIcons.repeat,
                    Colors.green,
                    data.recurringGrowth,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueCard(
                    'Novos Clientes',
                    _formatCurrency(data.newClientRevenue),
                    LucideIcons.userPlus,
                    Colors.purple,
                    data.newClientGrowth,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(String title, String value, IconData icon, Color color, double growth) {
    final isPositive = growth >= 0;
    final growthColor = isPositive ? Colors.green : Colors.red;
    final growthIcon = isPositive ? LucideIcons.arrowUp : LucideIcons.arrowDown;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: growthColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(growthIcon, size: 12, color: growthColor),
                    const SizedBox(width: 2),
                    Text(
                      '${growth.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: growthColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetrics(FinancialData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indicadores Financeiros',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Margem de Lucro',
                    '${(data.profitMargin * 100).toStringAsFixed(1)}%',
                    LucideIcons.percent,
                    _getMarginColor(data.profitMargin),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'EBITDA',
                    _formatCurrency(data.ebitda),
                    LucideIcons.barChart3,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'ROI',
                    '${(data.roi * 100).toStringAsFixed(1)}%',
                    LucideIcons.target,
                    _getROIColor(data.roi),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Ticket Médio',
                    _formatCurrency(data.averageTicket),
                    LucideIcons.receipt,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdown(FinancialData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receita por Área de Atuação',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...data.revenueByArea.entries.map((entry) => _buildAreaRevenueItem(
              entry.key,
              entry.value,
              data.totalRevenue,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaRevenueItem(String area, double revenue, double totalRevenue) {
    final percentage = (revenue / totalRevenue) * 100;
    final colors = [Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.red];
    final colorIndex = area.hashCode % colors.length;
    final color = colors[colorIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  area,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                _formatCurrency(revenue),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildProfitabilityAnalysis(FinancialData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise de Rentabilidade',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.1),
                    Colors.blue.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lucro Líquido',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatCurrency(data.netProfit),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.trendingUp,
                          color: Colors.green,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Margem: ${(data.profitMargin * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Crescimento: +${data.profitGrowth.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesBreakdown(FinancialData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribuição de Despesas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...data.expenses.entries.map((entry) => _buildExpenseItem(
              entry.key,
              entry.value,
              data.totalExpenses,
            )),
            const Divider(height: 32),
            Row(
              children: [
                Text(
                  'Total de Despesas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatCurrency(data.totalExpenses),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem(String category, double amount, double totalExpenses) {
    final percentage = (amount / totalExpenses) * 100;
    const color = Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(0)}k';
    } else {
      return 'R\$ ${value.toStringAsFixed(0)}';
    }
  }

  Color _getMarginColor(double margin) {
    if (margin >= 0.3) return Colors.green;
    if (margin >= 0.2) return Colors.orange;
    return Colors.red;
  }

  Color _getROIColor(double roi) {
    if (roi >= 0.25) return Colors.green;
    if (roi >= 0.15) return Colors.orange;
    return Colors.red;
  }

  static Map<String, FinancialData> _getMockFinancialData() {
    return {
      '2024': FinancialData(
        totalRevenue: 25600000,
        recurringRevenue: 18200000,
        newClientRevenue: 7400000,
        netProfit: 7680000,
        ebitda: 9600000,
        profitMargin: 0.30,
        roi: 0.28,
        averageTicket: 185000,
        revenueGrowth: 15.2,
        recurringGrowth: 12.8,
        newClientGrowth: 22.5,
        profitGrowth: 18.7,
        revenueByArea: {
          'Direito Empresarial': 8960000,
          'M&A e Corporate Finance': 6400000,
          'Direito Tributário': 4608000,
          'Compliance e Governança': 3200000,
          'Direito do Trabalho': 2432000,
        },
        expenses: {
          'Salários e Benefícios': 12800000,
          'Infraestrutura e Tecnologia': 2560000,
          'Marketing e BD': 1280000,
          'Despesas Administrativas': 960000,
          'Outros': 320000,
        },
        totalExpenses: 17920000,
      ),
      '2023': FinancialData(
        totalRevenue: 22200000,
        recurringRevenue: 16200000,
        newClientRevenue: 6000000,
        netProfit: 6660000,
        ebitda: 8436000,
        profitMargin: 0.28,
        roi: 0.26,
        averageTicket: 175000,
        revenueGrowth: 12.1,
        recurringGrowth: 10.5,
        newClientGrowth: 18.2,
        profitGrowth: 15.3,
        revenueByArea: {
          'Direito Empresarial': 7770000,
          'M&A e Corporate Finance': 5550000,
          'Direito Tributário': 3996000,
          'Compliance e Governança': 2775000,
          'Direito do Trabalho': 2109000,
        },
        expenses: {
          'Salários e Benefícios': 11100000,
          'Infraestrutura e Tecnologia': 2220000,
          'Marketing e BD': 1110000,
          'Despesas Administrativas': 833000,
          'Outros': 277000,
        },
        totalExpenses: 15540000,
      ),
      '2022': FinancialData(
        totalRevenue: 19800000,
        recurringRevenue: 14650000,
        newClientRevenue: 5150000,
        netProfit: 5940000,
        ebitda: 7524000,
        profitMargin: 0.26,
        roi: 0.24,
        averageTicket: 165000,
        revenueGrowth: 8.7,
        recurringGrowth: 7.8,
        newClientGrowth: 12.5,
        profitGrowth: 11.2,
        revenueByArea: {
          'Direito Empresarial': 6930000,
          'M&A e Corporate Finance': 4950000,
          'Direito Tributário': 3564000,
          'Compliance e Governança': 2475000,
          'Direito do Trabalho': 1881000,
        },
        expenses: {
          'Salários e Benefícios': 9900000,
          'Infraestrutura e Tecnologia': 1980000,
          'Marketing e BD': 990000,
          'Despesas Administrativas': 742000,
          'Outros': 248000,
        },
        totalExpenses: 13860000,
      ),
    };
  }
}

class FinancialData {
  final double totalRevenue;
  final double recurringRevenue;
  final double newClientRevenue;
  final double netProfit;
  final double ebitda;
  final double profitMargin;
  final double roi;
  final double averageTicket;
  final double revenueGrowth;
  final double recurringGrowth;
  final double newClientGrowth;
  final double profitGrowth;
  final Map<String, double> revenueByArea;
  final Map<String, double> expenses;
  final double totalExpenses;

  FinancialData({
    required this.totalRevenue,
    required this.recurringRevenue,
    required this.newClientRevenue,
    required this.netProfit,
    required this.ebitda,
    required this.profitMargin,
    required this.roi,
    required this.averageTicket,
    required this.revenueGrowth,
    required this.recurringGrowth,
    required this.newClientGrowth,
    required this.profitGrowth,
    required this.revenueByArea,
    required this.expenses,
    required this.totalExpenses,
  });
} 