import 'package:dio/dio.dart';
import '../../domain/entities/case_offer.dart';
import 'offers_remote_data_source.dart';

class OffersRemoteDataSourceImpl implements OffersRemoteDataSource {
  final Dio _dio;

  OffersRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<CaseOffer>> getPendingOffers() async {
    try {
      final response = await _dio.get('/offers/pending');
      return (response.data as List)
          .map((json) => CaseOffer.fromJson(json))
          .toList();
    } on DioException catch (e) {
      // TODO: Adicionar tratamento de erro mais robusto
      throw Exception('Erro ao buscar ofertas pendentes: ${e.message}');
    }
  }

  @override
  Future<List<CaseOffer>> getOfferHistory({String? status}) async {
    try {
      final response = await _dio.get(
        '/offers/history',
        queryParameters: status != null ? {'status': status} : null,
      );
      return (response.data as List)
          .map((json) => CaseOffer.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception('Erro ao buscar histórico de ofertas: ${e.message}');
    }
  }

  @override
  Future<OfferStats> getOfferStats() async {
    try {
      final response = await _dio.get('/offers/stats');
      return OfferStats.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Erro ao buscar estatísticas: ${e.message}');
    }
  }

  @override
  Future<void> acceptOffer(String offerId, {String? notes}) async {
    try {
      await _dio.patch(
        '/offers/$offerId/accept',
        data: {'notes': notes},
      );
    } on DioException catch (e) {
      throw Exception('Erro ao aceitar oferta: ${e.message}');
    }
  }

  @override
  Future<void> rejectOffer(String offerId, String reason) async {
    try {
      await _dio.patch(
        '/offers/$offerId/reject',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw Exception('Erro ao rejeitar oferta: ${e.message}');
    }
  }
} 