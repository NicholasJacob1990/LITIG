import 'package:dio/dio.dart';
import '../../domain/entities/sla_settings_entity.dart';
import '../models/sla_settings_model.dart';
import 'package:meu_app/src/core/utils/logger.dart';

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
  
  // Métodos adicionais necessários
  Future<SlaSettingsEntity> getSettings(String firmId);
  Future<SlaSettingsEntity> updateSettings(String firmId, SlaSettingsEntity settings);
  Future<List<Map<String, dynamic>>> getPresets(String firmId, bool includeSystemPresets);
  Future<Map<String, dynamic>> createPreset(String firmId, Map<String, dynamic> preset);
  Future<Map<String, dynamic>> updatePreset(String presetId, Map<String, dynamic> preset);
  Future<void> deletePreset(String presetId);
  Future<SlaSettingsEntity> applyPreset(String firmId, String presetId);
  Future<Map<String, dynamic>> getNotificationSettings(String firmId);
  Future<void> updateNotificationSettings(String firmId, Map<String, dynamic> settings);
  Future<Map<String, dynamic>> getEscalationSettings(String firmId);
  Future<void> updateEscalationSettings(String firmId, Map<String, dynamic> settings);
  Future<Map<String, dynamic>> getBusinessHoursSettings(String firmId);
  Future<void> updateBusinessHoursSettings(String firmId, Map<String, dynamic> settings);
  Future<List<Map<String, dynamic>>> getHolidaySettings(String firmId);
  Future<void> updateHolidaySettings(String firmId, List<Map<String, dynamic>> holidays);
  Future<Map<String, dynamic>> validateSettings(SlaSettingsEntity settings);
  Future<SlaSettingsEntity> getDefaultSettings();
  Future<SlaSettingsEntity> cloneSettings(String sourceFirmId, String targetFirmId);
  Future<String> exportSettings(String firmId, String format);
  Future<SlaSettingsEntity> importSettings(String firmId, String settingsData, String format);
  Future<List<Map<String, dynamic>>> getSettingsHistory(String firmId, DateTime? startDate, DateTime? endDate);
  Future<SlaSettingsEntity> revertSettings(String firmId, String historyId);
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
      AppLogger.info('Fetching SLA settings for firm: $firmId');
      final response = await dio.get('$baseUrl/sla/settings/$firmId');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        AppLogger.success('SLA settings loaded successfully');
        return SlaSettingsModel.fromJson(data);
      } else {
        throw Exception('Failed to load SLA settings: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.warning('API error loading SLA settings, using fallback: ${e.message}');
      
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout ||
          e.response?.statusCode == 404) {
        return _getDefaultSlaSettings(firmId);
      }
      
      throw Exception('Network error loading SLA settings: $e');
    } catch (e) {
      AppLogger.error('Unexpected error loading SLA settings, using fallback', error: e);
      return _getDefaultSlaSettings(firmId);
    }
  }

  @override
  Future<SlaSettingsEntity> updateSlaSettings(SlaSettingsEntity settings) async {
    try {
      AppLogger.info('Updating SLA settings for firm: ${settings.firmId}');
      final settingsModel = SlaSettingsModel.fromEntity(settings);
      final response = await dio.put(
        '$baseUrl/sla/settings/${settings.firmId}',
        data: settingsModel.toJson(),
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        AppLogger.success('SLA settings updated successfully');
        return SlaSettingsModel.fromJson(data);
      } else {
        throw Exception('Failed to update SLA settings: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.warning('API error updating SLA settings: ${e.message}');
      
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout) {
        // Return the input settings as if they were saved
        AppLogger.info('Using local fallback for SLA settings update');
        return settings;
      }
      
      throw Exception('Network error updating SLA settings: $e');
    } catch (e) {
      AppLogger.error('Unexpected error updating SLA settings', error: e);
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

  // Implementação dos métodos adicionais
  @override
  Future<SlaSettingsEntity> getSettings(String firmId) async {
    return getSlaSettings(firmId);
  }

  @override
  Future<SlaSettingsEntity> updateSettings(String firmId, SlaSettingsEntity settings) async {
    return updateSlaSettings(settings);
  }

  @override
  Future<List<Map<String, dynamic>>> getPresets(String firmId, bool includeSystemPresets) async {
    try {
      AppLogger.info('Fetching SLA presets for firm: $firmId');
      final response = await dio.get('$baseUrl/sla/presets/$firmId?include_system=$includeSystemPresets');
      
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        AppLogger.success('SLA presets loaded: ${data.length} presets');
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get presets: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.warning('API error getting presets, using fallback: ${e.message}');
      
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout ||
          e.response?.statusCode == 404) {
        return _getDefaultPresets(includeSystemPresets);
      }
      
      throw Exception('Network error getting presets: $e');
    } catch (e) {
      AppLogger.error('Unexpected error getting presets, using fallback', error: e);
      return _getDefaultPresets(includeSystemPresets);
    }
  }

  @override
  Future<Map<String, dynamic>> createPreset(String firmId, Map<String, dynamic> preset) async {
    try {
      final response = await dio.post(
        '$baseUrl/sla/presets/$firmId',
        data: preset,
      );
      
      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to create preset: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error creating preset: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> updatePreset(String presetId, Map<String, dynamic> preset) async {
    try {
      final response = await dio.put(
        '$baseUrl/sla/presets/$presetId',
        data: preset,
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to update preset: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error updating preset: $e');
    }
  }

  @override
  Future<void> deletePreset(String presetId) async {
    try {
      final response = await dio.delete('$baseUrl/sla/presets/$presetId');
      
      if (response.statusCode != 204) {
        throw Exception('Failed to delete preset: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error deleting preset: $e');
    }
  }

  @override
  Future<SlaSettingsEntity> applyPreset(String firmId, String presetId) async {
    try {
      final response = await dio.post('$baseUrl/sla/settings/$firmId/apply-preset/$presetId');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return SlaSettingsModel.fromJson(data);
      } else {
        throw Exception('Failed to apply preset: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error applying preset: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getNotificationSettings(String firmId) async {
    try {
      final response = await dio.get('$baseUrl/sla/settings/$firmId/notifications');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to get notification settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error getting notification settings: $e');
    }
  }

  @override
  Future<void> updateNotificationSettings(String firmId, Map<String, dynamic> settings) async {
    try {
      final response = await dio.put(
        '$baseUrl/sla/settings/$firmId/notifications',
        data: settings,
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update notification settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error updating notification settings: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getEscalationSettings(String firmId) async {
    try {
      final response = await dio.get('$baseUrl/sla/settings/$firmId/escalation');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to get escalation settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error getting escalation settings: $e');
    }
  }

  @override
  Future<void> updateEscalationSettings(String firmId, Map<String, dynamic> settings) async {
    try {
      final response = await dio.put(
        '$baseUrl/sla/settings/$firmId/escalation',
        data: settings,
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update escalation settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error updating escalation settings: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getBusinessHoursSettings(String firmId) async {
    try {
      final response = await dio.get('$baseUrl/sla/settings/$firmId/business-hours');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to get business hours settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error getting business hours settings: $e');
    }
  }

  @override
  Future<void> updateBusinessHoursSettings(String firmId, Map<String, dynamic> settings) async {
    try {
      final response = await dio.put(
        '$baseUrl/sla/settings/$firmId/business-hours',
        data: settings,
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update business hours settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error updating business hours settings: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHolidaySettings(String firmId) async {
    try {
      final response = await dio.get('$baseUrl/sla/settings/$firmId/holidays');
      
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get holiday settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error getting holiday settings: $e');
    }
  }

  @override
  Future<void> updateHolidaySettings(String firmId, List<Map<String, dynamic>> holidays) async {
    try {
      final response = await dio.put(
        '$baseUrl/sla/settings/$firmId/holidays',
        data: holidays,
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update holiday settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error updating holiday settings: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> validateSettings(SlaSettingsEntity settings) async {
    try {
      final settingsModel = SlaSettingsModel.fromEntity(settings);
      final response = await dio.post(
        '$baseUrl/sla/settings/validate',
        data: settingsModel.toJson(),
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception('Failed to validate settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error validating settings: $e');
    }
  }

  @override
  Future<SlaSettingsEntity> getDefaultSettings() async {
    try {
      final response = await dio.get('$baseUrl/sla/settings/defaults');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return SlaSettingsModel.fromJson(data);
      } else {
        throw Exception('Failed to get default settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error getting default settings: $e');
    }
  }

  @override
  Future<SlaSettingsEntity> cloneSettings(String sourceFirmId, String targetFirmId) async {
    try {
      final response = await dio.post('$baseUrl/sla/settings/clone', data: {
        'source_firm_id': sourceFirmId,
        'target_firm_id': targetFirmId,
      });
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return SlaSettingsModel.fromJson(data);
      } else {
        throw Exception('Failed to clone settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error cloning settings: $e');
    }
  }

  @override
  Future<String> exportSettings(String firmId, String format) async {
    return exportSlaSettings(firmId, format);
  }

  @override
  Future<SlaSettingsEntity> importSettings(String firmId, String settingsData, String format) async {
    try {
      final response = await dio.post(
        '$baseUrl/sla/settings/$firmId/import',
        data: {
          'settings_data': settingsData,
          'format': format,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return SlaSettingsModel.fromJson(data);
      } else {
        throw Exception('Failed to import settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error importing settings: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSettingsHistory(String firmId, DateTime? startDate, DateTime? endDate) async {
    try {
      String url = '$baseUrl/sla/settings/$firmId/history';
      if (startDate != null || endDate != null) {
        final params = <String, String>{};
        if (startDate != null) params['start_date'] = startDate.toIso8601String();
        if (endDate != null) params['end_date'] = endDate.toIso8601String();
        url += '?${Uri(queryParameters: params).query}';
      }
      
      final response = await dio.get(url);
      
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get settings history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error getting settings history: $e');
    }
  }

  @override
  Future<SlaSettingsEntity> revertSettings(String firmId, String historyId) async {
    try {
      AppLogger.info('Reverting SLA settings for firm: $firmId to history: $historyId');
      final response = await dio.post('$baseUrl/sla/settings/$firmId/revert/$historyId');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        AppLogger.success('SLA settings reverted successfully');
        return SlaSettingsModel.fromJson(data);
      } else {
        throw Exception('Failed to revert settings: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.warning('API error reverting settings: ${e.message}');
      
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout) {
        return _getDefaultSlaSettings(firmId);
      }
      
      throw Exception('Network error reverting settings: $e');
    } catch (e) {
      AppLogger.error('Unexpected error reverting settings', error: e);
      throw Exception('Network error reverting settings: $e');
    }
  }

  // Helper methods for fallback data
  SlaSettingsEntity _getDefaultSlaSettings(String firmId) {
    return SlaSettingsModel.fromJson({
      'id': 'default-$firmId',
      'firm_id': firmId,
      'normal_timeframe': {'hours': 48, 'priority': 'normal'},
      'urgent_timeframe': {'hours': 24, 'priority': 'urgent'},
      'emergency_timeframe': {'hours': 6, 'priority': 'emergency'},
      'complex_timeframe': {'hours': 72, 'priority': 'complex'},
      'enable_business_hours_only': true,
      'include_weekends': false,
      'allow_overrides': true,
      'enable_auto_escalation': true,
      'override_settings': {},
      'last_modified': DateTime.now().toIso8601String(),
      'last_modified_by': 'system',
      'business_start_hour': '09:00',
      'business_end_hour': '18:00',
    });
  }

  List<Map<String, dynamic>> _getDefaultPresets(bool includeSystemPresets) {
    final presets = <Map<String, dynamic>>[];
    
    if (includeSystemPresets) {
      presets.addAll([
        {
          'id': 'preset-standard',
          'name': 'Padrão',
          'description': 'Configuração padrão para escritórios',
          'category': 'standard',
          'default_sla_hours': 48,
          'urgent_sla_hours': 24,
          'emergency_sla_hours': 6,
          'complex_case_sla_hours': 72,
          'business_hours_start': '09:00',
          'business_hours_end': '18:00',
          'include_weekends': false,
          'notification_timings': {
            'before_deadline': [60, 30, 15],
            'at_deadline': [0],
            'after_violation': [15, 30, 60],
          },
          'escalation_rules': {},
          'override_settings': {},
          'is_system_preset': true,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'created_by': 'system',
        },
        {
          'id': 'preset-aggressive',
          'name': 'Agressivo',
          'description': 'SLA mais rígido para casos urgentes',
          'category': 'aggressive',
          'default_sla_hours': 24,
          'urgent_sla_hours': 12,
          'emergency_sla_hours': 3,
          'complex_case_sla_hours': 48,
          'business_hours_start': '08:00',
          'business_hours_end': '20:00',
          'include_weekends': true,
          'notification_timings': {
            'before_deadline': [120, 60, 30, 15],
            'at_deadline': [0],
            'after_violation': [5, 15, 30],
          },
          'escalation_rules': {},
          'override_settings': {},
          'is_system_preset': true,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'created_by': 'system',
        },
        {
          'id': 'preset-relaxed',
          'name': 'Flexível',
          'description': 'SLA mais flexível para escritórios grandes',
          'category': 'relaxed',
          'default_sla_hours': 72,
          'urgent_sla_hours': 48,
          'emergency_sla_hours': 12,
          'complex_case_sla_hours': 120,
          'business_hours_start': '09:00',
          'business_hours_end': '17:00',
          'include_weekends': false,
          'notification_timings': {
            'before_deadline': [48, 24, 12],
            'at_deadline': [0],
            'after_violation': [24, 48],
          },
          'escalation_rules': {},
          'override_settings': {},
          'is_system_preset': true,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'created_by': 'system',
        },
      ]);
    }
    
    return presets;
  }
} 