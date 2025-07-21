import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/lawyer_match_card.dart';
import 'package:meu_app/src/features/firms/presentation/bloc/firm_bloc.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import 'package:meu_app/injection_container.dart';

/// Tela "Ver Equipe Completa" para escritórios
/// 
/// Implementa a funcionalidade crítica identificada na análise:
/// - Navegação: `/firm/:firmId/lawyers`
/// - Perfis individuais completos de cada advogado do escritório
/// - Paridade total com LawyerMatchCard
/// - Opções de contratação individual vs institucional
class FirmTeamScreen extends StatelessWidget {
  final String firmId;

  const FirmTeamScreen({
    super.key,
    required this.firmId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<FirmBloc>()..add(GetFirmDetailsEvent(firmId: firmId)),
      child: FirmTeamView(firmId: firmId),
    );
  }
}

class FirmTeamView extends StatefulWidget {
  final String firmId;

  const FirmTeamView({
    super.key,
    required this.firmId,
  });

  @override
  State<FirmTeamView> createState() => _FirmTeamViewState();
}

class _FirmTeamViewState extends State<FirmTeamView> {
  String? _selectedAreaFilter;
  final List<String> _availableAreas = [
    'Todas as áreas',
    'Direito Civil',
    'Direito Trabalhista',
    'Direito Tributário',
    'Direito Empresarial',
    'Direito Penal',
    'Direito de Família',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipe do Escritório'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            onPressed: () => _shareFirm(context),
            tooltip: 'Compartilhar escritório',
          ),
        ],
      ),
      body: BlocBuilder<FirmBloc, FirmState>(
        builder: (context, state) {
          if (state is FirmLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FirmError) {
            return _buildErrorState(context, state.message);
          }

          if (state is FirmLoaded && state.firm != null) {
            return _buildTeamContent(context, state.firm!);
          }

          return _buildEmptyState(context);
        },
      ),
    );
  }

  Widget _buildTeamContent(BuildContext context, LawFirm firm) {
    // Mock lawyers data - em produção viria do backend
    final teamLawyers = _getMockTeamLawyers(firm);
    final filteredLawyers = _applyAreaFilter(teamLawyers);

    return Column(
      children: [
        // Header do Escritório (resumido)
        _buildFirmHeader(context, firm),
        
        // Filtros por Área Jurídica
        _buildAreaFilters(context),
        
        // Estatísticas da Equipe
        _buildTeamStats(context, firm, teamLawyers),
        
        // Lista de Advogados Individuais
        Expanded(
          child: _buildLawyersList(context, firm, filteredLawyers),
        ),
        
        // Ações da Equipe (bottom bar)
        _buildTeamActions(context, firm),
      ],
    );
  }

  Widget _buildFirmHeader(BuildContext context, LawFirm firm) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo do escritório
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              LucideIcons.building2,
              size: 30,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 16),
          
          // Informações básicas
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firm.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                if (firm.foundedYear != null)
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 14,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${DateTime.now().year - firm.foundedYear!} anos de mercado',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      LucideIcons.users,
                      size: 14,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_getMockTeamLawyers(firm).length} advogados',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Badge de autoridade institucional
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.shield,
                  size: 16,
                  color: AppColors.warning,
                ),
                SizedBox(width: 4),
                Text(
                  '🏛️ Escritório Renomado',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrar por Área Jurídica',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _availableAreas.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final area = _availableAreas[index];
                final isSelected = _selectedAreaFilter == area || 
                                 (_selectedAreaFilter == null && area == 'Todas as áreas');
                
                return FilterChip(
                  label: Text(area),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedAreaFilter = area == 'Todas as áreas' ? null : area;
                    });
                  },
                  backgroundColor: Colors.transparent,
                  selectedColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                  checkmarkColor: AppColors.primaryBlue,
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryBlue : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStats(BuildContext context, LawFirm firm, List<MatchedLawyer> lawyers) {
    final theme = Theme.of(context);
    final avgRating = lawyers.fold<double>(0, (sum, lawyer) => sum + (lawyer.rating ?? 0)) / lawyers.length;
    final avgSuccessRate = lawyers.fold<double>(0, (sum, lawyer) => sum + lawyer.features.successRate) / lawyers.length;
    final totalCases = lawyers.fold<int>(0, (sum, lawyer) => sum + lawyer.reviewCount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estatísticas da Equipe',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                icon: LucideIcons.star,
                label: 'Avaliação Média',
                value: avgRating.toStringAsFixed(1),
                color: AppColors.warning,
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                icon: LucideIcons.checkCircle,
                label: 'Taxa de Êxito',
                value: '${(avgSuccessRate * 100).toInt()}%',
                color: AppColors.success,
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                icon: LucideIcons.briefcase,
                label: 'Total de Casos',
                value: totalCases.toString(),
                color: AppColors.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLawyersList(BuildContext context, LawFirm firm, List<MatchedLawyer> lawyers) {
    if (lawyers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.filter,
                size: 64,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum advogado encontrado',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Tente ajustar os filtros de área jurídica',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<FirmBloc>().add(GetFirmDetailsEvent(firmId: widget.firmId));
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: lawyers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final lawyer = lawyers[index];
          
          return _buildFirmLawyerCard(context, firm, lawyer);
        },
      ),
    );
  }

  Widget _buildFirmLawyerCard(BuildContext context, LawFirm firm, MatchedLawyer lawyer) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Indicação: "Advogado do [Nome do Escritório]"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.building,
                    size: 14,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Advogado do ${firm.name}',
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // LawyerMatchCard completo
            LawyerMatchCard(
              lawyer: lawyer,
              onSelect: () => _handleDirectHiring(context, lawyer, firm),
              onExplain: () => _showLawyerExplanation(context, lawyer),
              // Não mostrar caseId/clientId pois é visualização da equipe
            ),
            
            const SizedBox(height: 12),
            
            // Opção: "Contratar via Escritório" vs "Contrato Direto"
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleFirmHiring(context, lawyer, firm),
                    icon: const Icon(
                      LucideIcons.building2,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                    label: const Text(
                      'Contratar via Escritório',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleDirectHiring(context, lawyer, firm),
                    icon: const Icon(LucideIcons.user, size: 16),
                    label: const Text(
                      'Contrato Direto',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamActions(BuildContext context, LawFirm firm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _handleTeamMeeting(context, firm),
              icon: const Icon(
                LucideIcons.video,
                size: 18,
                color: AppColors.info,
              ),
              label: const Text(
                'Reunião com Equipe',
                style: TextStyle(color: AppColors.info),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.info),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleTeamHiring(context, firm),
              icon: const Icon(LucideIcons.users, size: 18),
              label: const Text('Contratar Equipe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              'Erro ao carregar equipe',
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
              onPressed: () {
                context.read<FirmBloc>().add(GetFirmDetailsEvent(firmId: widget.firmId));
              },
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.users,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Equipe não encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Não foi possível carregar as informações da equipe',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods

  List<MatchedLawyer> _getMockTeamLawyers(LawFirm firm) {
    // Mock data - em produção viria do backend
    return [
      MatchedLawyer(
        id: '${firm.id}_lawyer_1',
        nome: 'Dr. Ana Silva',
        avatarUrl: 'https://example.com/ana.jpg',
        primaryArea: 'Direito Civil',
        specializations: const ['Direito Civil', 'Direito Imobiliário'],
        fair: 0.92,
        equity: 0.88,
        rating: 4.8,
        distanceKm: 0.0, // Mesmo escritório
        reviewCount: 156,
        isAvailable: true,
        features: const LawyerFeatures(
          successRate: 0.89,
          responseTime: 2,
          softSkills: 0.94,
        ),
        awards: const ['Top Lawyer 2023', 'OAB Destaque'],
        experienceYears: 12,
        professionalSummary: 'Especialista em Direito Civil com mais de 12 anos de experiência.',
      ),
      MatchedLawyer(
        id: '${firm.id}_lawyer_2',
        nome: 'Dr. Carlos Oliveira',
        avatarUrl: 'https://example.com/carlos.jpg',
        primaryArea: 'Direito Trabalhista',
        specializations: const ['Direito Trabalhista', 'Direito Sindical'],
        fair: 0.87,
        equity: 0.91,
        rating: 4.6,
        distanceKm: 0.0,
        reviewCount: 203,
        isAvailable: true,
        features: const LawyerFeatures(
          successRate: 0.91,
          responseTime: 1,
          softSkills: 0.88,
        ),
        awards: const ['Advogado do Ano 2022'],
        experienceYears: 15,
        professionalSummary: 'Especialista em questões trabalhistas e sindicais.',
      ),
      MatchedLawyer(
        id: '${firm.id}_lawyer_3',
        nome: 'Dra. Mariana Costa',
        avatarUrl: 'https://example.com/mariana.jpg',
        primaryArea: 'Direito Tributário',
        specializations: const ['Direito Tributário', 'Direito Empresarial'],
        fair: 0.85,
        equity: 0.85,
        rating: 4.7,
        distanceKm: 0.0,
        reviewCount: 98,
        isAvailable: false,
        features: const LawyerFeatures(
          successRate: 0.93,
          responseTime: 3,
          softSkills: 0.91,
        ),
        awards: const ['Especialista Tributário 2023'],
        experienceYears: 8,
        professionalSummary: 'Especialista em planejamento tributário e compliance.',
      ),
    ];
  }

  List<MatchedLawyer> _applyAreaFilter(List<MatchedLawyer> lawyers) {
    if (_selectedAreaFilter == null) return lawyers;
    
    return lawyers.where((lawyer) {
      return lawyer.specializations.contains(_selectedAreaFilter!) ||
             lawyer.primaryArea == _selectedAreaFilter;
    }).toList();
  }

  // Action Handlers

  void _handleDirectHiring(BuildContext context, MatchedLawyer lawyer, LawFirm firm) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contratação direta: ${lawyer.nome}'),
        backgroundColor: AppColors.success,
      ),
    );
    // TODO: Implementar modal de contratação direta
  }

  void _handleFirmHiring(BuildContext context, MatchedLawyer lawyer, LawFirm firm) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contratação via ${firm.name}: ${lawyer.nome}'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
    // TODO: Implementar modal de contratação institucional
  }

  void _handleTeamMeeting(BuildContext context, LawFirm firm) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Agendando reunião com ${firm.name}'),
        backgroundColor: AppColors.info,
      ),
    );
    // TODO: Implementar agendamento de reunião
  }

  void _handleTeamHiring(BuildContext context, LawFirm firm) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contratando equipe completa de ${firm.name}'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
    // TODO: Implementar contratação da equipe completa
  }

  void _showLawyerExplanation(BuildContext context, MatchedLawyer lawyer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Por que ${lawyer.nome}?'),
        content: Text(
          'Este advogado foi recomendado com base em sua experiência de ${lawyer.experienceYears} anos, '
          'taxa de êxito de ${(lawyer.features.successRate * 100).toInt()}% e avaliação de ${lawyer.rating?.toStringAsFixed(1)} estrelas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _shareFirm(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compartilhando informações do escritório...'),
      ),
    );
    // TODO: Implementar compartilhamento
  }
} 