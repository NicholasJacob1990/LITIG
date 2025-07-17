import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/sla_audit_entity.dart';
import '../bloc/sla_settings_bloc.dart';
import '../bloc/sla_settings_event.dart';
import '../bloc/sla_settings_state.dart';

class SlaAuditWidget extends StatefulWidget {
  const SlaAuditWidget({Key? key}) : super(key: key);

  @override
  State<SlaAuditWidget> createState() => _SlaAuditWidgetState();
}

class _SlaAuditWidgetState extends State<SlaAuditWidget> {
  String _selectedEventType = 'all';
  String _selectedSeverity = 'all';
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  bool _enableIntegrityCheck = true;
  bool _enableComplianceTracking = true;
  bool _enableAutoExport = false;
  
  final TextEditingController _searchController = TextEditingController();
  final List<SlaAuditEntity> _auditEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
    _loadAuditEvents();
  }

  void _loadAuditEvents() {
    // Load mock audit events for demonstration
    final mockEvents = [
      SlaAuditEntity.settingsChange(
        id: 'audit_1',
        firmId: 'current_firm',
        userId: 'user_1',
        description: 'Alteração nos tempos de resposta SLA',
        metadata: {'old_value': '48h', 'new_value': '24h'},
      ),
      SlaAuditEntity.violation(
        id: 'audit_2',
        firmId: 'current_firm',
        userId: 'user_2',
        description: 'Violação de SLA detectada para caso #12345',
        metadata: {'case_id': '12345', 'deadline': '2025-01-15 18:00'},
      ),
      SlaAuditEntity.escalation(
        id: 'audit_3',
        firmId: 'current_firm',
        userId: 'system',
        description: 'Escalação automática executada',
        metadata: {'escalation_level': '2', 'reason': 'timeout'},
      ),
    ];
    
    setState(() => _auditEvents.addAll(mockEvents));
  }

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
              _buildComplianceOverview(),
              const SizedBox(height: 24),
              _buildAuditFilters(),
              const SizedBox(height: 24),
              _buildAuditSettings(),
              const SizedBox(height: 24),
              _buildAuditTrail(),
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
            Icon(Icons.security, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'Auditoria SLA',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Monitore a conformidade, visualize logs de auditoria e mantenha a rastreabilidade completa.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildComplianceOverview() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Visão Geral de Compliance',
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
                  child: _buildComplianceCard(
                    'Score Geral',
                    '94%',
                    Icons.score,
                    Colors.green,
                    subtitle: 'Excelente',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildComplianceCard(
                    'Eventos Críticos',
                    '2',
                    Icons.warning,
                    Colors.orange,
                    subtitle: 'Últimos 7 dias',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildComplianceCard(
                    'Integridade',
                    '100%',
                    Icons.verified,
                    Colors.blue,
                    subtitle: 'Verificado',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildComplianceCard(
                    'Auditoria',
                    'Ativa',
                    Icons.visibility,
                    Colors.purple,
                    subtitle: 'Rastreamento',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sistema em conformidade com LGPD, ISO 27001 e regulamentações da OAB.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditFilters() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros de Auditoria',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar eventos',
                      hintText: 'Digite palavras-chave...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    value: _selectedEventType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Todos')),
                      DropdownMenuItem(value: 'settings_change', child: Text('Configuração')),
                      DropdownMenuItem(value: 'violation', child: Text('Violação')),
                      DropdownMenuItem(value: 'escalation', child: Text('Escalação')),
                      DropdownMenuItem(value: 'override', child: Text('Override')),
                      DropdownMenuItem(value: 'system', child: Text('Sistema')),
                    ],
                    onChanged: (value) => setState(() => _selectedEventType = value!),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    value: _selectedSeverity,
                    decoration: const InputDecoration(
                      labelText: 'Severidade',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Todas')),
                      DropdownMenuItem(value: 'low', child: Text('Baixa')),
                      DropdownMenuItem(value: 'medium', child: Text('Média')),
                      DropdownMenuItem(value: 'high', child: Text('Alta')),
                      DropdownMenuItem(value: 'critical', child: Text('Crítica')),
                    ],
                    onChanged: (value) => setState(() => _selectedSeverity = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDateRange,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range, size: 16),
                          const SizedBox(width: 8),
                          Text(_formatDateRange()),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _applyFilters,
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Aplicar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Limpar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Configurações de Auditoria',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Verificação de Integridade'),
              subtitle: const Text('Verificar hash de integridade dos eventos'),
              value: _enableIntegrityCheck,
              onChanged: (value) => setState(() => _enableIntegrityCheck = value),
            ),
            SwitchListTile(
              title: const Text('Rastreamento de Compliance'),
              subtitle: const Text('Monitorar conformidade com regulamentações'),
              value: _enableComplianceTracking,
              onChanged: (value) => setState(() => _enableComplianceTracking = value),
            ),
            SwitchListTile(
              title: const Text('Exportação Automática'),
              subtitle: const Text('Exportar logs automaticamente (mensal)'),
              value: _enableAutoExport,
              onChanged: (value) => setState(() => _enableAutoExport = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditTrail() {
    final filteredEvents = _getFilteredEvents();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Trilha de Auditoria',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filteredEvents.length} eventos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (filteredEvents.isEmpty)
              _buildEmptyAuditTrail()
            else
              ...filteredEvents.take(10).map((event) => _buildAuditEventItem(event)),
            if (filteredEvents.length > 10) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => _showAllEvents(),
                  child: Text('Ver todos os ${filteredEvents.length} eventos'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAuditTrail() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum evento encontrado',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajuste os filtros para ver mais eventos.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditEventItem(SlaAuditEntity event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getEventTypeColor(event.eventType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getEventTypeIcon(event.eventType),
              color: _getEventTypeColor(event.eventType),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.description,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(event.severity).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getSeverityLabel(event.severity),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getSeverityColor(event.severity),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      event.userId,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatEventTime(event.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_enableIntegrityCheck) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.verified,
                        size: 12,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verificado',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEventDetails(event),
            icon: const Icon(Icons.info_outline, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _exportAuditLog(),
            icon: const Icon(Icons.download),
            label: const Text('Exportar Log'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _generateComplianceReport(),
            icon: const Icon(Icons.assessment),
            label: const Text('Relatório Compliance'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _verifyIntegrity(),
            icon: const Icon(Icons.security),
            label: const Text('Verificar Integridade'),
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getEventTypeColor(String eventType) {
    switch (eventType) {
      case 'settings_change':
        return Colors.blue;
      case 'violation':
        return Colors.red;
      case 'escalation':
        return Colors.orange;
      case 'override':
        return Colors.purple;
      case 'system':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventTypeIcon(String eventType) {
    switch (eventType) {
      case 'settings_change':
        return Icons.settings;
      case 'violation':
        return Icons.warning;
      case 'escalation':
        return Icons.trending_up;
      case 'override':
        return Icons.admin_panel_settings;
      case 'system':
        return Icons.computer;
      default:
        return Icons.event;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getSeverityLabel(String severity) {
    switch (severity) {
      case 'low':
        return 'BAIXA';
      case 'medium':
        return 'MÉDIA';
      case 'high':
        return 'ALTA';
      case 'critical':
        return 'CRÍTICA';
      default:
        return 'N/A';
    }
  }

  String _formatDateRange() {
    if (_selectedDateRange == null) return 'Selecionar período';
    return '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - '
        '${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}';
  }

  String _formatEventTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d atrás';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h atrás';
    } else {
      return '${diff.inMinutes}m atrás';
    }
  }

  List<SlaAuditEntity> _getFilteredEvents() {
    var filtered = _auditEvents.where((event) {
      // Filter by event type
      if (_selectedEventType != 'all' && event.eventType != _selectedEventType) {
        return false;
      }
      
      // Filter by severity
      if (_selectedSeverity != 'all' && event.severity != _selectedSeverity) {
        return false;
      }
      
      // Filter by date range
      if (_selectedDateRange != null) {
        if (event.timestamp.isBefore(_selectedDateRange!.start) ||
            event.timestamp.isAfter(_selectedDateRange!.end)) {
          return false;
        }
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!event.description.toLowerCase().contains(query) &&
            !event.userId.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Sort by timestamp (newest first)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return filtered;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _applyFilters() {
    // Filters are applied automatically through _getFilteredEvents()
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filtros aplicados')),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedEventType = 'all';
      _selectedSeverity = 'all';
      _searchQuery = '';
      _searchController.clear();
      _selectedDateRange = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      );
    });
  }

  void _showAllEvents() {
    // TODO: Navigate to full audit log page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegando para log completo...')),
    );
  }

  void _showEventDetails(SlaAuditEntity event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalhes do Evento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Tipo', event.eventType),
            _buildDetailRow('Descrição', event.description),
            _buildDetailRow('Usuário', event.userId),
            _buildDetailRow('Severidade', event.severity),
            _buildDetailRow('Timestamp', event.timestamp.toString()),
            if (event.metadata.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Metadados:', style: Theme.of(context).textTheme.labelMedium),
              ...event.metadata.entries.map((e) => _buildDetailRow(e.key, e.value.toString())),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _exportAuditLog() {
    context.read<SlaSettingsBloc>().add(
      ExportSlaAuditLogEvent(
        dateRange: _selectedDateRange!,
        format: 'pdf',
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportando log de auditoria...')),
    );
  }

  void _generateComplianceReport() {
    context.read<SlaSettingsBloc>().add(
      GenerateSlaComplianceReportEvent(
        dateRange: _selectedDateRange!,
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gerando relatório de compliance...')),
    );
  }

  void _verifyIntegrity() {
    context.read<SlaSettingsBloc>().add(
      VerifySlaIntegrityEvent(),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verificando integridade dos dados...')),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/sla_audit_entity.dart';
import '../bloc/sla_settings_bloc.dart';
import '../bloc/sla_settings_event.dart';
import '../bloc/sla_settings_state.dart';

class SlaAuditWidget extends StatefulWidget {
  const SlaAuditWidget({Key? key}) : super(key: key);

  @override
  State<SlaAuditWidget> createState() => _SlaAuditWidgetState();
}

class _SlaAuditWidgetState extends State<SlaAuditWidget> {
  String _selectedEventType = 'all';
  String _selectedSeverity = 'all';
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  bool _enableIntegrityCheck = true;
  bool _enableComplianceTracking = true;
  bool _enableAutoExport = false;
  
  final TextEditingController _searchController = TextEditingController();
  final List<SlaAuditEntity> _auditEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
    _loadAuditEvents();
  }

  void _loadAuditEvents() {
    // Load mock audit events for demonstration
    final mockEvents = [
      SlaAuditEntity.settingsChange(
        id: 'audit_1',
        firmId: 'current_firm',
        userId: 'user_1',
        description: 'Alteração nos tempos de resposta SLA',
        metadata: {'old_value': '48h', 'new_value': '24h'},
      ),
      SlaAuditEntity.violation(
        id: 'audit_2',
        firmId: 'current_firm',
        userId: 'user_2',
        description: 'Violação de SLA detectada para caso #12345',
        metadata: {'case_id': '12345', 'deadline': '2025-01-15 18:00'},
      ),
      SlaAuditEntity.escalation(
        id: 'audit_3',
        firmId: 'current_firm',
        userId: 'system',
        description: 'Escalação automática executada',
        metadata: {'escalation_level': '2', 'reason': 'timeout'},
      ),
    ];
    
    setState(() => _auditEvents.addAll(mockEvents));
  }

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
              _buildComplianceOverview(),
              const SizedBox(height: 24),
              _buildAuditFilters(),
              const SizedBox(height: 24),
              _buildAuditSettings(),
              const SizedBox(height: 24),
              _buildAuditTrail(),
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
            Icon(Icons.security, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              'Auditoria SLA',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Monitore a conformidade, visualize logs de auditoria e mantenha a rastreabilidade completa.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildComplianceOverview() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Visão Geral de Compliance',
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
                  child: _buildComplianceCard(
                    'Score Geral',
                    '94%',
                    Icons.score,
                    Colors.green,
                    subtitle: 'Excelente',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildComplianceCard(
                    'Eventos Críticos',
                    '2',
                    Icons.warning,
                    Colors.orange,
                    subtitle: 'Últimos 7 dias',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildComplianceCard(
                    'Integridade',
                    '100%',
                    Icons.verified,
                    Colors.blue,
                    subtitle: 'Verificado',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildComplianceCard(
                    'Auditoria',
                    'Ativa',
                    Icons.visibility,
                    Colors.purple,
                    subtitle: 'Rastreamento',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sistema em conformidade com LGPD, ISO 27001 e regulamentações da OAB.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditFilters() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros de Auditoria',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar eventos',
                      hintText: 'Digite palavras-chave...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    value: _selectedEventType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Todos')),
                      DropdownMenuItem(value: 'settings_change', child: Text('Configuração')),
                      DropdownMenuItem(value: 'violation', child: Text('Violação')),
                      DropdownMenuItem(value: 'escalation', child: Text('Escalação')),
                      DropdownMenuItem(value: 'override', child: Text('Override')),
                      DropdownMenuItem(value: 'system', child: Text('Sistema')),
                    ],
                    onChanged: (value) => setState(() => _selectedEventType = value!),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    value: _selectedSeverity,
                    decoration: const InputDecoration(
                      labelText: 'Severidade',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Todas')),
                      DropdownMenuItem(value: 'low', child: Text('Baixa')),
                      DropdownMenuItem(value: 'medium', child: Text('Média')),
                      DropdownMenuItem(value: 'high', child: Text('Alta')),
                      DropdownMenuItem(value: 'critical', child: Text('Crítica')),
                    ],
                    onChanged: (value) => setState(() => _selectedSeverity = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDateRange,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range, size: 16),
                          const SizedBox(width: 8),
                          Text(_formatDateRange()),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _applyFilters,
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Aplicar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Limpar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Configurações de Auditoria',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Verificação de Integridade'),
              subtitle: const Text('Verificar hash de integridade dos eventos'),
              value: _enableIntegrityCheck,
              onChanged: (value) => setState(() => _enableIntegrityCheck = value),
            ),
            SwitchListTile(
              title: const Text('Rastreamento de Compliance'),
              subtitle: const Text('Monitorar conformidade com regulamentações'),
              value: _enableComplianceTracking,
              onChanged: (value) => setState(() => _enableComplianceTracking = value),
            ),
            SwitchListTile(
              title: const Text('Exportação Automática'),
              subtitle: const Text('Exportar logs automaticamente (mensal)'),
              value: _enableAutoExport,
              onChanged: (value) => setState(() => _enableAutoExport = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditTrail() {
    final filteredEvents = _getFilteredEvents();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Trilha de Auditoria',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filteredEvents.length} eventos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (filteredEvents.isEmpty)
              _buildEmptyAuditTrail()
            else
              ...filteredEvents.take(10).map((event) => _buildAuditEventItem(event)),
            if (filteredEvents.length > 10) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => _showAllEvents(),
                  child: Text('Ver todos os ${filteredEvents.length} eventos'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAuditTrail() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum evento encontrado',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajuste os filtros para ver mais eventos.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditEventItem(SlaAuditEntity event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getEventTypeColor(event.eventType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getEventTypeIcon(event.eventType),
              color: _getEventTypeColor(event.eventType),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.description,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(event.severity).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getSeverityLabel(event.severity),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getSeverityColor(event.severity),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      event.userId,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatEventTime(event.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_enableIntegrityCheck) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.verified,
                        size: 12,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verificado',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEventDetails(event),
            icon: const Icon(Icons.info_outline, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _exportAuditLog(),
            icon: const Icon(Icons.download),
            label: const Text('Exportar Log'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _generateComplianceReport(),
            icon: const Icon(Icons.assessment),
            label: const Text('Relatório Compliance'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _verifyIntegrity(),
            icon: const Icon(Icons.security),
            label: const Text('Verificar Integridade'),
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getEventTypeColor(String eventType) {
    switch (eventType) {
      case 'settings_change':
        return Colors.blue;
      case 'violation':
        return Colors.red;
      case 'escalation':
        return Colors.orange;
      case 'override':
        return Colors.purple;
      case 'system':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventTypeIcon(String eventType) {
    switch (eventType) {
      case 'settings_change':
        return Icons.settings;
      case 'violation':
        return Icons.warning;
      case 'escalation':
        return Icons.trending_up;
      case 'override':
        return Icons.admin_panel_settings;
      case 'system':
        return Icons.computer;
      default:
        return Icons.event;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getSeverityLabel(String severity) {
    switch (severity) {
      case 'low':
        return 'BAIXA';
      case 'medium':
        return 'MÉDIA';
      case 'high':
        return 'ALTA';
      case 'critical':
        return 'CRÍTICA';
      default:
        return 'N/A';
    }
  }

  String _formatDateRange() {
    if (_selectedDateRange == null) return 'Selecionar período';
    return '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - '
        '${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}';
  }

  String _formatEventTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d atrás';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h atrás';
    } else {
      return '${diff.inMinutes}m atrás';
    }
  }

  List<SlaAuditEntity> _getFilteredEvents() {
    var filtered = _auditEvents.where((event) {
      // Filter by event type
      if (_selectedEventType != 'all' && event.eventType != _selectedEventType) {
        return false;
      }
      
      // Filter by severity
      if (_selectedSeverity != 'all' && event.severity != _selectedSeverity) {
        return false;
      }
      
      // Filter by date range
      if (_selectedDateRange != null) {
        if (event.timestamp.isBefore(_selectedDateRange!.start) ||
            event.timestamp.isAfter(_selectedDateRange!.end)) {
          return false;
        }
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!event.description.toLowerCase().contains(query) &&
            !event.userId.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Sort by timestamp (newest first)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return filtered;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _applyFilters() {
    // Filters are applied automatically through _getFilteredEvents()
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filtros aplicados')),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedEventType = 'all';
      _selectedSeverity = 'all';
      _searchQuery = '';
      _searchController.clear();
      _selectedDateRange = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      );
    });
  }

  void _showAllEvents() {
    // TODO: Navigate to full audit log page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegando para log completo...')),
    );
  }

  void _showEventDetails(SlaAuditEntity event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalhes do Evento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Tipo', event.eventType),
            _buildDetailRow('Descrição', event.description),
            _buildDetailRow('Usuário', event.userId),
            _buildDetailRow('Severidade', event.severity),
            _buildDetailRow('Timestamp', event.timestamp.toString()),
            if (event.metadata.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Metadados:', style: Theme.of(context).textTheme.labelMedium),
              ...event.metadata.entries.map((e) => _buildDetailRow(e.key, e.value.toString())),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _exportAuditLog() {
    context.read<SlaSettingsBloc>().add(
      ExportSlaAuditLogEvent(
        dateRange: _selectedDateRange!,
        format: 'pdf',
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportando log de auditoria...')),
    );
  }

  void _generateComplianceReport() {
    context.read<SlaSettingsBloc>().add(
      GenerateSlaComplianceReportEvent(
        dateRange: _selectedDateRange!,
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gerando relatório de compliance...')),
    );
  }

  void _verifyIntegrity() {
    context.read<SlaSettingsBloc>().add(
      VerifySlaIntegrityEvent(),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verificando integridade dos dados...')),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 