import '../entities/partnership_recommendation.dart';

abstract class ClusterRepository {
  /// Busca recomendações de parceria para um advogado específico
  Future<List<PartnershipRecommendation>> getPartnershipRecommendations({
    required String lawyerId,
    int limit = 10,
    double minCompatibility = 0.6,
  });

  /// Envia feedback sobre uma recomendação de parceria para otimização do ML
  Future<void> providePartnershipFeedback({
    required String lawyerId,
    required String feedbackType,
    required double feedbackScore,
    int? interactionTimeSeconds,
    String? feedbackNotes,
  });

  /// Busca clusters em tendência
  Future<List<Map<String, dynamic>>> getTrendingClusters({
    String clusterType = 'case',
    int limit = 3,
  });

  /// Busca detalhes de um cluster específico
  Future<Map<String, dynamic>?> getClusterDetails(String clusterId);
} 