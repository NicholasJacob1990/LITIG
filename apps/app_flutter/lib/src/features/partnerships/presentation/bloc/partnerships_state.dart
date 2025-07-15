import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/partnerships/domain/entities/partnership.dart';

abstract class PartnershipsState extends Equatable {
  const PartnershipsState();

  @override
  List<Object> get props => [];
}

class PartnershipsInitial extends PartnershipsState {}

class PartnershipsLoading extends PartnershipsState {}

class PartnershipsLoaded extends PartnershipsState {
  final List<Partnership> partnerships;

  const PartnershipsLoaded(this.partnerships);

  @override
  List<Object> get props => [partnerships];
}

class PartnershipsError extends PartnershipsState {
  final String message;

  const PartnershipsError(this.message);

  @override
  List<Object> get props => [message];
} 