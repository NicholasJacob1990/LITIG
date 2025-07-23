import 'package:equatable/equatable.dart';
import '../../domain/entities/contract.dart';

abstract class ContractsState extends Equatable {
  const ContractsState();

  @override
  List<Object?> get props => [];
}

class ContractsInitial extends ContractsState {
  const ContractsInitial();
}

class ContractsLoading extends ContractsState {
  const ContractsLoading();
}

class ContractsLoaded extends ContractsState {
  final List<Contract> contracts;
  final String? filterStatus;
  final String? searchQuery;

  const ContractsLoaded({
    required this.contracts,
    this.filterStatus,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [contracts, filterStatus, searchQuery];

  ContractsLoaded copyWith({
    List<Contract>? contracts,
    String? filterStatus,
    String? searchQuery,
  }) {
    return ContractsLoaded(
      contracts: contracts ?? this.contracts,
      filterStatus: filterStatus ?? this.filterStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ContractsError extends ContractsState {
  final String message;

  const ContractsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ContractCreated extends ContractsState {
  final Contract contract;

  const ContractCreated(this.contract);

  @override
  List<Object?> get props => [contract];
}

class ContractSigned extends ContractsState {
  final Contract contract;

  const ContractSigned(this.contract);

  @override
  List<Object?> get props => [contract];
}

class ContractCanceled extends ContractsState {
  final Contract contract;

  const ContractCanceled(this.contract);

  @override
  List<Object?> get props => [contract];
}

class ContractDownloaded extends ContractsState {
  final String contractId;
  final String filePath;

  const ContractDownloaded({
    required this.contractId,
    required this.filePath,
  });

  @override
  List<Object?> get props => [contractId, filePath];
} 