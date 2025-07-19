import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/sla_settings_entity.dart';
import '../../domain/entities/sla_preset_entity.dart';

abstract class SlaSettingsEvent extends Equatable {
  const SlaSettingsEvent();

  @override
  List<Object?> get props => [];
}

// Core Settings Events
class LoadSlaSettingsEvent extends SlaSettingsEvent {
  final String firmId;
  final String? userId;

  const LoadSlaSettingsEvent({
    required this.firmId,
    this.userId,
  });

  @override
  List<Object?> get props => [firmId, userId];
}

class UpdateSlaSettingsEvent extends SlaSettingsEvent {
  final SlaSettingsEntity settings;
  final bool autoValidate;

  const UpdateSlaSettingsEvent({
    required this.settings,
    this.autoValidate = false,
  });

  @override
  List<Object?> get props => [settings, autoValidate];
}

class SaveSlaSettingsEvent extends SlaSettingsEvent {
  final bool forceSave;
  final String? saveComment;

  const SaveSlaSettingsEvent({
    this.forceSave = false,
    this.saveComment,
  });

  @override
  List<Object?> get props => [forceSave, saveComment];
}

// Preset Management Events
class ApplyPresetEvent extends SlaSettingsEvent {
  final SlaPresetEntity preset;
  final bool confirmOverwrite;

  const ApplyPresetEvent({
    required this.preset,
    this.confirmOverwrite = false,
  });

  @override
  List<Object?> get props => [preset, confirmOverwrite];
}

class CreateCustomPresetEvent extends SlaSettingsEvent {
  final String name;
  final String description;
  final int normalHours;
  final int urgentHours;
  final int emergencyHours;

  const CreateCustomPresetEvent({
    required this.name,
    required this.description,
    required this.normalHours,
    required this.urgentHours,
    required this.emergencyHours,
  });

  @override
  List<Object?> get props => [name, description, normalHours, urgentHours, emergencyHours];
}

class DeletePresetEvent extends SlaSettingsEvent {
  final SlaPresetEntity preset;
  final bool confirmDeletion;

  const DeletePresetEvent({
    required this.preset,
    this.confirmDeletion = false,
  });

  @override
  List<Object?> get props => [preset, confirmDeletion];
}

class DuplicatePresetEvent extends SlaSettingsEvent {
  final SlaPresetEntity preset;
  final String? newName;

  const DuplicatePresetEvent({
    required this.preset,
    this.newName,
  });

  @override
  List<Object?> get props => [preset, newName];
}

// Validation Events
class ValidateSettingsEvent extends SlaSettingsEvent {
  final bool showResults;

  const ValidateSettingsEvent({
    this.showResults = true,
  });

  @override
  List<Object?> get props => [showResults];
}

class ClearValidationErrorsEvent extends SlaSettingsEvent {
  const ClearValidationErrorsEvent();
}

// Import/Export Events
class ExportSettingsEvent extends SlaSettingsEvent {
  final String format; // 'json', 'yaml', 'xml'
  final String? filePath;
  final bool includePresets;

  const ExportSettingsEvent({
    this.format = 'json',
    this.filePath,
    this.includePresets = true,
  });

  @override
  List<Object?> get props => [format, filePath, includePresets];
}

class ImportSettingsEvent extends SlaSettingsEvent {
  final String filePath;
  final String format;
  final bool mergeWithExisting;
  final bool validateBeforeImport;

  const ImportSettingsEvent({
    required this.filePath,
    required this.format,
    this.mergeWithExisting = false,
    this.validateBeforeImport = true,
  });

  @override
  List<Object?> get props => [filePath, format, mergeWithExisting, validateBeforeImport];
}

// Utility Events
class ResetToDefaultEvent extends SlaSettingsEvent {
  final bool confirmReset;

  const ResetToDefaultEvent({
    this.confirmReset = false,
  });

  @override
  List<Object?> get props => [confirmReset];
}

class TestSlaCalculationEvent extends SlaSettingsEvent {
  final String priority; // 'normal', 'urgent', 'emergency'
  final String caseType;
  final DateTime startTime;
  final int? overrideHours;

  const TestSlaCalculationEvent({
    required this.priority,
    required this.caseType,
    required this.startTime,
    this.overrideHours,
  });

  @override
  List<Object?> get props => [priority, caseType, startTime, overrideHours];
}

// Specific Settings Updates
class UpdateBusinessHoursEvent extends SlaSettingsEvent {
  final int startHour;
  final int endHour;
  final List<int> businessDays;
  final String timezone;

  const UpdateBusinessHoursEvent({
    required this.startHour,
    required this.endHour,
    required this.businessDays,
    required this.timezone,
  });

  @override
  List<Object?> get props => [startHour, endHour, businessDays, timezone];
}

class UpdateEscalationRulesEvent extends SlaSettingsEvent {
  final bool enableEscalation;
  final List<int> escalationPercentages;

  const UpdateEscalationRulesEvent({
    required this.enableEscalation,
    required this.escalationPercentages,
  });

  @override
  List<Object?> get props => [enableEscalation, escalationPercentages];
}

class ToggleOverrideSettingsEvent extends SlaSettingsEvent {
  final bool allowOverride;
  final int? maxOverrideHours;
  final List<String>? requiredRoles;

  const ToggleOverrideSettingsEvent({
    required this.allowOverride,
    this.maxOverrideHours,
    this.requiredRoles,
  });

  @override
  List<Object?> get props => [allowOverride, maxOverrideHours, requiredRoles];
}

// Timeframe Specific Events
class UpdateNormalTimeframeEvent extends SlaSettingsEvent {
  final int hours;

  const UpdateNormalTimeframeEvent({required this.hours});

  @override
  List<Object?> get props => [hours];
}

class UpdateUrgentTimeframeEvent extends SlaSettingsEvent {
  final int hours;

  const UpdateUrgentTimeframeEvent({required this.hours});

  @override
  List<Object?> get props => [hours];
}

class UpdateEmergencyTimeframeEvent extends SlaSettingsEvent {
  final int hours;

  const UpdateEmergencyTimeframeEvent({required this.hours});

  @override
  List<Object?> get props => [hours];
}

// Holiday Management Events
class AddHolidayEvent extends SlaSettingsEvent {
  final DateTime date;
  final String name;
  final String? description;

  const AddHolidayEvent({
    required this.date,
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [date, name, description];
}

class RemoveHolidayEvent extends SlaSettingsEvent {
  final DateTime date;

  const RemoveHolidayEvent({required this.date});

  @override
  List<Object?> get props => [date];
}

class LoadHolidaysEvent extends SlaSettingsEvent {
  final int year;
  final String? region; // 'BR', 'SP', 'RJ', etc.

  const LoadHolidaysEvent({
    required this.year,
    this.region,
  });

  @override
  List<Object?> get props => [year, region];
}

// Notification Settings Events
class UpdateNotificationSettingsEvent extends SlaSettingsEvent {
  final bool enableNotifications;
  final List<String> notificationChannels; // 'email', 'push', 'sms'
  final Map<String, dynamic> notificationTemplates;

  const UpdateNotificationSettingsEvent({
    required this.enableNotifications,
    required this.notificationChannels,
    required this.notificationTemplates,
  });

  @override
  List<Object?> get props => [enableNotifications, notificationChannels, notificationTemplates];
}

// Backup and Restore Events
class CreateBackupEvent extends SlaSettingsEvent {
  final String? backupName;
  final bool includePresets;
  final bool includeHistory;

  const CreateBackupEvent({
    this.backupName,
    this.includePresets = true,
    this.includeHistory = false,
  });

  @override
  List<Object?> get props => [backupName, includePresets, includeHistory];
}

class RestoreFromBackupEvent extends SlaSettingsEvent {
  final String backupId;
  final bool confirmRestore;

  const RestoreFromBackupEvent({
    required this.backupId,
    this.confirmRestore = false,
  });

  @override
  List<Object?> get props => [backupId, confirmRestore];
}

// Audit Events
class ViewSettingsHistoryEvent extends SlaSettingsEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? userId;

  const ViewSettingsHistoryEvent({
    this.startDate,
    this.endDate,
    this.userId,
  });

  @override
  List<Object?> get props => [startDate, endDate, userId];
}

class RevertToVersionEvent extends SlaSettingsEvent {
  final String versionId;
  final bool confirmRevert;

  const RevertToVersionEvent({
    required this.versionId,
    this.confirmRevert = false,
  });

  @override
  List<Object?> get props => [versionId, confirmRevert];
}

// Missing events for widget compatibility
class ValidateSlaSettingsEvent extends SlaSettingsEvent {
  final dynamic settings;

  const ValidateSlaSettingsEvent({
    required this.settings,
  });

  @override
  List<Object?> get props => [settings];
}

class ResetSlaSettingsEvent extends SlaSettingsEvent {
  const ResetSlaSettingsEvent();
}

class TestSlaSettingsEvent extends SlaSettingsEvent {
  final dynamic settings;

  const TestSlaSettingsEvent({
    required this.settings,
  });

  @override
  List<Object?> get props => [settings];
}

class UpdateSlaNotificationSettingsEvent extends SlaSettingsEvent {
  final Map<String, dynamic> settings;

  const UpdateSlaNotificationSettingsEvent({
    required this.settings,
  });

  @override
  List<Object?> get props => [settings];
}

class UpdateSlaBusinessRulesEvent extends SlaSettingsEvent {
  final Map<String, dynamic> businessRules;

  const UpdateSlaBusinessRulesEvent({
    required this.businessRules,
  });

  @override
  List<Object?> get props => [businessRules];
}

class UpdateSlaEscalationSettingsEvent extends SlaSettingsEvent {
  final Map<String, dynamic> settings;

  const UpdateSlaEscalationSettingsEvent({
    required this.settings,
  });

  @override
  List<Object?> get props => [settings];
}

class TestSlaEscalationEvent extends SlaSettingsEvent {
  final String escalationId;

  const TestSlaEscalationEvent({
    required this.escalationId,
  });

  @override
  List<Object?> get props => [escalationId];
}

// Audit Events
class ExportSlaAuditLogEvent extends SlaSettingsEvent {
  final String format;
  final DateTimeRange? dateRange;

  const ExportSlaAuditLogEvent(
    this.format, {
    this.dateRange,
  });

  @override
  List<Object?> get props => [format, dateRange];
}

class GenerateSlaComplianceReportEvent extends SlaSettingsEvent {
  final DateTimeRange dateRange;

  const GenerateSlaComplianceReportEvent(this.dateRange);

  @override
  List<Object?> get props => [dateRange];
}

class VerifySlaIntegrityEvent extends SlaSettingsEvent {
  const VerifySlaIntegrityEvent();
}

// Notification Events
class TestSlaNotificationEvent extends SlaSettingsEvent {
  final String channel;

  const TestSlaNotificationEvent(this.channel);

  @override
  List<Object?> get props => [channel];
}

// Preset Events
class ApplySlaPresetEvent extends SlaSettingsEvent {
  final SlaPresetEntity preset;

  const ApplySlaPresetEvent(this.preset);

  @override
  List<Object?> get props => [preset];
}

class CreateCustomSlaPresetEvent extends SlaSettingsEvent {
  final SlaPresetEntity preset;

  const CreateCustomSlaPresetEvent(this.preset);

  @override
  List<Object?> get props => [preset];
}

class ExportSlaPresetEvent extends SlaSettingsEvent {
  final SlaPresetEntity preset;

  const ExportSlaPresetEvent(this.preset);

  @override
  List<Object?> get props => [preset];
}

class DeleteSlaPresetEvent extends SlaSettingsEvent {
  final String presetId;

  const DeleteSlaPresetEvent(this.presetId);

  @override
  List<Object?> get props => [presetId];
} 