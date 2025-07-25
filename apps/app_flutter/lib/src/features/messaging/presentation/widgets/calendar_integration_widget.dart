import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/core/theme/app_colors.dart';
import 'package:meu_app/src/features/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:meu_app/src/features/calendar/domain/entities/calendar_event.dart' as entities;
import 'package:intl/intl.dart';

/// Widget para integrar calendário na aba de mensagens
/// Mostra próximos eventos e permite criação rápida
class CalendarIntegrationWidget extends StatelessWidget {
  const CalendarIntegrationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          _buildCalendarContent(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.calendar,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próximos Compromissos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Sincronizado com Gmail e Outlook',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _syncCalendars(context),
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                tooltip: 'Sincronizar',
              ),
              IconButton(
                onPressed: () => _showCreateEventDialog(context),
                icon: const Icon(LucideIcons.plus, size: 18),
                tooltip: 'Criar evento',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarContent() {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        if (state is CalendarLoading || state is CalendarSyncing) {
          return _buildLoadingState();
        }

        if (state is CalendarError) {
          return _buildErrorState(context, state.message);
        }

        if (state is CalendarLoaded) {
          return _buildEventsState(context, state.events);
        }

        if (state is CalendarSynced) {
          return _buildSyncedState(context, state);
        }

        return _buildInitialState(context);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Carregando eventos...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            LucideIcons.alertCircle,
            color: AppColors.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Erro ao carregar calendário',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _loadEvents(context),
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsState(BuildContext context, List<entities.CalendarEvent> events) {
    // Filtrar próximos eventos (próximos 7 dias)
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    
    final upcomingEvents = events.where((event) {
      return event.startTime.isAfter(now) && 
             event.startTime.isBefore(nextWeek);
    }).take(3).toList();

    if (upcomingEvents.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        ...upcomingEvents.map((event) => _buildEventItem(context, event)),
        if (events.length > 3)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: () => _openFullCalendar(context),
              icon: const Icon(LucideIcons.externalLink, size: 16),
              label: Text('Ver todos os ${events.length} eventos'),
            ),
          ),
      ],
    );
  }

  Widget _buildEventItem(BuildContext context, entities.CalendarEvent event) {
    final startTime = event.startTime;
    final endTime = event.endTime;
    final title = event.title;
    final location = event.location;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 14,
                      color: AppColors.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatEventTime(startTime, endTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                if (location != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: AppColors.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: AppColors.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            LucideIcons.calendarCheck,
            color: AppColors.onSurface.withValues(alpha: 0.4),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhum compromisso próximo',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Você está livre para os próximos 7 dias',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showCreateEventDialog(context),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Criar evento'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            LucideIcons.calendar,
            color: AppColors.primary,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Calendário não carregado',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Toque para sincronizar seus eventos',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _loadEvents(context),
            icon: const Icon(LucideIcons.download, size: 16),
            label: const Text('Carregar eventos'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncedState(BuildContext context, CalendarSynced state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            LucideIcons.checkCircle,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${state.syncedEvents} eventos sincronizados',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            DateFormat('HH:mm').format(state.syncTime),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventTime(DateTime startTime, DateTime endTime) {

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(startTime.year, startTime.month, startTime.day);

    String dateStr;
    if (eventDate == today) {
      dateStr = 'Hoje';
    } else if (eventDate == today.add(const Duration(days: 1))) {
      dateStr = 'Amanhã';
    } else {
      dateStr = DateFormat('dd/MM').format(startTime);
    }

    final timeStr = DateFormat('HH:mm').format(startTime);
    
    final endTimeStr = DateFormat('HH:mm').format(endTime);
    return '$dateStr $timeStr-$endTimeStr';
  
    return '$dateStr $timeStr';
  }

  void _loadEvents(BuildContext context) {
    final now = DateTime.now();
    context.read<CalendarBloc>().add(LoadCalendarEvents(
      startDate: now,
      endDate: now.add(const Duration(days: 30)),
      refresh: true,
    ));
  }

  void _syncCalendars(BuildContext context) {
    context.read<CalendarBloc>().add(const SyncCalendars());
  }

  void _showCreateEventDialog(BuildContext context) {
    // TODO: Implementar dialog de criação rápida de evento
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar Evento'),
        content: const Text('Funcionalidade em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openFullCalendar(BuildContext context) {
    // TODO: Navegar para tela completa do calendário
    Navigator.pushNamed(context, '/calendar');
  }
} 