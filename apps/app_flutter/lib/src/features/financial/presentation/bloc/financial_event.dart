import 'package:equatable/equatable.dart';

abstract class FinancialEvent extends Equatable {
  const FinancialEvent();

  @override
  List<Object?> get props => [];
}

class LoadFinancialData extends FinancialEvent {
  final String? period;
  final String? feeType;

  const LoadFinancialData({
    this.period,
    this.feeType,
  });

  @override
  List<Object?> get props => [period, feeType];
}

class ExportFinancialData extends FinancialEvent {
  final String format;
  final String? period;

  const ExportFinancialData({
    required this.format,
    this.period,
  });

  @override
  List<Object?> get props => [format, period];
}

class MarkPaymentReceived extends FinancialEvent {
  final String paymentId;

  const MarkPaymentReceived({
    required this.paymentId,
  });

  @override
  List<Object?> get props => [paymentId];
}

class RequestPaymentRepass extends FinancialEvent {
  final String paymentId;

  const RequestPaymentRepass({
    required this.paymentId,
  });

  @override
  List<Object?> get props => [paymentId];
}

class RefreshFinancialData extends FinancialEvent {
  const RefreshFinancialData();
} 