import 'package:equatable/equatable.dart';
import '../../domain/entities/financial_data.dart';

abstract class FinancialState extends Equatable {
  const FinancialState();

  @override
  List<Object?> get props => [];
}

class FinancialInitial extends FinancialState {
  const FinancialInitial();
}

class FinancialLoading extends FinancialState {
  const FinancialLoading();
}

class FinancialLoaded extends FinancialState {
  final FinancialData data;

  const FinancialLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class FinancialError extends FinancialState {
  final String message;

  const FinancialError({required this.message});

  @override
  List<Object?> get props => [message];
}

class FinancialExporting extends FinancialState {
  const FinancialExporting();
}

class FinancialExported extends FinancialState {
  const FinancialExported();
}

class PaymentMarkedReceived extends FinancialState {
  const PaymentMarkedReceived();
}

class PaymentRepassRequested extends FinancialState {
  const PaymentRepassRequested();
} 