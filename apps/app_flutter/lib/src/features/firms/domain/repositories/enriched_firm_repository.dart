import '../entities/enriched_firm.dart';

abstract class EnrichedFirmRepository {
  Future<EnrichedFirm> getEnrichedFirm(String firmId);
  Future<EnrichedFirm> refreshEnrichedFirm(String firmId);
} 

abstract class EnrichedFirmRepository {
  Future<EnrichedFirm> getEnrichedFirm(String firmId);
  Future<EnrichedFirm> refreshEnrichedFirm(String firmId);
} 