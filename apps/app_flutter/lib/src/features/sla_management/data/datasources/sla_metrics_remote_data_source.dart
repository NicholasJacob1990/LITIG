import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/sla_metrics_entity.dart';
import '../models/sla_metrics_model.dart';

abstract class SlaMetricsRemoteDataSource {
  Future<SlaMetricsEntity> getMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? lawyerId,
    String? priority,
    String? caseType,
  });

  Future<List<SlaComplianceMetric>> getComplianceMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? groupBy,
  });

  Future<List<SlaPerformanceMetric>> getPerformanceMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? lawyerId,
  });

  Future<List<SlaViolationMetric>> getViolationMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  });

  Future<List<SlaEscalationMetric>> getEscalationMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? level,
  });

  Future<List<SlaTrendMetric>> getTrendMetrics({
    required String firmId,
    required String metric,
    required String period,
    String? granularity,
  });

  Future<Map<String, dynamic>> generateComplianceReport({
    required String firmId,
    required String period,
    bool includeDetails = true,
    String format = 'json',
  });

  Future<Map<String, dynamic>> generatePerformanceReport({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? lawyers,
    String format = 'json',
  });

  Future<List<Map<String, dynamic>>> getPerformanceTrends({
    required String firmId,
    required String metric,
    required String period,
    required String granularity,
  });

  Future<Map<String, dynamic>> getBenchmarkData({
    required String firmId,
    required String metric,
    String? industry,
    String? firmSize,
  });

  Future<Map<String, dynamic>> getPredictiveAnalytics({
    required String firmId,
    required String metric,
    int forecastDays = 30,
  });

  Future<List<SlaAlertMetric>> getAlertMetrics({
    required String firmId,
    String? severity,
    bool activeOnly = true,
  });

  Future<Map<String, dynamic>> getCustomReport({
    required String firmId,
    required Map<String, dynamic> reportConfig,
  });

  Future<bool> exportMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    required String format,
    String? filePath,
  });

  Future<Map<String, dynamic>> getMetricsSummary({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<Map<String, dynamic>>> getTopPerformers({
    required String firmId,
    required String metric,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Map<String, dynamic>> getKPIDashboard({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<bool> scheduleReport({
    required String firmId,
    required Map<String, dynamic> reportConfig,
    required String schedule,
    required List<String> recipients,
  });

  Future<List<Map<String, dynamic>>> getScheduledReports(String firmId);
}

class SlaMetricsRemoteDataSourceImpl implements SlaMetricsRemoteDataSource {
  final Dio dio;
  static const String baseUrl = '/api/v1/sla/metrics';

  SlaMetricsRemoteDataSourceImpl({required this.dio});

  @override
  Future<SlaMetricsEntity> getMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? lawyerId,
    String? priority,
    String? caseType,
  }) async {
    try {
      final queryParams = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (lawyerId != null) 'lawyer_id': lawyerId,
        if (priority != null) 'priority': priority,
        if (caseType != null) 'case_type': caseType,
      };

      final response = await dio.get(
        '$baseUrl/$firmId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return SlaMetricsModel.fromJson(response.data);
      } else {
        throw ServerException('Erro ao obter métricas: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<List<SlaComplianceMetric>> getComplianceMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? groupBy,
  }) async {
    try {
      final queryParams = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (groupBy != null) 'group_by': groupBy,
      };

      final response = await dio.get(
        '$baseUrl/$firmId/compliance',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => SlaComplianceMetric.fromJson(item)).toList();
      } else {
        throw ServerException('Erro ao obter métricas de compliance: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<List<SlaPerformanceMetric>> getPerformanceMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? lawyerId,
  }) async {
    try {
      final queryParams = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (lawyerId != null) 'lawyer_id': lawyerId,
      };

      final response = await dio.get(
        '$baseUrl/$firmId/performance',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => SlaPerformanceMetric.fromJson(item)).toList();
      } else {
        throw ServerException('Erro ao obter métricas de performance: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<List<SlaViolationMetric>> getViolationMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    try {
      final queryParams = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (reason != null) 'reason': reason,
      };

      final response = await dio.get(
        '$baseUrl/$firmId/violations',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => SlaViolationMetric.fromJson(item)).toList();
      } else {
        throw ServerException('Erro ao obter métricas de violação: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<List<SlaEscalationMetric>> getEscalationMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? level,
  }) async {
    try {
      final queryParams = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (level != null) 'level': level,
      };

      final response = await dio.get(
        '$baseUrl/$firmId/escalations',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => SlaEscalationMetric.fromJson(item)).toList();
      } else {
        throw ServerException('Erro ao obter métricas de escalação: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<List<SlaTrendMetric>> getTrendMetrics({
    required String firmId,
    required String metric,
    required String period,
    String? granularity,
  }) async {
    try {
      final queryParams = {
        'metric': metric,
        'period': period,
        if (granularity != null) 'granularity': granularity,
      };

      final response = await dio.get(
        '$baseUrl/$firmId/trends',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => SlaTrendMetric.fromJson(item)).toList();
      } else {
        throw ServerException('Erro ao obter métricas de tendência: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> generateComplianceReport({
    required String firmId,
    required String period,
    bool includeDetails = true,
    String format = 'json',
  }) async {
    try {
      final data = {
        'period': period,
        'include_details': includeDetails,
        'format': format,
      };

      final response = await dio.post(
        '$baseUrl/$firmId/reports/compliance',
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException('Erro ao gerar relatório de compliance: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> generatePerformanceReport({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? lawyers,
    String format = 'json',
  }) async {
    try {
      final data = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (lawyers != null) 'lawyers': lawyers,
        'format': format,
      };

      final response = await dio.post(
        '$baseUrl/$firmId/reports/performance',
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException('Erro ao gerar relatório de performance: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  // Implementação dos demais métodos seguindo o mesmo padrão...
  @override
  Future<List<Map<String, dynamic>>> getPerformanceTrends({
    required String firmId,
    required String metric,
    required String period,
    required String granularity,
  }) async {
    try {
      final queryParams = {
        'metric': metric,
        'period': period,
        'granularity': granularity,
      };

      final response = await dio.get(
        '$baseUrl/$firmId/performance/trends',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw ServerException('Erro ao obter tendências de performance: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  // Implementações similares para todos os outros métodos...
  @override
  Future<Map<String, dynamic>> getBenchmarkData({
    required String firmId,
    required String metric,
    String? industry,
    String? firmSize,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getBenchmarkData');
  }

  @override
  Future<Map<String, dynamic>> getPredictiveAnalytics({
    required String firmId,
    required String metric,
    int forecastDays = 30,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getPredictiveAnalytics');
  }

  @override
  Future<List<SlaAlertMetric>> getAlertMetrics({
    required String firmId,
    String? severity,
    bool activeOnly = true,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getAlertMetrics');
  }

  @override
  Future<Map<String, dynamic>> getCustomReport({
    required String firmId,
    required Map<String, dynamic> reportConfig,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getCustomReport');
  }

  @override
  Future<bool> exportMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    required String format,
    String? filePath,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar exportMetrics');
  }

  @override
  Future<Map<String, dynamic>> getMetricsSummary({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getMetricsSummary');
  }

  @override
  Future<List<Map<String, dynamic>>> getTopPerformers({
    required String firmId,
    required String metric,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getTopPerformers');
  }

  @override
  Future<Map<String, dynamic>> getKPIDashboard({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getKPIDashboard');
  }

  @override
  Future<bool> scheduleReport({
    required String firmId,
    required Map<String, dynamic> reportConfig,
    required String schedule,
    required List<String> recipients,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar scheduleReport');
  }

  @override
  Future<List<Map<String, dynamic>>> getScheduledReports(String firmId) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getScheduledReports');
  }
} 
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/sla_metrics_entity.dart';
import '../models/sla_metrics_model.dart';

abstract class SlaMetricsRemoteDataSource {
  Future<SlaMetricsEntity> getMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? lawyerId,
    String? priority,
    String? caseType,
  });

  Future<List<SlaComplianceMetric>> getComplianceMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? groupBy,
  });

  Future<List<SlaPerformanceMetric>> getPerformanceMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? lawyerId,
  });

  Future<List<SlaViolationMetric>> getViolationMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  });

  Future<List<SlaEscalationMetric>> getEscalationMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? level,
  });

  Future<List<SlaTrendMetric>> getTrendMetrics({
    required String firmId,
    required String metric,
    required String period,
    String? granularity,
  });

  Future<Map<String, dynamic>> generateComplianceReport({
    required String firmId,
    required String period,
    bool includeDetails = true,
    String format = 'json',
  });

  Future<Map<String, dynamic>> generatePerformanceReport({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? lawyers,
    String format = 'json',
  });

  Future<List<Map<String, dynamic>>> getPerformanceTrends({
    required String firmId,
    required String metric,
    required String period,
    required String granularity,
  });

  Future<Map<String, dynamic>> getBenchmarkData({
    required String firmId,
    required String metric,
    String? industry,
    String? firmSize,
  });

  Future<Map<String, dynamic>> getPredictiveAnalytics({
    required String firmId,
    required String metric,
    int forecastDays = 30,
  });

  Future<List<SlaAlertMetric>> getAlertMetrics({
    required String firmId,
    String? severity,
    bool activeOnly = true,
  });

  Future<Map<String, dynamic>> getCustomReport({
    required String firmId,
    required Map<String, dynamic> reportConfig,
  });

  Future<bool> exportMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    required String format,
    String? filePath,
  });

  Future<Map<String, dynamic>> getMetricsSummary({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<Map<String, dynamic>>> getTopPerformers({
    required String firmId,
    required String metric,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Map<String, dynamic>> getKPIDashboard({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<bool> scheduleReport({
    required String firmId,
    required Map<String, dynamic> reportConfig,
    required String schedule,
    required List<String> recipients,
  });

  Future<List<Map<String, dynamic>>> getScheduledReports(String firmId);
}

class SlaMetricsRemoteDataSourceImpl implements SlaMetricsRemoteDataSource {
  final Dio dio;
  static const String baseUrl = '/api/v1/sla/metrics';

  SlaMetricsRemoteDataSourceImpl({required this.dio});

  @override
  Future<SlaMetricsEntity> getMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? lawyerId,
    String? priority,
    String? caseType,
  }) async {
    try {
      final queryParams = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (lawyerId != null) 'lawyer_id': lawyerId,
        if (priority != null) 'priority': priority,
        if (caseType != null) 'case_type': caseType,
      };

      final response = await dio.get(
        '$baseUrl/$firmId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return SlaMetricsModel.fromJson(response.data);
      } else {
        throw ServerException('Erro ao obter métricas: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<List<SlaComplianceMetric>> getComplianceMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? groupBy,
  }) async {
    try {
      final queryParams = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (groupBy != null) 'group_by': groupBy,
      };

      final response = await dio.get(
        '$baseUrl/$firmId/compliance',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => SlaComplianceMetric.fromJson(item)).toList();
      } else {
        throw ServerException('Erro ao obter métricas de compliance: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<List<SlaPerformanceMetric>> getPerformanceMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? lawyerId,
  }) async {
    try {
      final queryParams = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (lawyerId != null) 'lawyer_id': lawyerId,
      };

      final response = await dio.get(
        '$baseUrl/$firmId/performance',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => SlaPerformanceMetric.fromJson(item)).toList();
      } else {
        throw ServerException('Erro ao obter métricas de performance: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<List<SlaViolationMetric>> getViolationMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    try {
      final queryParams = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (reason != null) 'reason': reason,
      };

      final response = await dio.get(
        '$baseUrl/$firmId/violations',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => SlaViolationMetric.fromJson(item)).toList();
      } else {
        throw ServerException('Erro ao obter métricas de violação: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<List<SlaEscalationMetric>> getEscalationMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? level,
  }) async {
    try {
      final queryParams = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (level != null) 'level': level,
      };

      final response = await dio.get(
        '$baseUrl/$firmId/escalations',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => SlaEscalationMetric.fromJson(item)).toList();
      } else {
        throw ServerException('Erro ao obter métricas de escalação: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<List<SlaTrendMetric>> getTrendMetrics({
    required String firmId,
    required String metric,
    required String period,
    String? granularity,
  }) async {
    try {
      final queryParams = {
        'metric': metric,
        'period': period,
        if (granularity != null) 'granularity': granularity,
      };

      final response = await dio.get(
        '$baseUrl/$firmId/trends',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => SlaTrendMetric.fromJson(item)).toList();
      } else {
        throw ServerException('Erro ao obter métricas de tendência: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> generateComplianceReport({
    required String firmId,
    required String period,
    bool includeDetails = true,
    String format = 'json',
  }) async {
    try {
      final data = {
        'period': period,
        'include_details': includeDetails,
        'format': format,
      };

      final response = await dio.post(
        '$baseUrl/$firmId/reports/compliance',
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException('Erro ao gerar relatório de compliance: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> generatePerformanceReport({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? lawyers,
    String format = 'json',
  }) async {
    try {
      final data = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (lawyers != null) 'lawyers': lawyers,
        'format': format,
      };

      final response = await dio.post(
        '$baseUrl/$firmId/reports/performance',
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException('Erro ao gerar relatório de performance: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  // Implementação dos demais métodos seguindo o mesmo padrão...
  @override
  Future<List<Map<String, dynamic>>> getPerformanceTrends({
    required String firmId,
    required String metric,
    required String period,
    required String granularity,
  }) async {
    try {
      final queryParams = {
        'metric': metric,
        'period': period,
        'granularity': granularity,
      };

      final response = await dio.get(
        '$baseUrl/$firmId/performance/trends',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw ServerException('Erro ao obter tendências de performance: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Erro de conexão');
      } else {
        throw ServerException('Erro do servidor: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Erro inesperado: ${e.toString()}');
    }
  }

  // Implementações similares para todos os outros métodos...
  @override
  Future<Map<String, dynamic>> getBenchmarkData({
    required String firmId,
    required String metric,
    String? industry,
    String? firmSize,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getBenchmarkData');
  }

  @override
  Future<Map<String, dynamic>> getPredictiveAnalytics({
    required String firmId,
    required String metric,
    int forecastDays = 30,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getPredictiveAnalytics');
  }

  @override
  Future<List<SlaAlertMetric>> getAlertMetrics({
    required String firmId,
    String? severity,
    bool activeOnly = true,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getAlertMetrics');
  }

  @override
  Future<Map<String, dynamic>> getCustomReport({
    required String firmId,
    required Map<String, dynamic> reportConfig,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getCustomReport');
  }

  @override
  Future<bool> exportMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    required String format,
    String? filePath,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar exportMetrics');
  }

  @override
  Future<Map<String, dynamic>> getMetricsSummary({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getMetricsSummary');
  }

  @override
  Future<List<Map<String, dynamic>>> getTopPerformers({
    required String firmId,
    required String metric,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getTopPerformers');
  }

  @override
  Future<Map<String, dynamic>> getKPIDashboard({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getKPIDashboard');
  }

  @override
  Future<bool> scheduleReport({
    required String firmId,
    required Map<String, dynamic> reportConfig,
    required String schedule,
    required List<String> recipients,
  }) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar scheduleReport');
  }

  @override
  Future<List<Map<String, dynamic>>> getScheduledReports(String firmId) async {
    // Implementação similar aos métodos acima
    throw UnimplementedError('Implementar getScheduledReports');
  }
} 