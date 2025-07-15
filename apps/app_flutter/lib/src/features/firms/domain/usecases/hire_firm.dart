import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/firm_repository.dart';

/// Use case para contratação de escritórios
/// 
/// Gerencia o processo de contratação de um escritório específico,
/// incluindo validações, criação de contrato e notificações.
class HireFirm {
  final FirmRepository repository;

  HireFirm(this.repository);

  Future<Result<HireFirmResult>> call(HireFirmParams params) async {
    // Validar parâmetros
    if (params.firmId.isEmpty) {
      return const Result.failure(ValidationFailure(message: 'ID do escritório é obrigatório'));
    }

    if (params.caseId.isEmpty) {
      return const Result.failure(ValidationFailure(message: 'ID do caso é obrigatório'));
    }

    if (params.clientId.isEmpty) {
      return const Result.failure(ValidationFailure(message: 'ID do cliente é obrigatório'));
    }

    // Verificar se o escritório está disponível
    final firmResult = await repository.getFirmById(params.firmId);
    if (firmResult.isFailure) {
      return const Result.failure(ServerFailure(message: 'Escritório não encontrado'));
    }

    final firm = firmResult.value;
    if (firm == null) {
      return const Result.failure(ServerFailure(message: 'Escritório não existe'));
    }

    // Simular processo de contratação (placeholder)
    try {
      // TODO: Implementar integração com API de contratação
      final result = HireFirmResult(
        contractId: 'contract_${DateTime.now().millisecondsSinceEpoch}',
        status: 'pending',
        createdAt: DateTime.now(),
        firmName: firm.name,
        contractDetails: {
          'firm_id': params.firmId,
          'case_id': params.caseId,
          'client_id': params.clientId,
          'contract_type': params.contractType,
        },
      );

      return Result.success(result);
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Erro ao processar contratação: ${e.toString()}'));
    }
  }
}

/// Parâmetros para contratação de escritório
class HireFirmParams {
  final String firmId;
  final String caseId;
  final String clientId;
  final String contractType;
  final Map<String, dynamic> contractTerms;
  final String notes;

  const HireFirmParams({
    required this.firmId,
    required this.caseId,
    required this.clientId,
    this.contractType = 'standard',
    this.contractTerms = const {},
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'firm_id': firmId,
      'case_id': caseId,
      'client_id': clientId,
      'contract_type': contractType,
      'contract_terms': contractTerms,
      'notes': notes,
    };
  }
}

/// Resultado da contratação de escritório
class HireFirmResult {
  final String contractId;
  final String status;
  final DateTime createdAt;
  final String firmName;
  final Map<String, dynamic> contractDetails;

  const HireFirmResult({
    required this.contractId,
    required this.status,
    required this.createdAt,
    required this.firmName,
    required this.contractDetails,
  });

  factory HireFirmResult.fromJson(Map<String, dynamic> json) {
    return HireFirmResult(
      contractId: json['contract_id'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      firmName: json['firm_name'] ?? '',
      contractDetails: json['contract_details'] ?? {},
    );
  }
} 