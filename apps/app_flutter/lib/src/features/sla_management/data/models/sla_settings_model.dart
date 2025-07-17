import 'dart:convert';
import '../../domain/entities/sla_settings_entity.dart';
import '../../domain/value_objects/sla_timeframe.dart';

class SlaSettingsModel extends SlaSettingsEntity {
  const SlaSettingsModel({
    required super.id,
    required super.firmId,
    required super.normalTimeframe,
    required super.urgentTimeframe,
    required super.emergencyTimeframe,
    required super.complexTimeframe,
    required super.enableBusinessHoursOnly,
    required super.includeWeekends,
    required super.allowOverrides,
    required super.enableAutoEscalation,
    required super.overrideSettings,
    required super.lastModified,
    required super.lastModifiedBy,
  });

  factory SlaSettingsModel.fromJson(Map<String, dynamic> json) {
    return SlaSettingsModel(
      id: json['id'] as String,
      firmId: json['firm_id'] as String,
      normalTimeframe: SlaTimeframeModel.fromJson(json['normal_timeframe'] as Map<String, dynamic>),
      urgentTimeframe: SlaTimeframeModel.fromJson(json['urgent_timeframe'] as Map<String, dynamic>),
      emergencyTimeframe: SlaTimeframeModel.fromJson(json['emergency_timeframe'] as Map<String, dynamic>),
      complexTimeframe: SlaTimeframeModel.fromJson(json['complex_timeframe'] as Map<String, dynamic>),
      enableBusinessHoursOnly: json['enable_business_hours_only'] as bool? ?? true,
      includeWeekends: json['include_weekends'] as bool? ?? false,
      allowOverrides: json['allow_overrides'] as bool? ?? true,
      enableAutoEscalation: json['enable_auto_escalation'] as bool? ?? true,
      overrideSettings: Map<String, dynamic>.from(json['override_settings'] as Map? ?? {}),
      lastModified: DateTime.parse(json['last_modified'] as String),
      lastModifiedBy: json['last_modified_by'] as String,
    );
  }

  factory SlaSettingsModel.fromEntity(SlaSettingsEntity entity) {
    return SlaSettingsModel(
      id: entity.id,
      firmId: entity.firmId,
      normalTimeframe: entity.normalTimeframe,
      urgentTimeframe: entity.urgentTimeframe,
      emergencyTimeframe: entity.emergencyTimeframe,
      complexTimeframe: entity.complexTimeframe,
      enableBusinessHoursOnly: entity.enableBusinessHoursOnly,
      includeWeekends: entity.includeWeekends,
      allowOverrides: entity.allowOverrides,
      enableAutoEscalation: entity.enableAutoEscalation,
      overrideSettings: entity.overrideSettings,
      lastModified: entity.lastModified,
      lastModifiedBy: entity.lastModifiedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firm_id': firmId,
      'normal_timeframe': SlaTimeframeModel.fromEntity(normalTimeframe).toJson(),
      'urgent_timeframe': SlaTimeframeModel.fromEntity(urgentTimeframe).toJson(),
      'emergency_timeframe': SlaTimeframeModel.fromEntity(emergencyTimeframe).toJson(),
      'complex_timeframe': SlaTimeframeModel.fromEntity(complexTimeframe).toJson(),
      'enable_business_hours_only': enableBusinessHoursOnly,
      'include_weekends': includeWeekends,
      'allow_overrides': allowOverrides,
      'enable_auto_escalation': enableAutoEscalation,
      'override_settings': overrideSettings,
      'last_modified': lastModified.toIso8601String(),
      'last_modified_by': lastModifiedBy,
    };
  }

  @override
  SlaSettingsModel copyWith({
    String? id,
    String? firmId,
    SlaTimeframe? normalTimeframe,
    SlaTimeframe? urgentTimeframe,
    SlaTimeframe? emergencyTimeframe,
    SlaTimeframe? complexTimeframe,
    bool? enableBusinessHoursOnly,
    bool? includeWeekends,
    bool? allowOverrides,
    bool? enableAutoEscalation,
    Map<String, dynamic>? overrideSettings,
    DateTime? lastModified,
    String? lastModifiedBy,
  }) {
    return SlaSettingsModel(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      normalTimeframe: normalTimeframe ?? this.normalTimeframe,
      urgentTimeframe: urgentTimeframe ?? this.urgentTimeframe,
      emergencyTimeframe: emergencyTimeframe ?? this.emergencyTimeframe,
      complexTimeframe: complexTimeframe ?? this.complexTimeframe,
      enableBusinessHoursOnly: enableBusinessHoursOnly ?? this.enableBusinessHoursOnly,
      includeWeekends: includeWeekends ?? this.includeWeekends,
      allowOverrides: allowOverrides ?? this.allowOverrides,
      enableAutoEscalation: enableAutoEscalation ?? this.enableAutoEscalation,
      overrideSettings: overrideSettings ?? this.overrideSettings,
      lastModified: lastModified ?? this.lastModified,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}

class SlaTimeframeModel {
  final int hours;
  final int minutes;
  final String type;
  final Map<String, dynamic> metadata;

  const SlaTimeframeModel({
    required this.hours,
    required this.minutes,
    required this.type,
    required this.metadata,
  });

  factory SlaTimeframeModel.fromJson(Map<String, dynamic> json) {
    return SlaTimeframeModel(
      hours: json['hours'] as int,
      minutes: json['minutes'] as int,
      type: json['type'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  factory SlaTimeframeModel.fromEntity(SlaTimeframe entity) {
    return SlaTimeframeModel(
      hours: entity.hours,
      minutes: entity.minutes,
      type: entity.type,
      metadata: entity.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hours': hours,
      'minutes': minutes,
      'type': type,
      'metadata': metadata,
    };
  }

  SlaTimeframe toEntity() {
    return SlaTimeframe(
      hours: hours,
      minutes: minutes,
      type: type,
      metadata: metadata,
    );
  }
} 