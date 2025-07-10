import '../entities/case_detail_models.dart';

abstract class CaseRepository {
  Future<CaseDetail> getCaseDetail(String caseId);
} 