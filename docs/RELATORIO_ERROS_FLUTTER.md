# Relatório de Erros Flutter - Sistema LITIG-1

## Resumo Executivo

Foram identificados **234 erros** e **40 warnings** no código Flutter. Os principais problemas são:

1. **Duplicação massiva de código**: Todas as classes de widgets SLA estão duplicadas
2. **Incompatibilidade entre camadas**: As entidades de domínio não correspondem ao esperado pelos widgets
3. **Imports incorretos**: Muitos arquivos têm imports duplicados ou mal posicionados
4. **Métodos e propriedades não definidos**: Vários métodos esperados pelos widgets não existem nas entidades

## Análise Detalhada por Arquivo

### 1. Arquivos SLA Widgets (sla_*.dart)

#### Problema Principal: Duplicação de Classes
Todos os arquivos de widgets SLA contêm suas classes duplicadas:
- `sla_audit_widget.dart`: Classes duplicadas nas linhas 1-890 e 897-1779
- `sla_basic_settings_widget.dart`: Classes duplicadas nas linhas 1-566 e 574-1131
- `sla_business_rules_widget.dart`: Classes duplicadas nas linhas 1-858 e 865-1715
- `sla_escalations_widget.dart`: Classes duplicadas nas linhas 1-826 e 833-1651
- `sla_notifications_widget.dart`: Classes duplicadas nas linhas 1-798 e 804-1595
- `sla_presets_widget.dart`: Classes duplicadas nas linhas 1-675 e 683-1349

**Resolução**: Remover as classes duplicadas mantendo apenas a primeira versão de cada classe.

### 2. Incompatibilidades de API

#### BusinessHours
**Problema**: Os widgets esperam propriedades que não existem na entidade:
- Widgets usam: `type`, `startTime`, `endTime`, `lunchStart`, `lunchEnd`
- Entidade tem: `startHour`, `startMinute`, `endHour`, `endMinute`

**Resolução**: 
```dart
// Adicionar na classe BusinessHours:
class BusinessHours {
  // ... propriedades existentes ...
  
  // Adicionar getters de compatibilidade
  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);
  TimeOfDay? get lunchStart => lunchStartHour != null ? TimeOfDay(hour: lunchStartHour!, minute: lunchStartMinute!) : null;
  TimeOfDay? get lunchEnd => lunchEndHour != null ? TimeOfDay(hour: lunchEndHour!, minute: lunchEndMinute!) : null;
  String get type => isStandard ? 'standard' : isExtended ? 'extended' : 'fullTime';
  
  // Adicionar métodos estáticos
  static BusinessHours standard() => BusinessHours(
    startHour: 9, startMinute: 0,
    endHour: 18, endMinute: 0,
    lunchStartHour: 12, lunchStartMinute: 0,
    lunchEndHour: 13, lunchEndMinute: 0,
    weekendDays: [DateTime.saturday, DateTime.sunday],
  );
}
```

#### SlaEscalationEntity
**Problema**: Métodos não definidos:
- `timeBasedEscalation()`
- `priorityBasedEscalation()`
- Propriedades: `triggerType`, `escalationLevels`

**Resolução**:
```dart
class SlaEscalationEntity {
  // ... código existente ...
  
  // Adicionar propriedades
  final EscalationTriggerType triggerType;
  final List<EscalationLevel> escalationLevels;
  
  // Adicionar métodos estáticos
  static SlaEscalationEntity timeBasedEscalation({
    required Duration after,
    required List<EscalationLevel> levels,
  }) {
    return SlaEscalationEntity(
      id: '',
      name: 'Time-based Escalation',
      isActive: true,
      trigger: EscalationTrigger.timeBased(after: after),
      triggerType: EscalationTriggerType.timeBased,
      escalationLevels: levels,
      actions: [],
      conditions: [],
    );
  }
  
  static SlaEscalationEntity priorityBasedEscalation({
    required CasePriority priority,
    required List<EscalationLevel> levels,
  }) {
    return SlaEscalationEntity(
      id: '',
      name: 'Priority-based Escalation',
      isActive: true,
      trigger: EscalationTrigger.priorityBased(priority: priority),
      triggerType: EscalationTriggerType.priorityBased,
      escalationLevels: levels,
      actions: [],
      conditions: [],
    );
  }
}
```

#### SlaPresetEntity
**Problema**: Métodos estáticos e propriedades não definidos:
- Métodos: `conservative()`, `balanced()`, `aggressive()`, `largeFirm()`, `boutiqueFirm()`
- Propriedades: `normalHours`, `urgentHours`, `emergencyHours`, `complexHours`

**Resolução**:
```dart
class SlaPresetEntity {
  // ... código existente ...
  
  // Adicionar getters de compatibilidade
  int get normalHours => defaultSlaHours;
  int get urgentHours => urgentSlaHours;
  int get emergencyHours => criticalSlaHours;
  int get complexHours => complexSlaHours;
  
  // Adicionar métodos estáticos
  static SlaPresetEntity conservative() => SlaPresetEntity(
    id: 'conservative',
    name: 'Conservative',
    description: 'Longer SLA times for careful case handling',
    isCustom: false,
    defaultSlaHours: 72,
    urgentSlaHours: 48,
    criticalSlaHours: 24,
    complexSlaHours: 120,
    businessHours: BusinessHours.standard(),
    escalationRules: [],
    notificationSettings: NotificationSettings.defaultSettings(),
  );
  
  // ... implementar outros métodos estáticos similares ...
}
```

### 3. Erros em Events do Bloc

**Problema**: Vários eventos não estão definidos nos blocs:
- `ExportSlaAuditLogEvent`
- `GenerateSlaComplianceReportEvent`
- `VerifySlaIntegrityEvent`
- `TestSlaNotificationEvent`
- `ApplySlaPresetEvent`
- `CreateCustomSlaPresetEvent`
- `ExportSlaPresetEvent`
- `DeleteSlaPresetEvent`

**Resolução**: Adicionar os eventos faltantes no arquivo `sla_settings_event.dart`:
```dart
// Eventos de Auditoria
class ExportSlaAuditLogEvent extends SlaSettingsEvent {
  final String format;
  ExportSlaAuditLogEvent(this.format);
}

class GenerateSlaComplianceReportEvent extends SlaSettingsEvent {
  final DateTimeRange period;
  GenerateSlaComplianceReportEvent(this.period);
}

class VerifySlaIntegrityEvent extends SlaSettingsEvent {}

// Eventos de Notificação
class TestSlaNotificationEvent extends SlaSettingsEvent {
  final NotificationChannel channel;
  TestSlaNotificationEvent(this.channel);
}

// Eventos de Preset
class ApplySlaPresetEvent extends SlaSettingsEvent {
  final SlaPresetEntity preset;
  ApplySlaPresetEvent(this.preset);
}

class CreateCustomSlaPresetEvent extends SlaSettingsEvent {
  final SlaPresetEntity preset;
  CreateCustomSlaPresetEvent(this.preset);
}

class ExportSlaPresetEvent extends SlaSettingsEvent {
  final SlaPresetEntity preset;
  ExportSlaPresetEvent(this.preset);
}

class DeleteSlaPresetEvent extends SlaSettingsEvent {
  final String presetId;
  DeleteSlaPresetEvent(this.presetId);
}
```

### 4. Erros no Video Call

**Problema**: Parâmetros incorretos em `ServerException`:
```dart
// Atual (incorreto)
ServerException('Erro ao criar sala de videochamada')

// Esperado
ServerException(message: 'Erro ao criar sala de videochamada')
```

**Resolução**: Atualizar todas as chamadas de `ServerException` no arquivo `video_call_repository_impl.dart` para usar parâmetro nomeado.

### 5. Avisos de Deprecação

**Problema**: Uso de `withOpacity()` está deprecado.

**Resolução**: Substituir todas as ocorrências:
```dart
// De:
color.withOpacity(0.5)

// Para:
color.withValues(alpha: 0.5)
```

## Ordem de Resolução Recomendada

1. **Remover duplicações de código** (Prioridade: CRÍTICA)
   - Deletar as segundas versões de todas as classes duplicadas
   - Manter apenas a primeira versão de cada classe

2. **Corrigir entidades de domínio** (Prioridade: ALTA)
   - Atualizar `BusinessHours` com getters e métodos estáticos
   - Atualizar `SlaEscalationEntity` com propriedades e métodos faltantes
   - Atualizar `SlaPresetEntity` com getters de compatibilidade e métodos estáticos

3. **Adicionar eventos faltantes** (Prioridade: ALTA)
   - Criar todos os eventos listados no arquivo `sla_settings_event.dart`
   - Implementar os handlers correspondentes no bloc

4. **Corrigir parâmetros de exceção** (Prioridade: MÉDIA)
   - Atualizar `video_call_repository_impl.dart` com parâmetros nomeados

5. **Atualizar código deprecado** (Prioridade: BAIXA)
   - Substituir `withOpacity()` por `withValues(alpha:)`

## Impacto Estimado

Após implementar todas as correções:
- **Erros reduzidos**: De 234 para ~10 erros
- **Warnings reduzidos**: De 40 para ~5 warnings
- **Manutenibilidade**: Significativamente melhorada com remoção de duplicações
- **Compatibilidade**: Camadas de domínio e apresentação totalmente alinhadas

## Próximos Passos

1. Executar as correções na ordem recomendada
2. Rodar `flutter analyze` após cada etapa para validar
3. Executar testes unitários para garantir que nada foi quebrado
4. Fazer commit das correções em pequenos blocos lógicos