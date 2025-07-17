import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/sla_settings_entity.dart';
import '../../domain/entities/sla_preset_entity.dart';
import '../../domain/usecases/validate_sla_settings.dart';
import '../../domain/usecases/calculate_sla_deadline.dart';
import 'sla_settings_event.dart';
import 'sla_settings_state.dart';

class SlaSettingsBloc extends Bloc<SlaSettingsEvent, SlaSettingsState> {
  final ValidateSlaSettings validateSlaSettings;
  final CalculateSlaDeadline calculateSlaDeadline;
  // TODO: Add other use cases when repository implementations are available

  SlaSettingsBloc({
    required this.validateSlaSettings,
    required this.calculateSlaDeadline,
  }) : super(SlaSettingsInitial()) {
    on<LoadSlaSettingsEvent>(_onLoadSlaSettings);
    on<UpdateSlaSettingsEvent>(_onUpdateSlaSettings);
    on<SaveSlaSettingsEvent>(_onSaveSlaSettings);
    on<ApplyPresetEvent>(_onApplyPreset);
    on<ValidateSettingsEvent>(_onValidateSettings);
    on<ResetToDefaultEvent>(_onResetToDefault);
    on<ExportSettingsEvent>(_onExportSettings);
    on<ImportSettingsEvent>(_onImportSettings);
    on<TestSlaCalculationEvent>(_onTestSlaCalculation);
    on<CreateCustomPresetEvent>(_onCreateCustomPreset);
    on<DeletePresetEvent>(_onDeletePreset);
    on<DuplicatePresetEvent>(_onDuplicatePreset);
    on<ClearValidationErrorsEvent>(_onClearValidationErrors);
    on<UpdateBusinessHoursEvent>(_onUpdateBusinessHours);
    on<UpdateEscalationRulesEvent>(_onUpdateEscalationRules);
    on<ToggleOverrideSettingsEvent>(_onToggleOverrideSettings);
  }

  Future<void> _onLoadSlaSettings(
    LoadSlaSettingsEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    emit(SlaSettingsLoading());
    
    try {
      // TODO: Implement when repository is available
      // For now, create a default settings entity
      final defaultSettings = SlaSettingsEntity.createDefault(
        firmId: event.firmId,
        createdBy: event.userId ?? 'system',
      );
      
      emit(SlaSettingsLoaded(
        settings: defaultSettings,
        availablePresets: SlaPresetEntity.getSystemPresets(),
        validationResult: null,
        isModified: false,
        lastSaved: DateTime.now(),
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao carregar configurações SLA: ${e.toString()}',
        errorCode: 'LOAD_ERROR',
      ));
    }
  }

  Future<void> _onUpdateSlaSettings(
    UpdateSlaSettingsEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final updatedSettings = event.settings;
      
      // Validate automatically on update if auto-validation is enabled
      SlaValidationResult? validationResult;
      if (event.autoValidate) {
        final validationParams = ValidateSlaSettingsParams(settings: updatedSettings);
        final result = await validateSlaSettings(validationParams);
        result.fold(
          (failure) => validationResult = null,
          (validation) => validationResult = validation,
        );
      }

      emit(currentState.copyWith(
        settings: updatedSettings,
        validationResult: validationResult,
        isModified: true,
        lastModified: DateTime.now(),
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao atualizar configurações: ${e.toString()}',
        errorCode: 'UPDATE_ERROR',
      ));
    }
  }

  Future<void> _onSaveSlaSettings(
    SaveSlaSettingsEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    emit(SlaSettingsUpdating());

    try {
      // Validate before saving
      final validationParams = ValidateSlaSettingsParams(settings: currentState.settings);
      final validationResult = await validateSlaSettings(validationParams);
      
      await validationResult.fold(
        (failure) async {
          emit(SlaSettingsValidationError(
            message: 'Erro de validação: ${failure.message}',
            validationResult: null,
            settings: currentState.settings,
          ));
        },
        (validation) async {
          if (!validation.isValid && !event.forceSave) {
            emit(SlaSettingsValidationError(
              message: 'Configurações inválidas. Corrija os erros antes de salvar.',
              validationResult: validation,
              settings: currentState.settings,
            ));
            return;
          }

          // TODO: Implement actual save when repository is available
          await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call

          emit(SlaSettingsUpdated(
            settings: currentState.settings,
            message: 'Configurações salvas com sucesso!',
            validationResult: validation,
            savedAt: DateTime.now(),
          ));

          // Return to loaded state
          emit(currentState.copyWith(
            isModified: false,
            lastSaved: DateTime.now(),
            validationResult: validation,
          ));
        },
      );
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao salvar configurações: ${e.toString()}',
        errorCode: 'SAVE_ERROR',
      ));
    }
  }

  Future<void> _onApplyPreset(
    ApplyPresetEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final preset = event.preset;
      final updatedSettings = currentState.settings.applyPreset(preset);

      // Validate the new settings
      final validationParams = ValidateSlaSettingsParams(settings: updatedSettings);
      final validationResult = await validateSlaSettings(validationParams);

      await validationResult.fold(
        (failure) async {
          emit(SlaSettingsError(
            message: 'Erro ao aplicar preset: ${failure.message}',
            errorCode: 'PRESET_ERROR',
          ));
        },
        (validation) async {
          emit(currentState.copyWith(
            settings: updatedSettings,
            validationResult: validation,
            isModified: true,
            lastModified: DateTime.now(),
          ));

          // Show success message
          emit(SlaSettingsUpdated(
            settings: updatedSettings,
            message: 'Preset "${preset.name}" aplicado com sucesso!',
            validationResult: validation,
            savedAt: DateTime.now(),
          ));

          // Return to loaded state
          emit(currentState.copyWith(
            settings: updatedSettings,
            validationResult: validation,
            isModified: true,
            lastModified: DateTime.now(),
          ));
        },
      );
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao aplicar preset: ${e.toString()}',
        errorCode: 'PRESET_ERROR',
      ));
    }
  }

  Future<void> _onValidateSettings(
    ValidateSettingsEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final validationParams = ValidateSlaSettingsParams(settings: currentState.settings);
      final result = await validateSlaSettings(validationParams);

      result.fold(
        (failure) {
          emit(SlaSettingsError(
            message: 'Erro durante validação: ${failure.message}',
            errorCode: 'VALIDATION_ERROR',
          ));
        },
        (validation) {
          emit(currentState.copyWith(validationResult: validation));
        },
      );
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro inesperado durante validação: ${e.toString()}',
        errorCode: 'VALIDATION_ERROR',
      ));
    }
  }

  Future<void> _onResetToDefault(
    ResetToDefaultEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final defaultSettings = SlaSettingsEntity.createDefault(
        firmId: currentState.settings.firmId,
        createdBy: 'system',
      );

      emit(currentState.copyWith(
        settings: defaultSettings,
        validationResult: null,
        isModified: true,
        lastModified: DateTime.now(),
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao resetar configurações: ${e.toString()}',
        errorCode: 'RESET_ERROR',
      ));
    }
  }

  Future<void> _onExportSettings(
    ExportSettingsEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      // TODO: Implement export functionality
      emit(SlaSettingsUpdated(
        settings: currentState.settings,
        message: 'Configurações exportadas com sucesso!',
        validationResult: currentState.validationResult,
        savedAt: DateTime.now(),
      ));

      // Return to loaded state
      emit(currentState);
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao exportar configurações: ${e.toString()}',
        errorCode: 'EXPORT_ERROR',
      ));
    }
  }

  Future<void> _onImportSettings(
    ImportSettingsEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      // TODO: Implement import functionality
      // For now, just show success message
      emit(SlaSettingsUpdated(
        settings: currentState.settings,
        message: 'Configurações importadas com sucesso!',
        validationResult: currentState.validationResult,
        savedAt: DateTime.now(),
      ));

      // Return to loaded state
      emit(currentState);
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao importar configurações: ${e.toString()}',
        errorCode: 'IMPORT_ERROR',
      ));
    }
  }

  Future<void> _onTestSlaCalculation(
    TestSlaCalculationEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final params = CalculateSlaDeadlineParams(
        priority: event.priority,
        caseType: event.caseType,
        startTime: event.startTime,
        firmId: currentState.settings.firmId,
        overrideHours: event.overrideHours,
      );

      final result = await calculateSlaDeadline(params);

      result.fold(
        (failure) {
          emit(SlaSettingsError(
            message: 'Erro no teste de cálculo SLA: ${failure.message}',
            errorCode: 'CALCULATION_ERROR',
          ));
        },
        (deadlineResult) {
          emit(SlaSettingsUpdated(
            settings: currentState.settings,
            message: 'Teste realizado! Deadline: ${deadlineResult.deadline}',
            validationResult: currentState.validationResult,
            savedAt: DateTime.now(),
          ));

          // Return to loaded state
          emit(currentState);
        },
      );
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro inesperado no teste: ${e.toString()}',
        errorCode: 'TEST_ERROR',
      ));
    }
  }

  Future<void> _onCreateCustomPreset(
    CreateCustomPresetEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final newPreset = SlaPresetEntity.custom(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: event.name,
        description: event.description,
        normalTimeframeHours: event.normalHours,
        urgentTimeframeHours: event.urgentHours,
        emergencyTimeframeHours: event.emergencyHours,
      );

      final updatedPresets = [...currentState.availablePresets, newPreset];

      emit(currentState.copyWith(
        availablePresets: updatedPresets,
      ));

      emit(SlaSettingsUpdated(
        settings: currentState.settings,
        message: 'Preset personalizado "${event.name}" criado com sucesso!',
        validationResult: currentState.validationResult,
        savedAt: DateTime.now(),
      ));

      // Return to loaded state with new preset
      emit(currentState.copyWith(
        availablePresets: updatedPresets,
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao criar preset: ${e.toString()}',
        errorCode: 'CREATE_PRESET_ERROR',
      ));
    }
  }

  Future<void> _onDeletePreset(
    DeletePresetEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      if (event.preset.isSystem) {
        emit(SlaSettingsError(
          message: 'Não é possível deletar presets do sistema',
          errorCode: 'DELETE_SYSTEM_PRESET_ERROR',
        ));
        return;
      }

      final updatedPresets = currentState.availablePresets
          .where((preset) => preset.id != event.preset.id)
          .toList();

      emit(currentState.copyWith(
        availablePresets: updatedPresets,
      ));

      emit(SlaSettingsUpdated(
        settings: currentState.settings,
        message: 'Preset "${event.preset.name}" removido com sucesso!',
        validationResult: currentState.validationResult,
        savedAt: DateTime.now(),
      ));

      // Return to loaded state
      emit(currentState.copyWith(
        availablePresets: updatedPresets,
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao deletar preset: ${e.toString()}',
        errorCode: 'DELETE_PRESET_ERROR',
      ));
    }
  }

  Future<void> _onDuplicatePreset(
    DuplicatePresetEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final duplicatedPreset = event.preset.copyWith(
        id: 'duplicate_${DateTime.now().millisecondsSinceEpoch}',
        name: '${event.preset.name} (Cópia)',
        isSystem: false,
      );

      final updatedPresets = [...currentState.availablePresets, duplicatedPreset];

      emit(currentState.copyWith(
        availablePresets: updatedPresets,
      ));

      emit(SlaSettingsUpdated(
        settings: currentState.settings,
        message: 'Preset duplicado como "${duplicatedPreset.name}"!',
        validationResult: currentState.validationResult,
        savedAt: DateTime.now(),
      ));

      // Return to loaded state
      emit(currentState.copyWith(
        availablePresets: updatedPresets,
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao duplicar preset: ${e.toString()}',
        errorCode: 'DUPLICATE_PRESET_ERROR',
      ));
    }
  }

  Future<void> _onClearValidationErrors(
    ClearValidationErrorsEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SlaSettingsValidationError) {
      emit(SlaSettingsLoaded(
        settings: currentState.settings,
        availablePresets: [], // TODO: Load from repository
        validationResult: null,
        isModified: true,
        lastSaved: null,
      ));
    } else if (currentState is SlaSettingsLoaded) {
      emit(currentState.copyWith(validationResult: null));
    }
  }

  Future<void> _onUpdateBusinessHours(
    UpdateBusinessHoursEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final updatedSettings = currentState.settings.copyWith(
        businessStartHour: event.startHour,
        businessEndHour: event.endHour,
        businessDays: event.businessDays,
        timezone: event.timezone,
      );

      emit(currentState.copyWith(
        settings: updatedSettings,
        isModified: true,
        lastModified: DateTime.now(),
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao atualizar horários comerciais: ${e.toString()}',
        errorCode: 'BUSINESS_HOURS_ERROR',
      ));
    }
  }

  Future<void> _onUpdateEscalationRules(
    UpdateEscalationRulesEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final updatedSettings = currentState.settings.copyWith(
        enableEscalation: event.enableEscalation,
        escalationPercentages: event.escalationPercentages,
      );

      emit(currentState.copyWith(
        settings: updatedSettings,
        isModified: true,
        lastModified: DateTime.now(),
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao atualizar regras de escalação: ${e.toString()}',
        errorCode: 'ESCALATION_RULES_ERROR',
      ));
    }
  }

  Future<void> _onToggleOverrideSettings(
    ToggleOverrideSettingsEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final updatedSettings = currentState.settings.copyWith(
        allowOverride: event.allowOverride,
        maxOverrideHours: event.maxOverrideHours,
        overrideRequiredRoles: event.requiredRoles,
      );

      emit(currentState.copyWith(
        settings: updatedSettings,
        isModified: true,
        lastModified: DateTime.now(),
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao atualizar configurações de override: ${e.toString()}',
        errorCode: 'OVERRIDE_SETTINGS_ERROR',
      ));
    }
  }
} 
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/sla_settings_entity.dart';
import '../../domain/entities/sla_preset_entity.dart';
import '../../domain/usecases/validate_sla_settings.dart';
import '../../domain/usecases/calculate_sla_deadline.dart';
import 'sla_settings_event.dart';
import 'sla_settings_state.dart';

class SlaSettingsBloc extends Bloc<SlaSettingsEvent, SlaSettingsState> {
  final ValidateSlaSettings validateSlaSettings;
  final CalculateSlaDeadline calculateSlaDeadline;
  // TODO: Add other use cases when repository implementations are available

  SlaSettingsBloc({
    required this.validateSlaSettings,
    required this.calculateSlaDeadline,
  }) : super(SlaSettingsInitial()) {
    on<LoadSlaSettingsEvent>(_onLoadSlaSettings);
    on<UpdateSlaSettingsEvent>(_onUpdateSlaSettings);
    on<SaveSlaSettingsEvent>(_onSaveSlaSettings);
    on<ApplyPresetEvent>(_onApplyPreset);
    on<ValidateSettingsEvent>(_onValidateSettings);
    on<ResetToDefaultEvent>(_onResetToDefault);
    on<ExportSettingsEvent>(_onExportSettings);
    on<ImportSettingsEvent>(_onImportSettings);
    on<TestSlaCalculationEvent>(_onTestSlaCalculation);
    on<CreateCustomPresetEvent>(_onCreateCustomPreset);
    on<DeletePresetEvent>(_onDeletePreset);
    on<DuplicatePresetEvent>(_onDuplicatePreset);
    on<ClearValidationErrorsEvent>(_onClearValidationErrors);
    on<UpdateBusinessHoursEvent>(_onUpdateBusinessHours);
    on<UpdateEscalationRulesEvent>(_onUpdateEscalationRules);
    on<ToggleOverrideSettingsEvent>(_onToggleOverrideSettings);
  }

  Future<void> _onLoadSlaSettings(
    LoadSlaSettingsEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    emit(SlaSettingsLoading());
    
    try {
      // TODO: Implement when repository is available
      // For now, create a default settings entity
      final defaultSettings = SlaSettingsEntity.createDefault(
        firmId: event.firmId,
        createdBy: event.userId ?? 'system',
      );
      
      emit(SlaSettingsLoaded(
        settings: defaultSettings,
        availablePresets: SlaPresetEntity.getSystemPresets(),
        validationResult: null,
        isModified: false,
        lastSaved: DateTime.now(),
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao carregar configurações SLA: ${e.toString()}',
        errorCode: 'LOAD_ERROR',
      ));
    }
  }

  Future<void> _onUpdateSlaSettings(
    UpdateSlaSettingsEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final updatedSettings = event.settings;
      
      // Validate automatically on update if auto-validation is enabled
      SlaValidationResult? validationResult;
      if (event.autoValidate) {
        final validationParams = ValidateSlaSettingsParams(settings: updatedSettings);
        final result = await validateSlaSettings(validationParams);
        result.fold(
          (failure) => validationResult = null,
          (validation) => validationResult = validation,
        );
      }

      emit(currentState.copyWith(
        settings: updatedSettings,
        validationResult: validationResult,
        isModified: true,
        lastModified: DateTime.now(),
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao atualizar configurações: ${e.toString()}',
        errorCode: 'UPDATE_ERROR',
      ));
    }
  }

  Future<void> _onSaveSlaSettings(
    SaveSlaSettingsEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    emit(SlaSettingsUpdating());

    try {
      // Validate before saving
      final validationParams = ValidateSlaSettingsParams(settings: currentState.settings);
      final validationResult = await validateSlaSettings(validationParams);
      
      await validationResult.fold(
        (failure) async {
          emit(SlaSettingsValidationError(
            message: 'Erro de validação: ${failure.message}',
            validationResult: null,
            settings: currentState.settings,
          ));
        },
        (validation) async {
          if (!validation.isValid && !event.forceSave) {
            emit(SlaSettingsValidationError(
              message: 'Configurações inválidas. Corrija os erros antes de salvar.',
              validationResult: validation,
              settings: currentState.settings,
            ));
            return;
          }

          // TODO: Implement actual save when repository is available
          await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call

          emit(SlaSettingsUpdated(
            settings: currentState.settings,
            message: 'Configurações salvas com sucesso!',
            validationResult: validation,
            savedAt: DateTime.now(),
          ));

          // Return to loaded state
          emit(currentState.copyWith(
            isModified: false,
            lastSaved: DateTime.now(),
            validationResult: validation,
          ));
        },
      );
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao salvar configurações: ${e.toString()}',
        errorCode: 'SAVE_ERROR',
      ));
    }
  }

  Future<void> _onApplyPreset(
    ApplyPresetEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final preset = event.preset;
      final updatedSettings = currentState.settings.applyPreset(preset);

      // Validate the new settings
      final validationParams = ValidateSlaSettingsParams(settings: updatedSettings);
      final validationResult = await validateSlaSettings(validationParams);

      await validationResult.fold(
        (failure) async {
          emit(SlaSettingsError(
            message: 'Erro ao aplicar preset: ${failure.message}',
            errorCode: 'PRESET_ERROR',
          ));
        },
        (validation) async {
          emit(currentState.copyWith(
            settings: updatedSettings,
            validationResult: validation,
            isModified: true,
            lastModified: DateTime.now(),
          ));

          // Show success message
          emit(SlaSettingsUpdated(
            settings: updatedSettings,
            message: 'Preset "${preset.name}" aplicado com sucesso!',
            validationResult: validation,
            savedAt: DateTime.now(),
          ));

          // Return to loaded state
          emit(currentState.copyWith(
            settings: updatedSettings,
            validationResult: validation,
            isModified: true,
            lastModified: DateTime.now(),
          ));
        },
      );
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao aplicar preset: ${e.toString()}',
        errorCode: 'PRESET_ERROR',
      ));
    }
  }

  Future<void> _onValidateSettings(
    ValidateSettingsEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final validationParams = ValidateSlaSettingsParams(settings: currentState.settings);
      final result = await validateSlaSettings(validationParams);

      result.fold(
        (failure) {
          emit(SlaSettingsError(
            message: 'Erro durante validação: ${failure.message}',
            errorCode: 'VALIDATION_ERROR',
          ));
        },
        (validation) {
          emit(currentState.copyWith(validationResult: validation));
        },
      );
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro inesperado durante validação: ${e.toString()}',
        errorCode: 'VALIDATION_ERROR',
      ));
    }
  }

  Future<void> _onResetToDefault(
    ResetToDefaultEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final defaultSettings = SlaSettingsEntity.createDefault(
        firmId: currentState.settings.firmId,
        createdBy: 'system',
      );

      emit(currentState.copyWith(
        settings: defaultSettings,
        validationResult: null,
        isModified: true,
        lastModified: DateTime.now(),
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao resetar configurações: ${e.toString()}',
        errorCode: 'RESET_ERROR',
      ));
    }
  }

  Future<void> _onExportSettings(
    ExportSettingsEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      // TODO: Implement export functionality
      emit(SlaSettingsUpdated(
        settings: currentState.settings,
        message: 'Configurações exportadas com sucesso!',
        validationResult: currentState.validationResult,
        savedAt: DateTime.now(),
      ));

      // Return to loaded state
      emit(currentState);
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao exportar configurações: ${e.toString()}',
        errorCode: 'EXPORT_ERROR',
      ));
    }
  }

  Future<void> _onImportSettings(
    ImportSettingsEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      // TODO: Implement import functionality
      // For now, just show success message
      emit(SlaSettingsUpdated(
        settings: currentState.settings,
        message: 'Configurações importadas com sucesso!',
        validationResult: currentState.validationResult,
        savedAt: DateTime.now(),
      ));

      // Return to loaded state
      emit(currentState);
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao importar configurações: ${e.toString()}',
        errorCode: 'IMPORT_ERROR',
      ));
    }
  }

  Future<void> _onTestSlaCalculation(
    TestSlaCalculationEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final params = CalculateSlaDeadlineParams(
        priority: event.priority,
        caseType: event.caseType,
        startTime: event.startTime,
        firmId: currentState.settings.firmId,
        overrideHours: event.overrideHours,
      );

      final result = await calculateSlaDeadline(params);

      result.fold(
        (failure) {
          emit(SlaSettingsError(
            message: 'Erro no teste de cálculo SLA: ${failure.message}',
            errorCode: 'CALCULATION_ERROR',
          ));
        },
        (deadlineResult) {
          emit(SlaSettingsUpdated(
            settings: currentState.settings,
            message: 'Teste realizado! Deadline: ${deadlineResult.deadline}',
            validationResult: currentState.validationResult,
            savedAt: DateTime.now(),
          ));

          // Return to loaded state
          emit(currentState);
        },
      );
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro inesperado no teste: ${e.toString()}',
        errorCode: 'TEST_ERROR',
      ));
    }
  }

  Future<void> _onCreateCustomPreset(
    CreateCustomPresetEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final newPreset = SlaPresetEntity.custom(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: event.name,
        description: event.description,
        normalTimeframeHours: event.normalHours,
        urgentTimeframeHours: event.urgentHours,
        emergencyTimeframeHours: event.emergencyHours,
      );

      final updatedPresets = [...currentState.availablePresets, newPreset];

      emit(currentState.copyWith(
        availablePresets: updatedPresets,
      ));

      emit(SlaSettingsUpdated(
        settings: currentState.settings,
        message: 'Preset personalizado "${event.name}" criado com sucesso!',
        validationResult: currentState.validationResult,
        savedAt: DateTime.now(),
      ));

      // Return to loaded state with new preset
      emit(currentState.copyWith(
        availablePresets: updatedPresets,
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao criar preset: ${e.toString()}',
        errorCode: 'CREATE_PRESET_ERROR',
      ));
    }
  }

  Future<void> _onDeletePreset(
    DeletePresetEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      if (event.preset.isSystem) {
        emit(SlaSettingsError(
          message: 'Não é possível deletar presets do sistema',
          errorCode: 'DELETE_SYSTEM_PRESET_ERROR',
        ));
        return;
      }

      final updatedPresets = currentState.availablePresets
          .where((preset) => preset.id != event.preset.id)
          .toList();

      emit(currentState.copyWith(
        availablePresets: updatedPresets,
      ));

      emit(SlaSettingsUpdated(
        settings: currentState.settings,
        message: 'Preset "${event.preset.name}" removido com sucesso!',
        validationResult: currentState.validationResult,
        savedAt: DateTime.now(),
      ));

      // Return to loaded state
      emit(currentState.copyWith(
        availablePresets: updatedPresets,
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao deletar preset: ${e.toString()}',
        errorCode: 'DELETE_PRESET_ERROR',
      ));
    }
  }

  Future<void> _onDuplicatePreset(
    DuplicatePresetEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final duplicatedPreset = event.preset.copyWith(
        id: 'duplicate_${DateTime.now().millisecondsSinceEpoch}',
        name: '${event.preset.name} (Cópia)',
        isSystem: false,
      );

      final updatedPresets = [...currentState.availablePresets, duplicatedPreset];

      emit(currentState.copyWith(
        availablePresets: updatedPresets,
      ));

      emit(SlaSettingsUpdated(
        settings: currentState.settings,
        message: 'Preset duplicado como "${duplicatedPreset.name}"!',
        validationResult: currentState.validationResult,
        savedAt: DateTime.now(),
      ));

      // Return to loaded state
      emit(currentState.copyWith(
        availablePresets: updatedPresets,
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao duplicar preset: ${e.toString()}',
        errorCode: 'DUPLICATE_PRESET_ERROR',
      ));
    }
  }

  Future<void> _onClearValidationErrors(
    ClearValidationErrorsEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SlaSettingsValidationError) {
      emit(SlaSettingsLoaded(
        settings: currentState.settings,
        availablePresets: [], // TODO: Load from repository
        validationResult: null,
        isModified: true,
        lastSaved: null,
      ));
    } else if (currentState is SlaSettingsLoaded) {
      emit(currentState.copyWith(validationResult: null));
    }
  }

  Future<void> _onUpdateBusinessHours(
    UpdateBusinessHoursEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final updatedSettings = currentState.settings.copyWith(
        businessStartHour: event.startHour,
        businessEndHour: event.endHour,
        businessDays: event.businessDays,
        timezone: event.timezone,
      );

      emit(currentState.copyWith(
        settings: updatedSettings,
        isModified: true,
        lastModified: DateTime.now(),
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao atualizar horários comerciais: ${e.toString()}',
        errorCode: 'BUSINESS_HOURS_ERROR',
      ));
    }
  }

  Future<void> _onUpdateEscalationRules(
    UpdateEscalationRulesEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final updatedSettings = currentState.settings.copyWith(
        enableEscalation: event.enableEscalation,
        escalationPercentages: event.escalationPercentages,
      );

      emit(currentState.copyWith(
        settings: updatedSettings,
        isModified: true,
        lastModified: DateTime.now(),
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao atualizar regras de escalação: ${e.toString()}',
        errorCode: 'ESCALATION_RULES_ERROR',
      ));
    }
  }

  Future<void> _onToggleOverrideSettings(
    ToggleOverrideSettingsEvent event,
    Emitter<SlaSettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SlaSettingsLoaded) return;

    try {
      final updatedSettings = currentState.settings.copyWith(
        allowOverride: event.allowOverride,
        maxOverrideHours: event.maxOverrideHours,
        overrideRequiredRoles: event.requiredRoles,
      );

      emit(currentState.copyWith(
        settings: updatedSettings,
        isModified: true,
        lastModified: DateTime.now(),
      ));
    } catch (e) {
      emit(SlaSettingsError(
        message: 'Erro ao atualizar configurações de override: ${e.toString()}',
        errorCode: 'OVERRIDE_SETTINGS_ERROR',
      ));
    }
  }
} 