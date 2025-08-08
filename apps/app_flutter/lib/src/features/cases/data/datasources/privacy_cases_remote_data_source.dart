import 'package:dio/dio.dart';
import 'package:meu_app/src/core/services/dio_service.dart';
import 'package:meu_app/src/core/utils/logger.dart';
import 'package:meu_app/src/features/cases/domain/entities/accepted_case_preview.dart';

class AcceptCaseResult {
  final bool success;
  final String? caseId;
  final String? acceptedBy;
  final String? acceptedAt;
  final String? error;

  const AcceptCaseResult({
    required this.success,
    this.caseId,
    this.acceptedBy,
    this.acceptedAt,
    this.error,
  });
}

abstract class PrivacyCasesRemoteDataSource {
  Future<bool> canAcceptCase(String caseId);
  Future<bool> hasFullAccess(String caseId);
  Future<AcceptCaseResult> acceptCase(String caseId);
  Future<void> abandonCase(String caseId, {String? reason});
  Future<List<AcceptedCasePreview>> getMyAcceptedCases();
}

class PrivacyCasesRemoteDataSourceImpl implements PrivacyCasesRemoteDataSource {
  final Dio _dio;

  PrivacyCasesRemoteDataSourceImpl() : _dio = DioService.dio;

  @override
  Future<bool> canAcceptCase(String caseId) async {
    try {
      final response = await _dio.get('/cases/$caseId/can-accept');
      final data = response.data as Map<String, dynamic>;
      return (data['can_accept'] as bool?) ?? false;
    } catch (e) {
      AppLogger.warning('canAcceptCase failed for $caseId: $e');
      return false;
    }
  }

  @override
  Future<bool> hasFullAccess(String caseId) async {
    try {
      final response = await _dio.get('/cases/$caseId');
      final data = response.data as Map<String, dynamic>;
      return data['access_level'] == 'full';
    } catch (e) {
      AppLogger.warning('hasFullAccess failed for $caseId: $e');
      return false;
    }
  }

  @override
  Future<AcceptCaseResult> acceptCase(String caseId) async {
    try {
      final response = await _dio.post('/cases/accept', data: {
        'case_id': caseId,
      });
      final data = response.data as Map<String, dynamic>;
      return AcceptCaseResult(
        success: (data['success'] as bool?) ?? false,
        caseId: data['case_id'] as String?,
        acceptedBy: data['accepted_by'] as String?,
        acceptedAt: data['accepted_at'] as String?,
        error: data['error'] as String?,
      );
    } catch (e) {
      AppLogger.error('acceptCase failed for $caseId', error: e);
      return const AcceptCaseResult(success: false, error: 'Erro ao aceitar caso');
    }
  }

  @override
  Future<void> abandonCase(String caseId, {String? reason}) async {
    try {
      await _dio.post('/cases/$caseId/abandon', data: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
    } catch (e) {
      AppLogger.error('abandonCase failed for $caseId', error: e);
      rethrow;
    }
  }

  @override
  Future<List<AcceptedCasePreview>> getMyAcceptedCases() async {
    try {
      final response = await _dio.get('/cases/my/accepted');
      final data = response.data as Map<String, dynamic>;
      final list = (data['cases'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      return list.map(AcceptedCasePreview.fromMap).toList();
    } catch (e) {
      AppLogger.error('getMyAcceptedCases failed', error: e);
      return [];
    }
  }
}


