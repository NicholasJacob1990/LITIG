import 'dart:convert';
import 'package:http/http.dart' as http;

abstract class ClusterRemoteDataSource {
  Future<List<Map<String, dynamic>>> getPartnershipRecommendations({
    required String lawyerId,
    int limit = 10,
    double minCompatibility = 0.6,
  });

  Future<void> providePartnershipFeedback({
    required String lawyerId,
    required String feedbackType,
    required double feedbackScore,
    int? interactionTimeSeconds,
    String? feedbackNotes,
  });

  Future<List<Map<String, dynamic>>> getTrendingClusters({
    String clusterType = 'case',
    int limit = 3,
  });

  Future<Map<String, dynamic>?> getClusterDetails(String clusterId);
}

class ClusterRemoteDataSourceImpl implements ClusterRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  ClusterRemoteDataSourceImpl({
    required this.client,
    this.baseUrl = 'http://127.0.0.1:8080',
  });

  @override
  Future<List<Map<String, dynamic>>> getPartnershipRecommendations({
    required String lawyerId,
    int limit = 10,
    double minCompatibility = 0.6,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/clusters/recommendations/$lawyerId')
          .replace(queryParameters: {
        'limit': limit.toString(),
        'min_compatibility': minCompatibility.toString(),
      });

      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao buscar recomendações: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro inesperado: $e');
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
      final uri = Uri.parse('$baseUrl/api/partnership/feedback/');
      final body = json.encode({
        'user_id': 'current_user_id', // TODO: Obter do auth service
        'lawyer_id': 'current_lawyer_id', // TODO: Obter do auth service
        'recommended_lawyer_id': lawyerId,
        'feedback_type': feedbackType,
        'feedback_score': feedbackScore,
        'interaction_time_seconds': interactionTimeSeconds,
        'feedback_notes': feedbackNotes,
      });

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erro ao enviar feedback: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTrendingClusters({
    String clusterType = 'case',
    int limit = 3,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/clusters/trending')
          .replace(queryParameters: {
        'cluster_type': clusterType,
        'limit': limit.toString(),
      });

      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao buscar clusters: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getClusterDetails(String clusterId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/clusters/$clusterId');

      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erro ao buscar detalhes do cluster: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }
} 