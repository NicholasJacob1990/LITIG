import '../../domain/entities/sla_preset_entity.dart';

/// Model que implementa serialização JSON para SlaPresetEntity
/// 
/// Responsável pela conversão entre JSON e entidade de domínio
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
  factory SlaPresetModel.fromJson(Map<String, dynamic> json) {
    return SlaPresetModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      defaultSlaHours: json['default_sla_hours'] as int,
      urgentSlaHours: json['urgent_sla_hours'] as int,
      emergencySlaHours: json['emergency_sla_hours'] as int,
      complexCaseSlaHours: json['complex_case_sla_hours'] as int,
      businessHoursStart: json['business_hours_start'] as String,
      businessHoursEnd: json['business_hours_end'] as String,
      includeWeekends: json['include_weekends'] as bool,
      notificationTimings: Map<String, List<int>>.from(
        (json['notification_timings'] as Map).map(
          (key, value) => MapEntry(key, (value as List).cast<int>()),
        ),
      ),
      escalationRules: Map<String, dynamic>.from(json['escalation_rules'] as Map),
      overrideSettings: Map<String, dynamic>.from(json['override_settings'] as Map),
      isSystemPreset: json['is_system_preset'] as bool,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      firmId: json['firm_id'] as String?,
      createdBy: json['created_by'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata'] as Map) 
          : null,
    );
  }

  /// Converte o SlaPresetModel para JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'default_sla_hours': defaultSlaHours,
      'urgent_sla_hours': urgentSlaHours,
      'emergency_sla_hours': emergencySlaHours,
      'complex_case_sla_hours': complexCaseSlaHours,
      'business_hours_start': businessHoursStart,
      'business_hours_end': businessHoursEnd,
      'include_weekends': includeWeekends,
      'notification_timings': notificationTimings,
      'escalation_rules': escalationRules,
      'override_settings': overrideSettings,
      'is_system_preset': isSystemPreset,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (firmId != null) 'firm_id': firmId,
      if (createdBy != null) 'created_by': createdBy,
      if (tags != null) 'tags': tags,
      if (metadata != null) 'metadata': metadata,
    };
  }

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
  @override
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
