import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/contracts_repository.dart';
import 'contracts_event.dart';
import 'contracts_state.dart';

class ContractsBloc extends Bloc<ContractsEvent, ContractsState> {
  final ContractsRepository repository;

  ContractsBloc({required this.repository}) : super(const ContractsInitial()) {
    on<LoadContracts>(_onLoadContracts);
    on<FilterContracts>(_onFilterContracts);
    on<CreateContract>(_onCreateContract);
    on<SignContract>(_onSignContract);
    on<CancelContract>(_onCancelContract);
    on<DownloadContract>(_onDownloadContract);
    on<RefreshContracts>(_onRefreshContracts);
  }

  Future<void> _onLoadContracts(
    LoadContracts event,
    Emitter<ContractsState> emit,
  ) async {
    emit(const ContractsLoading());

    final result = await repository.getContracts();

    result.fold(
      (failure) => emit(ContractsError(failure.message)),
      (contracts) => emit(ContractsLoaded(contracts: contracts)),
    );
  }

  Future<void> _onFilterContracts(
    FilterContracts event,
    Emitter<ContractsState> emit,
  ) async {
    if (state is ContractsLoaded) {
      final currentState = state as ContractsLoaded;
      emit(currentState.copyWith(
        filterStatus: event.status,
        searchQuery: event.searchQuery,
      ));
    }

    final result = await repository.getContracts(
      status: event.status,
      searchQuery: event.searchQuery,
    );

    result.fold(
      (failure) => emit(ContractsError(failure.message)),
      (contracts) => emit(ContractsLoaded(
        contracts: contracts,
        filterStatus: event.status,
        searchQuery: event.searchQuery,
      )),
    );
  }

  Future<void> _onCreateContract(
    CreateContract event,
    Emitter<ContractsState> emit,
  ) async {
    final result = await repository.createContract(
      caseId: event.caseId,
      lawyerId: event.lawyerId,
      feeModel: event.feeModel,
    );

    result.fold(
      (failure) => emit(ContractsError(failure.message)),
      (contract) {
        emit(ContractCreated(contract));
        // Recarregar a lista de contratos
        add(const LoadContracts());
      },
    );
  }

  Future<void> _onSignContract(
    SignContract event,
    Emitter<ContractsState> emit,
  ) async {
    final result = await repository.signContract(
      contractId: event.contractId,
      role: event.role,
    );

    result.fold(
      (failure) => emit(ContractsError(failure.message)),
      (contract) {
        emit(ContractSigned(contract));
        // Recarregar a lista de contratos
        add(const LoadContracts());
      },
    );
  }

  Future<void> _onCancelContract(
    CancelContract event,
    Emitter<ContractsState> emit,
  ) async {
    final result = await repository.cancelContract(
      contractId: event.contractId,
    );

    result.fold(
      (failure) => emit(ContractsError(failure.message)),
      (contract) {
        emit(ContractCanceled(contract));
        // Recarregar a lista de contratos
        add(const LoadContracts());
      },
    );
  }

  Future<void> _onDownloadContract(
    DownloadContract event,
    Emitter<ContractsState> emit,
  ) async {
    final result = await repository.downloadContract(
      contractId: event.contractId,
    );

    result.fold(
      (failure) => emit(ContractsError(failure.message)),
      (filePath) => emit(ContractDownloaded(
        contractId: event.contractId,
        filePath: filePath,
      )),
    );
  }

  Future<void> _onRefreshContracts(
    RefreshContracts event,
    Emitter<ContractsState> emit,
  ) async {
    add(const LoadContracts());
  }
} 