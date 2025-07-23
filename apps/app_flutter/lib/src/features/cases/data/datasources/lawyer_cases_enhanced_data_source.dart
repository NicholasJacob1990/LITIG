import 'dart:core';
import '../../domain/entities/client_info.dart';
import '../../domain/entities/lawyer_metrics.dart';
import '../../domain/entities/allocation_type.dart';
import '../../../../core/utils/logger.dart';

/// Classe para agrupar todos os dados de um caso melhorado
class EnhancedCaseData {
  final String caseId;
  final String title;
  final String status;
  final String caseType;
  final ClientInfo clientInfo;
  final LawyerMetrics? metrics;

  const EnhancedCaseData({
    required this.caseId,
    required this.title,
    required this.status,
    required this.caseType,
    required this.clientInfo,
    this.metrics,
  });
}

/// Data source mock para casos dos advogados com dados contextuais
class LawyerCasesEnhancedDataSource {
  /// Retorna dados mock completos para teste dos novos componentes
  static List<EnhancedCaseData> getMockCasesForLawyer({
    required String lawyerId,
    required String lawyerRole,
  }) {
    AppLogger.info('Loading enhanced cases for lawyer $lawyerId with role $lawyerRole');

    switch (lawyerRole) {
      case 'lawyer_associated':
        return _getAssociateCases(lawyerId);
      case 'lawyer_platform_associate':
        return _getSuperAssociateCases(lawyerId);
      case 'lawyer_individual':
      case 'lawyer_office':
        return _getContractorCases(lawyerId);
      default:
        return [];
    }
  }

  /// Casos para Advogados Associados (Delegação Interna)
  static List<EnhancedCaseData> _getAssociateCases(String lawyerId) {
    return [
      EnhancedCaseData(
        caseId: 'case_associate_1',
        title: 'Rescisão Indireta - Assédio Moral',
        status: 'Em Andamento',
        caseType: 'Divórcio',
        clientInfo: const ClientInfo(
          id: 'client_1',
          name: 'Maria Silva',
          type: 'PF',
          email: 'maria.silva@email.com',
          phone: '(11) 99999-1111',
          riskScore: 25.0,
          previousCases: 1,
          averageRating: 4.8,
          paymentReliability: 95.0,
          preferredCommunication: 'whatsapp',
          averageResponseTimeHours: 4,
          specialNeeds: ['Acessibilidade', 'Urgência médica'],
          preferredLanguage: 'pt-BR',
          status: ClientStatus.active,
          budgetRangeMin: 2000.0,
          budgetRangeMax: 5000.0,
          decisionMaker: 'Maria Silva',
          isDecisionMaker: true,
          interests: ['Trabalhista', 'Previdenciário'],
          expansionPotential: 60.0,
          referralSource: 'Indicação',
          lastInteraction: null,
          industry: null,
          companySize: null,
          companyStage: null,
        ),
        metrics: AssociateLawyerMetrics(
          caseId: 'case_associate_1',
          lastUpdated: DateTime.now(),
          timeInvested: const Duration(hours: 45),
          estimatedRemaining: const Duration(hours: 60),
          supervisorRating: 4.2,
          learningPoints: 85,
          skillsToImprove: const [
            Skill(
              name: 'Redação Petições',
              category: 'Técnica',
              currentLevel: 3,
              targetLevel: 4,
              description: 'Melhorar clareza e objetividade',
              improvementActions: ['Curso técnico', 'Revisão com supervisor'],
            ),
          ],
          completionPercentage: 75.0,
          delegatorFeedback: const ['Boa evolução', 'Precisa melhorar prazos'],
          tasksCompleted: 12,
          tasksTotal: 16,
          billableHours: 42.5,
          supervisorName: 'Dr. João Santos',
        ),
      ),
    ];
  }

  /// Casos para Super Associados (Via Algoritmo)
  static List<EnhancedCaseData> _getSuperAssociateCases(String lawyerId) {
    return [
      EnhancedCaseData(
        caseId: 'case_super_1',
        title: 'Multa de Trânsito Indevida',
        status: 'Em Andamento',
        caseType: 'Trânsito',
        clientInfo: const ClientInfo(
          id: 'client_3',
          name: 'Carlos Oliveira',
          type: 'PF',
          email: 'carlos.oliveira@email.com',
          phone: '(11) 88888-2222',
          riskScore: 15.0,
          previousCases: 0,
          averageRating: 0.0,
          paymentReliability: 100.0,
          preferredCommunication: 'phone',
          averageResponseTimeHours: 2,
          specialNeeds: [],
          preferredLanguage: 'pt-BR',
          status: ClientStatus.active,
          budgetRangeMin: 500.0,
          budgetRangeMax: 1000.0,
          decisionMaker: 'Carlos Oliveira',
          isDecisionMaker: true,
          interests: ['Trânsito', 'Administrativo'],
          expansionPotential: 30.0,
          referralSource: 'Algoritmo',
          lastInteraction: null,
          industry: null,
          companySize: null,
          companyStage: null,
        ),
        metrics: IndependentLawyerMetrics(
          caseId: 'case_super_1',
          lastUpdated: DateTime.now(),
          matchScore: 92.5,
          successProbability: 0.85,
          caseValue: 500.0,
          competitorCount: 0,
          differentiator: 'Especialista em trânsito',
          clientSatisfactionPrediction: 4.7,
          strengthAreas: const ['Experiência similar', 'Localização próxima'],
          riskFactors: const ['Cliente novo'],
          timeToClosePrediction: 45.0,
          revenueProjection: 750.0,
          caseSource: CaseSource.algorithm,
        ),
      ),
    ];
  }

  /// Casos para Contratantes (Algoritmo + Captação Direta)
  static List<EnhancedCaseData> _getContractorCases(String lawyerId) {
    return [
      EnhancedCaseData(
        caseId: 'case_contractor_1',
        title: 'Divórcio Consensual',
        status: 'Em Andamento',
        caseType: 'Divórcio',
        clientInfo: const ClientInfo(
          id: 'client_5',
          name: 'Roberto e Patricia Lima',
          type: 'PF',
          email: 'roberto.lima@email.com',
          phone: '(11) 66666-4444',
          riskScore: 20.0,
          previousCases: 1,
          averageRating: 4.9,
          paymentReliability: 98.0,
          preferredCommunication: 'email',
          averageResponseTimeHours: 6,
          specialNeeds: ['Filhos menores'],
          preferredLanguage: 'pt-BR',
          status: ClientStatus.active,
          budgetRangeMin: 3000.0,
          budgetRangeMax: 8000.0,
          decisionMaker: 'Roberto Lima',
          isDecisionMaker: true,
          interests: ['Família', 'Divórcio'],
          expansionPotential: 70.0,
          referralSource: 'Algoritmo',
          lastInteraction: null,
          industry: null,
          companySize: null,
          companyStage: null,
        ),
        metrics: IndependentLawyerMetrics(
          caseId: 'case_contractor_1',
          lastUpdated: DateTime.now(),
          matchScore: 94.0,
          successProbability: 0.95,
          caseValue: 5000.0,
          competitorCount: 2,
          differentiator: 'Especialista em família',
          clientSatisfactionPrediction: 4.9,
          strengthAreas: const ['Experiência', 'Avaliações positivas'],
          riskFactors: const ['Questão patrimonial complexa'],
          timeToClosePrediction: 90.0,
          revenueProjection: 7500.0,
          caseSource: CaseSource.algorithm,
        ),
      ),
    ];
  }

  /// Retorna contexto do match baseado no tipo de alocação
  static String getMatchContext({
    required String caseId,
    required String userRole,
    required LawyerMetrics? metrics,
  }) {
    if (metrics == null) return 'Informações não disponíveis';

    switch (userRole) {
      case 'lawyer_associated':
        return 'Caso delegado internamente pelo supervisor para desenvolvimento de habilidades específicas';
      
      case 'lawyer_platform_associate':
        if (metrics is IndependentLawyerMetrics) {
          return 'Match de ${metrics.matchScore.toStringAsFixed(1)}% baseado em experiência similar e localização. Algoritmo identificou alta compatibilidade com seu perfil.';
        }
        return 'Caso atribuído via algoritmo da plataforma';
      
      case 'lawyer_individual':
      case 'lawyer_office':
        if (metrics is IndependentLawyerMetrics) {
          if (metrics.caseSource == CaseSource.algorithm) {
            return 'Match de ${metrics.matchScore.toStringAsFixed(1)}% via algoritmo. Cliente escolheu você entre ${metrics.competitorCount} opções.';
          } else {
            return 'Cliente captado via ${metrics.caseSource.displayName}. Relacionamento direto estabelecido.';
          }
        } else if (metrics is OfficeLawyerMetrics) {
          return 'Caso obtido via parceria com ${metrics.partnership.partnerName}. Divisão: ${metrics.revenueShare.toStringAsFixed(0)}% / ${metrics.partnership.partnerShare.toStringAsFixed(0)}%';
        }
        return 'Caso contratado diretamente';
      
      default:
        return 'Informações não disponíveis';
    }
  }
}