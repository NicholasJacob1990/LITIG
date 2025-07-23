import 'package:equatable/equatable.dart';

class FinancialData extends Equatable {
  final double currentMonthEarnings;
  final double quarterlyEarnings;
  final double totalEarnings;
  final double pendingReceivables;
  final List<PaymentRecord> paymentHistory;
  final Map<String, double> earningsByType;
  final List<MonthlyTrend> monthlyTrend;
  final DateTime lastUpdated;

  const FinancialData({
    required this.currentMonthEarnings,
    required this.quarterlyEarnings,
    required this.totalEarnings,
    required this.pendingReceivables,
    required this.paymentHistory,
    required this.earningsByType,
    required this.monthlyTrend,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        currentMonthEarnings,
        quarterlyEarnings,
        totalEarnings,
        pendingReceivables,
        paymentHistory,
        earningsByType,
        monthlyTrend,
        lastUpdated,
      ];
}

class PaymentRecord extends Equatable {
  final String id;
  final String caseId;
  final String caseTitle;
  final double amount;
  final String feeType;
  final DateTime paidAt;
  final String status;

  const PaymentRecord({
    required this.id,
    required this.caseId,
    required this.caseTitle,
    required this.amount,
    required this.feeType,
    required this.paidAt,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        caseId,
        caseTitle,
        amount,
        feeType,
        paidAt,
        status,
      ];
}

class MonthlyTrend extends Equatable {
  final String month;
  final double earnings;
  final double expenses;
  final double profit;

  const MonthlyTrend({
    required this.month,
    required this.earnings,
    required this.expenses,
    required this.profit,
  });

  @override
  List<Object?> get props => [month, earnings, expenses, profit];
} 