import 'package:dio/dio.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/match_result.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';

abstract class LawyersRemoteDataSource {
  Future<List<MatchedLawyer>> findMatches({
    required String caseId, 
    bool expandSearch = false,
  });
  
  /// Nova versão que retorna tanto advogados quanto escritórios
  Future<MatchResult> findMatchesWithFirms({
    required String caseId, 
    bool expandSearch = false,
  });
}

class LawyersRemoteDataSourceImpl implements LawyersRemoteDataSource {
  final Dio dio;

  LawyersRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<MatchedLawyer>> findMatches({
    required String caseId, 
    bool expandSearch = false,
  }) async {
    try {
      final response = await dio.post(
        // TODO: Mover URL para uma constante
        'http://127.0.0.1:8080/api/match', 
        data: {
          'case_id': caseId, 
          'k': 5, 
          'preset': 'balanced',
          'expand_search': expandSearch, // NOVO: Busca híbrida
        },
      );

      if (response.statusCode == 200 && response.data['matches'] != null) {
        final List<dynamic> lawyerList = response.data['matches'];
        return lawyerList.map((json) => MatchedLawyer.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao buscar advogados: ${response.statusMessage}');
      }
    } catch (e) {
      // TODO: Melhorar tratamento de erro
      rethrow;
    }
  }

  @override
  Future<MatchResult> findMatchesWithFirms({
    required String caseId, 
    bool expandSearch = false,
  }) async {
    try {
      final response = await dio.post(
        // TODO: Mover URL para uma constante
        'http://127.0.0.1:8080/api/match', 
        data: {
          'case_id': caseId, 
          'k': 5, 
          'preset': 'balanced',
          'expand_search': expandSearch,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // Processar advogados
        final List<MatchedLawyer> lawyers = [];
        if (responseData['lawyers'] != null) {
          final List<dynamic> lawyerList = responseData['lawyers'];
          lawyers.addAll(lawyerList.map((json) => MatchedLawyer.fromJson(json)));
        }
        
        // Processar escritórios
        final List<LawFirm> firms = [];
        if (responseData['firms'] != null) {
          final List<dynamic> firmList = responseData['firms'];
          firms.addAll(firmList.map((json) => _convertFirmFromApi(json)));
        }
        
        return MatchResult(
          lawyers: lawyers,
          firms: firms,
          caseId: responseData['case_id'] ?? caseId,
          matchId: responseData['match_id'] ?? '',
          totalLawyersEvaluated: responseData['total_lawyers_evaluated'] ?? 0,
          algorithmVersion: responseData['algorithm_version'] ?? '',
          executionTimeMs: (responseData['execution_time_ms'] ?? 0.0).toDouble(),
        );
      } else {
        throw Exception('Falha ao buscar resultados: ${response.statusMessage}');
      }
    } catch (e) {
      // TODO: Melhorar tratamento de erro
      rethrow;
    }
  }
  
  /// Converte dados da API para LawFirm
  LawFirm _convertFirmFromApi(Map<String, dynamic> json) {
    return LawFirm(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      teamSize: json['team_size'] ?? 0,
      mainLat: json['latitude']?.toDouble(),
      mainLon: json['longitude']?.toDouble(),
      specializations: List<String>.from(json['specializations'] ?? []),
      rating: (json['reputation_score'] ?? 0.0).toDouble(),
    );
  }
} 