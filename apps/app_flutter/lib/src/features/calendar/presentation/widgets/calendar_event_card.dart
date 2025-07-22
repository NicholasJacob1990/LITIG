import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import '../screens/client_agenda_screen.dart';

/// Card para exibir eventos de calendário
class CalendarEventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final bool isToday;

  const CalendarEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onEdit,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeConfig = _getTypeConfig(event.type);
    final urgencyConfig = _getUrgencyConfig(event.urgency);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isToday ? 4 : 2,
        shadowColor: isToday ? typeConfig.color.withValues(alpha: 0.3) : Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isToday
              ? BorderSide(color: typeConfig.color, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, typeConfig, urgencyConfig),
                const SizedBox(height: 8),
                _buildContent(context),
                const SizedBox(height: 12),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EventTypeConfig typeConfig, UrgencyConfig urgencyConfig) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: typeConfig.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: typeConfig.color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                typeConfig.icon,
                size: 14,
                color: typeConfig.color,
              ),
              const SizedBox(width: 4),
              Text(
                typeConfig.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: typeConfig.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (event.urgency != EventUrgency.media)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: urgencyConfig.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: urgencyConfig.color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              urgencyConfig.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: urgencyConfig.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const Spacer(),
        if (onEdit != null)
          IconButton(
            icon: Icon(
              LucideIcons.edit3,
              size: 16,
              color: theme.colorScheme.outline,
            ),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (event.description?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(
            event.description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.clock,
              size: 14,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Text(
              _formatEventTime(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (event.location?.isNotEmpty == true) ...[
              const SizedBox(width: 16),
              Icon(
                LucideIcons.mapPin,
                size: 14,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.location!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        if (event.caseNumber?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                LucideIcons.fileText,
                size: 14,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 4),
              Text(
                'Processo: ${event.caseNumber}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
        if (isToday) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.calendar,
                  size: 12,
                  color: AppColors.info,
                ),
                const SizedBox(width: 4),
                Text(
                  'HOJE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatEventTime() {
    final start = event.startTime;
    final end = event.endTime;
    
    if (_isSameDay(start, end)) {
      return '${_formatTime(start)} - ${_formatTime(end)}';
    } else {
      return '${_formatDateTime(start)} - ${_formatDateTime(end)}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  EventTypeConfig _getTypeConfig(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.audiencia:
        return const EventTypeConfig(
          label: 'Audiência',
          icon: LucideIcons.gavel,
          color: AppColors.error,
        );
      case CalendarEventType.consulta:
        return const EventTypeConfig(
          label: 'Consulta',
          icon: LucideIcons.messageCircle,
          color: AppColors.info,
        );
      case CalendarEventType.prazo:
        return const EventTypeConfig(
          label: 'Prazo',
          icon: LucideIcons.alertTriangle,
          color: AppColors.warning,
        );
      case CalendarEventType.reuniao:
        return const EventTypeConfig(
          label: 'Reunião',
          icon: LucideIcons.users,
          color: AppColors.primaryBlue,
        );
      case CalendarEventType.outros:
        return const EventTypeConfig(
          label: 'Outros',
          icon: LucideIcons.calendar,
          color: AppColors.lightText2,
        );
    }
  }

  UrgencyConfig _getUrgencyConfig(EventUrgency urgency) {
    switch (urgency) {
      case EventUrgency.baixa:
        return const UrgencyConfig(
          label: 'Baixa',
          color: AppColors.success,
        );
      case EventUrgency.media:
        return const UrgencyConfig(
          label: 'Média',
          color: AppColors.info,
        );
      case EventUrgency.alta:
        return const UrgencyConfig(
          label: 'Alta',
          color: AppColors.warning,
        );
      case EventUrgency.critica:
        return const UrgencyConfig(
          label: 'Crítica',
          color: AppColors.error,
        );
    }
  }
}

class EventTypeConfig {
  final String label;
  final IconData icon;
  final Color color;

  const EventTypeConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class UrgencyConfig {
  final String label;
  final Color color;

  const UrgencyConfig({
    required this.label,
    required this.color,
  });
}