import '../../domain/entities/enriched_firm.dart';
import '../../domain/repositories/enriched_firm_repository.dart';
import '../datasources/enriched_firm_data_source.dart';

class EnrichedFirmRepositoryImpl implements EnrichedFirmRepository {
  final EnrichedFirmDataSource dataSource;

  EnrichedFirmRepositoryImpl({required this.dataSource});

  @override
  Future<EnrichedFirm> getEnrichedFirm(String firmId) async {
    try {
      final enrichedFirmModel = await dataSource.getEnrichedFirm(firmId);
      return enrichedFirmModel;
    } catch (e) {
      throw Exception('Failed to get enriched firm: $e');
    }
  }

  @override
  Future<EnrichedFirm> refreshEnrichedFirm(String firmId) async {
    try {
      final enrichedFirmModel = await dataSource.refreshEnrichedFirm(firmId);
      return enrichedFirmModel;
    } catch (e) {
      throw Exception('Failed to refresh enriched firm: $e');
    }
  }
} 