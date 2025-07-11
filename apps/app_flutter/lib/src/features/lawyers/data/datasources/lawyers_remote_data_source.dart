import 'package:dio/dio.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';

abstract class LawyersRemoteDataSource {
  Future<List<MatchedLawyer>> findMatches({required String caseId});
}

class LawyersRemoteDataSourceImpl implements LawyersRemoteDataSource {
  final Dio dio;

  LawyersRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<MatchedLawyer>> findMatches({required String caseId}) async {
    try {
      final response = await dio.post(
        // TODO: Mover URL para uma constante
        'http://localhost:8000/api/match', 
        data: {'case_id': caseId, 'k': 5, 'preset': 'balanced'},
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
} 