part of 'matches_bloc.dart';

abstract class MatchesEvent {
  const MatchesEvent();
}

class FetchMatches extends MatchesEvent {
  final String? caseId;

  const FetchMatches({this.caseId});

  @override
  List<Object?> get props => [caseId];
} 