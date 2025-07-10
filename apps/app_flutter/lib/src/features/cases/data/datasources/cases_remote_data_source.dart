import 'package:dio/dio.dart';
import 'package:meu_app/src/features/cases/domain/entities/case.dart';

abstract class CasesRemoteDataSource {
  Future<List<Case>> getMyCases();
}

class CasesRemoteDataSourceImpl implements CasesRemoteDataSource {
  final Dio dio;

  CasesRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<Case>> getMyCases() async {
    try {
      final response = await dio.get('/api/cases/my-cases');
      
      if (response.statusCode == 200 && response.data['cases'] != null) {
        final List<dynamic> caseList = response.data['cases'];
        return caseList.map((json) => Case.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao buscar casos: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      // TODO: Melhorar tratamento de erro Dio
      throw Exception('Erro de rede ao buscar casos: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: ${e.toString()}');
    }
  }
} 