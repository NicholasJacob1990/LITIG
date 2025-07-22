import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/sla_preset_entity.dart';
import '../../domain/entities/sla_settings_entity.dart';
import '../../domain/repositories/sla_settings_repository.dart';
import '../../domain/value_objects/sla_timeframe.dart';
import '../datasources/sla_settings_remote_data_source.dart';
import '../datasources/sla_settings_local_data_source.dart';

class SlaSettingsRepositoryImpl implements SlaSettingsRepository {
  final SlaSettingsRemoteDataSource remoteDataSource;
  final SlaSettingsLocalDataSource localDataSource;

  SlaSettingsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, SlaPresetEntity>> getSettings({
    required String firmId,
  }) async {
    try {
      final settings = await remoteDataSource.getSettings(firmId);
      // Converter SlaSettingsEntity para SlaPresetEntity
      return Right(SlaPresetEntity(
        id: settings.id,
        name: 'Settings',
        description: 'Current settings',
        category: 'system',
        defaultSlaHours: settings.defaultSlaHours ?? 48,
        urgentSlaHours: settings.urgentSlaHours ?? 24,
        emergencySlaHours: settings.emergencySlaHours ?? 6,
        complexCaseSlaHours: settings.complexCaseSlaHours ?? 72,
        businessHoursStart: settings.businessHoursStart,
        businessHoursEnd: settings.businessHoursEnd,
        includeWeekends: settings.includeWeekends,
        notificationTimings: const {
          'before_deadline': [60, 30, 15],
          'at_deadline': [0],
          'after_violation': [15, 30, 60],
        },
        escalationRules: settings.escalationRules ?? {},
        overrideSettings: settings.overrideSettings,
        isSystemPreset: true,
        isActive: true,
        createdAt: settings.lastModified,
        updatedAt: settings.lastModified,
        createdBy: settings.lastModifiedBy,
      ));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get settings: $e'));
    }
  }

  @override
  Future<Either<Failure, SlaPresetEntity>> updateSettings({
    required String firmId,
    required SlaPresetEntity settings,
  }) async {
    try {
      // Converter SlaPresetEntity para SlaSettingsEntity
      final settingsEntity = SlaSettingsEntity(
        id: settings.id,
        firmId: firmId,
        normalTimeframe: SlaTimeframe(hours: settings.defaultSlaHours, priority: 'normal'),
        urgentTimeframe: SlaTimeframe(hours: settings.urgentSlaHours, priority: 'urgent'),
        emergencyTimeframe: SlaTimeframe(hours: settings.emergencySlaHours, priority: 'emergency'),
        complexTimeframe: SlaTimeframe(hours: settings.complexCaseSlaHours, priority: 'complex'),
        enableBusinessHoursOnly: true,
        includeWeekends: settings.includeWeekends,
        allowOverrides: true,
        enableAutoEscalation: true,
        overrideSettings: settings.overrideSettings,
        lastModified: DateTime.now(),
        lastModifiedBy: settings.createdBy ?? 'system',
        businessStartHour: settings.businessHoursStart,
        businessEndHour: settings.businessHoursEnd,
      );
      
      final updated = await remoteDataSource.updateSettings(firmId, settingsEntity);
      return Right(settings);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update settings: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SlaPresetEntity>>> getPresets({
    required String firmId,
    bool includeSystemPresets = true,
  }) async {
    try {
      final presetsData = await remoteDataSource.getPresets(firmId, includeSystemPresets);
      // Converter Map para SlaPresetEntity
      final presets = presetsData.map((data) => SlaPresetEntity(
        id: data['id'] as String,
        name: data['name'] as String,
        description: data['description'] as String,
        category: data['category'] as String,
        defaultSlaHours: data['default_sla_hours'] as int? ?? 48,
        urgentSlaHours: data['urgent_sla_hours'] as int? ?? 24,
        emergencySlaHours: data['emergency_sla_hours'] as int? ?? 6,
        complexCaseSlaHours: data['complex_case_sla_hours'] as int? ?? 72,
        businessHoursStart: data['business_hours_start'] as String? ?? '09:00',
        businessHoursEnd: data['business_hours_end'] as String? ?? '18:00',
        includeWeekends: data['include_weekends'] as bool? ?? false,
        notificationTimings: Map<String, List<int>>.from(data['notification_timings'] ?? {}),
        escalationRules: Map<String, dynamic>.from(data['escalation_rules'] ?? {}),
        overrideSettings: Map<String, dynamic>.from(data['override_settings'] ?? {}),
        isSystemPreset: data['is_system_preset'] as bool? ?? false,
        isActive: data['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(data['created_at'] as String),
        updatedAt: DateTime.parse(data['updated_at'] as String),
        firmId: data['firm_id'] as String?,
        createdBy: data['created_by'] as String?,
      )).toList();
      return Right(presets);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get presets: $e'));
    }
  }

  @override
  Future<Either<Failure, SlaPresetEntity>> createPreset({
    required String firmId,
    required SlaPresetEntity preset,
  }) async {
    try {
      final presetData = {
        'name': preset.name,
        'description': preset.description,
        'category': preset.category,
        'default_sla_hours': preset.defaultSlaHours,
        'urgent_sla_hours': preset.urgentSlaHours,
        'emergency_sla_hours': preset.emergencySlaHours,
        'complex_case_sla_hours': preset.complexCaseSlaHours,
        'business_hours_start': preset.businessHoursStart,
        'business_hours_end': preset.businessHoursEnd,
        'include_weekends': preset.includeWeekends,
        'notification_timings': preset.notificationTimings,
        'escalation_rules': preset.escalationRules,
        'override_settings': preset.overrideSettings,
        'is_system_preset': preset.isSystemPreset,
        'is_active': preset.isActive,
        'firm_id': preset.firmId,
        'created_by': preset.createdBy,
      };
      
      final created = await remoteDataSource.createPreset(firmId, presetData);
      return Right(preset);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create preset: $e'));
    }
  }

  @override
  Future<Either<Failure, SlaPresetEntity>> updatePreset({
    required String presetId,
    required SlaPresetEntity preset,
  }) async {
    try {
      final presetData = {
        'name': preset.name,
        'description': preset.description,
        'category': preset.category,
        'default_sla_hours': preset.defaultSlaHours,
        'urgent_sla_hours': preset.urgentSlaHours,
        'emergency_sla_hours': preset.emergencySlaHours,
        'complex_case_sla_hours': preset.complexCaseSlaHours,
        'business_hours_start': preset.businessHoursStart,
        'business_hours_end': preset.businessHoursEnd,
        'include_weekends': preset.includeWeekends,
        'notification_timings': preset.notificationTimings,
        'escalation_rules': preset.escalationRules,
        'override_settings': preset.overrideSettings,
        'is_system_preset': preset.isSystemPreset,
        'is_active': preset.isActive,
        'firm_id': preset.firmId,
        'created_by': preset.createdBy,
      };
      
      final updated = await remoteDataSource.updatePreset(presetId, presetData);
      return Right(preset);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update preset: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePreset({
    required String presetId,
  }) async {
    try {
      await remoteDataSource.deletePreset(presetId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete preset: $e'));
    }
  }

  @override
  Future<Either<Failure, SlaPresetEntity>> applyPreset({
    required String firmId,
    required String presetId,
  }) async {
    try {
      final applied = await remoteDataSource.applyPreset(firmId, presetId);
      // Converter SlaSettingsEntity para SlaPresetEntity
      final preset = SlaPresetEntity(
        id: applied.id,
        name: 'Applied Preset',
        description: 'Preset applied to settings',
        category: 'applied',
        defaultSlaHours: applied.normalTimeframe.hours,
        urgentSlaHours: applied.urgentTimeframe.hours,
        emergencySlaHours: applied.emergencyTimeframe.hours,
        complexCaseSlaHours: applied.complexTimeframe.hours,
        businessHoursStart: applied.businessStartHour,
        businessHoursEnd: applied.businessEndHour,
        includeWeekends: applied.includeWeekends,
        notificationTimings: const {},
        escalationRules: const {},
        overrideSettings: applied.overrideSettings,
        isSystemPreset: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        firmId: applied.firmId,
        createdBy: applied.lastModifiedBy,
      );
      return Right(preset);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to apply preset: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getNotificationSettings({
    required String firmId,
  }) async {
    try {
      final settings = await remoteDataSource.getNotificationSettings(firmId);
      return Right(settings);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get notification settings: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateNotificationSettings({
    required String firmId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      await remoteDataSource.updateNotificationSettings(firmId, settings);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update notification settings: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getEscalationSettings({
    required String firmId,
  }) async {
    try {
      final settings = await remoteDataSource.getEscalationSettings(firmId);
      return Right(settings);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get escalation settings: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateEscalationSettings({
    required String firmId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      await remoteDataSource.updateEscalationSettings(firmId, settings);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update escalation settings: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getBusinessHoursSettings({
    required String firmId,
  }) async {
    try {
      final settings = await remoteDataSource.getBusinessHoursSettings(firmId);
      return Right(settings);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get business hours settings: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateBusinessHoursSettings({
    required String firmId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      await remoteDataSource.updateBusinessHoursSettings(firmId, settings);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update business hours settings: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getHolidaySettings({
    required String firmId,
  }) async {
    try {
      final holidays = await remoteDataSource.getHolidaySettings(firmId);
      return Right(holidays);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get holiday settings: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateHolidaySettings({
    required String firmId,
    required List<Map<String, dynamic>> holidays,
  }) async {
    try {
      await remoteDataSource.updateHolidaySettings(firmId, holidays);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update holiday settings: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> validateSettings({
    required SlaPresetEntity settings,
  }) async {
    try {
      // Converter SlaPresetEntity para SlaSettingsEntity
      final settingsEntity = SlaSettingsEntity(
        id: settings.id,
        firmId: settings.firmId ?? '',
        normalTimeframe: SlaTimeframe(hours: settings.defaultSlaHours, priority: 'normal'),
        urgentTimeframe: SlaTimeframe(hours: settings.urgentSlaHours, priority: 'urgent'),
        emergencyTimeframe: SlaTimeframe(hours: settings.emergencySlaHours, priority: 'emergency'),
        complexTimeframe: SlaTimeframe(hours: settings.complexCaseSlaHours, priority: 'complex'),
        enableBusinessHoursOnly: true,
        includeWeekends: settings.includeWeekends,
        allowOverrides: true,
        enableAutoEscalation: true,
        overrideSettings: settings.overrideSettings,
        lastModified: DateTime.now(),
        lastModifiedBy: settings.createdBy ?? 'system',
        businessStartHour: settings.businessHoursStart,
        businessEndHour: settings.businessHoursEnd,
      );
      final result = await remoteDataSource.validateSettings(settingsEntity);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to validate settings: $e'));
    }
  }

  @override
  Future<Either<Failure, SlaPresetEntity>> getDefaultSettings() async {
    try {
      final settings = await remoteDataSource.getDefaultSettings();
      // Converter SlaSettingsEntity para SlaPresetEntity
      final preset = SlaPresetEntity(
        id: settings.id,
        name: 'Default Settings',
        description: 'Default SLA settings',
        category: 'default',
        defaultSlaHours: settings.normalTimeframe.hours,
        urgentSlaHours: settings.urgentTimeframe.hours,
        emergencySlaHours: settings.emergencyTimeframe.hours,
        complexCaseSlaHours: settings.complexTimeframe.hours,
        businessHoursStart: settings.businessStartHour,
        businessHoursEnd: settings.businessEndHour,
        includeWeekends: settings.includeWeekends,
        notificationTimings: const {},
        escalationRules: const {},
        overrideSettings: settings.overrideSettings,
        isSystemPreset: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        firmId: settings.firmId,
        createdBy: settings.lastModifiedBy,
      );
      return Right(preset);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get default settings: $e'));
    }
  }

  @override
  Future<Either<Failure, SlaPresetEntity>> cloneSettings({
    required String sourceFirmId,
    required String targetFirmId,
  }) async {
    try {
      final cloned = await remoteDataSource.cloneSettings(sourceFirmId, targetFirmId);
      // Converter SlaSettingsEntity para SlaPresetEntity
      final preset = SlaPresetEntity(
        id: cloned.id,
        name: 'Cloned Settings',
        description: 'Settings cloned from $sourceFirmId',
        category: 'cloned',
        defaultSlaHours: cloned.normalTimeframe.hours,
        urgentSlaHours: cloned.urgentTimeframe.hours,
        emergencySlaHours: cloned.emergencyTimeframe.hours,
        complexCaseSlaHours: cloned.complexTimeframe.hours,
        businessHoursStart: cloned.businessStartHour,
        businessHoursEnd: cloned.businessEndHour,
        includeWeekends: cloned.includeWeekends,
        notificationTimings: const {},
        escalationRules: const {},
        overrideSettings: cloned.overrideSettings,
        isSystemPreset: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        firmId: cloned.firmId,
        createdBy: cloned.lastModifiedBy,
      );
      return Right(preset);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to clone settings: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> exportSettings({
    required String firmId,
    String format = 'json',
  }) async {
    try {
      final exported = await remoteDataSource.exportSettings(firmId, format);
      return Right(exported);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to export settings: $e'));
    }
  }

  @override
  Future<Either<Failure, SlaPresetEntity>> importSettings({
    required String firmId,
    required String settingsData,
    String format = 'json',
  }) async {
    try {
      final imported = await remoteDataSource.importSettings(firmId, settingsData, format);
      // Converter SlaSettingsEntity para SlaPresetEntity
      final preset = SlaPresetEntity(
        id: imported.id,
        name: 'Imported Settings',
        description: 'Settings imported from file',
        category: 'imported',
        defaultSlaHours: imported.normalTimeframe.hours,
        urgentSlaHours: imported.urgentTimeframe.hours,
        emergencySlaHours: imported.emergencyTimeframe.hours,
        complexCaseSlaHours: imported.complexTimeframe.hours,
        businessHoursStart: imported.businessStartHour,
        businessHoursEnd: imported.businessEndHour,
        includeWeekends: imported.includeWeekends,
        notificationTimings: const {},
        escalationRules: const {},
        overrideSettings: imported.overrideSettings,
        isSystemPreset: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        firmId: imported.firmId,
        createdBy: imported.lastModifiedBy,
      );
      return Right(preset);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to import settings: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getSettingsHistory({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final history = await remoteDataSource.getSettingsHistory(firmId, startDate, endDate);
      return Right(history);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get settings history: $e'));
    }
  }

  @override
  Future<Either<Failure, SlaPresetEntity>> revertSettings({
    required String firmId,
    required String historyId,
  }) async {
    try {
      final reverted = await remoteDataSource.revertSettings(firmId, historyId);
      // Converter SlaSettingsEntity para SlaPresetEntity
      final preset = SlaPresetEntity(
        id: reverted.id,
        name: 'Reverted Settings',
        description: 'Settings reverted from history',
        category: 'reverted',
        defaultSlaHours: reverted.normalTimeframe.hours,
        urgentSlaHours: reverted.urgentTimeframe.hours,
        emergencySlaHours: reverted.emergencyTimeframe.hours,
        complexCaseSlaHours: reverted.complexTimeframe.hours,
        businessHoursStart: reverted.businessStartHour,
        businessHoursEnd: reverted.businessEndHour,
        includeWeekends: reverted.includeWeekends,
        notificationTimings: const {},
        escalationRules: const {},
        overrideSettings: reverted.overrideSettings,
        isSystemPreset: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        firmId: reverted.firmId,
        createdBy: reverted.lastModifiedBy,
      );
      return Right(preset);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to revert settings: $e'));
    }
  }
}