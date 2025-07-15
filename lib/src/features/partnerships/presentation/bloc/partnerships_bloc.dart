import 'dart:async';
import '../../domain/repositories/partnership_repository.dart';
import 'partnerships_event.dart';
import 'partnerships_state.dart';

class PartnershipsBloc {
  final PartnershipRepository repository;
  
  final _stateController = StreamController<PartnershipsState>.broadcast();
  final _eventController = StreamController<PartnershipsEvent>();
  
  PartnershipsState _currentState = const PartnershipsInitial();
  
  Stream<PartnershipsState> get stream => _stateController.stream;
  PartnershipsState get state => _currentState;
  
  PartnershipsBloc({required this.repository}) {
    _eventController.stream.listen(_mapEventToState);
  }
  
  void add(PartnershipsEvent event) {
    _eventController.add(event);
  }
  
  void _emit(PartnershipsState state) {
    _currentState = state;
    _stateController.add(state);
  }
  
  Future<void> _mapEventToState(PartnershipsEvent event) async {
    if (event is FetchPartnerships) {
      await _onFetchPartnerships(event);
    } else if (event is CreatePartnership) {
      await _onCreatePartnership(event);
    } else if (event is AcceptPartnership) {
      await _onAcceptPartnership(event);
    } else if (event is RejectPartnership) {
      await _onRejectPartnership(event);
    } else if (event is AcceptContract) {
      await _onAcceptContract(event);
    } else if (event is GenerateContract) {
      await _onGenerateContract(event);
    }
  }

  Future<void> _onFetchPartnerships(FetchPartnerships event) async {
    _emit(const PartnershipsLoading());
    
    try {
      final sentResult = await repository.getSentPartnerships();
      final receivedResult = await repository.getReceivedPartnerships();
      
      if (sentResult.isSuccess && receivedResult.isSuccess) {
        _emit(PartnershipsLoaded(
          sent: sentResult.value!,
          received: receivedResult.value!,
        ));
      } else {
        final errorMessage = sentResult.isFailure 
            ? sentResult.failure!.message 
            : receivedResult.failure!.message;
        _emit(PartnershipsError(errorMessage));
      }
    } catch (e) {
      _emit(PartnershipsError('Erro ao carregar parcerias: $e'));
    }
  }

  Future<void> _onCreatePartnership(CreatePartnership event) async {
    try {
      final result = await repository.createPartnership(
        partnerId: event.partnerId,
        caseId: event.caseId,
        type: event.type,
        honorarios: event.honorarios,
        proposalMessage: event.proposalMessage,
      );
      
      if (result.isSuccess) {
        // Recarregar a lista após criar
        add(const FetchPartnerships());
      } else {
        _emit(PartnershipsError(result.failure!.message));
      }
    } catch (e) {
      _emit(PartnershipsError('Erro ao criar parceria: $e'));
    }
  }

  Future<void> _onAcceptPartnership(AcceptPartnership event) async {
    try {
      final result = await repository.acceptPartnership(event.partnershipId);
      
      if (result.isSuccess) {
        // Recarregar a lista após aceitar
        add(const FetchPartnerships());
      } else {
        _emit(PartnershipsError(result.failure!.message));
      }
    } catch (e) {
      _emit(PartnershipsError('Erro ao aceitar parceria: $e'));
    }
  }

  Future<void> _onRejectPartnership(RejectPartnership event) async {
    try {
      final result = await repository.rejectPartnership(event.partnershipId);
      
      if (result.isSuccess) {
        // Recarregar a lista após rejeitar
        add(const FetchPartnerships());
      } else {
        _emit(PartnershipsError(result.failure!.message));
      }
    } catch (e) {
      _emit(PartnershipsError('Erro ao rejeitar parceria: $e'));
    }
  }

  Future<void> _onAcceptContract(AcceptContract event) async {
    try {
      final result = await repository.acceptContract(event.partnershipId);
      
      if (result.isSuccess) {
        // Recarregar a lista após aceitar contrato
        add(const FetchPartnerships());
      } else {
        _emit(PartnershipsError(result.failure!.message));
      }
    } catch (e) {
      _emit(PartnershipsError('Erro ao aceitar contrato: $e'));
    }
  }

  Future<void> _onGenerateContract(GenerateContract event) async {
    try {
      final result = await repository.generateContract(event.partnershipId);
      
      if (result.isSuccess) {
        // Recarregar a lista após gerar contrato
        add(const FetchPartnerships());
      } else {
        _emit(PartnershipsError(result.failure!.message));
      }
    } catch (e) {
      _emit(PartnershipsError('Erro ao gerar contrato: $e'));
    }
  }
  
  void dispose() {
    _stateController.close();
    _eventController.close();
  }
} 