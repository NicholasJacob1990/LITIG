part of 'matches_bloc.dart';

abstract class MatchesEvent {
  const MatchesEvent();
}

class FetchMatches extends MatchesEvent {
  final String caseId;

  const FetchMatches({required this.caseId});
} 