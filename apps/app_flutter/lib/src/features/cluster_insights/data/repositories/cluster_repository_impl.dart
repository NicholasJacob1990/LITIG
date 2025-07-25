import '../../domain/repositories/cluster_repository.dart';
import '../../domain/entities/partnership_recommendation.dart';
import '../datasources/cluster_remote_datasource.dart';

class ClusterRepositoryImpl implements ClusterRepository {
  final ClusterRemoteDataSource remoteDataSource;

  ClusterRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<PartnershipRecommendation>> getPartnershipRecommendations({
    required String lawyerId,
    int limit = 10,
    double minCompatibility = 0.6,
  }) async {
    try {
      final response = await remoteDataSource.getPartnershipRecommendations(
        lawyerId: lawyerId,
        limit: limit,
        minCompatibility: minCompatibility,
      );

      return response.map((json) => PartnershipRecommendation.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar recomendações de parceria: $e');
    }
  }

  @override
  Future<void> providePartnershipFeedback({
    required String lawyerId,
    required String feedbackType,
    required double feedbackScore,
    int? interactionTimeSeconds,
    String? feedbackNotes,
  }) async {
    try {
      await remoteDataSource.providePartnershipFeedback(
        lawyerId: lawyerId,
        feedbackType: feedbackType,
        feedbackScore: feedbackScore,
        interactionTimeSeconds: interactionTimeSeconds,
        feedbackNotes: feedbackNotes,
      );
    } catch (e) {
      throw Exception('Erro ao enviar feedback: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTrendingClusters({
    String clusterType = 'case',
    int limit = 3,
  }) async {
    try {
      return await remoteDataSource.getTrendingClusters(
        clusterType: clusterType,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Erro ao buscar clusters em tendência: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getClusterDetails(String clusterId) async {
    try {
      return await remoteDataSource.getClusterDetails(clusterId);
    } catch (e) {
      throw Exception('Erro ao buscar detalhes do cluster: $e');
    }
  }
} 