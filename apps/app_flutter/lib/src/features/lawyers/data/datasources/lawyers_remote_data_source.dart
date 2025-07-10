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
        '/api/match', 
        data: {
          'case_id': caseId,
          'top_n': 5,
          'preset': 'balanced',
        }
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> lawyerList = response.data['lawyers'];
        return lawyerList.map((json) => MatchedLawyer.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao buscar advogados: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Erro de rede ao buscar advogados: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: ${e.toString()}');
    }
  }
} 