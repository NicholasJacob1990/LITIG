import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/sla_audit_entity.dart';
import '../models/sla_audit_model.dart';

abstract class SlaAuditRemoteDataSource {
  Future<SlaAuditEntity> createAuditEntry({
    required String firmId,
    required SlaAuditEventType eventType,
    required String entityId,
    required String entityType,
    required String userId,
    required Map<String, dynamic> changes,
    required Map<String, dynamic> metadata,
  });

  Future<List<SlaAuditEntity>> getAuditTrail({
    required String firmId,
    String? entityId,
    String? entityType,
    List<SlaAuditEventType>? eventTypes,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  });

  Future<Map<String, dynamic>> generateComplianceReport({
    required String firmId,
    required String period,
    bool includeDetails = true,
    List<String> complianceStandards = const ['ISO9001', 'LGPD', 'OAB', 'INTERNAL'],
    String format = 'json',
  });

  Future<Map<String, dynamic>> verifyIntegrity({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<String> exportAuditLog({
    required String firmId,
    required String format,
    DateTime? startDate,
    DateTime? endDate,
    bool includeMetadata = true,
    bool encryptFile = false,
  });

  Future<List<Map<String, dynamic>>> getSecurityEvents({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    String? severity,
  });

  Future<Map<String, dynamic>> getAuditStatistics({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<Map<String, dynamic>>> getUserActivity({
    required String firmId,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  });

  Future<Map<String, dynamic>> getChangeHistory({
    required String firmId,
    required String entityId,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<Map<String, dynamic>>> getComplianceViolations({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    String? standard,
    String? severity,
  });

  Future<bool> createRetentionPolicy({
    required String firmId,
    required Map<String, dynamic> policy,
  });

  Future<List<Map<String, dynamic>>> getRetentionPolicies(String firmId);

  Future<bool> executeRetentionPolicy({
    required String firmId,
    required String policyId,
    bool dryRun = false,
  });

  Future<Map<String, dynamic>> getDataGovernanceReport({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<bool> createComplianceAlert({
    required String firmId,
    required Map<String, dynamic> alertConfig,
  });

  Future<List<Map<String, dynamic>>> getComplianceAlerts({
    required String firmId,
    bool activeOnly = true,
  });

  Future<Map<String, dynamic>> getRiskAssessment({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<bool> archiveAuditEntries({
    required String firmId,
    required DateTime beforeDate,
    String? archiveLocation,
  });
}

class SlaAuditRemoteDataSourceImpl implements SlaAuditRemoteDataSource {
  final Dio dio;
  static const String baseUrl = '/api/v1/sla/audit';

  SlaAuditRemoteDataSourceImpl({required this.dio});

  @override
  Future<SlaAuditEntity> createAuditEntry({
    required String firmId,
    required SlaAuditEventType eventType,
    required String entityId,
    required String entityType,
    required String userId,
    required Map<String, dynamic> changes,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final data = {
        'event_type': eventType.toString().split('.').last,
        'entity_id': entityId,
        'entity_type': entityType,
        'user_id': userId,
        'changes': changes,
        'metadata': metadata,
      };

      final response = await dio.post(
        '$baseUrl/$firmId/entries',
        data: data,
      );

      if (response.statusCode == 201) {
        return SlaAuditModel.fromJson(response.data);
      } else {
        throw ServerException(message: 'Erro ao criar entrada de auditoria: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException(message: 'Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException(message: 'Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<List<SlaAuditEntity>> getAuditTrail({
    required String firmId,
    String? entityId,
    String? entityType,
    List<SlaAuditEventType>? eventTypes,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if (entityId != null) 'entity_id': entityId,
        if (entityType != null) 'entity_type': entityType,
        if (userId != null) 'user_id': userId,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (eventTypes != null)
          'event_types': eventTypes.map((e) => e.toString().split('.').last).toList(),
      };

      final response = await dio.get(
        '$baseUrl/$firmId/trail',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => SlaAuditModel.fromJson(item)).toList();
      } else {
        throw ServerException(message: 'Erro ao obter trilha de auditoria: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException(message: 'Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException(message: 'Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> generateComplianceReport({
    required String firmId,
    required String period,
    bool includeDetails = true,
    List<String> complianceStandards = const ['ISO9001', 'LGPD', 'OAB', 'INTERNAL'],
    String format = 'json',
  }) async {
    try {
      final data = {
        'period': period,
        'include_details': includeDetails,
        'compliance_standards': complianceStandards,
        'format': format,
      };

      final response = await dio.post(
        '$baseUrl/$firmId/reports/compliance',
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException(message: 'Erro ao gerar relatório de compliance: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException(message: 'Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException(message: 'Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> verifyIntegrity({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final response = await dio.get(
        '$baseUrl/$firmId/integrity/verify',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException(message: 'Erro ao verificar integridade: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException(message: 'Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException(message: 'Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<String> exportAuditLog({
    required String firmId,
    required String format,
    DateTime? startDate,
    DateTime? endDate,
    bool includeMetadata = true,
    bool encryptFile = false,
  }) async {
    try {
      final data = {
        'format': format,
        'include_metadata': includeMetadata,
        'encrypt_file': encryptFile,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final response = await dio.post(
        '$baseUrl/$firmId/export',
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data['download_url'] as String;
      } else {
        throw ServerException(message: 'Erro ao exportar log de auditoria: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException(message: 'Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException(message: 'Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSecurityEvents({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    String? severity,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (severity != null) 'severity': severity,
      };

      final response = await dio.get(
        '$baseUrl/$firmId/security/events',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw ServerException(message: 'Erro ao obter eventos de segurança: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException(message: 'Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException(message: 'Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getAuditStatistics({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final response = await dio.get(
        '$baseUrl/$firmId/statistics',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException(message: 'Erro ao obter estatísticas de auditoria: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException(message: 'Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException(message: 'Erro inesperado: ${e.toString()}');
    }
  }

  // Implementações dos demais métodos seguindo o mesmo padrão...
  @override
  Future<List<Map<String, dynamic>>> getUserActivity({
    required String firmId,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getUserActivity');
  }

  @override
  Future<Map<String, dynamic>> getChangeHistory({
    required String firmId,
    required String entityId,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getChangeHistory');
  }

  @override
  Future<List<Map<String, dynamic>>> getComplianceViolations({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    String? standard,
    String? severity,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getComplianceViolations');
  }

  @override
  Future<bool> createRetentionPolicy({
    required String firmId,
    required Map<String, dynamic> policy,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar createRetentionPolicy');
  }

  @override
  Future<List<Map<String, dynamic>>> getRetentionPolicies(String firmId) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getRetentionPolicies');
  }

  @override
  Future<bool> executeRetentionPolicy({
    required String firmId,
    required String policyId,
    bool dryRun = false,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar executeRetentionPolicy');
  }

  @override
  Future<Map<String, dynamic>> getDataGovernanceReport({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getDataGovernanceReport');
  }

  @override
  Future<bool> createComplianceAlert({
    required String firmId,
    required Map<String, dynamic> alertConfig,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar createComplianceAlert');
  }

  @override
  Future<List<Map<String, dynamic>>> getComplianceAlerts({
    required String firmId,
    bool activeOnly = true,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getComplianceAlerts');
  }

  @override
  Future<Map<String, dynamic>> getRiskAssessment({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getRiskAssessment');
  }

  @override
  Future<bool> archiveAuditEntries({
    required String firmId,
    required DateTime beforeDate,
    String? archiveLocation,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar archiveAuditEntries');
  }
} 
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/sla_audit_entity.dart';
import '../models/sla_audit_model.dart';

abstract class SlaAuditRemoteDataSource {
  Future<SlaAuditEntity> createAuditEntry({
    required String firmId,
    required SlaAuditEventType eventType,
    required String entityId,
    required String entityType,
    required String userId,
    required Map<String, dynamic> changes,
    required Map<String, dynamic> metadata,
  });

  Future<List<SlaAuditEntity>> getAuditTrail({
    required String firmId,
    String? entityId,
    String? entityType,
    List<SlaAuditEventType>? eventTypes,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  });

  Future<Map<String, dynamic>> generateComplianceReport({
    required String firmId,
    required String period,
    bool includeDetails = true,
    List<String> complianceStandards = const ['ISO9001', 'LGPD', 'OAB', 'INTERNAL'],
    String format = 'json',
  });

  Future<Map<String, dynamic>> verifyIntegrity({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<String> exportAuditLog({
    required String firmId,
    required String format,
    DateTime? startDate,
    DateTime? endDate,
    bool includeMetadata = true,
    bool encryptFile = false,
  });

  Future<List<Map<String, dynamic>>> getSecurityEvents({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    String? severity,
  });

  Future<Map<String, dynamic>> getAuditStatistics({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<Map<String, dynamic>>> getUserActivity({
    required String firmId,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  });

  Future<Map<String, dynamic>> getChangeHistory({
    required String firmId,
    required String entityId,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<Map<String, dynamic>>> getComplianceViolations({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    String? standard,
    String? severity,
  });

  Future<bool> createRetentionPolicy({
    required String firmId,
    required Map<String, dynamic> policy,
  });

  Future<List<Map<String, dynamic>>> getRetentionPolicies(String firmId);

  Future<bool> executeRetentionPolicy({
    required String firmId,
    required String policyId,
    bool dryRun = false,
  });

  Future<Map<String, dynamic>> getDataGovernanceReport({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<bool> createComplianceAlert({
    required String firmId,
    required Map<String, dynamic> alertConfig,
  });

  Future<List<Map<String, dynamic>>> getComplianceAlerts({
    required String firmId,
    bool activeOnly = true,
  });

  Future<Map<String, dynamic>> getRiskAssessment({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<bool> archiveAuditEntries({
    required String firmId,
    required DateTime beforeDate,
    String? archiveLocation,
  });
}

class SlaAuditRemoteDataSourceImpl implements SlaAuditRemoteDataSource {
  final Dio dio;
  static const String baseUrl = '/api/v1/sla/audit';

  SlaAuditRemoteDataSourceImpl({required this.dio});

  @override
  Future<SlaAuditEntity> createAuditEntry({
    required String firmId,
    required SlaAuditEventType eventType,
    required String entityId,
    required String entityType,
    required String userId,
    required Map<String, dynamic> changes,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final data = {
        'event_type': eventType.toString().split('.').last,
        'entity_id': entityId,
        'entity_type': entityType,
        'user_id': userId,
        'changes': changes,
        'metadata': metadata,
      };

      final response = await dio.post(
        '$baseUrl/$firmId/entries',
        data: data,
      );

      if (response.statusCode == 201) {
        return SlaAuditModel.fromJson(response.data);
      } else {
        throw ServerException(message: 'Erro ao criar entrada de auditoria: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException(message: 'Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException(message: 'Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<List<SlaAuditEntity>> getAuditTrail({
    required String firmId,
    String? entityId,
    String? entityType,
    List<SlaAuditEventType>? eventTypes,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if (entityId != null) 'entity_id': entityId,
        if (entityType != null) 'entity_type': entityType,
        if (userId != null) 'user_id': userId,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (eventTypes != null)
          'event_types': eventTypes.map((e) => e.toString().split('.').last).toList(),
      };

      final response = await dio.get(
        '$baseUrl/$firmId/trail',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => SlaAuditModel.fromJson(item)).toList();
      } else {
        throw ServerException(message: 'Erro ao obter trilha de auditoria: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException(message: 'Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException(message: 'Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> generateComplianceReport({
    required String firmId,
    required String period,
    bool includeDetails = true,
    List<String> complianceStandards = const ['ISO9001', 'LGPD', 'OAB', 'INTERNAL'],
    String format = 'json',
  }) async {
    try {
      final data = {
        'period': period,
        'include_details': includeDetails,
        'compliance_standards': complianceStandards,
        'format': format,
      };

      final response = await dio.post(
        '$baseUrl/$firmId/reports/compliance',
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException(message: 'Erro ao gerar relatório de compliance: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException(message: 'Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException(message: 'Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> verifyIntegrity({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final response = await dio.get(
        '$baseUrl/$firmId/integrity/verify',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException(message: 'Erro ao verificar integridade: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException(message: 'Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException(message: 'Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<String> exportAuditLog({
    required String firmId,
    required String format,
    DateTime? startDate,
    DateTime? endDate,
    bool includeMetadata = true,
    bool encryptFile = false,
  }) async {
    try {
      final data = {
        'format': format,
        'include_metadata': includeMetadata,
        'encrypt_file': encryptFile,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final response = await dio.post(
        '$baseUrl/$firmId/export',
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data['download_url'] as String;
      } else {
        throw ServerException(message: 'Erro ao exportar log de auditoria: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException(message: 'Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException(message: 'Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSecurityEvents({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    String? severity,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (severity != null) 'severity': severity,
      };

      final response = await dio.get(
        '$baseUrl/$firmId/security/events',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw ServerException(message: 'Erro ao obter eventos de segurança: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException(message: 'Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException(message: 'Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getAuditStatistics({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final response = await dio.get(
        '$baseUrl/$firmId/statistics',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException(message: 'Erro ao obter estatísticas de auditoria: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException(message: 'Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException(message: 'Erro inesperado: ${e.toString()}');
    }
  }

  // Implementações dos demais métodos seguindo o mesmo padrão...
  @override
  Future<List<Map<String, dynamic>>> getUserActivity({
    required String firmId,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getUserActivity');
  }

  @override
  Future<Map<String, dynamic>> getChangeHistory({
    required String firmId,
    required String entityId,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getChangeHistory');
  }

  @override
  Future<List<Map<String, dynamic>>> getComplianceViolations({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    String? standard,
    String? severity,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getComplianceViolations');
  }

  @override
  Future<bool> createRetentionPolicy({
    required String firmId,
    required Map<String, dynamic> policy,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar createRetentionPolicy');
  }

  @override
  Future<List<Map<String, dynamic>>> getRetentionPolicies(String firmId) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getRetentionPolicies');
  }

  @override
  Future<bool> executeRetentionPolicy({
    required String firmId,
    required String policyId,
    bool dryRun = false,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar executeRetentionPolicy');
  }

  @override
  Future<Map<String, dynamic>> getDataGovernanceReport({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getDataGovernanceReport');
  }

  @override
  Future<bool> createComplianceAlert({
    required String firmId,
    required Map<String, dynamic> alertConfig,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar createComplianceAlert');
  }

  @override
  Future<List<Map<String, dynamic>>> getComplianceAlerts({
    required String firmId,
    bool activeOnly = true,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getComplianceAlerts');
  }

  @override
  Future<Map<String, dynamic>> getRiskAssessment({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getRiskAssessment');
  }

  @override
  Future<bool> archiveAuditEntries({
    required String firmId,
    required DateTime beforeDate,
    String? archiveLocation,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar archiveAuditEntries');
  }
} 