import 'package:equatable/equatable.dart';

enum CaseStatus { active, closed, pending, won, lost }

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

extension CaseAreaExtension on CaseArea {
  String get displayName {
    switch (this) {
      case CaseArea.civil:
        return 'Direito Civil';
      case CaseArea.criminal:
        return 'Direito Criminal';
      case CaseArea.corporate:
        return 'Direito Empresarial';
      case CaseArea.labor:
        return 'Direito Trabalhista';
      case CaseArea.tax:
        return 'Direito Tributário';
      case CaseArea.family:
        return 'Direito de Família';
      case CaseArea.intellectual:
        return 'Propriedade Intelectual';
      case CaseArea.environmental:
        return 'Direito Ambiental';
      case CaseArea.constitutional:
        return 'Direito Constitucional';
      case CaseArea.administrative:
        return 'Direito Administrativo';
    }
  }
}

extension CaseStatusExtension on CaseStatus {
  String get displayName {
    switch (this) {
      case CaseStatus.active:
        return 'Ativo';
      case CaseStatus.closed:
        return 'Encerrado';
      case CaseStatus.pending:
        return 'Pendente';
      case CaseStatus.won:
        return 'Ganho';
      case CaseStatus.lost:
        return 'Perdido';
    }
  }
} 