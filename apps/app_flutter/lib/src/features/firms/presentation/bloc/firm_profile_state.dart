import 'package:equatable/equatable.dart';
import '../../domain/entities/enriched_firm.dart';

abstract class FirmProfileState extends Equatable {
  const FirmProfileState();

  @override
  List<Object> get props => [];
}

class FirmProfileInitial extends FirmProfileState {}

class FirmProfileLoading extends FirmProfileState {}

class FirmProfileLoaded extends FirmProfileState {
  final EnrichedFirm enrichedFirm;

  const FirmProfileLoaded({required this.enrichedFirm});

  @override
  List<Object> get props => [enrichedFirm];
}

class FirmProfileError extends FirmProfileState {
  final String message;

  const FirmProfileError({required this.message});

  @override
  List<Object> get props => [message];
} 