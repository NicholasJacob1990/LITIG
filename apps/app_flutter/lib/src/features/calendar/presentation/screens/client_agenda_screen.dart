import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import 'package:meu_app/src/features/calendar/presentation/widgets/calendar_event_card.dart';
import 'package:meu_app/src/features/calendar/presentation/widgets/calendar_sync_widget.dart';

/// Tela de agenda para clientes com integração Unipile
class ClientAgendaScreen extends StatefulWidget {
  const ClientAgendaScreen({super.key});

  @override
  State<ClientAgendaScreen> createState() => _ClientAgendaScreenState();
}

class _ClientAgendaScreenState extends State<ClientAgendaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateTime _selectedDate = DateTime.now();
  List<CalendarEvent> _events = [];
  bool _isLoading = false;
  bool _isGoogleSynced = false;
  bool _isOutlookSynced = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implementar carregamento via Unipile SDK
      await Future.delayed(const Duration(seconds: 1)); // Simulação
      
      // Eventos de exemplo
      _events = [
        CalendarEvent(
          id: '1',
          title: 'Audiência - Processo Trabalhista',
          description: 'Audiência inicial no TRT',
          startTime: DateTime.now().add(const Duration(days: 2, hours: 14)),
          endTime: DateTime.now().add(const Duration(days: 2, hours: 16)),
          location: 'TRT - São Paulo',
          type: CalendarEventType.audiencia,
          caseId: 'case_123',
          caseNumber: 'T-12345/2024',
          urgency: EventUrgency.alta,
        ),
        CalendarEvent(
          id: '2',
          title: 'Consulta - Direito Empresarial',
          description: 'Revisão de contratos',
          startTime: DateTime.now().add(const Duration(days: 5, hours: 10)),
          endTime: DateTime.now().add(const Duration(days: 5, hours: 11)),
          location: 'Escritório - Video call',
          type: CalendarEventType.consulta,
          caseId: 'case_456',
          urgency: EventUrgency.media,
        ),
        CalendarEvent(
          id: '3',
          title: 'Prazo - Contestação',
          description: 'Prazo para apresentar contestação',
          startTime: DateTime.now().add(const Duration(days: 10)),
          endTime: DateTime.now().add(const Duration(days: 10, hours: 1)),
          location: 'Online',
          type: CalendarEventType.prazo,
          caseId: 'case_789',
          caseNumber: 'C-98765/2024',
          urgency: EventUrgency.critica,
        ),
      ];
    } catch (e) {
      // TODO: Implementar tratamento de erro
      debugPrint('Erro ao carregar eventos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implementar sincronização via Unipile SDK
      await Future.delayed(const Duration(seconds: 2)); // Simulação
      setState(() => _isGoogleSynced = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sincronizado com Google Calendar'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao sincronizar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncWithOutlook() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implementar sincronização via Unipile SDK
      await Future.delayed(const Duration(seconds: 2)); // Simulação
      setState(() => _isOutlookSynced = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sincronizado com Outlook'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao sincronizar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Agenda'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => _showSyncSettings(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(LucideIcons.calendar),
              text: 'Próximos',
            ),
            Tab(
              icon: Icon(LucideIcons.clock),
              text: 'Hoje',
            ),
            Tab(
              icon: Icon(LucideIcons.refreshCw),
              text: 'Sincronia',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingEventsTab(context),
          _buildTodayEventsTab(context),
          _buildSyncTab(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEventDialog(context),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildUpcomingEventsTab(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final upcomingEvents = _events
        .where((event) => event.startTime.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (upcomingEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.calendar,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum evento próximo',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seus próximos compromissos aparecerão aqui',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upcomingEvents.length,
      itemBuilder: (context, index) {
        final event = upcomingEvents[index];
        return CalendarEventCard(
          event: event,
          onTap: () => _showEventDetails(context, event),
          onEdit: () => _editEvent(context, event),
        );
      },
    );
  }

  Widget _buildTodayEventsTab(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final todayEvents = _events
        .where((event) =>
            event.startTime.year == today.year &&
            event.startTime.month == today.month &&
            event.startTime.day == today.day)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (todayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.clock,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum evento hoje',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aproveite seu dia livre!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: todayEvents.length,
      itemBuilder: (context, index) {
        final event = todayEvents[index];
        return CalendarEventCard(
          event: event,
          onTap: () => _showEventDetails(context, event),
          onEdit: () => _editEvent(context, event),
          isToday: true,
        );
      },
    );
  }

  Widget _buildSyncTab(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sincronização de Calendários',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conecte seus calendários externos para sincronização automática',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          
          CalendarSyncWidget(
            provider: CalendarProvider.google,
            isConnected: _isGoogleSynced,
            isLoading: _isLoading,
            onConnect: _syncWithGoogle,
            onDisconnect: () => setState(() => _isGoogleSynced = false),
          ),
          
          const SizedBox(height: 16),
          
          CalendarSyncWidget(
            provider: CalendarProvider.outlook,
            isConnected: _isOutlookSynced,
            isLoading: _isLoading,
            onConnect: _syncWithOutlook,
            onDisconnect: () => setState(() => _isOutlookSynced = false),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.info,
                      size: 20,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sobre a Sincronização',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Eventos LITIG-1 são automaticamente sincronizados\n'
                  '• Sincronização bidirecional mantém tudo atualizado\n'
                  '• Eventos incluem detalhes do caso e lembretes\n'
                  '• Seguro e criptografado via Unipile',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSyncSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações de Agenda',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(LucideIcons.refreshCw),
              title: const Text('Sincronizar agora'),
              subtitle: const Text('Atualizar todos os calendários'),
              onTap: () {
                Navigator.pop(context);
                _loadEvents();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.settings),
              title: const Text('Preferências de notificação'),
              subtitle: const Text('Configurar lembretes'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar configurações de notificação
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.download),
              title: const Text('Exportar calendário'),
              subtitle: const Text('Baixar eventos em PDF'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar exportação
              },
            ),
          ],
        ),
      );
      },
    );
  }

  void _showEventDetails(BuildContext context, CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description?.isNotEmpty == true) ...[
              Text(event.description!),
              const SizedBox(height: 16),
            ],
            _buildEventDetailRow(context, LucideIcons.clock, 'Horário',
                '${_formatDateTime(event.startTime)} - ${_formatTime(event.endTime)}'),
            if (event.location?.isNotEmpty == true)
              _buildEventDetailRow(context, LucideIcons.mapPin, 'Local', event.location!),
            if (event.caseNumber?.isNotEmpty == true)
              _buildEventDetailRow(context, LucideIcons.fileText, 'Processo', event.caseNumber!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          if (event.caseId != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/case-detail/${event.caseId}');
              },
              child: const Text('Ver Caso'),
            ),
        ],
      ),
    );
  }

  Widget _buildEventDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _editEvent(BuildContext context, CalendarEvent event) {
    // TODO: Implementar edição de eventos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edição de eventos em desenvolvimento')),
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    // TODO: Implementar criação de eventos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Criação de eventos em desenvolvimento')),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} às ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Models para eventos de calendário
class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final CalendarEventType type;
  final String? caseId;
  final String? caseNumber;
  final EventUrgency urgency;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.type,
    this.caseId,
    this.caseNumber,
    this.urgency = EventUrgency.media,
  });
}

enum CalendarEventType {
  audiencia,
  consulta,
  prazo,
  reuniao,
  outros,
}

enum EventUrgency {
  baixa,
  media,
  alta,
  critica,
}

enum CalendarProvider {
  google,
  outlook,
}