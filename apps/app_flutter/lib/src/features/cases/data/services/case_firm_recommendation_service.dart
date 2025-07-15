import '../../domain/entities/case.dart';
import '../../../firms/domain/entities/law_firm.dart';
import '../../../firms/domain/usecases/get_firms.dart';

/// Serviço para integração de recomendações de escritórios em casos
/// 
/// Este serviço é responsável por identificar casos que devem receber
/// recomendações de escritórios e aplicar o algoritmo de matching B2B.
class CaseFirmRecommendationService {
  final GetFirms getFirms;

  CaseFirmRecommendationService({required this.getFirms});

  /// Enriquece uma lista de casos com recomendações de escritórios
  /// 
  /// Para casos corporativos ou de alta complexidade, busca escritórios
  /// especializados e aplica o algoritmo de matching.
  Future<List<Case>> enrichCasesWithFirmRecommendations(List<Case> cases) async {
    final enrichedCases = <Case>[];

    for (final caseItem in cases) {
      if (caseItem.shouldShowFirmRecommendation) {
        final enrichedCase = await _enrichCaseWithFirmRecommendation(caseItem);
        enrichedCases.add(enrichedCase);
      } else {
        enrichedCases.add(caseItem);
      }
    }

    return enrichedCases;
  }

  /// Enriquece um caso específico com recomendação de escritório
  Future<Case> _enrichCaseWithFirmRecommendation(Case caseItem) async {
    try {
      // Buscar escritórios especializados
      final firmsResult = await getFirms(GetFirmsParams(
        limit: 10,
        offset: 0,
        includeKpis: true,
        includeLawyersCount: true,
        // Filtros específicos para casos corporativos
        minTeamSize: caseItem.isHighComplexity ? 5 : 3,
        minSuccessRate: 0.7,
      ));

      return firmsResult.fold(
        (failure) => caseItem, // Retorna caso original se falhar
        (firms) => _selectBestFirmForCase(caseItem, firms),
      );
    } catch (e) {
      // Em caso de erro, retorna o caso original
      return caseItem;
    }
  }

  /// Seleciona o melhor escritório para um caso específico
  /// 
  /// Aplica algoritmo de matching simplificado baseado em:
  /// - Tamanho da equipe
  /// - Taxa de sucesso
  /// - Especialização (inferida do tipo do caso)
  Case _selectBestFirmForCase(Case caseItem, List<LawFirm> firms) {
    if (firms.isEmpty) return caseItem;

    // Calcular score para cada escritório
    final firmScores = firms.map((firm) => _calculateFirmScore(caseItem, firm)).toList();
    
    // Encontrar o melhor score
    var bestIndex = 0;
    var bestScore = firmScores[0];
    
    for (int i = 1; i < firmScores.length; i++) {
      if (firmScores[i] > bestScore) {
        bestScore = firmScores[i];
        bestIndex = i;
      }
    }

    final bestFirm = firms[bestIndex];

    return Case.withRecommendedFirm(
      originalCase: caseItem,
      recommendedFirm: bestFirm,
      matchScore: bestScore,
    );
  }

  /// Calcula score de matching entre um caso e um escritório
  /// 
  /// Algoritmo simplificado baseado em:
  /// - Tamanho da equipe (40%)
  /// - Taxa de sucesso (35%)
  /// - Complexidade do caso vs capacidade do escritório (25%)
  double _calculateFirmScore(Case caseItem, LawFirm firm) {
    double score = 0.0;

    // 1. Score do tamanho da equipe (40%)
    final teamSizeScore = _calculateTeamSizeScore(caseItem, firm);
    score += teamSizeScore * 0.4;

    // 2. Score da taxa de sucesso (35%)
    final successRateScore = _calculateSuccessRateScore(firm);
    score += successRateScore * 0.35;

    // 3. Score de complexidade/capacidade (25%)
    final complexityScore = _calculateComplexityScore(caseItem, firm);
    score += complexityScore * 0.25;

    return score.clamp(0.0, 1.0);
  }

  /// Calcula score baseado no tamanho da equipe
  double _calculateTeamSizeScore(Case caseItem, LawFirm firm) {
    final requiredTeamSize = caseItem.isHighComplexity ? 10 : 5;
    
    if (firm.teamSize >= requiredTeamSize) {
      // Normalizar para 0-1, com 20+ advogados = score máximo
      return (firm.teamSize / 20.0).clamp(0.0, 1.0);
    } else {
      // Penalizar escritórios pequenos para casos complexos
      return (firm.teamSize / requiredTeamSize) * 0.7;
    }
  }

  /// Calcula score baseado na taxa de sucesso
  double _calculateSuccessRateScore(LawFirm firm) {
    if (firm.kpis == null) return 0.5; // Score neutro se não há KPIs
    
    return firm.kpis!.successRate;
  }

  /// Calcula score baseado na complexidade do caso
  double _calculateComplexityScore(Case caseItem, LawFirm firm) {
    if (firm.kpis == null) return 0.5;

    // Para casos de alta complexidade, valorizar escritórios com:
    // - Alta reputação
    // - Diversidade (indica capacidade de lidar com casos complexos)
    if (caseItem.isHighComplexity) {
      return (firm.kpis!.reputationScore * 0.6 + 
              firm.kpis!.diversityIndex * 0.4);
    } else {
      // Para casos simples, valorizar disponibilidade (menos casos ativos)
      final availabilityScore = firm.kpis!.activeCases > 0 
          ? (1.0 - (firm.kpis!.activeCases / 100.0)).clamp(0.0, 1.0)
          : 1.0;
      
      return availabilityScore;
    }
  }

  /// Determina se um caso deve receber recomendação de escritório
  /// 
  /// Critérios:
  /// - Casos corporativos
  /// - Casos de alta complexidade
  /// - Casos sem advogado atribuído ainda
  static bool shouldRecommendFirm(Case caseItem) {
    return caseItem.shouldShowFirmRecommendation && caseItem.lawyer == null;
  }

  /// Gera mock de recomendação para testes
  static Case createMockCaseWithFirmRecommendation(Case originalCase) {
    final mockFirm = LawFirm(
      id: 'mock_firm_1',
      name: 'Silva & Associados',
      teamSize: 15,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
      kpis: null, // Será carregado sob demanda
    );

    return Case.withRecommendedFirm(
      originalCase: originalCase,
      recommendedFirm: mockFirm,
      matchScore: 0.85,
    );
  }
} 