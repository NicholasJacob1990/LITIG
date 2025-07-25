import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/utils/app_colors.dart';
import '../../domain/entities/lawyer_metrics.dart';
import '../../data/datasources/lawyer_cases_enhanced_data_source.dart';
import '../widgets/lawyer_case_card_enhanced.dart';
import '../widgets/sections/client_profile_section.dart';

/// Página de demonstração para testar os componentes de casos dos advogados
class LawyerCasesDemoPage extends StatefulWidget {
  const LawyerCasesDemoPage({super.key});

  @override
  State<LawyerCasesDemoPage> createState() => _LawyerCasesDemoPageState();
}

class _LawyerCasesDemoPageState extends State<LawyerCasesDemoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<String> _lawyerRoles = [
    'lawyer_associated',
    'lawyer_platform_associate',
    'lawyer_individual',
    'lawyer_office',
  ];
  
  final List<String> _roleLabels = [
    'Associado',
    'Super Associado',
    'Autônomo',
    'Escritório',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _lawyerRoles.length, vsync: this);
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
        title: const Text('Demo: Casos dos Advogados'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: _roleLabels
              .map((label) => Tab(
                    text: label,
                    icon: Icon(_getRoleIcon(label)),
                  ))
              .toList(),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _lawyerRoles.map((role) => _buildRoleTab(role)).toList(),
      ),
    );
  }

  Widget _buildRoleTab(String role) {
    final cases = LawyerCasesEnhancedDataSource.getMockCasesForLawyer(
      lawyerId: 'demo_lawyer',
      lawyerRole: role,
    );

    return RefreshIndicator(
      onRefresh: () async {
        // Simular refresh
        await Future.delayed(const Duration(seconds: 1));
        setState(() {});
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildRoleHeader(role),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final caseData = cases[index];
                return Column(
                  children: [
                    LawyerCaseCardEnhanced(
                      caseId: caseData.caseId,
                      title: caseData.title,
                      status: caseData.status,
                      caseType: caseData.caseType ?? 'litigation',
                      clientInfo: caseData.clientInfo,
                      metrics: caseData.metrics,
                      userRole: role,
                      onTap: () => _showCaseDetail(caseData, role),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
              childCount: cases.length,
            ),
          ),
          if (cases.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.folderOpen,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Nenhum caso encontrado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoleHeader(String role) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getRoleIcon(_getRoleLabel(role)),
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getRoleLabel(role),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getRoleDescription(role),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRoleFeatures(role),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleFeatures(String role) {
    List<String> features;
    
    switch (role) {
      case 'lawyer_associated':
        features = [
          'Casos delegados internamente',
          'Métricas de aprendizado',
          'Avaliação do supervisor',
          'Desenvolvimento de habilidades',
        ];
        break;
      case 'lawyer_platform_associate':
        features = [
          'Casos via algoritmo (exclusivo)',
          'Score de match algorítmico',
          'Performance otimizada',
          'Sem aba de parcerias',
        ];
        break;
      case 'lawyer_individual':
        features = [
          'Casos via algoritmo + captação direta',
          'Aba "Meus Casos" + "Parcerias"',
          'Métricas de competição',
          'ROI e valor do caso',
        ];
        break;
      case 'lawyer_office':
        features = [
          'Casos via algoritmo + diretos + parcerias',
          'Gestão de equipe',
          'Colaboração com outros escritórios',
          'Métricas de sinergia',
        ];
        break;
      default:
        features = [];
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: features
          .map((feature) => Chip(
                label: Text(
                  feature,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
              ))
          .toList(),
    );
  }

  void _showCaseDetail(EnhancedCaseData caseData, String role) {
    final matchContext = LawyerCasesEnhancedDataSource.getMatchContext(
      caseId: caseData.caseId,
      userRole: role,
      metrics: caseData.metrics,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caseData.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Status: ${caseData.status}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ClientProfileSection(
                        clientInfo: caseData.clientInfo,
                        matchContext: matchContext,
                        onContactClient: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Abrindo conversa com o cliente...'),
                            ),
                          );
                        },
                        onViewClientHistory: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Carregando histórico do cliente...'),
                            ),
                          );
                        },
                      ),
                      if (caseData.metrics != null) ...[
                        const SizedBox(height: 24),
                        _buildMetricsDetail(caseData.metrics!, role),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsDetail(LawyerMetrics metrics, String role) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  LucideIcons.barChart3,
                  color: AppColors.primaryBlue,
                ),
                SizedBox(width: 8),
                Text(
                  'Métricas Detalhadas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSpecificMetricsDetail(metrics, role),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificMetricsDetail(LawyerMetrics metrics, String role) {
    if (metrics is AssociateLawyerMetrics) {
      return _buildAssociateMetricsDetail(metrics);
    } else if (metrics is IndependentLawyerMetrics) {
      return _buildIndependentMetricsDetail(metrics, role);
    } else if (metrics is OfficeLawyerMetrics) {
      return _buildOfficeMetricsDetail(metrics);
    }
    return const SizedBox.shrink();
  }

  Widget _buildAssociateMetricsDetail(AssociateLawyerMetrics metrics) {
    return Column(
      children: [
        _buildMetricRow('Tempo Investido', '${metrics.timeInvested.inHours}h'),
        _buildMetricRow('Tempo Restante', '${metrics.estimatedRemaining.inHours}h'),
        _buildMetricRow('Avaliação Supervisor', metrics.supervisorRating.toStringAsFixed(1)),
        _buildMetricRow('Pontos de Aprendizado', '${metrics.learningPoints}'),
        _buildMetricRow('Supervisor', metrics.supervisorName),
        _buildMetricRow('Progresso', '${metrics.completionPercentage.toStringAsFixed(1)}%'),
        _buildMetricRow('Tarefas Concluídas', '${metrics.tasksCompleted}/${metrics.tasksTotal}'),
      ],
    );
  }

  Widget _buildIndependentMetricsDetail(IndependentLawyerMetrics metrics, String role) {
    return Column(
      children: [
        if (metrics.matchScore > 0)
          _buildMetricRow('Score de Match', '${metrics.matchScore.toStringAsFixed(1)}%'),
        _buildMetricRow('Probabilidade de Sucesso', '${(metrics.successProbability * 100).toStringAsFixed(1)}%'),
        _buildMetricRow('Valor do Caso', 'R\$ ${metrics.caseValue.toStringAsFixed(2)}'),
        if (metrics.competitorCount > 0)
          _buildMetricRow('Competidores', '${metrics.competitorCount}'),
        _buildMetricRow('Diferencial', metrics.differentiator),
        _buildMetricRow('Fonte do Caso', metrics.caseSource.displayName),
        _buildMetricRow('Receita Projetada', 'R\$ ${metrics.revenueProjection.toStringAsFixed(2)}'),
        _buildMetricRow('Prazo Estimado', '${metrics.timeToClosePrediction.toStringAsFixed(0)} dias'),
      ],
    );
  }

  Widget _buildOfficeMetricsDetail(OfficeLawyerMetrics metrics) {
    return Column(
      children: [
        _buildMetricRow('Parceiro', metrics.partnership.partnerName),
        _buildMetricRow('Tipo de Parceria', metrics.partnership.partnerType),
        _buildMetricRow('Divisão de Receita', '${metrics.revenueShare.toStringAsFixed(1)}%'),
        _buildMetricRow('Score de Colaboração', '${metrics.collaborationScore.toStringAsFixed(1)}%'),
        _buildMetricRow('Índice de Sinergia', '${metrics.synergyIndex.toStringAsFixed(1)}%'),
        _buildMetricRow('Membros da Equipe', '${metrics.teamMembers}'),
        _buildMetricRow('Margem de Lucro', '${metrics.profitMargin.toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String roleLabel) {
    switch (roleLabel) {
      case 'Associado':
        return LucideIcons.graduationCap;
      case 'Super Associado':
        return LucideIcons.crown;
      case 'Autônomo':
        return LucideIcons.user;
      case 'Escritório':
        return LucideIcons.building;
      default:
        return LucideIcons.user;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'lawyer_associated':
        return 'Associado';
      case 'lawyer_platform_associate':
        return 'Super Associado';
      case 'lawyer_individual':
        return 'Autônomo';
      case 'lawyer_office':
        return 'Escritório';
      default:
        return 'Advogado';
    }
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'lawyer_associated':
        return 'Casos delegados internamente pelo supervisor';
      case 'lawyer_platform_associate':
        return 'Casos exclusivos via algoritmo da plataforma';
      case 'lawyer_individual':
        return 'Casos via algoritmo e captação direta';
      case 'lawyer_office':
        return 'Casos via algoritmo, diretos e parcerias';
      default:
        return 'Casos jurídicos';
    }
  }
} 
 