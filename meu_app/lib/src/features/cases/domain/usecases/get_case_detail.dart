import '../entities/case_detail_models.dart';
import '../repositories/case_repository.dart';

/// Use case para obter detalhes de um caso específico
class GetCaseDetail {
  final CaseRepository repository;

  GetCaseDetail(this.repository);

  /// Executa o use case para obter detalhes do caso
  /// 
  /// [caseId] - ID do caso a ser consultado
  /// 
  /// Retorna um [CaseDetail] com as informações completas do caso
  Future<CaseDetail> execute(String caseId) async {
    try {
    return await repository.getCaseDetail(caseId);
    } catch (e) {
      throw Exception('Erro ao carregar detalhes do caso: $e');
    }
  }
} 