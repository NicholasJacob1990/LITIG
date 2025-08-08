import 'package:meu_app/src/features/cases/domain/entities/accepted_case_preview.dart';
import 'package:meu_app/src/features/cases/domain/repositories/privacy_cases_repository.dart';

class CanAcceptCaseUseCase {
  final PrivacyCasesRepository repository;
  CanAcceptCaseUseCase(this.repository);
  Future<bool> call(String caseId) => repository.canAccept(caseId);
}

class AcceptCaseUseCase {
  final PrivacyCasesRepository repository;
  AcceptCaseUseCase(this.repository);
  Future<bool> call(String caseId) => repository.accept(caseId);
}

class AbandonCaseUseCase {
  final PrivacyCasesRepository repository;
  AbandonCaseUseCase(this.repository);
  Future<void> call(String caseId, {String? reason}) => repository.abandon(caseId, reason: reason);
}

class HasFullAccessUseCase {
  final PrivacyCasesRepository repository;
  HasFullAccessUseCase(this.repository);
  Future<bool> call(String caseId) => repository.hasFullAccess(caseId);
}

class ListMyAcceptedCasesUseCase {
  final PrivacyCasesRepository repository;
  ListMyAcceptedCasesUseCase(this.repository);
  Future<List<AcceptedCasePreview>> call() => repository.listMyAccepted();
}


