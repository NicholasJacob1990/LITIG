import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/sla_preset_entity.dart';

/// Contrato do repositório para configurações SLA
/// 
/// Define todas as operações relacionadas ao gerenciamento
/// de configurações, presets e personalização do sistema SLA
abstract class SlaSettingsRepository {
  
  /// Obtém configurações SLA atuais para uma firma
  Future<Either<Failure, SlaPresetEntity>> getSettings({
    required String firmId,
  });

  /// Atualiza configurações SLA
  Future<Either<Failure, SlaPresetEntity>> updateSettings({
    required String firmId,
    required SlaPresetEntity settings,
  });

  /// Obtém todos os presets disponíveis
  Future<Either<Failure, List<SlaPresetEntity>>> getPresets({
    required String firmId,
    bool includeSystemPresets = true,
  });

  /// Cria novo preset personalizado
  Future<Either<Failure, SlaPresetEntity>> createPreset({
    required String firmId,
    required SlaPresetEntity preset,
  });

  /// Atualiza preset existente
  Future<Either<Failure, SlaPresetEntity>> updatePreset({
    required String presetId,
    required SlaPresetEntity preset,
  });

  /// Remove preset personalizado
  Future<Either<Failure, void>> deletePreset({
    required String presetId,
  });

  /// Aplica preset como configuração ativa
  Future<Either<Failure, SlaPresetEntity>> applyPreset({
    required String firmId,
    required String presetId,
  });

  /// Obtém configurações de notificação
  Future<Either<Failure, Map<String, dynamic>>> getNotificationSettings({
    required String firmId,
  });

  /// Atualiza configurações de notificação
  Future<Either<Failure, void>> updateNotificationSettings({
    required String firmId,
    required Map<String, dynamic> settings,
  });

  /// Obtém configurações de escalação
  Future<Either<Failure, Map<String, dynamic>>> getEscalationSettings({
    required String firmId,
  });

  /// Atualiza configurações de escalação
  Future<Either<Failure, void>> updateEscalationSettings({
    required String firmId,
    required Map<String, dynamic> settings,
  });

  /// Obtém configurações de horário de negócio
  Future<Either<Failure, Map<String, dynamic>>> getBusinessHoursSettings({
    required String firmId,
  });

  /// Atualiza configurações de horário de negócio
  Future<Either<Failure, void>> updateBusinessHoursSettings({
    required String firmId,
    required Map<String, dynamic> settings,
  });

  /// Obtém configurações de feriados
  Future<Either<Failure, List<Map<String, dynamic>>>> getHolidaySettings({
    required String firmId,
  });

  /// Atualiza configurações de feriados
  Future<Either<Failure, void>> updateHolidaySettings({
    required String firmId,
    required List<Map<String, dynamic>> holidays,
  });

  /// Valida configurações SLA
  Future<Either<Failure, Map<String, dynamic>>> validateSettings({
    required SlaPresetEntity settings,
  });

  /// Obtém configurações padrão para nova firma
  Future<Either<Failure, SlaPresetEntity>> getDefaultSettings();

  /// Clona configurações de outra firma
  Future<Either<Failure, SlaPresetEntity>> cloneSettings({
    required String sourceFirmId,
    required String targetFirmId,
  });

  /// Exporta configurações
  Future<Either<Failure, String>> exportSettings({
    required String firmId,
    String format = 'json',
  });

  /// Importa configurações
  Future<Either<Failure, SlaPresetEntity>> importSettings({
    required String firmId,
    required String settingsData,
    String format = 'json',
  });

  /// Obtém histórico de mudanças nas configurações
  Future<Either<Failure, List<Map<String, dynamic>>>> getSettingsHistory({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Reverte para configuração anterior
  Future<Either<Failure, SlaPresetEntity>> revertSettings({
    required String firmId,
    required String historyId,
  });
}