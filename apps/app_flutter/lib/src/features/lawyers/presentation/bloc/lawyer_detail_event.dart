import 'package:equatable/equatable.dart';

abstract class LawyerDetailEvent extends Equatable {
  const LawyerDetailEvent();

  @override
  List<Object> get props => [];
}

class LoadLawyerDetail extends LawyerDetailEvent {
  final String lawyerId;

  const LoadLawyerDetail(this.lawyerId);

  @override
  List<Object> get props => [lawyerId];
}

class RefreshLawyerDetail extends LawyerDetailEvent {
  final String lawyerId;

  const RefreshLawyerDetail(this.lawyerId);

  @override
  List<Object> get props => [lawyerId];
} 

abstract class LawyerDetailEvent extends Equatable {
  const LawyerDetailEvent();

  @override
  List<Object> get props => [];
}

class LoadLawyerDetail extends LawyerDetailEvent {
  final String lawyerId;

  const LoadLawyerDetail(this.lawyerId);

  @override
  List<Object> get props => [lawyerId];
}

class RefreshLawyerDetail extends LawyerDetailEvent {
  final String lawyerId;

  const RefreshLawyerDetail(this.lawyerId);

  @override
  List<Object> get props => [lawyerId];
} 