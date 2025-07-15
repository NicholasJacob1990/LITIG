import 'package:dio/dio.dart';
import 'package:meu_app/src/core/utils/result.dart';
import 'package:meu_app/src/features/offers/data/datasources/offers_remote_data_source.dart';
import 'package:meu_app/src/features/offers/domain/entities/case_offer.dart';
import 'package:meu_app/src/features/offers/domain/repositories/offers_repository.dart';

class OffersRepositoryImpl implements OffersRepository {
  final OffersRemoteDataSource _remoteDataSource;

  OffersRepositoryImpl({required OffersRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Result<void>> acceptOffer(String offerId, {String? notes}) async {
    try {
      await _remoteDataSource.acceptOffer(offerId, notes: notes);
      return const Result.success(null);
    } on DioException catch (e) {
      return Result.genericFailure(e.message ?? 'Erro ao aceitar oferta', e.toString());
    }
  }

  @override
  Future<Result<List<CaseOffer>>> getOfferHistory({String? status}) async {
    try {
      final result = await _remoteDataSource.getOfferHistory(status: status);
      return Result.success(result);
    } on DioException catch (e) {
      return Result.genericFailure(e.message ?? 'Erro ao buscar histórico', e.toString());
    }
  }

  @override
  Future<Result<OfferStats>> getOfferStats() async {
    try {
      final result = await _remoteDataSource.getOfferStats();
      return Result.success(result);
    } on DioException catch (e) {
      return Result.genericFailure(e.message ?? 'Erro ao buscar estatísticas', e.toString());
    }
  }

  @override
  Future<Result<List<CaseOffer>>> getPendingOffers() async {
    try {
      final result = await _remoteDataSource.getPendingOffers();
      return Result.success(result);
    } on DioException catch (e) {
      return Result.genericFailure(e.message ?? 'Erro ao buscar ofertas pendentes', e.toString());
    }
  }

  @override
  Future<Result<void>> rejectOffer(String offerId, String reason) async {
    try {
      await _remoteDataSource.rejectOffer(offerId, reason);
      return const Result.success(null);
    } on DioException catch (e) {
      return Result.genericFailure(e.message ?? 'Erro ao rejeitar oferta', e.toString());
    }
  }
} 