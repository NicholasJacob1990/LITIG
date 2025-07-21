import 'package:flutter/material.dart';
import '../../domain/entities/case_detail.dart';
import '../../domain/entities/contextual_case_data.dart';
import '../../domain/entities/allocation_type.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../shared/utils/app_colors.dart';
import '../../../../core/utils/logger.dart';

// Widgets da experiência atual do cliente (manter intactos)
import 'lawyer_responsible_section.dart';
import 'consultation_info_section.dart';
import 'pre_analysis_section.dart';
import 'next_steps_section.dart';
import 'documents_section.dart';
import 'process_status_section.dart';
import 'litigation_parties_section.dart'; // NOVO: Seção de partes processuais

// Seções contextuais especializadas
import 'sections/internal_team_section.dart';
import 'sections/case_assignment_section.dart';
import 'sections/business_opportunity_section.dart';
import 'sections/platform_opportunity_section.dart';
import 'sections/client_contact_section.dart';
import 'sections/case_complexity_section.dart';
import 'sections/match_explanation_section.dart';
import 'sections/task_breakdown_section.dart';
import 'sections/time_tracking_section.dart';
import 'sections/work_documents_section.dart';
import 'sections/strategic_documents_section.dart';
import 'sections/platform_documents_section.dart';
import 'sections/delivery_framework_section.dart';
import 'sections/profitability_section.dart';
import 'sections/quality_control_section.dart';
import 'sections/escalation_section.dart';
import 'sections/competitor_analysis_section.dart';
import 'sections/next_opportunities_section.dart';

/// Factory principal para seções contextuais da tela de detalhes do caso
/// 
/// **Arquitetura:** Factory Pattern + Clean Architecture
/// **Performance:** Lazy loading e cache para carregamento < 2s
/// **Compatibilidade:** Zero regressão para clientes
/// 
/// Responsabilidade:
/// - Para clientes: manter experiência EXATA atual (zero regressão)
/// - Para advogados: criar seções contextuais baseadas no allocation_type
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md
class ContextualCaseDetailSectionFactory {
  // Cache de seções para evitar rebuilds desnecessários
  static final Map<String, List<Widget>> _sectionCache = {};
  
  /// Constrói seções apropriadas baseadas no perfil do usuário e contexto do caso
  /// 
  /// **Performance optimizada:**
  /// - Cache de seções por chave
  /// - Lazy loading de seções pesadas
  /// - Fallback rápido para experiência do cliente
  static List<Widget> buildSectionsForUser({
    required User currentUser,
    required CaseDetail? caseDetail,
    required ContextualCaseData? contextualData,
  }) {
    final stopwatch = Stopwatch()..start();
    
    AppLogger.info('Building sections for user role: ${currentUser.role}, allocation: ${contextualData?.allocationType}');
    
    final cacheKey = _buildCacheKey(currentUser, caseDetail, contextualData);
    
    // Verificar cache primeiro para performance
    if (_sectionCache.containsKey(cacheKey)) {
      stopwatch.stop();
      AppLogger.debug('Using cached sections (${stopwatch.elapsedMilliseconds}ms)');
      return _sectionCache[cacheKey]!;
    }
    
    List<Widget> sections;
    
    // **CLIENTE: Manter experiência atual INTACTA**
    if (_isClient(currentUser.role)) {
      sections = _buildClientSections(caseDetail);
    } else {
      // **ADVOGADOS: Usar contexto + allocation_type**
      if (contextualData != null && caseDetail != null) {
        sections = _buildLawyerSections(
          userRole: currentUser.role ?? '',
          allocationType: contextualData.allocationType,
          caseDetail: caseDetail,
          contextualData: contextualData,
        );
      } else {
        // **FALLBACK: Experiência padrão do cliente**
        AppLogger.warning('No contextual data available, falling back to client sections');
        sections = _buildClientSections(caseDetail);
      }
    }
    
    // Cache para próximas utilizações
    _sectionCache[cacheKey] = sections;
    
    stopwatch.stop();
    AppLogger.info('Sections built in ${stopwatch.elapsedMilliseconds}ms');
    
    return sections;
  }
  
  /// **EXPERIÊNCIA DO CLIENTE - MANTER INTACTA**
  /// Esta é a experiência de referência que deve ser preservada 100%
  static List<Widget> _buildClientSections(CaseDetail? caseDetail) {
    AppLogger.info('Building client sections (reference experience)');
    
    List<Widget> sections = [
      // EXPERIÊNCIA ATUAL DO CLIENTE - NÃO ALTERAR
      const LazySection(
        priority: SectionPriority.critical,
        child: LawyerResponsibleSection(),
      ),
      const SizedBox(height: 16),
      const LazySection(
        priority: SectionPriority.high,
        child: ConsultationInfoSection(),
      ),
      const SizedBox(height: 16),
      const LazySection(
        priority: SectionPriority.high,
        child: PreAnalysisSection(),
      ),
      const SizedBox(height: 16),
      
      // NOVO: Seção de partes processuais (apenas para casos contenciosos)
      if (caseDetail?.isLitigation == true && caseDetail!.parties.isNotEmpty)
        LazySection(
          priority: SectionPriority.high,
          child: LitigationPartiesSection(
            parties: caseDetail.parties,
            title: 'Partes do Processo',
          ),
        ),
      if (caseDetail?.isLitigation == true && caseDetail!.parties.isNotEmpty)
        const SizedBox(height: 16),
      
      const LazySection(
        priority: SectionPriority.medium,
        child: NextStepsSection(),
      ),
      const SizedBox(height: 16),
      const LazySection(
        priority: SectionPriority.medium,
        child: DocumentsSection(),
      ),
      const SizedBox(height: 16),
      const LazySection(
        priority: SectionPriority.low,
        child: ProcessStatusSection(),
      ),
      const SizedBox(height: 24), // Espaço extra no final
    ];
    
    return sections;
  }
  
  /// **EXPERIÊNCIA DOS ADVOGADOS - CONTEXTUAL**
  /// Retorna seções específicas baseadas no role + allocation_type
  static List<Widget> _buildLawyerSections(
    {required String userRole, 
    required AllocationType allocationType, 
    required CaseDetail caseDetail, 
    required ContextualCaseData contextualData}
  ) {
    AppLogger.info('Building lawyer sections for role: $userRole, allocation: $allocationType');
    
    switch (allocationType) {
      case AllocationType.internalDelegation:
        return _buildAssociatedLawyerSections(caseDetail, contextualData);
      case AllocationType.platformMatchDirect:
        if (_isSuperAssociate(userRole)) {
          return _buildSuperAssociateSections(caseDetail, contextualData);
        } else {
          return _buildContractingLawyerSections(caseDetail, contextualData);
        }
      case AllocationType.partnershipProactiveSearch:
      case AllocationType.partnershipPlatformSuggestion:
        return _buildPartnershipSections(caseDetail, contextualData);
      default:
        return _buildDefaultLawyerSections(caseDetail, contextualData);
    }
  }
  
  /// **ADVOGADO ASSOCIADO** - Foco em produtividade e tarefas internas
  static List<Widget> _buildAssociatedLawyerSections(
    CaseDetail caseDetail, 
    ContextualCaseData contextualData
  ) {
    return [
      // Seções críticas carregadas imediatamente
      LazySection(
        priority: SectionPriority.critical,
        child: InternalTeamSection(
          caseDetail: caseDetail,
          contextualData: contextualData.toMap(),
        ),
      ),
      const SizedBox(height: 16),
      LazySection(
        priority: SectionPriority.critical,
        child: CaseAssignmentSection(
          caseDetail: caseDetail,
          contextualData: contextualData?.toMap(),
        ),
      ),
      const SizedBox(height: 16),
      
      // Seções importantes carregadas em seguida
      LazySection(
        priority: SectionPriority.high,
        child: TaskBreakdownSection(
          caseDetail: caseDetail,
          contextualData: contextualData.toMap(),
        ),
      ),
      const SizedBox(height: 16),
      LazySection(
        priority: SectionPriority.high,
        child: WorkDocumentsSection(
          caseDetail: caseDetail,
          contextualData: contextualData.toMap(),
        ),
      ),
      const SizedBox(height: 16),
      
      // Seções menos críticas carregadas por último
      LazySection(
        priority: SectionPriority.medium,
        child: TimeTrackingSection(
          caseDetail: caseDetail,
          contextualData: contextualData.toMap(),
        ),
      ),
      const SizedBox(height: 16),
      LazySection(
        priority: SectionPriority.low,
        child: EscalationSection(
          caseDetail: caseDetail,
        ),
      ),
      const SizedBox(height: 24),
    ];
  }
  
  /// **ADVOGADO CONTRATANTE** - Foco em oportunidade de negócio
  static List<Widget> _buildContractingLawyerSections(
    CaseDetail caseDetail, 
    ContextualCaseData contextualData
  ) {
    return [
      // Informações essenciais do cliente primeiro
      LazySection(
        priority: SectionPriority.critical,
        child: ClientContactSection(
          caseDetail: caseDetail,
          contextualData: contextualData.toMap(),
        ),
      ),
      const SizedBox(height: 16),
      LazySection(
        priority: SectionPriority.critical,
        child: BusinessOpportunitySection(
          caseDetail: caseDetail,
          contextualData: contextualData.toMap(),
        ),
      ),
      const SizedBox(height: 16),
      
      // Análises técnicas
      LazySection(
        priority: SectionPriority.high,
        child: CaseComplexitySection(
          caseDetail: caseDetail,
          contextualData: contextualData.toMap(),
        ),
      ),
      const SizedBox(height: 16),
      LazySection(
        priority: SectionPriority.high,
        child: MatchExplanationSection(
          caseDetail: caseDetail,
          contextualData: contextualData.toMap(),
        ),
      ),
      const SizedBox(height: 16),
      
      // Gestão e estratégia
      LazySection(
        priority: SectionPriority.medium,
        child: StrategicDocumentsSection(
          caseDetail: caseDetail,
          contextualData: contextualData.toMap(),
        ),
      ),
      const SizedBox(height: 16),
      LazySection(
        priority: SectionPriority.medium,
        child: ProfitabilitySection(
          caseDetail: caseDetail,
          contextualData: contextualData.toMap(),
        ),
      ),
      const SizedBox(height: 16),
      
      // Análises avançadas (lazy loading pesado)
      LazySection(
        priority: SectionPriority.low,
        child: CompetitorAnalysisSection(
          caseDetail: caseDetail,
        ),
      ),
      const SizedBox(height: 24),
    ];
  }
  
  /// **SUPER ASSOCIADO** - Foco em performance na plataforma
  static List<Widget> _buildSuperAssociateSections(
    CaseDetail caseDetail, 
    ContextualCaseData contextualData
  ) {
    return [
      // Informações da plataforma primeiro
      LazySection(
        priority: SectionPriority.critical,
        child: PlatformOpportunitySection(
          caseDetail: caseDetail,
          contextualData: contextualData.toMap(),
        ),
      ),
      const SizedBox(height: 16),
      LazySection(
        priority: SectionPriority.critical,
        child: MatchExplanationSection(
          caseDetail: caseDetail,
          contextualData: contextualData.toMap(),
        ),
      ),
      const SizedBox(height: 16),
      
      // Framework e processos
      LazySection(
        priority: SectionPriority.high,
        child: DeliveryFrameworkSection(
          caseDetail: caseDetail,
          contextualData: contextualData.toMap(),
        ),
      ),
      const SizedBox(height: 16),
      LazySection(
        priority: SectionPriority.high,
        child: PlatformDocumentsSection(
          caseDetail: caseDetail,
          contextualData: contextualData.toMap(),
        ),
      ),
      const SizedBox(height: 16),
      
      // Qualidade e controle
      LazySection(
        priority: SectionPriority.medium,
        child: QualityControlSection(
          caseDetail: caseDetail,
        ),
      ),
      const SizedBox(height: 16),
      
      // Oportunidades futuras (menor prioridade)
      LazySection(
        priority: SectionPriority.low,
        child: NextOpportunitiesSection(
          caseDetail: caseDetail,
        ),
      ),
      const SizedBox(height: 24),
    ];
  }
  
  /// **PARCERIAS** - Foco em colaboração
  static List<Widget> _buildPartnershipSections(
    CaseDetail caseDetail, 
    ContextualCaseData contextualData
  ) {
    return [
      _PlaceholderSection(
        title: 'Informações da Parceria',
        description: 'Parceiro: ${contextualData.partnerName ?? 'N/A'} | Divisão: ${contextualData.yourShare ?? 0}/${contextualData.partnerShare ?? 0}%',
        icon: Icons.handshake,
        color: Colors.purple,
      ),
      const SizedBox(height: 16),
      LazySection(
        priority: SectionPriority.high,
        child: MatchExplanationSection(
          caseDetail: caseDetail,
          contextualData: contextualData.toMap(),
        ),
      ),
      const SizedBox(height: 16),
      const _PlaceholderSection(
        title: 'Documentos Estratégicos',
        description: 'Documentos compartilhados com o parceiro',
        icon: Icons.folder_shared,
        color: Colors.purple,
      ),
      const SizedBox(height: 16),
      const _PlaceholderSection(
        title: 'Análise de Competidores',
        description: 'Estratégia competitiva da parceria',
        icon: Icons.trending_up,
        color: Colors.purple,
      ),
      const SizedBox(height: 24),
    ];
  }
  
  /// **FALLBACK** - Experiência padrão para advogados
  static List<Widget> _buildDefaultLawyerSections(
    CaseDetail caseDetail, 
    ContextualCaseData contextualData
  ) {
    AppLogger.warning('Using default lawyer sections - consider implementing specific allocation type');
    
    return [
      _PlaceholderSection(
        title: 'Informações Gerais',
        description: 'Caso ${caseDetail.id} - ${caseDetail.status}',
        icon: Icons.info_outline,
        color: AppColors.primaryBlue,
      ),
      const SizedBox(height: 16),
      const _PlaceholderSection(
        title: 'Ações Disponíveis',
        description: 'Ações baseadas no contexto do caso',
        icon: Icons.touch_app,
        color: Colors.green,
      ),
      const SizedBox(height: 24),
    ];
  }
  
  // Métodos auxiliares
  
  static bool _isClient(String? role) {
    return role == null || role == 'client' || role == 'CLIENT' || role == 'PF';
  }
  
  static bool _isSuperAssociate(String role) {
    return role == 'lawyer_platform_associate';
  }
  
  static String _buildCacheKey(User user, CaseDetail? caseDetail, ContextualCaseData? contextualData) {
    return '${user.role}_${caseDetail?.id}_${contextualData?.allocationType}';
  }
  
  /// Limpar cache quando necessário (exemplo: mudança de dados)
  static void clearCache() {
    _sectionCache.clear();
    AppLogger.debug('Section cache cleared');
  }
}

/// Widget para lazy loading de seções com prioridade
class LazySection extends StatelessWidget {
  final Widget child;
  final SectionPriority priority;
  
  const LazySection({
    required this.child,
    this.priority = SectionPriority.medium,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    // Para seções críticas, carregar imediatamente
    if (priority == SectionPriority.critical) {
      return child;
    }
    
    // Para outras seções, usar lazy loading
    return FutureBuilder<Widget>(
      future: _loadSection(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!;
        }
        
        if (snapshot.hasError) {
          return _buildErrorSection();
        }
        
        return _buildLoadingSection();
      },
    );
  }
  
  Future<Widget> _loadSection() async {
    // Delay baseado na prioridade
    final delay = _getDelayForPriority(priority);
    await Future.delayed(delay);
    return child;
  }
  
  Duration _getDelayForPriority(SectionPriority priority) {
    switch (priority) {
      case SectionPriority.critical:
        return Duration.zero;
      case SectionPriority.high:
        return const Duration(milliseconds: 50);
      case SectionPriority.medium:
        return const Duration(milliseconds: 150);
      case SectionPriority.low:
        return const Duration(milliseconds: 300);
    }
  }
  
  Widget _buildLoadingSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text(
              'Carregando seção...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(20),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 16),
            Text(
              'Erro ao carregar seção',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prioridades de carregamento das seções
enum SectionPriority {
  critical, // Carrega imediatamente (0ms)
  high,     // Carrega rapidamente (50ms) 
  medium,   // Carrega normalmente (150ms)
  low,      // Carrega por último (300ms)
}

// Widget placeholder para seções não implementadas
class _PlaceholderSection extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _PlaceholderSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
} 
