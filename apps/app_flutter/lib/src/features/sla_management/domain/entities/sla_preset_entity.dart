import 'package:equatable/equatable.dart';

/// Entidade que representa um preset de configuração SLA
/// 
/// Presets são templates pré-configurados que permitem aplicar
/// configurações SLA rapidamente baseadas em cenários comuns
class SlaPresetEntity extends Equatable {
  const SlaPresetEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.defaultSlaHours,
    required this.urgentSlaHours,
    required this.emergencySlaHours,
    required this.complexCaseSlaHours,
    required this.businessHoursStart,
    required this.businessHoursEnd,
    required this.includeWeekends,
    required this.notificationTimings,
    required this.escalationRules,
    required this.overrideSettings,
    required this.isSystemPreset,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.firmId,
    this.createdBy,
    this.tags,
    this.metadata,
  });

  /// ID único do preset
  final String id;

  /// Nome do preset (ex: "Conservador", "Agressivo", "Escritório Grande")
  final String name;

  /// Descrição detalhada do preset
  final String description;

  /// Categoria do preset (system, custom, imported)
  final String category;

  /// SLA padrão em horas para casos normais
  final int defaultSlaHours;

  /// SLA em horas para casos urgentes
  final int urgentSlaHours;

  /// SLA em horas para casos de emergência
  final int emergencySlaHours;

  /// SLA em horas para casos complexos
  final int complexCaseSlaHours;

  /// Hora de início do expediente (formato HH:mm)
  final String businessHoursStart;

  /// Hora de fim do expediente (formato HH:mm)
  final String businessHoursEnd;

  /// Se inclui finais de semana no cálculo
  final bool includeWeekends;

  /// Configurações de timing para notificações
  /// Map com keys: 'before_deadline', 'at_deadline', 'after_violation'
  /// Values: lista de minutos antes/depois
  final Map<String, List<int>> notificationTimings;

  /// Regras de escalação automática
  /// Map com levels e configurações de cada nível
  final Map<String, dynamic> escalationRules;

  /// Configurações de override de SLA
  final Map<String, dynamic> overrideSettings;

  /// Se é um preset do sistema (não editável)
  final bool isSystemPreset;

  /// Se o preset está ativo
  final bool isActive;

  /// Data de criação
  final DateTime createdAt;

  /// Data da última atualização
  final DateTime updatedAt;

  /// ID da firma (null para presets do sistema)
  final String? firmId;

  /// ID do usuário que criou o preset
  final String? createdBy;

  /// Tags para categorização e busca
  final List<String>? tags;

  /// Metadados adicionais
  final Map<String, dynamic>? metadata;

  // Compatibility getters for widgets
  int get normalHours => defaultSlaHours;
  int get urgentHours => urgentSlaHours;
  int get emergencyHours => emergencySlaHours;
  int get complexHours => complexCaseSlaHours;

  /// Presets padrão do sistema
  static const List<Map<String, dynamic>> systemPresets = [
    {
      'id': 'conservative',
      'name': 'Conservador',
      'description': 'Prazos mais longos para garantir qualidade e evitar violações',
      'category': 'system',
      'defaultSlaHours': 72,
      'urgentSlaHours': 48,
      'emergencySlaHours': 24,
      'complexCaseSlaHours': 96,
      'businessHoursStart': '09:00',
      'businessHoursEnd': '18:00',
      'includeWeekends': false,
      'tags': ['conservador', 'qualidade', 'seguro'],
    },
    {
      'id': 'balanced',
      'name': 'Equilibrado',
      'description': 'Balanceamento entre agilidade e qualidade',
      'category': 'system',
      'defaultSlaHours': 48,
      'urgentSlaHours': 24,
      'emergencySlaHours': 12,
      'complexCaseSlaHours': 72,
      'businessHoursStart': '08:00',
      'businessHoursEnd': '19:00',
      'includeWeekends': false,
      'tags': ['equilibrado', 'padrão', 'versátil'],
    },
    {
      'id': 'aggressive',
      'name': 'Agressivo',
      'description': 'Prazos curtos para máxima agilidade e competitividade',
      'category': 'system',
      'defaultSlaHours': 24,
      'urgentSlaHours': 12,
      'emergencySlaHours': 6,
      'complexCaseSlaHours': 48,
      'businessHoursStart': '07:00',
      'businessHoursEnd': '20:00',
      'includeWeekends': true,
      'tags': ['agressivo', 'rápido', 'competitivo'],
    },
    {
      'id': 'large_firm',
      'name': 'Escritório Grande',
      'description': 'Configuração otimizada para escritórios com muitos advogados',
      'category': 'system',
      'defaultSlaHours': 36,
      'urgentSlaHours': 18,
      'emergencySlaHours': 8,
      'complexCaseSlaHours': 60,
      'businessHoursStart': '08:00',
      'businessHoursEnd': '19:00',
      'includeWeekends': false,
      'tags': ['grande', 'corporativo', 'escala'],
    },
    {
      'id': 'boutique_firm',
      'name': 'Escritório Boutique',
      'description': 'Configuração para escritórios especializados e menores',
      'category': 'system',
      'defaultSlaHours': 60,
      'urgentSlaHours': 36,
      'emergencySlaHours': 18,
      'complexCaseSlaHours': 84,
      'businessHoursStart': '09:00',
      'businessHoursEnd': '18:00',
      'includeWeekends': false,
      'tags': ['boutique', 'especializado', 'premium'],
    },
  ];

  /// Método estático para preset conservador
  static SlaPresetEntity conservative() {
    const preset = systemPresets[0];
    return SlaPresetEntity(
      id: preset['id'] as String,
      name: preset['name'] as String,
      description: preset['description'] as String,
      category: preset['category'] as String,
      defaultSlaHours: preset['defaultSlaHours'] as int,
      urgentSlaHours: preset['urgentSlaHours'] as int,
      emergencySlaHours: preset['emergencySlaHours'] as int,
      complexCaseSlaHours: preset['complexCaseSlaHours'] as int,
      businessHoursStart: preset['businessHoursStart'] as String,
      businessHoursEnd: preset['businessHoursEnd'] as String,
      includeWeekends: preset['includeWeekends'] as bool,
      notificationTimings: _defaultNotificationTimings,
      escalationRules: _defaultEscalationRules,
      overrideSettings: _defaultOverrideSettings,
      isSystemPreset: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: List<String>.from(preset['tags'] as List),
    );
  }

  /// Método estático para preset equilibrado
  static SlaPresetEntity balanced() {
    const preset = systemPresets[1];
    return SlaPresetEntity(
      id: preset['id'] as String,
      name: preset['name'] as String,
      description: preset['description'] as String,
      category: preset['category'] as String,
      defaultSlaHours: preset['defaultSlaHours'] as int,
      urgentSlaHours: preset['urgentSlaHours'] as int,
      emergencySlaHours: preset['emergencySlaHours'] as int,
      complexCaseSlaHours: preset['complexCaseSlaHours'] as int,
      businessHoursStart: preset['businessHoursStart'] as String,
      businessHoursEnd: preset['businessHoursEnd'] as String,
      includeWeekends: preset['includeWeekends'] as bool,
      notificationTimings: _defaultNotificationTimings,
      escalationRules: _defaultEscalationRules,
      overrideSettings: _defaultOverrideSettings,
      isSystemPreset: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: List<String>.from(preset['tags'] as List),
    );
  }

  /// Método estático para preset agressivo
  static SlaPresetEntity aggressive() {
    const preset = systemPresets[2];
    return SlaPresetEntity(
      id: preset['id'] as String,
      name: preset['name'] as String,
      description: preset['description'] as String,
      category: preset['category'] as String,
      defaultSlaHours: preset['defaultSlaHours'] as int,
      urgentSlaHours: preset['urgentSlaHours'] as int,
      emergencySlaHours: preset['emergencySlaHours'] as int,
      complexCaseSlaHours: preset['complexCaseSlaHours'] as int,
      businessHoursStart: preset['businessHoursStart'] as String,
      businessHoursEnd: preset['businessHoursEnd'] as String,
      includeWeekends: preset['includeWeekends'] as bool,
      notificationTimings: _defaultNotificationTimings,
      escalationRules: _defaultEscalationRules,
      overrideSettings: _defaultOverrideSettings,
      isSystemPreset: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: List<String>.from(preset['tags'] as List),
    );
  }

  /// Método estático para preset de escritório grande
  static SlaPresetEntity largeFirm() {
    const preset = systemPresets[3];
    return SlaPresetEntity(
      id: preset['id'] as String,
      name: preset['name'] as String,
      description: preset['description'] as String,
      category: preset['category'] as String,
      defaultSlaHours: preset['defaultSlaHours'] as int,
      urgentSlaHours: preset['urgentSlaHours'] as int,
      emergencySlaHours: preset['emergencySlaHours'] as int,
      complexCaseSlaHours: preset['complexCaseSlaHours'] as int,
      businessHoursStart: preset['businessHoursStart'] as String,
      businessHoursEnd: preset['businessHoursEnd'] as String,
      includeWeekends: preset['includeWeekends'] as bool,
      notificationTimings: _defaultNotificationTimings,
      escalationRules: _defaultEscalationRules,
      overrideSettings: _defaultOverrideSettings,
      isSystemPreset: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: List<String>.from(preset['tags'] as List),
    );
  }

  /// Método estático para preset de escritório boutique
  static SlaPresetEntity boutiqueFirm() {
    const preset = systemPresets[4];
    return SlaPresetEntity(
      id: preset['id'] as String,
      name: preset['name'] as String,
      description: preset['description'] as String,
      category: preset['category'] as String,
      defaultSlaHours: preset['defaultSlaHours'] as int,
      urgentSlaHours: preset['urgentSlaHours'] as int,
      emergencySlaHours: preset['emergencySlaHours'] as int,
      complexCaseSlaHours: preset['complexCaseSlaHours'] as int,
      businessHoursStart: preset['businessHoursStart'] as String,
      businessHoursEnd: preset['businessHoursEnd'] as String,
      includeWeekends: preset['includeWeekends'] as bool,
      notificationTimings: _defaultNotificationTimings,
      escalationRules: _defaultEscalationRules,
      overrideSettings: _defaultOverrideSettings,
      isSystemPreset: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: List<String>.from(preset['tags'] as List),
    );
  }

  /// Cria um preset customizado baseado em configurações existentes
  factory SlaPresetEntity.fromSettings({
    required String name,
    required String description,
    required int defaultSlaHours,
    required int urgentSlaHours,
    required int emergencySlaHours,
    required int complexCaseSlaHours,
    required String businessHoursStart,
    required String businessHoursEnd,
    required bool includeWeekends,
    String? firmId,
    String? createdBy,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return SlaPresetEntity(
      id: 'custom_${now.millisecondsSinceEpoch}',
      name: name,
      description: description,
      category: 'custom',
      defaultSlaHours: defaultSlaHours,
      urgentSlaHours: urgentSlaHours,
      emergencySlaHours: emergencySlaHours,
      complexCaseSlaHours: complexCaseSlaHours,
      businessHoursStart: businessHoursStart,
      businessHoursEnd: businessHoursEnd,
      includeWeekends: includeWeekends,
      notificationTimings: _defaultNotificationTimings,
      escalationRules: _defaultEscalationRules,
      overrideSettings: _defaultOverrideSettings,
      isSystemPreset: false,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      firmId: firmId,
      createdBy: createdBy,
      tags: tags ?? [],
      metadata: metadata,
    );
  }

  /// Configurações padrão de notificação
  static const Map<String, List<int>> _defaultNotificationTimings = {
    'before_deadline': [1440, 720, 360, 60], // 24h, 12h, 6h, 1h antes
    'at_deadline': [0], // No momento do deadline
    'after_violation': [60, 180, 360], // 1h, 3h, 6h após violação
  };

  /// Regras padrão de escalação
  static const Map<String, dynamic> _defaultEscalationRules = {
    'enabled': true,
    'levels': [
      {
        'level': 1,
        'trigger_minutes': 60, // 1h após violação
        'notify_roles': ['supervisor'],
        'action': 'notify',
      },
      {
        'level': 2,
        'trigger_minutes': 180, // 3h após violação
        'notify_roles': ['partner'],
        'action': 'escalate',
      },
      {
        'level': 3,
        'trigger_minutes': 360, // 6h após violação
        'notify_roles': ['admin'],
        'action': 'critical_escalate',
      },
    ],
  };

  /// Configurações padrão de override
  static const Map<String, dynamic> _defaultOverrideSettings = {
    'allow_override': true,
    'max_override_hours': 24,
    'require_justification': true,
    'require_approval': false,
    'allowed_roles': ['lawyer_office', 'partner', 'admin'],
  };

  /// Valida se o preset tem configurações válidas
  bool get isValid {
    return name.isNotEmpty &&
           description.isNotEmpty &&
           defaultSlaHours > 0 &&
           urgentSlaHours > 0 &&
           emergencySlaHours > 0 &&
           complexCaseSlaHours > 0 &&
           urgentSlaHours <= defaultSlaHours &&
           emergencySlaHours <= urgentSlaHours &&
           _isValidTimeFormat(businessHoursStart) &&
           _isValidTimeFormat(businessHoursEnd);
  }

  /// Verifica se o formato de hora é válido (HH:mm)
  bool _isValidTimeFormat(String time) {
    final regex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(time);
  }

  /// Calcula duração do expediente em horas
  double get businessHoursDuration {
    final start = _parseTime(businessHoursStart);
    final end = _parseTime(businessHoursEnd);
    
    if (end > start) {
      return (end - start).inMinutes / 60.0;
    } else {
      // Expediente cruza a meia-noite
      return (const Duration(hours: 24) - (start - end)).inMinutes / 60.0;
    }
  }

  /// Converte string de tempo para Duration
  Duration _parseTime(String time) {
    final parts = time.split(':');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
    );
  }

  /// Método toJson para serialização
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'defaultSlaHours': defaultSlaHours,
      'urgentSlaHours': urgentSlaHours,
      'emergencySlaHours': emergencySlaHours,
      'complexCaseSlaHours': complexCaseSlaHours,
      'businessHoursStart': businessHoursStart,
      'businessHoursEnd': businessHoursEnd,
      'includeWeekends': includeWeekends,
      'notificationTimings': notificationTimings,
      'escalationRules': escalationRules,
      'overrideSettings': overrideSettings,
      'isSystemPreset': isSystemPreset,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'firmId': firmId,
      'createdBy': createdBy,
      'tags': tags,
      'metadata': metadata,
    };
  }

  /// Cria uma cópia com modificações
  SlaPresetEntity copyWith({
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
    return SlaPresetEntity(
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

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        defaultSlaHours,
        urgentSlaHours,
        emergencySlaHours,
        complexCaseSlaHours,
        businessHoursStart,
        businessHoursEnd,
        includeWeekends,
        notificationTimings,
        escalationRules,
        overrideSettings,
        isSystemPreset,
        isActive,
        createdAt,
        updatedAt,
        firmId,
        createdBy,
        tags,
        metadata,
      ];

  @override
  String toString() {
    return 'SlaPresetEntity('
        'id: $id, '
        'name: $name, '
        'category: $category, '
        'defaultSla: ${defaultSlaHours}h, '
        'urgentSla: ${urgentSlaHours}h, '
        'emergencySla: ${emergencySlaHours}h, '
        'isSystemPreset: $isSystemPreset, '
        'isActive: $isActive'
        ')';
  }
}