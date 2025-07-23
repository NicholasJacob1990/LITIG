import '../../domain/entities/financial_data.dart';

class FinancialDataModel extends FinancialData {
  const FinancialDataModel({
    required super.currentMonthEarnings,
    required super.quarterlyEarnings,
    required super.totalEarnings,
    required super.pendingReceivables,
    required super.paymentHistory,
    required super.earningsByType,
    required super.monthlyTrend,
    required super.lastUpdated,
  });

  factory FinancialDataModel.fromJson(Map<String, dynamic> json) {
    return FinancialDataModel(
      currentMonthEarnings: (json['current_month_earnings'] as num).toDouble(),
      quarterlyEarnings: (json['quarterly_earnings'] as num).toDouble(),
      totalEarnings: (json['total_earnings'] as num).toDouble(),
      pendingReceivables: (json['pending_receivables'] as num).toDouble(),
      paymentHistory: (json['payment_history'] as List<dynamic>)
          .map((item) => PaymentRecordModel.fromJson(item))
          .toList(),
      earningsByType: Map<String, double>.from(
        (json['earnings_by_type'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      monthlyTrend: (json['monthly_trend'] as List<dynamic>)
          .map((item) => MonthlyTrendModel.fromJson(item))
          .toList(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_month_earnings': currentMonthEarnings,
      'quarterly_earnings': quarterlyEarnings,
      'total_earnings': totalEarnings,
      'pending_receivables': pendingReceivables,
      'payment_history': paymentHistory.map((item) => (item as PaymentRecordModel).toJson()).toList(),
      'earnings_by_type': earningsByType,
      'monthly_trend': monthlyTrend.map((item) => (item as MonthlyTrendModel).toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

class PaymentRecordModel extends PaymentRecord {
  const PaymentRecordModel({
    required super.id,
    required super.caseId,
    required super.caseTitle,
    required super.amount,
    required super.feeType,
    required super.paidAt,
    required super.status,
  });

  factory PaymentRecordModel.fromJson(Map<String, dynamic> json) {
    return PaymentRecordModel(
      id: json['id'] as String,
      caseId: json['case_id'] as String,
      caseTitle: json['case_title'] as String,
      amount: (json['amount'] as num).toDouble(),
      feeType: json['fee_type'] as String,
      paidAt: DateTime.parse(json['paid_at'] as String),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_id': caseId,
      'case_title': caseTitle,
      'amount': amount,
      'fee_type': feeType,
      'paid_at': paidAt.toIso8601String(),
      'status': status,
    };
  }
}

class MonthlyTrendModel extends MonthlyTrend {
  const MonthlyTrendModel({
    required super.month,
    required super.earnings,
    required super.expenses,
    required super.profit,
  });

  factory MonthlyTrendModel.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendModel(
      month: json['month'] as String,
      earnings: (json['earnings'] as num).toDouble(),
      expenses: (json['expenses'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'earnings': earnings,
      'expenses': expenses,
      'profit': profit,
    };
  }
} 