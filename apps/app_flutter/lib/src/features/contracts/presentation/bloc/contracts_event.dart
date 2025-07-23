import 'package:equatable/equatable.dart';

abstract class ContractsEvent extends Equatable {
  const ContractsEvent();

  @override
  List<Object?> get props => [];
}

class LoadContracts extends ContractsEvent {
  const LoadContracts();
}

class FilterContracts extends ContractsEvent {
  final String? status;
  final String? searchQuery;

  const FilterContracts({
    this.status,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [status, searchQuery];
}

class CreateContract extends ContractsEvent {
  final String caseId;
  final String lawyerId;
  final Map<String, dynamic> feeModel;

  const CreateContract({
    required this.caseId,
    required this.lawyerId,
    required this.feeModel,
  });

  @override
  List<Object?> get props => [caseId, lawyerId, feeModel];
}

class SignContract extends ContractsEvent {
  final String contractId;
  final String role; // 'client' ou 'lawyer'

  const SignContract({
    required this.contractId,
    required this.role,
  });

  @override
  List<Object?> get props => [contractId, role];
}

class CancelContract extends ContractsEvent {
  final String contractId;

  const CancelContract({
    required this.contractId,
  });

  @override
  List<Object?> get props => [contractId];
}

class DownloadContract extends ContractsEvent {
  final String contractId;

  const DownloadContract({
    required this.contractId,
  });

  @override
  List<Object?> get props => [contractId];
}

class RefreshContracts extends ContractsEvent {
  const RefreshContracts();
} 