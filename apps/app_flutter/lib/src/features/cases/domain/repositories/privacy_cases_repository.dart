import 'package:meu_app/src/features/cases/domain/entities/accepted_case_preview.dart';

abstract class PrivacyCasesRepository {
  Future<bool> canAccept(String caseId);
  Future<bool> hasFullAccess(String caseId);
  Future<bool> accept(String caseId);
  Future<void> abandon(String caseId, {String? reason});
  Future<List<AcceptedCasePreview>> listMyAccepted();
}


