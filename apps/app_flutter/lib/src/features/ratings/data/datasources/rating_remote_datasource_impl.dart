import 'package:dio/dio.dart';
import '../models/case_rating_model.dart';
import '../models/lawyer_rating_stats_model.dart';
import 'rating_remote_datasource.dart';

/// Implementação do datasource remoto para avaliações
class RatingRemoteDataSourceImpl implements RatingRemoteDataSource {
  final Dio _dio;

  RatingRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<String> createRating(CaseRatingModel rating) async {
    try {
      final response = await _dio.post(
        '/ratings',
        data: rating.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['rating_id'] as String;
      } else {
        throw Exception('Erro ao criar avaliação: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Erro na API: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<List<CaseRatingModel>> getLawyerRatings(
    String lawyerId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/ratings/lawyer/$lawyerId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> ratingsJson = response.data['ratings'] ?? [];
        return ratingsJson
            .map((json) => CaseRatingModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Erro ao buscar avaliações: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Erro na API: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<LawyerRatingStatsModel> getLawyerStats(String lawyerId) async {
    try {
      final response = await _dio.get('/ratings/stats/lawyer/$lawyerId');

      if (response.statusCode == 200) {
        return LawyerRatingStatsModel.fromJson(response.data['statistics']);
      } else {
        throw Exception('Erro ao buscar estatísticas: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Erro na API: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> canRateCase(String caseId) async {
    try {
      final response = await _dio.get('/ratings/case/$caseId/can-rate');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Erro ao verificar permissão: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Erro na API: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<List<CaseRatingModel>> getCaseRatings(String caseId) async {
    try {
      final response = await _dio.get('/ratings/case/$caseId');

      if (response.statusCode == 200) {
        final List<dynamic> ratingsJson = response.data['ratings'] ?? [];
        return ratingsJson
            .map((json) => CaseRatingModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Erro ao buscar avaliações do caso: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Erro na API: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<void> updateRating(CaseRatingModel rating) async {
    try {
      final response = await _dio.put(
        '/ratings/${rating.id}',
        data: rating.toJson(),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao atualizar avaliação: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Erro na API: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<void> deleteRating(String ratingId) async {
    try {
      final response = await _dio.delete('/ratings/$ratingId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erro ao deletar avaliação: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Erro na API: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<void> voteHelpful(String ratingId) async {
    try {
      final response = await _dio.post('/ratings/$ratingId/helpful');

      if (response.statusCode != 200) {
        throw Exception('Erro ao votar como útil: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Erro na API: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final response = await _dio.get('/ratings/stats/system');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Erro ao buscar estatísticas do sistema: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Erro na API: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }
} 