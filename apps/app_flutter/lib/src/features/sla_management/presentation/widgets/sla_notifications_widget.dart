import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sla_settings_bloc.dart';
import '../bloc/sla_settings_event.dart';
import '../bloc/sla_settings_state.dart';

class SlaNotificationsWidget extends StatefulWidget {
  const SlaNotificationsWidget({super.key});

  @override
  State<SlaNotificationsWidget> createState() => _SlaNotificationsWidgetState();
}

class _SlaNotificationsWidgetState extends State<SlaNotificationsWidget> {
  // Notification Channels
  bool _enablePushNotifications = true;
  bool _enableEmailNotifications = true;
  bool _enableSMSNotifications = false;
  bool _enableInAppNotifications = true;

  // Timing Settings
  bool _notifyBeforeDeadline = true;
  bool _notifyAtDeadline = true;
  bool _notifyAfterViolation = true;
  
  int _beforeDeadlineHours = 4;
  int _escalationDelayMinutes = 30;
  
  // Recipients
  bool _notifyAssignedLawyer = true;
  bool _notifySupervisor = true;
  bool _notifyPartner = false;
  bool _notifyClient = false;
  
  // Anti-spam settings
  int _maxNotificationsPerHour = 3;
  bool _enableQuietHours = true;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SlaSettingsBloc, SlaSettingsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildNotificationChannels(),
              const SizedBox(height: 24),
              _buildTimingSettings(),
              const SizedBox(height: 24),
              _buildRecipientSettings(),
              const SizedBox(height: 24),
              _buildTemplateSettings(),
              const SizedBox(height: 24),
              _buildAntiSpamSettings(),
              const SizedBox(height: 24),
              _buildTestSection(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notifications, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'Configurações de Notificações',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Configure como e quando as notificações SLA serão enviadas para os responsáveis.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationChannels() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.send, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Canais de Notificação',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildChannelTile(
              'Push Notifications',
              'Notificações push no aplicativo',
              Icons.phone_android,
              _enablePushNotifications,
              (value) => setState(() => _enablePushNotifications = value),
              Colors.blue,
            ),
            _buildChannelTile(
              'Email',
              'Notificações por email',
              Icons.email,
              _enableEmailNotifications,
              (value) => setState(() => _enableEmailNotifications = value),
              Colors.green,
            ),
            _buildChannelTile(
              'SMS',
              'Mensagens de texto (casos urgentes)',
              Icons.sms,
              _enableSMSNotifications,
              (value) => setState(() => _enableSMSNotifications = value),
              Colors.orange,
            ),
            _buildChannelTile(
              'In-App',
              'Notificações internas do sistema',
              Icons.notifications_active,
              _enableInAppNotifications,
              (value) => setState(() => _enableInAppNotifications = value),
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.05) : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, color: value ? color : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: color,
      ),
    );
  }

  Widget _buildTimingSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Timing das Notificações',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Notificar Antes do Prazo'),
              subtitle: const Text('Enviar alerta preventivo'),
              value: _notifyBeforeDeadline,
              onChanged: (value) => setState(() => _notifyBeforeDeadline = value),
            ),
            if (_notifyBeforeDeadline) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('Antecedência: '),
                    Expanded(
                      child: Slider(
                        value: _beforeDeadlineHours.toDouble(),
                        min: 1,
                        max: 24,
                        divisions: 23,
                        label: '$_beforeDeadlineHours horas',
                        onChanged: (value) => setState(() => _beforeDeadlineHours = value.round()),
                      ),
                    ),
                    Text('${_beforeDeadlineHours}h'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Notificar no Prazo Final'),
              subtitle: const Text('Alerta quando o prazo expira'),
              value: _notifyAtDeadline,
              onChanged: (value) => setState(() => _notifyAtDeadline = value),
            ),
            SwitchListTile(
              title: const Text('Notificar Após Violação'),
              subtitle: const Text('Alerta quando SLA é violado'),
              value: _notifyAfterViolation,
              onChanged: (value) => setState(() => _notifyAfterViolation = value),
            ),
            if (_notifyAfterViolation) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('Delay para escalação: '),
                    Expanded(
                      child: Slider(
                        value: _escalationDelayMinutes.toDouble(),
                        min: 5,
                        max: 120,
                        divisions: 23,
                        label: '$_escalationDelayMinutes minutos',
                        onChanged: (value) => setState(() => _escalationDelayMinutes = value.round()),
                      ),
                    ),
                    Text('${_escalationDelayMinutes}m'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Destinatários',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRecipientTile(
              'Advogado Responsável',
              'Advogado atribuído ao caso',
              Icons.person,
              _notifyAssignedLawyer,
              (value) => setState(() => _notifyAssignedLawyer = value),
              Colors.blue,
              priority: 'Alta',
            ),
            _buildRecipientTile(
              'Supervisor',
              'Supervisor direto do advogado',
              Icons.supervisor_account,
              _notifySupervisor,
              (value) => setState(() => _notifySupervisor = value),
              Colors.orange,
              priority: 'Média',
            ),
            _buildRecipientTile(
              'Sócio',
              'Sócio responsável pela área',
              Icons.business_center,
              _notifyPartner,
              (value) => setState(() => _notifyPartner = value),
              Colors.purple,
              priority: 'Baixa',
            ),
            _buildRecipientTile(
              'Cliente',
              'Cliente proprietário do caso',
              Icons.account_circle,
              _notifyClient,
              (value) => setState(() => _notifyClient = value),
              Colors.green,
              priority: 'Opcional',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    Color color, {
    String? priority,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.05) : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, color: value ? color : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
            if (priority != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: color,
      ),
    );
  }

  Widget _buildTemplateSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_snippet, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Templates de Mensagem',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTemplatePreview(
              'Prazo Aproximando',
              'Caso #{caseId} vence em {timeLeft}. Cliente: {clientName}',
              Icons.warning_amber,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildTemplatePreview(
              'SLA Violado',
              'ATENÇÃO: SLA violado para caso #{caseId}. Ação imediata necessária.',
              Icons.error,
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildTemplatePreview(
              'Escalação',
              'Escalação necessária: {reason}. Caso #{caseId} requer atenção.',
              Icons.trending_up,
              Colors.purple,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _customizeTemplates(),
              icon: const Icon(Icons.edit),
              label: const Text('Personalizar Templates'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatePreview(String title, String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAntiSpamSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.block, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Configurações Anti-Spam',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Máximo por Hora',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _maxNotificationsPerHour.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: '$_maxNotificationsPerHour',
                              onChanged: (value) => setState(() => _maxNotificationsPerHour = value.round()),
                            ),
                          ),
                          Text('$_maxNotificationsPerHour/h'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Horário Silencioso'),
              subtitle: const Text('Não enviar notificações em horários específicos'),
              value: _enableQuietHours,
              onChanged: (value) => setState(() => _enableQuietHours = value),
            ),
            if (_enableQuietHours) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeSelector(
                      'Início',
                      _quietHoursStart,
                      (time) => setState(() => _quietHoursStart = time),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeSelector(
                      'Fim',
                      _quietHoursEnd,
                      (time) => setState(() => _quietHoursEnd = time),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(time.format(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_arrow, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Testar Notificações',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Envie notificações de teste para verificar se as configurações estão funcionando corretamente.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _sendTestNotification('deadline'),
                  icon: const Icon(Icons.warning_amber, size: 16),
                  label: const Text('Teste Prazo'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _sendTestNotification('violation'),
                  icon: const Icon(Icons.error, size: 16),
                  label: const Text('Teste Violação'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _sendTestNotification('escalation'),
                  icon: const Icon(Icons.trending_up, size: 16),
                  label: const Text('Teste Escalação'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _resetToDefaults(),
            icon: const Icon(Icons.refresh),
            label: const Text('Restaurar Padrões'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _previewNotifications(),
            icon: const Icon(Icons.preview),
            label: const Text('Visualizar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _saveNotificationSettings(),
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
          ),
        ),
      ],
    );
  }

  void _customizeTemplates() {
    // TODO: Implement template customization
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de personalização em desenvolvimento')),
    );
  }

  void _sendTestNotification(String type) {
    context.read<SlaSettingsBloc>().add(
      TestSlaNotificationEvent(type: type),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notificação de teste "$type" enviada')),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Configurações Padrão'),
        content: const Text(
          'Isso irá restaurar todas as configurações de notificação para os valores padrão. Continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset all settings to defaults
              setState(() {
                _enablePushNotifications = true;
                _enableEmailNotifications = true;
                _enableSMSNotifications = false;
                _enableInAppNotifications = true;
                _notifyBeforeDeadline = true;
                _notifyAtDeadline = true;
                _notifyAfterViolation = true;
                _beforeDeadlineHours = 4;
                _escalationDelayMinutes = 30;
                _notifyAssignedLawyer = true;
                _notifySupervisor = true;
                _notifyPartner = false;
                _notifyClient = false;
                _maxNotificationsPerHour = 3;
                _enableQuietHours = true;
                _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
                _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
              });
            },
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  void _previewNotifications() {
    // TODO: Implement notification preview
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de preview em desenvolvimento')),
    );
  }

  void _saveNotificationSettings() {
    final settings = {
      'channels': {
        'push': _enablePushNotifications,
        'email': _enableEmailNotifications,
        'sms': _enableSMSNotifications,
        'inApp': _enableInAppNotifications,
      },
      'timing': {
        'beforeDeadline': _notifyBeforeDeadline,
        'atDeadline': _notifyAtDeadline,
        'afterViolation': _notifyAfterViolation,
        'beforeDeadlineHours': _beforeDeadlineHours,
        'escalationDelayMinutes': _escalationDelayMinutes,
      },
      'recipients': {
        'assignedLawyer': _notifyAssignedLawyer,
        'supervisor': _notifySupervisor,
        'partner': _notifyPartner,
        'client': _notifyClient,
      },
      'antiSpam': {
        'maxPerHour': _maxNotificationsPerHour,
        'quietHours': _enableQuietHours,
        'quietStart': '${_quietHoursStart.hour}:${_quietHoursStart.minute}',
        'quietEnd': '${_quietHoursEnd.hour}:${_quietHoursEnd.minute}',
      },
    };

    context.read<SlaSettingsBloc>().add(
      UpdateSlaNotificationSettingsEvent(settings: settings),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações de notificação salvas com sucesso')),
    );
  }
} 
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sla_settings_bloc.dart';
import '../bloc/sla_settings_event.dart';
import '../bloc/sla_settings_state.dart';

class SlaNotificationsWidget extends StatefulWidget {
  const SlaNotificationsWidget({super.key});

  @override
  State<SlaNotificationsWidget> createState() => _SlaNotificationsWidgetState();
}

class _SlaNotificationsWidgetState extends State<SlaNotificationsWidget> {
  // Notification Channels
  bool _enablePushNotifications = true;
  bool _enableEmailNotifications = true;
  bool _enableSMSNotifications = false;
  bool _enableInAppNotifications = true;

  // Timing Settings
  bool _notifyBeforeDeadline = true;
  bool _notifyAtDeadline = true;
  bool _notifyAfterViolation = true;
  
  int _beforeDeadlineHours = 4;
  int _escalationDelayMinutes = 30;
  
  // Recipients
  bool _notifyAssignedLawyer = true;
  bool _notifySupervisor = true;
  bool _notifyPartner = false;
  bool _notifyClient = false;
  
  // Anti-spam settings
  int _maxNotificationsPerHour = 3;
  bool _enableQuietHours = true;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SlaSettingsBloc, SlaSettingsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildNotificationChannels(),
              const SizedBox(height: 24),
              _buildTimingSettings(),
              const SizedBox(height: 24),
              _buildRecipientSettings(),
              const SizedBox(height: 24),
              _buildTemplateSettings(),
              const SizedBox(height: 24),
              _buildAntiSpamSettings(),
              const SizedBox(height: 24),
              _buildTestSection(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notifications, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'Configurações de Notificações',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Configure como e quando as notificações SLA serão enviadas para os responsáveis.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationChannels() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.send, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Canais de Notificação',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildChannelTile(
              'Push Notifications',
              'Notificações push no aplicativo',
              Icons.phone_android,
              _enablePushNotifications,
              (value) => setState(() => _enablePushNotifications = value),
              Colors.blue,
            ),
            _buildChannelTile(
              'Email',
              'Notificações por email',
              Icons.email,
              _enableEmailNotifications,
              (value) => setState(() => _enableEmailNotifications = value),
              Colors.green,
            ),
            _buildChannelTile(
              'SMS',
              'Mensagens de texto (casos urgentes)',
              Icons.sms,
              _enableSMSNotifications,
              (value) => setState(() => _enableSMSNotifications = value),
              Colors.orange,
            ),
            _buildChannelTile(
              'In-App',
              'Notificações internas do sistema',
              Icons.notifications_active,
              _enableInAppNotifications,
              (value) => setState(() => _enableInAppNotifications = value),
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.05) : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, color: value ? color : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: color,
      ),
    );
  }

  Widget _buildTimingSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Timing das Notificações',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Notificar Antes do Prazo'),
              subtitle: const Text('Enviar alerta preventivo'),
              value: _notifyBeforeDeadline,
              onChanged: (value) => setState(() => _notifyBeforeDeadline = value),
            ),
            if (_notifyBeforeDeadline) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('Antecedência: '),
                    Expanded(
                      child: Slider(
                        value: _beforeDeadlineHours.toDouble(),
                        min: 1,
                        max: 24,
                        divisions: 23,
                        label: '$_beforeDeadlineHours horas',
                        onChanged: (value) => setState(() => _beforeDeadlineHours = value.round()),
                      ),
                    ),
                    Text('${_beforeDeadlineHours}h'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Notificar no Prazo Final'),
              subtitle: const Text('Alerta quando o prazo expira'),
              value: _notifyAtDeadline,
              onChanged: (value) => setState(() => _notifyAtDeadline = value),
            ),
            SwitchListTile(
              title: const Text('Notificar Após Violação'),
              subtitle: const Text('Alerta quando SLA é violado'),
              value: _notifyAfterViolation,
              onChanged: (value) => setState(() => _notifyAfterViolation = value),
            ),
            if (_notifyAfterViolation) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('Delay para escalação: '),
                    Expanded(
                      child: Slider(
                        value: _escalationDelayMinutes.toDouble(),
                        min: 5,
                        max: 120,
                        divisions: 23,
                        label: '$_escalationDelayMinutes minutos',
                        onChanged: (value) => setState(() => _escalationDelayMinutes = value.round()),
                      ),
                    ),
                    Text('${_escalationDelayMinutes}m'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Destinatários',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRecipientTile(
              'Advogado Responsável',
              'Advogado atribuído ao caso',
              Icons.person,
              _notifyAssignedLawyer,
              (value) => setState(() => _notifyAssignedLawyer = value),
              Colors.blue,
              priority: 'Alta',
            ),
            _buildRecipientTile(
              'Supervisor',
              'Supervisor direto do advogado',
              Icons.supervisor_account,
              _notifySupervisor,
              (value) => setState(() => _notifySupervisor = value),
              Colors.orange,
              priority: 'Média',
            ),
            _buildRecipientTile(
              'Sócio',
              'Sócio responsável pela área',
              Icons.business_center,
              _notifyPartner,
              (value) => setState(() => _notifyPartner = value),
              Colors.purple,
              priority: 'Baixa',
            ),
            _buildRecipientTile(
              'Cliente',
              'Cliente proprietário do caso',
              Icons.account_circle,
              _notifyClient,
              (value) => setState(() => _notifyClient = value),
              Colors.green,
              priority: 'Opcional',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    Color color, {
    String? priority,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.05) : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, color: value ? color : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
            if (priority != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: color,
      ),
    );
  }

  Widget _buildTemplateSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_snippet, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Templates de Mensagem',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTemplatePreview(
              'Prazo Aproximando',
              'Caso #{caseId} vence em {timeLeft}. Cliente: {clientName}',
              Icons.warning_amber,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildTemplatePreview(
              'SLA Violado',
              'ATENÇÃO: SLA violado para caso #{caseId}. Ação imediata necessária.',
              Icons.error,
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildTemplatePreview(
              'Escalação',
              'Escalação necessária: {reason}. Caso #{caseId} requer atenção.',
              Icons.trending_up,
              Colors.purple,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _customizeTemplates(),
              icon: const Icon(Icons.edit),
              label: const Text('Personalizar Templates'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatePreview(String title, String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAntiSpamSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.block, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Configurações Anti-Spam',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Máximo por Hora',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _maxNotificationsPerHour.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: '$_maxNotificationsPerHour',
                              onChanged: (value) => setState(() => _maxNotificationsPerHour = value.round()),
                            ),
                          ),
                          Text('$_maxNotificationsPerHour/h'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Horário Silencioso'),
              subtitle: const Text('Não enviar notificações em horários específicos'),
              value: _enableQuietHours,
              onChanged: (value) => setState(() => _enableQuietHours = value),
            ),
            if (_enableQuietHours) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeSelector(
                      'Início',
                      _quietHoursStart,
                      (time) => setState(() => _quietHoursStart = time),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeSelector(
                      'Fim',
                      _quietHoursEnd,
                      (time) => setState(() => _quietHoursEnd = time),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(time.format(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_arrow, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Testar Notificações',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Envie notificações de teste para verificar se as configurações estão funcionando corretamente.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _sendTestNotification('deadline'),
                  icon: const Icon(Icons.warning_amber, size: 16),
                  label: const Text('Teste Prazo'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _sendTestNotification('violation'),
                  icon: const Icon(Icons.error, size: 16),
                  label: const Text('Teste Violação'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _sendTestNotification('escalation'),
                  icon: const Icon(Icons.trending_up, size: 16),
                  label: const Text('Teste Escalação'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _resetToDefaults(),
            icon: const Icon(Icons.refresh),
            label: const Text('Restaurar Padrões'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _previewNotifications(),
            icon: const Icon(Icons.preview),
            label: const Text('Visualizar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _saveNotificationSettings(),
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
          ),
        ),
      ],
    );
  }

  void _customizeTemplates() {
    // TODO: Implement template customization
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de personalização em desenvolvimento')),
    );
  }

  void _sendTestNotification(String type) {
    context.read<SlaSettingsBloc>().add(
      TestSlaNotificationEvent(type: type),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notificação de teste "$type" enviada')),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Configurações Padrão'),
        content: const Text(
          'Isso irá restaurar todas as configurações de notificação para os valores padrão. Continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset all settings to defaults
              setState(() {
                _enablePushNotifications = true;
                _enableEmailNotifications = true;
                _enableSMSNotifications = false;
                _enableInAppNotifications = true;
                _notifyBeforeDeadline = true;
                _notifyAtDeadline = true;
                _notifyAfterViolation = true;
                _beforeDeadlineHours = 4;
                _escalationDelayMinutes = 30;
                _notifyAssignedLawyer = true;
                _notifySupervisor = true;
                _notifyPartner = false;
                _notifyClient = false;
                _maxNotificationsPerHour = 3;
                _enableQuietHours = true;
                _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
                _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
              });
            },
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  void _previewNotifications() {
    // TODO: Implement notification preview
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de preview em desenvolvimento')),
    );
  }

  void _saveNotificationSettings() {
    final settings = {
      'channels': {
        'push': _enablePushNotifications,
        'email': _enableEmailNotifications,
        'sms': _enableSMSNotifications,
        'inApp': _enableInAppNotifications,
      },
      'timing': {
        'beforeDeadline': _notifyBeforeDeadline,
        'atDeadline': _notifyAtDeadline,
        'afterViolation': _notifyAfterViolation,
        'beforeDeadlineHours': _beforeDeadlineHours,
        'escalationDelayMinutes': _escalationDelayMinutes,
      },
      'recipients': {
        'assignedLawyer': _notifyAssignedLawyer,
        'supervisor': _notifySupervisor,
        'partner': _notifyPartner,
        'client': _notifyClient,
      },
      'antiSpam': {
        'maxPerHour': _maxNotificationsPerHour,
        'quietHours': _enableQuietHours,
        'quietStart': '${_quietHoursStart.hour}:${_quietHoursStart.minute}',
        'quietEnd': '${_quietHoursEnd.hour}:${_quietHoursEnd.minute}',
      },
    };

    context.read<SlaSettingsBloc>().add(
      UpdateSlaNotificationSettingsEvent(settings: settings),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações de notificação salvas com sucesso')),
    );
  }
} 