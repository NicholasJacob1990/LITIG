import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:meu_app/src/features/admin/presentation/bloc/admin_event.dart';
import 'package:meu_app/src/features/admin/presentation/bloc/admin_state.dart';
import 'package:meu_app/src/features/admin/domain/entities/admin_audit_log.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';

/// Tela de Auditoria Administrativa
/// 
/// Exibe logs de atividades e eventos do sistema para controle de segurança
class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  String _selectedSeverity = 'Todos';
  String _selectedAction = 'Todas';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _severityLevels = ['Todos', 'Baixo', 'Médio', 'Alto', 'Crítico'];
  final List<String> _actionTypes = ['Todas', 'Login', 'Logout', 'Criação', 'Edição', 'Exclusão', 'Acesso'];

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const LoadAdminAuditLogs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs de Auditoria'),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filtrar logs',
          ),
          IconButton(
            icon: const Icon(LucideIcons.download),
            onPressed: () => _exportAuditLogs(context),
            tooltip: 'Exportar logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros ativos
          _buildActiveFilters(),
          
          // Lista de logs
          Expanded(
            child: BlocBuilder<AdminBloc, AdminState>(
              builder: (context, state) {
                if (state is AdminLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AdminError) {
                  return _buildErrorState(context, state.message);
                }

                if (state is AdminAuditLogsLoaded) {
                  return _buildAuditLogsList(context, state.auditLogs);
                }

                return _buildEmptyState(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    final hasFilters = _selectedSeverity != 'Todos' || 
                      _selectedAction != 'Todas' || 
                      _startDate != null || 
                      _endDate != null;

    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.filter,
            size: 16,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filtros ativos: ${_getActiveFiltersText()}',
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  String _getActiveFiltersText() {
    final filters = <String>[];
    
    if (_selectedSeverity != 'Todos') filters.add('Severidade: $_selectedSeverity');
    if (_selectedAction != 'Todas') filters.add('Ação: $_selectedAction');
    if (_startDate != null) filters.add('De: ${_formatDate(_startDate!)}');
    if (_endDate != null) filters.add('Até: ${_formatDate(_endDate!)}');
    
    return filters.join(', ');
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _clearFilters() {
    setState(() {
      _selectedSeverity = 'Todos';
      _selectedAction = 'Todas';
      _startDate = null;
      _endDate = null;
    });
    context.read<AdminBloc>().add(const LoadAdminAuditLogs());
  }

  Widget _buildAuditLogsList(BuildContext context, List<AdminAuditLog> auditLogs) {
    final filteredLogs = _filterAuditLogs(auditLogs);

    if (filteredLogs.isEmpty) {
      return _buildNoResultsState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        final log = filteredLogs[index];
        return _buildAuditLogCard(context, log);
      },
    );
  }

  List<AdminAuditLog> _filterAuditLogs(List<AdminAuditLog> logs) {
    return logs.where((log) {
      // Filtro por severidade
      if (_selectedSeverity != 'Todos' && log.severity != _selectedSeverity) {
        return false;
      }
      
      // Filtro por ação
      if (_selectedAction != 'Todas' && !log.action.contains(_selectedAction)) {
        return false;
      }
      
      // Filtro por data
      if (_startDate != null && log.timestamp.isBefore(_startDate!)) {
        return false;
      }
      
      if (_endDate != null && log.timestamp.isAfter(_endDate!.add(const Duration(days: 1)))) {
        return false;
      }
      
      return true;
    }).toList();
  }

  Widget _buildAuditLogCard(BuildContext context, AdminAuditLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com ação e severidade
            Row(
              children: [
                _buildSeverityBadge(log.severity ?? 'medium'),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    log.action,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _formatDateTime(log.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Detalhes do usuário
            if (log.userInfo['name'] != null) ...[
              Row(
                children: [
                  Icon(
                    LucideIcons.user,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${log.userInfo['name']} (${log.userInfo['email']})',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            
            // IP e localização
            Row(
              children: [
                Icon(
                  LucideIcons.globe,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '${log.ipAddress} - Localização desconhecida',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            // Detalhes adicionais
            if (log.details != null && log.details!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.details?.toString() ?? 'Nenhum detalhe disponível',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            
            // Status de sucesso
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  log.isSuccessful ? LucideIcons.checkCircle : LucideIcons.xCircle,
                  size: 16,
                  color: log.isSuccessful ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  log.isSuccessful ? 'Sucesso' : 'Falha',
                  style: TextStyle(
                    color: log.isSuccessful ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color color;
    IconData icon;
    
    switch (severity.toLowerCase()) {
      case 'crítico':
        color = Colors.red;
        icon = LucideIcons.alertTriangle;
        break;
      case 'alto':
        color = Colors.orange;
        icon = LucideIcons.alertCircle;
        break;
      case 'médio':
        color = Colors.yellow;
        icon = LucideIcons.info;
        break;
      case 'baixo':
        color = Colors.blue;
        icon = LucideIcons.checkCircle;
        break;
      default:
        color = Colors.grey;
        icon = LucideIcons.circle;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            severity,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Logs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filtro por severidade
            DropdownButtonFormField<String>(
              value: _selectedSeverity,
              decoration: const InputDecoration(
                labelText: 'Severidade',
                border: OutlineInputBorder(),
              ),
              items: _severityLevels.map((severity) => DropdownMenuItem(
                value: severity,
                child: Text(severity),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSeverity = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Filtro por ação
            DropdownButtonFormField<String>(
              value: _selectedAction,
              decoration: const InputDecoration(
                labelText: 'Tipo de Ação',
                border: OutlineInputBorder(),
              ),
              items: _actionTypes.map((action) => DropdownMenuItem(
                value: action,
                child: Text(action),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAction = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Filtro por data
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    icon: const Icon(LucideIcons.calendar),
                    label: Text(_startDate != null 
                      ? _formatDate(_startDate!) 
                      : 'Data inicial'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    icon: const Icon(LucideIcons.calendar),
                    label: Text(_endDate != null 
                      ? _formatDate(_endDate!) 
                      : 'Data final'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AdminBloc>().add(const LoadAdminAuditLogs());
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _exportAuditLogs(BuildContext context) {
    // TODO: Implementar exportação de logs
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportação de logs em desenvolvimento'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.searchX,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum log encontrado',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros aplicados',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 64,
            color: Colors.red.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar logs',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<AdminBloc>().add(const LoadAdminAuditLogs()),
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.shield,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum log de auditoria',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Os logs de auditoria aparecerão aqui',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 