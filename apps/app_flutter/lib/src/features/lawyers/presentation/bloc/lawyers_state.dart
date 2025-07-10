part of 'lawyers_bloc.dart';

abstract class LawyersState {
  const LawyersState();
}

class LawyersInitial extends LawyersState {}

class LawyersLoading extends LawyersState {}

class LawyersLoaded extends LawyersState {
  final List<dynamic> lawyers;
  const LawyersLoaded(this.lawyers);
}

class LawyersError extends LawyersState {
  final String message;
  const LawyersError(this.message);
}

class ExplanationLoaded extends LawyersState {
  final String explanation;
  final Map<String, dynamic> lawyer;
  const ExplanationLoaded(this.explanation, this.lawyer);
} 