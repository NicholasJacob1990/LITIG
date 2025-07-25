import 'package:flutter/material.dart';
import '../../domain/entities/client_profile.dart';

// This file contains additional communication-related widgets
// that can be reused across different communication screens

class CommunicationSummaryCard extends StatelessWidget {
  final CommunicationPreferences preferences;
  
  const CommunicationSummaryCard({
    super.key,
    required this.preferences,
  });

  @override
  Widget build(BuildContext context) {
    final enabledChannels = preferences.preferredChannels
        .where((channel) => channel.isEnabled)
        .length;
    
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.forum,
                  color: Theme.of(context).primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumo das Preferências',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Suas configurações de comunicação',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.chat,
                    label: 'Canais Ativos',
                    value: '$enabledChannels',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.schedule,
                    label: 'Fuso Horário',
                    value: _getTimezoneShort(preferences.availability.timezone),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.notifications,
                    label: 'Notificações',
                    value: '${_getActiveNotificationsCount()}/5',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.security,
                    label: 'Emergência',
                    value: preferences.availability.acceptEmergencyOutsideHours ? 'Sim' : 'Não',
                    color: preferences.availability.acceptEmergencyOutsideHours ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTimezoneShort(String timezone) {
    switch (timezone) {
      case 'America/Sao_Paulo':
        return 'GMT-3';
      case 'America/Manaus':
        return 'GMT-4';
      case 'America/Fortaleza':
        return 'GMT-3';
      case 'America/Rio_Branco':
        return 'GMT-5';
      default:
        return 'GMT-3';
    }
  }

  int _getActiveNotificationsCount() {
    return preferences.notificationSettings.values
        .where((enabled) => enabled)
        .length;
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class QuickToggleSection extends StatelessWidget {
  final CommunicationPreferences preferences;
  final ValueChanged<CommunicationPreferences> onChanged;
  
  const QuickToggleSection({
    super.key,
    required this.preferences,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações Rápidas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            _buildQuickToggle(
              'Modo "Não Perturbe"',
              'Desabilita todas as notificações temporariamente',
              Icons.do_not_disturb,
              false, // TODO: Implement do not disturb logic
              (value) {
                // TODO: Implement do not disturb toggle
              },
            ),
            
            _buildQuickToggle(
              'Somente Emergências',
              'Receber apenas contatos marcados como urgentes',
              Icons.priority_high,
              preferences.availability.acceptEmergencyOutsideHours,
              (value) {
                final updatedAvailability = ClientAvailability(
                  timezone: preferences.availability.timezone,
                  weeklySchedule: preferences.availability.weeklySchedule,
                  acceptHolidays: preferences.availability.acceptHolidays,
                  acceptEmergencyOutsideHours: value,
                );
                
                onChanged(CommunicationPreferences(
                  preferredChannels: preferences.preferredChannels,
                  availability: updatedAvailability,
                  notificationSettings: preferences.notificationSettings,
                  authorizations: preferences.authorizations,
                ));
              },
            ),
            
            _buildQuickToggle(
              'Contato nos Feriados',
              'Permitir contato durante feriados nacionais',
              Icons.event,
              preferences.availability.acceptHolidays,
              (value) {
                final updatedAvailability = ClientAvailability(
                  timezone: preferences.availability.timezone,
                  weeklySchedule: preferences.availability.weeklySchedule,
                  acceptHolidays: value,
                  acceptEmergencyOutsideHours: preferences.availability.acceptEmergencyOutsideHours,
                );
                
                onChanged(CommunicationPreferences(
                  preferredChannels: preferences.preferredChannels,
                  availability: updatedAvailability,
                  notificationSettings: preferences.notificationSettings,
                  authorizations: preferences.authorizations,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class CommunicationTipsCard extends StatelessWidget {
  const CommunicationTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.amber[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Dicas de Comunicação',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.amber[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildTip(
              'Configure horários de disponibilidade realistas para evitar contatos indesejados.',
            ),
            _buildTip(
              'Mantenha pelo menos um canal de emergência ativo para casos urgentes.',
            ),
            _buildTip(
              'Revise suas preferências periodicamente para garantir que estão atualizadas.',
            ),
            _buildTip(
              'Use diferentes canais para diferentes tipos de comunicação (ex: WhatsApp para informais, email para formais).',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.amber[700],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.amber[800]),
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklyScheduleOverview extends StatelessWidget {
  final ClientAvailability availability;
  
  const WeeklyScheduleOverview({
    super.key,
    required this.availability,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo Semanal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            ...WeekDay.values.map((day) {
              final timeSlots = availability.getTimeSlotsForDay(day);
              return _buildDayOverview(context, day, timeSlots);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDayOverview(BuildContext context, WeekDay day, List<TimeSlot> timeSlots) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: timeSlots.isNotEmpty ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              _getWeekDayShort(day),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: timeSlots.isEmpty
                ? Text(
                    'Não disponível',
                    style: TextStyle(color: Colors.grey[600]),
                  )
                : Wrap(
                    spacing: 8,
                    children: timeSlots
                        .map((slot) => Text(
                              '${slot.startTime}-${slot.endTime}',
                              style: TextStyle(color: Colors.green[700]),
                            ))
                        .toList(),
                  ),
          ),
          Icon(
            timeSlots.isNotEmpty ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: timeSlots.isNotEmpty ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  String _getWeekDayShort(WeekDay day) {
    switch (day) {
      case WeekDay.monday:
        return 'Segunda';
      case WeekDay.tuesday:
        return 'Terça';
      case WeekDay.wednesday:
        return 'Quarta';
      case WeekDay.thursday:
        return 'Quinta';
      case WeekDay.friday:
        return 'Sexta';
      case WeekDay.saturday:
        return 'Sábado';
      case WeekDay.sunday:
        return 'Domingo';
    }
  }
}

class ChannelStatusIndicator extends StatelessWidget {
  final ChannelType channelType;
  final bool isEnabled;
  final bool hasConfiguration;
  
  const ChannelStatusIndicator({
    super.key,
    required this.channelType,
    required this.isEnabled,
    this.hasConfiguration = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getChannelIcon(),
            size: 16,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (!isEnabled) return Colors.grey;
    if (!hasConfiguration) return Colors.orange;
    return Colors.green;
  }

  IconData _getChannelIcon() {
    switch (channelType) {
      case ChannelType.email:
        return Icons.email;
      case ChannelType.whatsapp:
        return Icons.chat;
      case ChannelType.sms:
        return Icons.message;
      case ChannelType.phone:
        return Icons.phone;
      case ChannelType.inAppNotification:
        return Icons.notifications;
      case ChannelType.pushNotification:
        return Icons.notification_important;
    }
  }

  String _getStatusText() {
    if (!isEnabled) return 'Desabilitado';
    if (!hasConfiguration) return 'Configurar';
    return 'Ativo';
  }
}