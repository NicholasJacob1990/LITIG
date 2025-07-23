import '../../../../core/error/exceptions.dart';
import '../../../../core/services/dio_service.dart';
import '../models/financial_data_model.dart';

abstract class FinancialRemoteDataSource {
  Future<FinancialDataModel> getFinancialData({
    String? period,
    String? feeType,
  });

  Future<void> exportFinancialData({
    required String format,
    String? period,
  });

  Future<void> markPaymentReceived({
    required String paymentId,
  });

  Future<void> requestPaymentRepass({
    required String paymentId,
  });
}

class FinancialRemoteDataSourceImpl implements FinancialRemoteDataSource {
  @override
  Future<FinancialDataModel> getFinancialData({
    String? period,
    String? feeType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;
      if (feeType != null) queryParams['fee_type'] = feeType;

      final response = await DioService.get(
        '/financials/dashboard',
        queryParameters: queryParams,
      );

      return FinancialDataModel.fromJson(response.data);
    } catch (e) {
      throw ServerException(message: 'Erro ao carregar dados financeiros: $e');
    }
  }

  @override
  Future<void> exportFinancialData({
    required String format,
    String? period,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'format': format,
      };
      if (period != null) queryParams['period'] = period;

      await DioService.post(
        '/financials/export',
        data: queryParams,
      );
    } catch (e) {
      throw ServerException(message: 'Erro ao exportar dados financeiros: $e');
    }
  }

  @override
  Future<void> markPaymentReceived({
    required String paymentId,
  }) async {
    try {
      await DioService.patch(
        '/financials/payments/$paymentId/received',
      );
    } catch (e) {
      throw ServerException(message: 'Erro ao marcar pagamento como recebido: $e');
    }
  }

  @override
  Future<void> requestPaymentRepass({
    required String paymentId,
  }) async {
    try {
      await DioService.post(
        '/financials/payments/$paymentId/repass',
      );
    } catch (e) {
      throw ServerException(message: 'Erro ao solicitar repasse: $e');
    }
  }
} 