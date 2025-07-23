import '../../domain/entities/contract.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/dio_service.dart';

abstract class ContractsRemoteDataSource {
  Future<List<Contract>> getContracts({
    String? status,
    String? searchQuery,
  });

  Future<Contract> createContract({
    required String caseId,
    required String lawyerId,
    required Map<String, dynamic> feeModel,
  });

  Future<Contract> signContract({
    required String contractId,
    required String role,
  });

  Future<Contract> cancelContract({
    required String contractId,
  });

  Future<String> downloadContract({
    required String contractId,
  });
}

class ContractsRemoteDataSourceImpl implements ContractsRemoteDataSource {
  @override
  Future<List<Contract>> getContracts({
    String? status,
    String? searchQuery,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (searchQuery != null) queryParams['search'] = searchQuery;

      final response = await DioService.get('/contracts', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> contractsJson = response.data as List<dynamic>;
        return contractsJson.map((json) => Contract.fromJson(json)).toList();
      } else {
        throw ServerException(message: 'Erro ao buscar contratos: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Erro de conexão: $e');
    }
  }

  @override
  Future<Contract> createContract({
    required String caseId,
    required String lawyerId,
    required Map<String, dynamic> feeModel,
  }) async {
    try {
      final response = await DioService.post('/contracts', data: {
        'case_id': caseId,
        'lawyer_id': lawyerId,
        'fee_model': feeModel,
      });

      if (response.statusCode == 201) {
        return Contract.fromJson(response.data);
      } else {
        throw ServerException(message: 'Erro ao criar contrato: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Erro de conexão: $e');
    }
  }

  @override
  Future<Contract> signContract({
    required String contractId,
    required String role,
  }) async {
    try {
      final response = await DioService.patch(
        '/contracts/$contractId/sign',
        data: {
          'role': role,
        },
      );

      if (response.statusCode == 200) {
        return Contract.fromJson(response.data);
      } else {
        throw ServerException(message: 'Erro ao assinar contrato: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Erro de conexão: $e');
    }
  }

  @override
  Future<Contract> cancelContract({
    required String contractId,
  }) async {
    try {
      final response = await DioService.patch('/contracts/$contractId/cancel');

      if (response.statusCode == 200) {
        return Contract.fromJson(response.data);
      } else {
        throw ServerException(message: 'Erro ao cancelar contrato: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Erro de conexão: $e');
    }
  }

  @override
  Future<String> downloadContract({
    required String contractId,
  }) async {
    try {
      final response = await DioService.get('/contracts/$contractId/download');

      if (response.statusCode == 200) {
        return response.data['pdf_url'] ?? response.data['content'];
      } else {
        throw ServerException(message: 'Erro ao baixar contrato: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Erro de conexão: $e');
    }
  }
}