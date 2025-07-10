part of 'lawyers_bloc.dart';

abstract class LawyersEvent {
  const LawyersEvent();
}

class FetchLawyers extends LawyersEvent {
  final String caseId;
  const FetchLawyers({required this.caseId});
}

class ExplainMatch extends LawyersEvent {
  final String caseId;
  final String lawyerId;
  const ExplainMatch({required this.caseId, required this.lawyerId});
} 