import 'package:meu_app/src/core/utils/logger.dart';
import 'package:meu_app/src/features/cases/data/datasources/privacy_cases_remote_data_source.dart';
import 'package:meu_app/src/features/cases/domain/entities/accepted_case_preview.dart';
import 'package:meu_app/src/features/cases/domain/repositories/privacy_cases_repository.dart';

class PrivacyCasesRepositoryImpl implements PrivacyCasesRepository {
  final PrivacyCasesRemoteDataSource remote;

  PrivacyCasesRepositoryImpl(this.remote);

  @override
  Future<bool> canAccept(String caseId) => remote.canAcceptCase(caseId);

  @override
  Future<bool> hasFullAccess(String caseId) => remote.hasFullAccess(caseId);

  @override
  Future<bool> accept(String caseId) async {
    final res = await remote.acceptCase(caseId);
    if (!res.success) {
      AppLogger.warning('accept() failed: ${res.error}');
    }
    return res.success;
  }

  @override
  Future<void> abandon(String caseId, {String? reason}) => remote.abandonCase(caseId, reason: reason);

  @override
  Future<List<AcceptedCasePreview>> listMyAccepted() => remote.getMyAcceptedCases();
}


