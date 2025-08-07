import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/bloc/financial_bloc.dart';
import '../../presentation/bloc/financial_event.dart';
import '../../domain/entities/financial_data.dart';

class PaymentStatusCard extends StatelessWidget {
  final List<PaymentRecord> paymentHistory;

  const PaymentStatusCard({
    super.key,
    required this.paymentHistory,
  });

  @override
  Widget build(BuildContext context) {
    final recentPayments = paymentHistory.take(5).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pagamentos Recentes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navegar para lista completa
                  },
                  child: const Text('Ver Todos'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentPayments.isEmpty)
              const Center(
                child: Text('Nenhum pagamento recente'),
              )
            else
              Column(
                children: recentPayments.map((payment) {
                  return _buildPaymentItem(context, payment);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(BuildContext context, PaymentRecord payment) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(payment.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(payment.status).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(payment.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.caseTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${payment.feeType} • ${dateFormat.format(payment.paidAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(payment.amount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _getStatusText(payment.status),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getStatusColor(payment.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (payment.status.toLowerCase() == 'pending')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Marcar como recebido',
                      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                      onPressed: () {
                        context.read<FinancialBloc>().add(MarkPaymentReceived(paymentId: payment.id));
                      },
                    ),
                    IconButton(
                      tooltip: 'Solicitar repasse',
                      icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.teal),
                      onPressed: () {
                        context.read<FinancialBloc>().add(RequestPaymentRepass(paymentId: payment.id));
                      },
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Pago';
      case 'pending':
        return 'Pendente';
      case 'processing':
        return 'Processando';
      default:
        return 'Desconhecido';
    }
  }
} 