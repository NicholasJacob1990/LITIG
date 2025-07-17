import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/sla_preset_entity.dart';

part 'sla_preset_model.g.dart';

/// Model que implementa serialização JSON para SlaPresetEntity
/// 
/// Responsável pela conversão entre JSON e entidade de domínio,
/// utilizando json_annotation para geração automática de código
@JsonSerializable(explicitToJson: true)
class SlaPresetModel extends SlaPresetEntity {
  const SlaPresetModel({
    required super.id,
    required super.name,
    required super.description,
    required super.category,
    required super.defaultSlaHours,
    required super.urgentSlaHours,
    required super.emergencySlaHours,
    required super.complexCaseSlaHours,
    required super.businessHoursStart,
    required super.businessHoursEnd,
    required super.includeWeekends,
    required super.notificationTimings,
    required super.escalationRules,
    required super.overrideSettings,
    required super.isSystemPreset,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.firmId,
    super.createdBy,
    super.tags,
    super.metadata,
  });

  /// Cria um SlaPresetModel a partir de JSON
  factory SlaPresetModel.fromJson(Map<String, dynamic> json) => 
      _$SlaPresetModelFromJson(json);

  /// Converte o SlaPresetModel para JSON
  Map<String, dynamic> toJson() => _$SlaPresetModelToJson(this);

  /// Converte uma entidade de domínio para model
  factory SlaPresetModel.fromEntity(SlaPresetEntity entity) {
    return SlaPresetModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      category: entity.category,
      defaultSlaHours: entity.defaultSlaHours,
      urgentSlaHours: entity.urgentSlaHours,
      emergencySlaHours: entity.emergencySlaHours,
      complexCaseSlaHours: entity.complexCaseSlaHours,
      businessHoursStart: entity.businessHoursStart,
      businessHoursEnd: entity.businessHoursEnd,
      includeWeekends: entity.includeWeekends,
      notificationTimings: entity.notificationTimings,
      escalationRules: entity.escalationRules,
      overrideSettings: entity.overrideSettings,
      isSystemPreset: entity.isSystemPreset,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      firmId: entity.firmId,
      createdBy: entity.createdBy,
      tags: entity.tags,
      metadata: entity.metadata,
    );
  }

  /// Converte o model para entidade de domínio
  SlaPresetEntity toEntity() {
    return SlaPresetEntity(
      id: id,
      name: name,
      description: description,
      category: category,
      defaultSlaHours: defaultSlaHours,
      urgentSlaHours: urgentSlaHours,
      emergencySlaHours: emergencySlaHours,
      complexCaseSlaHours: complexCaseSlaHours,
      businessHoursStart: businessHoursStart,
      businessHoursEnd: businessHoursEnd,
      includeWeekends: includeWeekends,
      notificationTimings: notificationTimings,
      escalationRules: escalationRules,
      overrideSettings: overrideSettings,
      isSystemPreset: isSystemPreset,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      firmId: firmId,
      createdBy: createdBy,
      tags: tags,
      metadata: metadata,
    );
  }

  /// Cria presets do sistema como models
  static List<SlaPresetModel> get systemPresetModels {
    return SlaPresetEntity.systemPresets.map((presetData) {
      return SlaPresetModel(
        id: presetData['id'] as String,
        name: presetData['name'] as String,
        description: presetData['description'] as String,
        category: presetData['category'] as String,
        defaultSlaHours: presetData['defaultSlaHours'] as int,
        urgentSlaHours: presetData['urgentSlaHours'] as int,
        emergencySlaHours: presetData['emergencySlaHours'] as int,
        complexCaseSlaHours: presetData['complexCaseSlaHours'] as int,
        businessHoursStart: presetData['businessHoursStart'] as String,
        businessHoursEnd: presetData['businessHoursEnd'] as String,
        includeWeekends: presetData['includeWeekends'] as bool,
        notificationTimings: const {
          'before_deadline': [1440, 720, 360, 60],
          'at_deadline': [0],
          'after_violation': [60, 180, 360],
        },
        escalationRules: const {
          'enabled': true,
          'levels': [
            {
              'level': 1,
              'trigger_minutes': 60,
              'notify_roles': ['supervisor'],
              'action': 'notify',
            },
            {
              'level': 2,
              'trigger_minutes': 180,
              'notify_roles': ['partner'],
              'action': 'escalate',
            },
            {
              'level': 3,
              'trigger_minutes': 360,
              'notify_roles': ['admin'],
              'action': 'critical_escalate',
            },
          ],
        },
        overrideSettings: const {
          'allow_override': true,
          'max_override_hours': 24,
          'require_justification': true,
          'require_approval': false,
          'allowed_roles': ['lawyer_office', 'partner', 'admin'],
        },
        isSystemPreset: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: (presetData['tags'] as List<dynamic>).cast<String>(),
      );
    }).toList();
  }

  /// Cria uma cópia com modificações
  SlaPresetModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? defaultSlaHours,
    int? urgentSlaHours,
    int? emergencySlaHours,
    int? complexCaseSlaHours,
    String? businessHoursStart,
    String? businessHoursEnd,
    bool? includeWeekends,
    Map<String, List<int>>? notificationTimings,
    Map<String, dynamic>? escalationRules,
    Map<String, dynamic>? overrideSettings,
    bool? isSystemPreset,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firmId,
    String? createdBy,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return SlaPresetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      defaultSlaHours: defaultSlaHours ?? this.defaultSlaHours,
      urgentSlaHours: urgentSlaHours ?? this.urgentSlaHours,
      emergencySlaHours: emergencySlaHours ?? this.emergencySlaHours,
      complexCaseSlaHours: complexCaseSlaHours ?? this.complexCaseSlaHours,
      businessHoursStart: businessHoursStart ?? this.businessHoursStart,
      businessHoursEnd: businessHoursEnd ?? this.businessHoursEnd,
      includeWeekends: includeWeekends ?? this.includeWeekends,
      notificationTimings: notificationTimings ?? this.notificationTimings,
      escalationRules: escalationRules ?? this.escalationRules,
      overrideSettings: overrideSettings ?? this.overrideSettings,
      isSystemPreset: isSystemPreset ?? this.isSystemPreset,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      firmId: firmId ?? this.firmId,
      createdBy: createdBy ?? this.createdBy,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }
} 
import '../../domain/entities/sla_preset_entity.dart';

part 'sla_preset_model.g.dart';

/// Model que implementa serialização JSON para SlaPresetEntity
/// 
/// Responsável pela conversão entre JSON e entidade de domínio,
/// utilizando json_annotation para geração automática de código
@JsonSerializable(explicitToJson: true)
class SlaPresetModel extends SlaPresetEntity {
  const SlaPresetModel({
    required super.id,
    required super.name,
    required super.description,
    required super.category,
    required super.defaultSlaHours,
    required super.urgentSlaHours,
    required super.emergencySlaHours,
    required super.complexCaseSlaHours,
    required super.businessHoursStart,
    required super.businessHoursEnd,
    required super.includeWeekends,
    required super.notificationTimings,
    required super.escalationRules,
    required super.overrideSettings,
    required super.isSystemPreset,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.firmId,
    super.createdBy,
    super.tags,
    super.metadata,
  });

  /// Cria um SlaPresetModel a partir de JSON
  factory SlaPresetModel.fromJson(Map<String, dynamic> json) => 
      _$SlaPresetModelFromJson(json);

  /// Converte o SlaPresetModel para JSON
  Map<String, dynamic> toJson() => _$SlaPresetModelToJson(this);

  /// Converte uma entidade de domínio para model
  factory SlaPresetModel.fromEntity(SlaPresetEntity entity) {
    return SlaPresetModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      category: entity.category,
      defaultSlaHours: entity.defaultSlaHours,
      urgentSlaHours: entity.urgentSlaHours,
      emergencySlaHours: entity.emergencySlaHours,
      complexCaseSlaHours: entity.complexCaseSlaHours,
      businessHoursStart: entity.businessHoursStart,
      businessHoursEnd: entity.businessHoursEnd,
      includeWeekends: entity.includeWeekends,
      notificationTimings: entity.notificationTimings,
      escalationRules: entity.escalationRules,
      overrideSettings: entity.overrideSettings,
      isSystemPreset: entity.isSystemPreset,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      firmId: entity.firmId,
      createdBy: entity.createdBy,
      tags: entity.tags,
      metadata: entity.metadata,
    );
  }

  /// Converte o model para entidade de domínio
  SlaPresetEntity toEntity() {
    return SlaPresetEntity(
      id: id,
      name: name,
      description: description,
      category: category,
      defaultSlaHours: defaultSlaHours,
      urgentSlaHours: urgentSlaHours,
      emergencySlaHours: emergencySlaHours,
      complexCaseSlaHours: complexCaseSlaHours,
      businessHoursStart: businessHoursStart,
      businessHoursEnd: businessHoursEnd,
      includeWeekends: includeWeekends,
      notificationTimings: notificationTimings,
      escalationRules: escalationRules,
      overrideSettings: overrideSettings,
      isSystemPreset: isSystemPreset,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      firmId: firmId,
      createdBy: createdBy,
      tags: tags,
      metadata: metadata,
    );
  }

  /// Cria presets do sistema como models
  static List<SlaPresetModel> get systemPresetModels {
    return SlaPresetEntity.systemPresets.map((presetData) {
      return SlaPresetModel(
        id: presetData['id'] as String,
        name: presetData['name'] as String,
        description: presetData['description'] as String,
        category: presetData['category'] as String,
        defaultSlaHours: presetData['defaultSlaHours'] as int,
        urgentSlaHours: presetData['urgentSlaHours'] as int,
        emergencySlaHours: presetData['emergencySlaHours'] as int,
        complexCaseSlaHours: presetData['complexCaseSlaHours'] as int,
        businessHoursStart: presetData['businessHoursStart'] as String,
        businessHoursEnd: presetData['businessHoursEnd'] as String,
        includeWeekends: presetData['includeWeekends'] as bool,
        notificationTimings: const {
          'before_deadline': [1440, 720, 360, 60],
          'at_deadline': [0],
          'after_violation': [60, 180, 360],
        },
        escalationRules: const {
          'enabled': true,
          'levels': [
            {
              'level': 1,
              'trigger_minutes': 60,
              'notify_roles': ['supervisor'],
              'action': 'notify',
            },
            {
              'level': 2,
              'trigger_minutes': 180,
              'notify_roles': ['partner'],
              'action': 'escalate',
            },
            {
              'level': 3,
              'trigger_minutes': 360,
              'notify_roles': ['admin'],
              'action': 'critical_escalate',
            },
          ],
        },
        overrideSettings: const {
          'allow_override': true,
          'max_override_hours': 24,
          'require_justification': true,
          'require_approval': false,
          'allowed_roles': ['lawyer_office', 'partner', 'admin'],
        },
        isSystemPreset: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: (presetData['tags'] as List<dynamic>).cast<String>(),
      );
    }).toList();
  }

  /// Cria uma cópia com modificações
  SlaPresetModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? defaultSlaHours,
    int? urgentSlaHours,
    int? emergencySlaHours,
    int? complexCaseSlaHours,
    String? businessHoursStart,
    String? businessHoursEnd,
    bool? includeWeekends,
    Map<String, List<int>>? notificationTimings,
    Map<String, dynamic>? escalationRules,
    Map<String, dynamic>? overrideSettings,
    bool? isSystemPreset,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firmId,
    String? createdBy,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return SlaPresetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      defaultSlaHours: defaultSlaHours ?? this.defaultSlaHours,
      urgentSlaHours: urgentSlaHours ?? this.urgentSlaHours,
      emergencySlaHours: emergencySlaHours ?? this.emergencySlaHours,
      complexCaseSlaHours: complexCaseSlaHours ?? this.complexCaseSlaHours,
      businessHoursStart: businessHoursStart ?? this.businessHoursStart,
      businessHoursEnd: businessHoursEnd ?? this.businessHoursEnd,
      includeWeekends: includeWeekends ?? this.includeWeekends,
      notificationTimings: notificationTimings ?? this.notificationTimings,
      escalationRules: escalationRules ?? this.escalationRules,
      overrideSettings: overrideSettings ?? this.overrideSettings,
      isSystemPreset: isSystemPreset ?? this.isSystemPreset,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      firmId: firmId ?? this.firmId,
      createdBy: createdBy ?? this.createdBy,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }
} 