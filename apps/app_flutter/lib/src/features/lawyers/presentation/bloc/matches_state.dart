part of 'matches_bloc.dart';

abstract class MatchesState {
  const MatchesState();
}

class MatchesInitial extends MatchesState {}

class MatchesLoading extends MatchesState {}

class MatchesLoaded extends MatchesState {
  final List<MatchedLawyer> lawyers;

  const MatchesLoaded(this.lawyers);

  // Getter para compatibilidade
  List<MatchedLawyer> get matches => lawyers;
}

class MatchesError extends MatchesState {
  final String message;

  const MatchesError(this.message);
} 