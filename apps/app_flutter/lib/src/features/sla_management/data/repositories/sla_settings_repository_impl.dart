import 'dart:convert';
import 'package:dio/dio.dart';
import '../../domain/entities/sla_settings_entity.dart';
import '../../domain/repositories/sla_settings_repository.dart';
import '../datasources/sla_settings_remote_data_source.dart';
import '../datasources/sla_settings_local_data_source.dart';
import '../models/sla_settings_model.dart';

class SlaSettingsRepositoryImpl implements SlaSettingsRepository {
  final SlaSettingsRemoteDataSource remoteDataSource;
  final SlaSettingsLocalDataSource localDataSource;
  final Dio dio;

  SlaSettingsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.dio,
  });

  @override
  Future<SlaSettingsEntity> getSlaSettings(String firmId) async {
    try {
      // Try to get from cache first
      final cachedSettings = await localDataSource.getSlaSettings(firmId);
      if (cachedSettings != null) {
        return cachedSettings;
      }

      // Fetch from remote
      final remoteSettings = await remoteDataSource.getSlaSettings(firmId);
      
      // Cache the result
      await localDataSource.cacheSlaSettings(remoteSettings);
      
      return remoteSettings;
    } catch (e) {
      // Fallback to local cache if remote fails
      final cachedSettings = await localDataSource.getSlaSettings(firmId);
      if (cachedSettings != null) {
        return cachedSettings;
      }
      throw Exception('Failed to load SLA settings: $e');
    }
  }

  @override
  Future<SlaSettingsEntity> updateSlaSettings(SlaSettingsEntity settings) async {
    try {
      // Update remote first
      final updatedSettings = await remoteDataSource.updateSlaSettings(settings);
      
      // Update local cache
      await localDataSource.cacheSlaSettings(updatedSettings);
      
      return updatedSettings;
    } catch (e) {
      throw Exception('Failed to update SLA settings: $e');
    }
  }

  @override
  Future<void> deleteSlaSettings(String firmId) async {
    try {
      await remoteDataSource.deleteSlaSettings(firmId);
      await localDataSource.clearSlaSettings(firmId);
    } catch (e) {
      throw Exception('Failed to delete SLA settings: $e');
    }
  }

  @override
  Future<List<SlaSettingsEntity>> getAllSlaSettings() async {
    try {
      final settings = await remoteDataSource.getAllSlaSettings();
      return settings;
    } catch (e) {
      throw Exception('Failed to load all SLA settings: $e');
    }
  }

  @override
  Future<SlaSettingsEntity> createSlaSettings(SlaSettingsEntity settings) async {
    try {
      final createdSettings = await remoteDataSource.createSlaSettings(settings);
      await localDataSource.cacheSlaSettings(createdSettings);
      return createdSettings;
    } catch (e) {
      throw Exception('Failed to create SLA settings: $e');
    }
  }

  @override
  Future<bool> validateSlaSettings(SlaSettingsEntity settings) async {
    try {
      final validationResult = await remoteDataSource.validateSlaSettings(settings);
      return validationResult.isValid;
    } catch (e) {
      throw Exception('Failed to validate SLA settings: $e');
    }
  }

  @override
  Future<String> exportSlaSettings(String firmId, String format) async {
    try {
      final exportPath = await remoteDataSource.exportSlaSettings(firmId, format);
      return exportPath;
    } catch (e) {
      throw Exception('Failed to export SLA settings: $e');
    }
  }

  @override
  Future<SlaSettingsEntity> importSlaSettings(String filePath) async {
    try {
      final importedSettings = await remoteDataSource.importSlaSettings(filePath);
      await localDataSource.cacheSlaSettings(importedSettings);
      return importedSettings;
    } catch (e) {
      throw Exception('Failed to import SLA settings: $e');
    }
  }

  @override
  Future<SlaSettingsEntity> resetToDefaults(String firmId) async {
    try {
      final defaultSettings = await remoteDataSource.resetToDefaults(firmId);
      await localDataSource.cacheSlaSettings(defaultSettings);
      return defaultSettings;
    } catch (e) {
      throw Exception('Failed to reset SLA settings: $e');
    }
  }

  @override
  Future<SlaSettingsEntity> backupSlaSettings(String firmId) async {
    try {
      final backupSettings = await remoteDataSource.backupSlaSettings(firmId);
      return backupSettings;
    } catch (e) {
      throw Exception('Failed to backup SLA settings: $e');
    }
  }

  @override
  Future<SlaSettingsEntity> restoreSlaSettings(String backupId) async {
    try {
      final restoredSettings = await remoteDataSource.restoreSlaSettings(backupId);
      await localDataSource.cacheSlaSettings(restoredSettings);
      return restoredSettings;
    } catch (e) {
      throw Exception('Failed to restore SLA settings: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getSlaSettingsHistory(String firmId) async {
    try {
      final history = await remoteDataSource.getSlaSettingsHistory(firmId);
      return history;
    } catch (e) {
      throw Exception('Failed to get SLA settings history: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await localDataSource.clearAllSlaSettings();
    } catch (e) {
      throw Exception('Failed to clear SLA settings cache: $e');
    }
  }
} 