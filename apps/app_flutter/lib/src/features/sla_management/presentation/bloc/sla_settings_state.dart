import 'package:equatable/equatable.dart';
import '../../domain/entities/sla_settings_entity.dart';
import '../../domain/entities/sla_preset_entity.dart';
import '../../domain/usecases/validate_sla_settings.dart';

abstract class SlaSettingsState extends Equatable {
  const SlaSettingsState();

  @override
  List<Object?> get props => [];
}

// Initial State
class SlaSettingsInitial extends SlaSettingsState {
  const SlaSettingsInitial();
}

// Loading State
class SlaSettingsLoading extends SlaSettingsState {
  final String? message;

  const SlaSettingsLoading({this.message});

  @override
  List<Object?> get props => [message];
}

// Loaded State - Main state when settings are loaded and ready for editing
class SlaSettingsLoaded extends SlaSettingsState {
  final SlaSettingsEntity settings;
  final List<SlaPresetEntity> availablePresets;
  final SlaValidationResult? validationResult;
  final bool isModified;
  final DateTime? lastSaved;
  final DateTime? lastModified;
  final Map<String, dynamic>? metadata;

  const SlaSettingsLoaded({
    required this.settings,
    required this.availablePresets,
    this.validationResult,
    this.isModified = false,
    this.lastSaved,
    this.lastModified,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        settings,
        availablePresets,
        validationResult,
        isModified,
        lastSaved,
        lastModified,
        metadata,
      ];

  SlaSettingsLoaded copyWith({
    SlaSettingsEntity? settings,
    List<SlaPresetEntity>? availablePresets,
    SlaValidationResult? validationResult,
    bool? isModified,
    DateTime? lastSaved,
    DateTime? lastModified,
    Map<String, dynamic>? metadata,
  }) {
    return SlaSettingsLoaded(
      settings: settings ?? this.settings,
      availablePresets: availablePresets ?? this.availablePresets,
      validationResult: validationResult ?? this.validationResult,
      isModified: isModified ?? this.isModified,
      lastSaved: lastSaved ?? this.lastSaved,
      lastModified: lastModified ?? this.lastModified,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper getters
  bool get hasValidationErrors => validationResult?.violations.isNotEmpty ?? false;
  bool get hasValidationWarnings => validationResult?.warnings.isNotEmpty ?? false;
  bool get isValid => validationResult?.isValid ?? true;
  int get validationScore => validationResult?.score ?? 100;
  bool get needsSaving => isModified;
  bool get hasUnsavedChanges => isModified && lastModified != null;
}

// Updating State - When save operation is in progress
class SlaSettingsUpdating extends SlaSettingsState {
  final String? message;
  final double? progress; // 0.0 to 1.0

  const SlaSettingsUpdating({
    this.message,
    this.progress,
  });

  @override
  List<Object?> get props => [message, progress];
}

// Updated State - Temporary state to show success message
class SlaSettingsUpdated extends SlaSettingsState {
  final SlaSettingsEntity settings;
  final String message;
  final SlaValidationResult? validationResult;
  final DateTime savedAt;

  const SlaSettingsUpdated({
    required this.settings,
    required this.message,
    this.validationResult,
    required this.savedAt,
  });

  @override
  List<Object?> get props => [settings, message, validationResult, savedAt];
}

// Validation Error State - When validation fails
class SlaSettingsValidationError extends SlaSettingsState {
  final String message;
  final SlaValidationResult? validationResult;
  final SlaSettingsEntity settings;

  const SlaSettingsValidationError({
    required this.message,
    this.validationResult,
    required this.settings,
  });

  @override
  List<Object?> get props => [message, validationResult, settings];

  // Helper getters
  List<SlaValidationViolation> get violations => validationResult?.violations ?? [];
  List<SlaValidationWarning> get warnings => validationResult?.warnings ?? [];
  bool get hasViolations => violations.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

// Error State - For general errors
class SlaSettingsError extends SlaSettingsState {
  final String message;
  final String? errorCode;
  final dynamic error;
  final StackTrace? stackTrace;

  const SlaSettingsError({
    required this.message,
    this.errorCode,
    this.error,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, errorCode, error, stackTrace];

  // Helper getters
  bool get isNetworkError => errorCode?.contains('NETWORK') ?? false;
  bool get isServerError => errorCode?.contains('SERVER') ?? false;
  bool get isValidationError => errorCode?.contains('VALIDATION') ?? false;
  bool get isPermissionError => errorCode?.contains('PERMISSION') ?? false;
}

// Preset Management States
class SlaPresetsLoading extends SlaSettingsState {
  final String? message;

  const SlaPresetsLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class SlaPresetsLoaded extends SlaSettingsState {
  final List<SlaPresetEntity> presets;
  final SlaPresetEntity? selectedPreset;

  const SlaPresetsLoaded({
    required this.presets,
    this.selectedPreset,
  });

  @override
  List<Object?> get props => [presets, selectedPreset];

  // Helper getters
  List<SlaPresetEntity> get systemPresets => presets.where((p) => p.isSystemPreset).toList();
  List<SlaPresetEntity> get customPresets => presets.where((p) => !p.isSystemPreset).toList();
  bool get hasCustomPresets => customPresets.isNotEmpty;
}

// Import/Export States
class SlaSettingsExporting extends SlaSettingsState {
  final String format;
  final double? progress;

  const SlaSettingsExporting({
    required this.format,
    this.progress,
  });

  @override
  List<Object?> get props => [format, progress];
}

class SlaSettingsExported extends SlaSettingsState {
  final String filePath;
  final String format;
  final DateTime exportedAt;

  const SlaSettingsExported({
    required this.filePath,
    required this.format,
    required this.exportedAt,
  });

  @override
  List<Object?> get props => [filePath, format, exportedAt];
}

class SlaSettingsImporting extends SlaSettingsState {
  final String filePath;
  final String format;
  final double? progress;

  const SlaSettingsImporting({
    required this.filePath,
    required this.format,
    this.progress,
  });

  @override
  List<Object?> get props => [filePath, format, progress];
}

class SlaSettingsImported extends SlaSettingsState {
  final SlaSettingsEntity settings;
  final String message;
  final DateTime importedAt;

  const SlaSettingsImported({
    required this.settings,
    required this.message,
    required this.importedAt,
  });

  @override
  List<Object?> get props => [settings, message, importedAt];
}

// Testing States
class SlaCalculationTesting extends SlaSettingsState {
  final String priority;
  final String caseType;
  final DateTime startTime;

  const SlaCalculationTesting({
    required this.priority,
    required this.caseType,
    required this.startTime,
  });

  @override
  List<Object?> get props => [priority, caseType, startTime];
}

class SlaCalculationTestResult extends SlaSettingsState {
  final DateTime deadline;
  final List<DateTime> milestones;
  final Duration totalDuration;
  final Map<String, dynamic> calculationDetails;

  const SlaCalculationTestResult({
    required this.deadline,
    required this.milestones,
    required this.totalDuration,
    required this.calculationDetails,
  });

  @override
  List<Object?> get props => [deadline, milestones, totalDuration, calculationDetails];
}

// Backup and Restore States
class SlaSettingsBackingUp extends SlaSettingsState {
  final String? backupName;
  final double? progress;

  const SlaSettingsBackingUp({
    this.backupName,
    this.progress,
  });

  @override
  List<Object?> get props => [backupName, progress];
}

class SlaSettingsBackedUp extends SlaSettingsState {
  final String backupId;
  final String backupName;
  final DateTime backedUpAt;

  const SlaSettingsBackedUp({
    required this.backupId,
    required this.backupName,
    required this.backedUpAt,
  });

  @override
  List<Object?> get props => [backupId, backupName, backedUpAt];
}

class SlaSettingsRestoring extends SlaSettingsState {
  final String backupId;
  final double? progress;

  const SlaSettingsRestoring({
    required this.backupId,
    this.progress,
  });

  @override
  List<Object?> get props => [backupId, progress];
}

class SlaSettingsRestored extends SlaSettingsState {
  final SlaSettingsEntity settings;
  final String backupId;
  final DateTime restoredAt;

  const SlaSettingsRestored({
    required this.settings,
    required this.backupId,
    required this.restoredAt,
  });

  @override
  List<Object?> get props => [settings, backupId, restoredAt];
}

// History and Audit States
class SlaSettingsHistoryLoading extends SlaSettingsState {
  const SlaSettingsHistoryLoading();
}

class SlaSettingsHistoryLoaded extends SlaSettingsState {
  final List<Map<String, dynamic>> history;
  final DateTime? startDate;
  final DateTime? endDate;

  const SlaSettingsHistoryLoaded({
    required this.history,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [history, startDate, endDate];

  // Helper getters
  int get totalChanges => history.length;
  Map<String, dynamic>? get latestChange => history.isNotEmpty ? history.first : null;
}

// Multi-step operation states
class SlaSettingsMultiStepOperation extends SlaSettingsState {
  final String operationType;
  final int currentStep;
  final int totalSteps;
  final String currentStepName;
  final double progress;

  const SlaSettingsMultiStepOperation({
    required this.operationType,
    required this.currentStep,
    required this.totalSteps,
    required this.currentStepName,
    required this.progress,
  });

  @override
  List<Object?> get props => [operationType, currentStep, totalSteps, currentStepName, progress];

  // Helper getters
  bool get isFirstStep => currentStep == 1;
  bool get isLastStep => currentStep == totalSteps;
  double get progressPercent => progress * 100;
}

// Test Result Classes
class SlaEscalationTestResult {
  final bool isSuccessful;
  final String message;
  final Map<String, dynamic> details;

  const SlaEscalationTestResult({
    required this.isSuccessful,
    required this.message,
    required this.details,
  });

  @override
  String toString() {
    return 'SlaEscalationTestResult(isSuccessful: $isSuccessful, message: $message)';
  }
}

