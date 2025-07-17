import 'package:dio/dio.dart';
import '../../domain/entities/sla_settings_entity.dart';
import '../models/sla_settings_model.dart';

abstract class SlaSettingsRemoteDataSource {
  Future<SlaSettingsEntity> getSlaSettings(String firmId);
  Future<SlaSettingsEntity> updateSlaSettings(SlaSettingsEntity settings);
  Future<void> deleteSlaSettings(String firmId);
  Future<List<SlaSettingsEntity>> getAllSlaSettings();
  Future<SlaSettingsEntity> createSlaSettings(SlaSettingsEntity settings);
  Future<bool> validateSlaSettings(SlaSettingsEntity settings);
  Future<String> exportSlaSettings(String firmId, String format);
  Future<SlaSettingsEntity> importSlaSettings(String filePath);
  Future<SlaSettingsEntity> resetToDefaults(String firmId);
  Future<SlaSettingsEntity> backupSlaSettings(String firmId);
  Future<SlaSettingsEntity> restoreSlaSettings(String backupId);
  Future<Map<String, dynamic>> getSlaSettingsHistory(String firmId);
}

class SlaSettingsRemoteDataSourceImpl implements SlaSettingsRemoteDataSource {
  final Dio dio;
  final String baseUrl;

  SlaSettingsRemoteDataSourceImpl({
    required this.dio,
    required this.baseUrl,
  });

  @override
  Future<SlaSettingsEntity> getSlaSettings(String firmId) async {
    try {
      final response = await dio.get('$baseUrl/sla/settings/$firmId');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return SlaSettingsModel.fromJson(data);
      } else {
        throw Exception('Failed to load SLA settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error loading SLA settings: $e');
    }
  }

  @override
  Future<SlaSettingsEntity> updateSlaSettings(SlaSettingsEntity settings) async {
    try {
      final settingsModel = SlaSettingsModel.fromEntity(settings);
      final response = await dio.put(
        '$baseUrl/sla/settings/${settings.firmId}',
        data: settingsModel.toJson(),
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return SlaSettingsModel.fromJson(data);
      } else {
        throw Exception('Failed to update SLA settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error updating SLA settings: $e');
    }
  }

  @override
  Future<void> deleteSlaSettings(String firmId) async {
    try {
      final response = await dio.delete('$baseUrl/sla/settings/$firmId');
      
      if (response.statusCode != 204) {
        throw Exception('Failed to delete SLA settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error deleting SLA settings: $e');
    }
  }

  @override
  Future<List<SlaSettingsEntity>> getAllSlaSettings() async {
    try {
      final response = await dio.get('$baseUrl/sla/settings');
      
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data
            .map((json) => SlaSettingsModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load all SLA settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error loading all SLA settings: $e');
    }
  }

  @override
  Future<SlaSettingsEntity> createSlaSettings(SlaSettingsEntity settings) async {
    try {
      final settingsModel = SlaSettingsModel.fromEntity(settings);
      final response = await dio.post(
        '$baseUrl/sla/settings',
        data: settingsModel.toJson(),
      );
      
      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return SlaSettingsModel.fromJson(data);
      } else {
        throw Exception('Failed to create SLA settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error creating SLA settings: $e');
    }
  }

  @override
  Future<bool> validateSlaSettings(SlaSettingsEntity settings) async {
    try {
      final settingsModel = SlaSettingsModel.fromEntity(settings);
      final response = await dio.post(
        '$baseUrl/sla/settings/validate',
        data: settingsModel.toJson(),
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['is_valid'] as bool? ?? false;
      } else {
        throw Exception('Failed to validate SLA settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error validating SLA settings: $e');
    }
  }

  @override
  Future<String> exportSlaSettings(String firmId, String format) async {
    try {
      final response = await dio.get(
        '$baseUrl/sla/settings/$firmId/export',
        queryParameters: {'format': format},
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['file_path'] as String;
      } else {
        throw Exception('Failed to export SLA settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error exporting SLA settings: $e');
    }
  }

  @override
  Future<SlaSettingsEntity> importSlaSettings(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      
      final response = await dio.post(
        '$baseUrl/sla/settings/import',
        data: formData,
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return SlaSettingsModel.fromJson(data);
      } else {
        throw Exception('Failed to import SLA settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error importing SLA settings: $e');
    }
  }

  @override
  Future<SlaSettingsEntity> resetToDefaults(String firmId) async {
    try {
      final response = await dio.post('$baseUrl/sla/settings/$firmId/reset');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return SlaSettingsModel.fromJson(data);
      } else {
        throw Exception('Failed to reset SLA settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error resetting SLA settings: $e');
    }
  }

  @override
  Future<SlaSettingsEntity> backupSlaSettings(String firmId) async {
    try {
      final response = await dio.post('$baseUrl/sla/settings/$firmId/backup');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return SlaSettingsModel.fromJson(data);
      } else {
        throw Exception('Failed to backup SLA settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error backing up SLA settings: $e');
    }
  }

  @override
  Future<SlaSettingsEntity> restoreSlaSettings(String backupId) async {
    try {
      final response = await dio.post('$baseUrl/sla/settings/restore/$backupId');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return SlaSettingsModel.fromJson(data);
      } else {
        throw Exception('Failed to restore SLA settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error restoring SLA settings: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getSlaSettingsHistory(String firmId) async {
    try {
      final response = await dio.get('$baseUrl/sla/settings/$firmId/history');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to get SLA settings history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error getting SLA settings history: $e');
    }
  }
} 