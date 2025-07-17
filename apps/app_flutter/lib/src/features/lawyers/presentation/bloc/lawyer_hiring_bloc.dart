import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/hiring_proposal.dart';
import '../../domain/entities/hiring_result.dart';
import '../../domain/usecases/hire_lawyer.dart';
import '../../domain/usecases/get_hiring_proposals.dart';
import '../../domain/usecases/respond_to_proposal.dart';

// Events
abstract class LawyerHiringEvent extends Equatable {
  const LawyerHiringEvent();

  @override
  List<Object?> get props => [];
}

class ConfirmLawyerHiring extends LawyerHiringEvent {
  final HireLawyerParams params;

  const ConfirmLawyerHiring({required this.params});

  @override
  List<Object?> get props => [params];
}

class LoadHiringProposals extends LawyerHiringEvent {
  final String lawyerId;
  final String? status;

  const LoadHiringProposals({
    required this.lawyerId,
    this.status,
  });

  @override
  List<Object?> get props => [lawyerId, status];
}

class AcceptHiringProposal extends LawyerHiringEvent {
  final String proposalId;

  const AcceptHiringProposal({required this.proposalId});

  @override
  List<Object?> get props => [proposalId];
}

class RejectHiringProposal extends LawyerHiringEvent {
  final String proposalId;
  final String? reason;

  const RejectHiringProposal({
    required this.proposalId,
    this.reason,
  });

  @override
  List<Object?> get props => [proposalId, reason];
}

// States
abstract class LawyerHiringState extends Equatable {
  const LawyerHiringState();

  @override
  List<Object?> get props => [];
}

class LawyerHiringInitial extends LawyerHiringState {}

class LawyerHiringLoading extends LawyerHiringState {}

class LawyerHiringSuccess extends LawyerHiringState {
  final HiringResult result;

  const LawyerHiringSuccess({required this.result});

  @override
  List<Object?> get props => [result];
}

class LawyerHiringError extends LawyerHiringState {
  final String message;

  const LawyerHiringError({required this.message});

  @override
  List<Object?> get props => [message];
}

class HiringProposalsLoading extends LawyerHiringState {}

class HiringProposalsLoaded extends LawyerHiringState {
  final List<HiringProposal> proposals;

  const HiringProposalsLoaded({required this.proposals});

  @override
  List<Object?> get props => [proposals];
}

class HiringProposalsError extends LawyerHiringState {
  final String message;

  const HiringProposalsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ProposalResponseLoading extends LawyerHiringState {}

class ProposalResponseSuccess extends LawyerHiringState {
  final HiringProposal proposal;

  const ProposalResponseSuccess({required this.proposal});

  @override
  List<Object?> get props => [proposal];
}

class ProposalResponseError extends LawyerHiringState {
  final String message;

  const ProposalResponseError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class LawyerHiringBloc extends Bloc<LawyerHiringEvent, LawyerHiringState> {
  final HireLawyer hireLawyer;
  final GetHiringProposals getHiringProposals;
  final RespondToProposal respondToProposal;

  LawyerHiringBloc({
    required this.hireLawyer,
    required this.getHiringProposals,
    required this.respondToProposal,
  }) : super(LawyerHiringInitial()) {
    on<ConfirmLawyerHiring>(_onConfirmLawyerHiring);
    on<LoadHiringProposals>(_onLoadHiringProposals);
    on<AcceptHiringProposal>(_onAcceptHiringProposal);
    on<RejectHiringProposal>(_onRejectHiringProposal);
  }

  Future<void> _onConfirmLawyerHiring(
    ConfirmLawyerHiring event,
    Emitter<LawyerHiringState> emit,
  ) async {
    emit(LawyerHiringLoading());

    final result = await hireLawyer(event.params);
    result.fold(
      (failure) => emit(LawyerHiringError(message: failure.message)),
      (success) => emit(LawyerHiringSuccess(result: success)),
    );
  }

  Future<void> _onLoadHiringProposals(
    LoadHiringProposals event,
    Emitter<LawyerHiringState> emit,
  ) async {
    emit(HiringProposalsLoading());

    final params = GetHiringProposalsParams(
      lawyerId: event.lawyerId,
      status: event.status,
    );

    final result = await getHiringProposals(params);
    result.fold(
      (failure) => emit(HiringProposalsError(message: failure.message)),
      (proposals) => emit(HiringProposalsLoaded(proposals: proposals)),
    );
  }

  Future<void> _onAcceptHiringProposal(
    AcceptHiringProposal event,
    Emitter<LawyerHiringState> emit,
  ) async {
    emit(ProposalResponseLoading());

    final params = RespondToProposalParams(
      proposalId: event.proposalId,
      accept: true,
    );

    final result = await respondToProposal(params);
    result.fold(
      (failure) => emit(ProposalResponseError(message: failure.message)),
      (proposal) => emit(ProposalResponseSuccess(proposal: proposal)),
    );
  }

  Future<void> _onRejectHiringProposal(
    RejectHiringProposal event,
    Emitter<LawyerHiringState> emit,
  ) async {
    emit(ProposalResponseLoading());

    final params = RespondToProposalParams(
      proposalId: event.proposalId,
      accept: false,
      reason: event.reason,
    );

    final result = await respondToProposal(params);
    result.fold(
      (failure) => emit(ProposalResponseError(message: failure.message)),
      (proposal) => emit(ProposalResponseSuccess(proposal: proposal)),
    );
  }
}