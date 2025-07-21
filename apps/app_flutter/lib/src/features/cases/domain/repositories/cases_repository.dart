import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/features/cases/domain/entities/allocation_type.dart';
import 'package:dartz/dartz.dart';
import 'package:meu_app/src/core/error/failures.dart';

abstract class CasesRepository {
  Future<List<Case>> getMyCases();
  Future<Case> getCaseById(String caseId);
  
  /// Atualiza a alocação de um caso
  /// 
  /// Permite modificar como o caso é distribuído entre advogados
  /// e escritórios, incluindo mudanças de responsabilidade
  Future<Either<Failure, Case>> updateCaseAllocation({
    required String caseId,
    required AllocationType allocationType,
    String? newAssigneeId,
    String? reason,
    Map<String, dynamic>? metadata,
  });
  
  /// Obtém histórico de alocações de um caso
  Future<Either<Failure, List<CaseAllocationHistory>>> getAllocationHistory(String caseId);
  
  /// Verifica se uma alocação é possível
  Future<Either<Failure, AllocationValidationResult>> validateAllocation({
    required String caseId,
    required AllocationType allocationType,
    required String targetAssigneeId,
  });
}

/// Histórico de mudanças de alocação
class CaseAllocationHistory {
  final String id;
  final String caseId;
  final AllocationType fromAllocationType;
  final AllocationType toAllocationType;
  final String? fromAssigneeId;
  final String? toAssigneeId;
  final String reason;
  final DateTime changedAt;
  final String changedBy;
  final Map<String, dynamic>? metadata;

  const CaseAllocationHistory({
    required this.id,
    required this.caseId,
    required this.fromAllocationType,
    required this.toAllocationType,
    this.fromAssigneeId,
    this.toAssigneeId,
    required this.reason,
    required this.changedAt,
    required this.changedBy,
    this.metadata,
  });
}

/// Resultado da validação de alocação
class AllocationValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic>? additionalInfo;

  const AllocationValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.additionalInfo,
  });
} 