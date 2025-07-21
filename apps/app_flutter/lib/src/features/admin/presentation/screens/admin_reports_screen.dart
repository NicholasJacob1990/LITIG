import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:meu_app/src/features/admin/presentation/bloc/admin_event.dart';
import 'package:meu_app/src/features/admin/presentation/bloc/admin_state.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';

/// Tela de Relatórios Administrativos
/// 
/// Permite gerar e visualizar relatórios executivos do sistema
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedReportType = 'Executivo';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  final List<String> _reportTypes = [
    'Executivo',
    'Financeiro',
    'Usuários',
    'Casos',
    'Performance',
    'Segurança',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => _showReportSettings(context),
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminError) {
            return _buildErrorState(context, state.message);
          }

          if (state is AdminReportGenerated) {
            return _buildReportContent(context, state.reportUrl);
          }

          return _buildReportsList(context);
        },
      ),
    );
  }

  Widget _buildReportsList(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),
          
          const SizedBox(height: 24),
          
          // Relatórios disponíveis
          _buildAvailableReports(context),
          
          const SizedBox(height: 24),
          
          // Relatórios recentes
          _buildRecentReports(context),
          
          const SizedBox(height: 24),
          
          // Ações rápidas
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.fileText,
            size: 32,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relatórios Executivos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gere relatórios detalhados sobre o sistema',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableReports(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relatórios Disponíveis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: _reportTypes.length,
          itemBuilder: (context, index) {
            final reportType = _reportTypes[index];
            return _buildReportCard(context, reportType);
          },
        ),
      ],
    );
  }

  Widget _buildReportCard(BuildContext context, String reportType) {
    IconData icon;
    Color color;
    String description;

    switch (reportType) {
      case 'Executivo':
        icon = LucideIcons.barChart3;
        color = Colors.blue;
        description = 'Visão geral do sistema';
        break;
      case 'Financeiro':
        icon = LucideIcons.dollarSign;
        color = Colors.green;
        description = 'Dados financeiros e receita';
        break;
      case 'Usuários':
        icon = LucideIcons.users;
        color = Colors.purple;
        description = 'Estatísticas de usuários';
        break;
      case 'Casos':
        icon = LucideIcons.briefcase;
        color = Colors.orange;
        description = 'Análise de casos';
        break;
      case 'Performance':
        icon = LucideIcons.activity;
        color = Colors.red;
        description = 'Métricas de performance';
        break;
      case 'Segurança':
        icon = LucideIcons.shield;
        color = Colors.indigo;
        description = 'Logs de segurança';
        break;
      default:
        icon = LucideIcons.fileText;
        color = Colors.grey;
        description = 'Relatório padrão';
    }

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _generateReport(context, reportType),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const Spacer(),
                  Icon(
                    LucideIcons.arrowRight,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                reportType,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReports(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relatórios Recentes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Lista de relatórios recentes (mock)
        _buildRecentReportItem(
          context,
          'Relatório Executivo - Janeiro 2025',
          'Executivo',
          DateTime.now().subtract(const Duration(days: 2)),
          '2.3 MB',
        ),
        _buildRecentReportItem(
          context,
          'Análise Financeira - Dezembro 2024',
          'Financeiro',
          DateTime.now().subtract(const Duration(days: 15)),
          '1.8 MB',
        ),
        _buildRecentReportItem(
          context,
          'Relatório de Usuários - Q4 2024',
          'Usuários',
          DateTime.now().subtract(const Duration(days: 30)),
          '3.1 MB',
        ),
      ],
    );
  }

  Widget _buildRecentReportItem(
    BuildContext context,
    String title,
    String type,
    DateTime date,
    String size,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getReportTypeColor(type).withValues(alpha: 0.1),
          child: Icon(
            _getReportTypeIcon(type),
            color: _getReportTypeColor(type),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${_formatDate(date)} • $size',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(LucideIcons.moreVertical),
          onSelected: (value) => _handleReportAction(context, value, title),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(LucideIcons.download),
                  SizedBox(width: 8),
                  Text('Baixar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(LucideIcons.share2),
                  SizedBox(width: 8),
                  Text('Compartilhar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(LucideIcons.trash2),
                  SizedBox(width: 8),
                  Text('Excluir'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getReportTypeColor(String type) {
    switch (type) {
      case 'Executivo':
        return Colors.blue;
      case 'Financeiro':
        return Colors.green;
      case 'Usuários':
        return Colors.purple;
      case 'Casos':
        return Colors.orange;
      case 'Performance':
        return Colors.red;
      case 'Segurança':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getReportTypeIcon(String type) {
    switch (type) {
      case 'Executivo':
        return LucideIcons.barChart3;
      case 'Financeiro':
        return LucideIcons.dollarSign;
      case 'Usuários':
        return LucideIcons.users;
      case 'Casos':
        return LucideIcons.briefcase;
      case 'Performance':
        return LucideIcons.activity;
      case 'Segurança':
        return LucideIcons.shield;
      default:
        return LucideIcons.fileText;
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _generateReport(context, 'Executivo'),
                icon: const Icon(LucideIcons.fileText),
                label: const Text('Relatório Executivo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showReportSettings(context),
                icon: const Icon(LucideIcons.settings),
                label: const Text('Configurar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _generateReport(BuildContext context, String reportType) {
    context.read<AdminBloc>().add(GenerateExecutiveReport(
      reportType: reportType,
      dateRange: {'month': DateTime.now().month},
    ));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gerando relatório $reportType...'),
        backgroundColor: AppColors.info,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showReportSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações de Relatório'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tipo de relatório
            DropdownButtonFormField<String>(
              value: _selectedReportType,
              decoration: const InputDecoration(
                labelText: 'Tipo de Relatório',
                border: OutlineInputBorder(),
              ),
              items: _reportTypes.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReportType = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Período
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
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
                    label: Text('De: ${_formatDate(_startDate)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
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
                    label: Text('Até: ${_formatDate(_endDate)}'),
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
              _generateReport(context, _selectedReportType);
            },
            child: const Text('Gerar'),
          ),
        ],
      ),
    );
  }

  void _handleReportAction(BuildContext context, String action, String reportTitle) {
    switch (action) {
      case 'download':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Baixando $reportTitle...'),
            backgroundColor: AppColors.success,
          ),
        );
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Compartilhando $reportTitle...'),
            backgroundColor: AppColors.info,
          ),
        );
        break;
      case 'delete':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excluindo $reportTitle...'),
            backgroundColor: AppColors.error,
          ),
        );
        break;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildReportContent(BuildContext context, String reportUrl) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.checkCircle,
            size: 64,
            color: Colors.green.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Relatório Gerado com Sucesso!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'O relatório está disponível para download',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implementar download do relatório
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download iniciado...'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(LucideIcons.download),
            label: const Text('Baixar Relatório'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
            'Erro ao gerar relatório',
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
            onPressed: () => context.read<AdminBloc>().add(const GenerateExecutiveReport(
              reportType: 'executive',
              dateRange: {'month': 11},
            )),
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }
} 