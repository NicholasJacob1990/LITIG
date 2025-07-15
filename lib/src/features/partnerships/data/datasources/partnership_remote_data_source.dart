import 'package:dio/dio.dart';
import '../models/partnership_model.dart';
import '../../domain/entities/partnership.dart';

abstract class PartnershipRemoteDataSource {
  Future<List<PartnershipModel>> getMyPartnerships();
  Future<List<PartnershipModel>> getSentPartnerships();
  Future<List<PartnershipModel>> getReceivedPartnerships();
  Future<PartnershipModel> createPartnership({
    required String partnerId,
    String? caseId,
    required PartnershipType type,
    required String honorarios,
    String? proposalMessage,
  });
  Future<void> acceptPartnership(String partnershipId);
  Future<void> rejectPartnership(String partnershipId);
  Future<void> acceptContract(String partnershipId);
  Future<String> generateContract(String partnershipId);
}

class PartnershipRemoteDataSourceImpl implements PartnershipRemoteDataSource {
  final Dio dio;
  final String baseUrl;

  PartnershipRemoteDataSourceImpl({
    required this.dio,
    required this.baseUrl,
  });

  @override
  Future<List<PartnershipModel>> getMyPartnerships() async {
    try {
      final response = await dio.get(
        '$baseUrl/partnerships',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => PartnershipModel.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar parcerias: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<List<PartnershipModel>> getSentPartnerships() async {
    try {
      final response = await dio.get(
        '$baseUrl/partnerships/sent',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => PartnershipModel.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar parcerias enviadas: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<List<PartnershipModel>> getReceivedPartnerships() async {
    try {
      final response = await dio.get(
        '$baseUrl/partnerships/received',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => PartnershipModel.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar parcerias recebidas: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<PartnershipModel> createPartnership({
    required String partnerId,
    String? caseId,
    required PartnershipType type,
    required String honorarios,
    String? proposalMessage,
  }) async {
    try {
      final requestData = {
        'partner_id': partnerId,
        'case_id': caseId,
        'type': _partnershipTypeToString(type),
        'honorarios': honorarios,
        'proposal_message': proposalMessage,
      };

      final response = await dio.post(
        '$baseUrl/partnerships',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        return PartnershipModel.fromJson(response.data);
      } else {
        throw Exception('Falha ao criar parceria: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<void> acceptPartnership(String partnershipId) async {
    try {
      final response = await dio.patch(
        '$baseUrl/partnerships/$partnershipId/accept',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Falha ao aceitar parceria: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<void> rejectPartnership(String partnershipId) async {
    try {
      final response = await dio.patch(
        '$baseUrl/partnerships/$partnershipId/reject',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Falha ao rejeitar parceria: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<void> acceptContract(String partnershipId) async {
    try {
      final response = await dio.patch(
        '$baseUrl/partnerships/$partnershipId/accept-contract',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Falha ao aceitar contrato: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  @override
  Future<String> generateContract(String partnershipId) async {
    try {
      final response = await dio.post(
        '$baseUrl/partnerships/$partnershipId/generate-contract',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data['contract_url'] as String;
      } else {
        throw Exception('Falha ao gerar contrato: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  String _partnershipTypeToString(PartnershipType type) {
    switch (type) {
      case PartnershipType.consultoria:
        return 'consultoria';
      case PartnershipType.peticaoTecnica:
        return 'peticao_tecnica';
      case PartnershipType.audiencia:
        return 'audiencia';
      case PartnershipType.atuacaoTotal:
        return 'atuacao_total';
      case PartnershipType.parceriaRecorrente:
        return 'parceria_recorrente';
    }
  }

  void _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      throw Exception('Timeout na conexão');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      throw Exception('Timeout ao receber dados');
    } else if (e.response?.statusCode == 401) {
      throw Exception('Usuário não autenticado');
    } else if (e.response?.statusCode == 403) {
      throw Exception('Acesso negado');
    } else if (e.response?.statusCode == 404) {
      throw Exception('Recurso não encontrado');
    } else if (e.response?.statusCode == 500) {
      throw Exception('Erro interno do servidor');
    } else {
      throw Exception('Erro de conexão: ${e.message}');
    }
  }
} 