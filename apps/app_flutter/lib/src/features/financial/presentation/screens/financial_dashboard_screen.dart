import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/financial_bloc.dart';
import '../bloc/financial_event.dart';
import '../bloc/financial_state.dart';
import '../widgets/financial_summary_card.dart';
import '../widgets/revenue_chart.dart';
import '../widgets/expense_chart.dart';
import '../widgets/payment_status_card.dart';
import '../widgets/financial_metrics_grid.dart';
import '../../domain/entities/financial_data.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  State<FinancialDashboardScreen> createState() => _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  String _selectedPeriod = 'month';
  String _selectedView = 'overview';

  @override
  void initState() {
    super.initState();
    context.read<FinancialBloc>().add(const LoadFinancialData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Financeiro'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
              context.read<FinancialBloc>().add(LoadFinancialData(period: value));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('Semana')),
              const PopupMenuItem(value: 'month', child: Text('Mês')),
              const PopupMenuItem(value: 'quarter', child: Text('Trimestre')),
              const PopupMenuItem(value: 'year', child: Text('Ano')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getPeriodLabel(_selectedPeriod)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildViewSelector(),
          Expanded(
            child: BlocConsumer<FinancialBloc, FinancialState>(
              listener: (context, state) {
                if (state is FinancialError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                if (state is PaymentMarkedReceived) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pagamento marcado como recebido'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.read<FinancialBloc>().add(LoadFinancialData(period: _selectedPeriod));
                }
                if (state is PaymentRepassRequested) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Repasse solicitado com sucesso'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                  context.read<FinancialBloc>().add(LoadFinancialData(period: _selectedPeriod));
                }
              },
              builder: (context, state) {
                if (state is FinancialLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is FinancialLoaded) {
                  return _buildDashboardContent(state);
                }

                if (state is FinancialError) {
                  return _buildErrorState(state.message);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildViewButton('overview', 'Visão Geral', Icons.dashboard),
          const SizedBox(width: 8),
          _buildViewButton('revenue', 'Receitas', Icons.trending_up),
          const SizedBox(width: 8),
          _buildViewButton('expenses', 'Despesas', Icons.trending_down),
          const SizedBox(width: 8),
          _buildViewButton('payments', 'Pagamentos', Icons.payment),
        ],
      ),
    );
  }

  Widget _buildViewButton(String value, String label, IconData icon) {
    final isSelected = _selectedView == value;
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _selectedView = value;
          });
        },
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.grey[700],
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(FinancialLoaded state) {
    switch (_selectedView) {
      case 'overview':
        return _buildOverviewView(state);
      case 'revenue':
        return _buildRevenueView(state);
      case 'expenses':
        return _buildExpensesView(state);
      case 'payments':
        return _buildPaymentsView(state);
      default:
        return _buildOverviewView(state);
    }
  }

  Widget _buildOverviewView(FinancialLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FinancialBloc>().add(LoadFinancialData(period: _selectedPeriod));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo Financeiro
            FinancialSummaryCard(data: state.data),
            const SizedBox(height: 24),
            
            // Métricas Financeiras
            FinancialMetricsGrid(
              earningsByType: state.data.earningsByType,
            ),
            const SizedBox(height: 24),
            
            // Gráfico de Receitas
            RevenueChart(
              monthlyTrend: state.data.monthlyTrend,
            ),
            const SizedBox(height: 24),
            
            // Status de Pagamentos
            PaymentStatusCard(
              paymentHistory: state.data.paymentHistory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueView(FinancialLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FinancialBloc>().add(LoadFinancialData(period: _selectedPeriod));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo de Receitas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo de Receitas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            'Receita Total',
                            state.data.totalEarnings,
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricItem(
                            'Receita Média',
                            state.data.currentMonthEarnings,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Gráfico Detalhado de Receitas
            RevenueChart(
              monthlyTrend: state.data.monthlyTrend,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesView(FinancialLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FinancialBloc>().add(LoadFinancialData(period: _selectedPeriod));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo de Despesas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo de Despesas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            'Despesa Total',
                            state.data.pendingReceivables,
                            Colors.red,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricItem(
                            'Despesa Média',
                            state.data.currentMonthEarnings * 0.3, // Estimativa
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Gráfico de Despesas
            ExpenseChart(
              monthlyTrend: state.data.monthlyTrend,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsView(FinancialLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FinancialBloc>().add(LoadFinancialData(period: _selectedPeriod));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status de Pagamentos Detalhado
            PaymentStatusCard(
              paymentHistory: state.data.paymentHistory,
            ),
            const SizedBox(height: 16),
            
            // Lista de Pagamentos Recentes
            if (state.data.paymentHistory.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Histórico de Pagamentos',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ...state.data.paymentHistory.take(10).map((payment) => 
                        _buildPaymentItem(payment),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'R\$ ${NumberFormat('#,##0.00').format(value)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentItem(PaymentRecord payment, {bool isOverdue = false}) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverdue ? Colors.red[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.caseTitle,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${payment.feeType} • ${dateFormat.format(payment.paidAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(payment.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isOverdue ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar dados financeiros',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.red[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<FinancialBloc>().add(LoadFinancialData(period: _selectedPeriod));
            },
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'week':
        return 'Semana';
      case 'month':
        return 'Mês';
      case 'quarter':
        return 'Trimestre';
      case 'year':
        return 'Ano';
      default:
        return 'Mês';
    }
  }
} 