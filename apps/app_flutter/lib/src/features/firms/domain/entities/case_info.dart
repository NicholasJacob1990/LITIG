import 'package:equatable/equatable.dart';

enum CaseArea {
  civil,
  criminal,
  corporate,
  labor,
  tax,
  family,
  intellectual,
  environmental,
  constitutional,
  administrative
}

enum CaseStatus { active, closed, pending, won, lost }

class CaseInfo extends Equatable {
  final String id;
  final String caseNumber;
  final String title;
  final CaseArea area;
  final CaseStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final String summary;
  final double successProbability;
  final String clientName;
  final double caseValue;
  final List<String> tags;

  const CaseInfo({
    required this.id,
    required this.caseNumber,
    required this.title,
    required this.area,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.summary,
    required this.successProbability,
    required this.clientName,
    required this.caseValue,
    required this.tags,
  });

  @override
  List<Object?> get props => [
        id,
        caseNumber,
        title,
        area,
        status,
        startDate,
        endDate,
        summary,
        successProbability,
        clientName,
        caseValue,
        tags,
      ];
}