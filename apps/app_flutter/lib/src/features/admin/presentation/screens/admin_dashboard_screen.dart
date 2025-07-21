import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/atoms/custom_card.dart';
import '../../../../shared/widgets/atoms/loading_indicator.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Carregar dados iniciais
    context.read<AdminBloc>().add(const LoadAdminDashboard());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Controladoria Administrativa',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(LucideIcons.pieChart), text: 'Dashboard'),
            Tab(icon: Icon(LucideIcons.users), text: 'Advogados'),
            Tab(icon: Icon(LucideIcons.shield), text: 'Auditoria'),
            Tab(icon: Icon(LucideIcons.settings), text: 'Sistema'),
          ],
        ),
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: LoadingIndicator());
          }
          
          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.alertTriangle,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar dados administrativos',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.lightText2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<AdminBloc>().add(const LoadAdminDashboard());
                    },
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardTab(context, state),
              _buildLawyersTab(context, state),
              _buildAuditTab(context, state),
              _buildSystemTab(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboardTab(BuildContext context, AdminState state) {
    if (state is! AdminDashboardLoaded) {
      return const Center(child: Text('Dados não carregados'));
    }

    final data = state.dashboardData;
    final sistema = data.sistema;
    final qualidadeDados = data.qualidadeDados;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AdminBloc>().add(const LoadAdminDashboard());
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Métricas Gerais
            Text(
              'Visão Geral do Sistema',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Advogados',
                    value: sistema['total_advogados']?.toString() ?? '0',
                    icon: LucideIcons.briefcase,
                    color: AppColors.primaryBlue,
                    subtitle: '+${sistema['usuarios_novos_30d'] ?? 0} este mês',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Clientes',
                    value: sistema['total_clientes']?.toString() ?? '0',
                    icon: LucideIcons.users,
                    color: AppColors.success,
                    subtitle: 'Usuários ativos',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Casos',
                    value: sistema['total_casos']?.toString() ?? '0',
                    icon: LucideIcons.fileText,
                    color: AppColors.warning,
                    subtitle: '+${sistema['casos_novos_30d'] ?? 0} este mês',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Qualidade',
                    value: '${((qualidadeDados['sync_coverage'] ?? 0) * 100).round()}%',
                    icon: LucideIcons.checkCircle,
                    color: AppColors.info,
                    subtitle: 'Cobertura de dados',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Qualidade de Dados
            Text(
              'Qualidade dos Dados',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.database,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sincronização de Dados',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildDataQualityRow(
                      'Advogados Sincronizados',
                      qualidadeDados['synced_lawyers']?.toString() ?? '0',
                      qualidadeDados['total_lawyers']?.toString() ?? '0',
                    ),
                    
                    _buildDataQualityRow(
                      'Dados de Alta Qualidade',
                      qualidadeDados['high_quality_data']?.toString() ?? '0',
                      qualidadeDados['synced_lawyers']?.toString() ?? '0',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    LinearProgressIndicator(
                      value: (qualidadeDados['sync_coverage'] ?? 0).toDouble(),
                      backgroundColor: AppColors.lightTextSecondary.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Última sincronização: ${_formatDateTime(qualidadeDados['last_sync'])}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.lightText2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Ações Rápidas
            Text(
              'Ações Administrativas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    title: 'Sincronizar Dados',
                    icon: LucideIcons.refreshCw,
                    color: AppColors.primaryBlue,
                    onTap: () {
                      _showSyncConfirmation(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    title: 'Relatório Completo',
                    icon: LucideIcons.fileBarChart,
                    color: AppColors.success,
                    onTap: () {
                      context.read<AdminBloc>().add(const GenerateExecutiveReport(
                        reportType: 'monthly',
                        dateRange: {'month': 11},
                      ));
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 80), // Espaço para navegação inferior
          ],
        ),
      ),
    );
  }

  Widget _buildLawyersTab(BuildContext context, AdminState state) {
    return const Center(
      child: Text(
        'Gestão de Advogados\n(Em desenvolvimento)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: AppColors.lightText2,
        ),
      ),
    );
  }

  Widget _buildAuditTab(BuildContext context, AdminState state) {
    return const Center(
      child: Text(
        'Auditoria de Dados\n(Em desenvolvimento)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: AppColors.lightText2,
        ),
      ),
    );
  }

  Widget _buildSystemTab(BuildContext context, AdminState state) {
    return const Center(
      child: Text(
        'Configurações do Sistema\n(Em desenvolvimento)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: AppColors.lightText2,
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.lightText2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.lightText2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataQualityRow(String label, String value, String total) {
    final percentage = total != '0' 
        ? ((int.tryParse(value) ?? 0) / (int.tryParse(total) ?? 1) * 100).round()
        : 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.lightText,
            ),
          ),
          Text(
            '$value/$total ($percentage%)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.lightText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSyncConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sincronizar Dados'),
        content: const Text(
          'Esta ação irá sincronizar todos os dados dos advogados com as APIs externas. '
          'O processo pode levar alguns minutos. Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminBloc>().add(const ForceGlobalSync());
              _showSyncStartedSnackbar(context);
            },
            child: const Text('Sincronizar'),
          ),
        ],
      ),
    );
  }

  void _showSyncStartedSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Sincronização iniciada...'),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    
    try {
      final DateTime parsed = DateTime.parse(dateTime.toString());
      return '${parsed.day.toString().padLeft(2, '0')}/'
             '${parsed.month.toString().padLeft(2, '0')}/'
             '${parsed.year} às '
             '${parsed.hour.toString().padLeft(2, '0')}:'
             '${parsed.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Data inválida';
    }
  }
} 