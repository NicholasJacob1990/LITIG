import 'package:equatable/equatable.dart';

import '../../domain/entities/enriched_lawyer.dart';

abstract class LawyerDetailState extends Equatable {
  const LawyerDetailState();

  @override
  List<Object> get props => [];
}

class LawyerDetailInitial extends LawyerDetailState {}

class LawyerDetailLoading extends LawyerDetailState {}

class LawyerDetailLoaded extends LawyerDetailState {
  final EnrichedLawyer enrichedLawyer;

  const LawyerDetailLoaded({required this.enrichedLawyer});

  @override
  List<Object> get props => [enrichedLawyer];
}

class LawyerDetailError extends LawyerDetailState {
  final String message;

  const LawyerDetailError({required this.message});

  @override
  List<Object> get props => [message];
} 