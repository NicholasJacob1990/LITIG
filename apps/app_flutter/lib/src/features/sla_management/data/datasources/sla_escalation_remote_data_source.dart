import 'package:dio/dio.dart';
import '../../domain/entities/sla_escalation_entity.dart';
import '../models/sla_escalation_model.dart';

abstract class SlaEscalationRemoteDataSource {
  Future<List<SlaEscalationEntity>> getEscalations(String firmId);
  Future<SlaEscalationEntity> createEscalation(SlaEscalationEntity escalation);
  Future<SlaEscalationEntity> updateEscalation(SlaEscalationEntity escalation);
  Future<void> deleteEscalation(String escalationId);
  Future<SlaEscalationEntity> getEscalationById(String escalationId);
  Future<bool> executeEscalation(String escalationId, Map<String, dynamic> context);
  Future<List<Map<String, dynamic>>> getEscalationHistory(String firmId);
  Future<Map<String, dynamic>> getEscalationStats(String firmId);
  Future<bool> testEscalation(String escalationId);
  Future<List<SlaEscalationEntity>> getActiveEscalations(String firmId);
  Future<void> activateEscalation(String escalationId);
  Future<void> deactivateEscalation(String escalationId);
  Future<SlaEscalationEntity> duplicateEscalation(String escalationId);
  Future<String> exportEscalation(String escalationId, String format);
  Future<SlaEscalationEntity> importEscalation(String filePath);
  Future<List<Map<String, dynamic>>> getEscalationLogs(String escalationId);
  Future<Map<String, dynamic>> validateEscalation(SlaEscalationEntity escalation);
}

class SlaEscalationRemoteDataSourceImpl implements SlaEscalationRemoteDataSource {
  final Dio dio;
  final String baseUrl;

  SlaEscalationRemoteDataSourceImpl({
    required this.dio,
    required this.baseUrl,
  });

  @override
  Future<List<SlaEscalationEntity>> getEscalations(String firmId) async {
    try {
      final response = await dio.get('$baseUrl/sla/escalations/$firmId');
      
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data
            .map((json) => SlaEscalationModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load escalations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error loading escalations: $e');
    }
  }

  @override
  Future<SlaEscalationEntity> createEscalation(SlaEscalationEntity escalation) async {
    try {
      final escalationModel = SlaEscalationModel.fromEntity(escalation);
      final response = await dio.post(
        '$baseUrl/sla/escalations',
        data: escalationModel.toJson(),
      );
      
      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return SlaEscalationModel.fromJson(data);
      } else {
        throw Exception('Failed to create escalation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error creating escalation: $e');
    }
  }

  @override
  Future<SlaEscalationEntity> updateEscalation(SlaEscalationEntity escalation) async {
    try {
      final escalationModel = SlaEscalationModel.fromEntity(escalation);
      final response = await dio.put(
        '$baseUrl/sla/escalations/${escalation.id}',
        data: escalationModel.toJson(),
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return SlaEscalationModel.fromJson(data);
      } else {
        throw Exception('Failed to update escalation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error updating escalation: $e');
    }
  }

  @override
  Future<void> deleteEscalation(String escalationId) async {
    try {
      final response = await dio.delete('$baseUrl/sla/escalations/$escalationId');
      
      if (response.statusCode != 204) {
        throw Exception('Failed to delete escalation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error deleting escalation: $e');
    }
  }

  @override
  Future<SlaEscalationEntity> getEscalationById(String escalationId) async {
    try {
      final response = await dio.get('$baseUrl/sla/escalations/$escalationId');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return SlaEscalationModel.fromJson(data);
      } else {
        throw Exception('Failed to get escalation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error getting escalation: $e');
    }
  }

  @override
  Future<bool> executeEscalation(String escalationId, Map<String, dynamic> context) async {
    try {
      final response = await dio.post(
        '$baseUrl/sla/escalations/$escalationId/execute',
        data: context,
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['success'] as bool? ?? false;
      } else {
        throw Exception('Failed to execute escalation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error executing escalation: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEscalationHistory(String firmId) async {
    try {
      final response = await dio.get('$baseUrl/sla/escalations/$firmId/history');
      
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to get escalation history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error getting escalation history: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getEscalationStats(String firmId) async {
    try {
      final response = await dio.get('$baseUrl/sla/escalations/$firmId/stats');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to get escalation stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error getting escalation stats: $e');
    }
  }

  @override
  Future<bool> testEscalation(String escalationId) async {
    try {
      final response = await dio.post('$baseUrl/sla/escalations/$escalationId/test');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['success'] as bool? ?? false;
      } else {
        throw Exception('Failed to test escalation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error testing escalation: $e');
    }
  }

  @override
  Future<List<SlaEscalationEntity>> getActiveEscalations(String firmId) async {
    try {
      final response = await dio.get('$baseUrl/sla/escalations/$firmId/active');
      
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data
            .map((json) => SlaEscalationModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to get active escalations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error getting active escalations: $e');
    }
  }

  @override
  Future<void> activateEscalation(String escalationId) async {
    try {
      final response = await dio.post('$baseUrl/sla/escalations/$escalationId/activate');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to activate escalation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error activating escalation: $e');
    }
  }

  @override
  Future<void> deactivateEscalation(String escalationId) async {
    try {
      final response = await dio.post('$baseUrl/sla/escalations/$escalationId/deactivate');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to deactivate escalation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error deactivating escalation: $e');
    }
  }

  @override
  Future<SlaEscalationEntity> duplicateEscalation(String escalationId) async {
    try {
      final response = await dio.post('$baseUrl/sla/escalations/$escalationId/duplicate');
      
      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return SlaEscalationModel.fromJson(data);
      } else {
        throw Exception('Failed to duplicate escalation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error duplicating escalation: $e');
    }
  }

  @override
  Future<String> exportEscalation(String escalationId, String format) async {
    try {
      final response = await dio.get(
        '$baseUrl/sla/escalations/$escalationId/export',
        queryParameters: {'format': format},
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['file_path'] as String;
      } else {
        throw Exception('Failed to export escalation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error exporting escalation: $e');
    }
  }

  @override
  Future<SlaEscalationEntity> importEscalation(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      
      final response = await dio.post(
        '$baseUrl/sla/escalations/import',
        data: formData,
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return SlaEscalationModel.fromJson(data);
      } else {
        throw Exception('Failed to import escalation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error importing escalation: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEscalationLogs(String escalationId) async {
    try {
      final response = await dio.get('$baseUrl/sla/escalations/$escalationId/logs');
      
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to get escalation logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error getting escalation logs: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> validateEscalation(SlaEscalationEntity escalation) async {
    try {
      final escalationModel = SlaEscalationModel.fromEntity(escalation);
      final response = await dio.post(
        '$baseUrl/sla/escalations/validate',
        data: escalationModel.toJson(),
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to validate escalation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error validating escalation: $e');
    }
  }
} 