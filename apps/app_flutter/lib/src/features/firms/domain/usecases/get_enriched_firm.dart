import '../entities/enriched_firm.dart';
import '../repositories/enriched_firm_repository.dart';

class GetEnrichedFirmUseCase {
  final EnrichedFirmRepository repository;

  GetEnrichedFirmUseCase({required this.repository});

  Future<EnrichedFirm> call(String firmId) async {
    return await repository.getEnrichedFirm(firmId);
  }
}

class RefreshEnrichedFirmUseCase {
  final EnrichedFirmRepository repository;

  RefreshEnrichedFirmUseCase({required this.repository});

  Future<EnrichedFirm> call(String firmId) async {
    return await repository.refreshEnrichedFirm(firmId);
  }
} 
import '../repositories/enriched_firm_repository.dart';

class GetEnrichedFirmUseCase {
  final EnrichedFirmRepository repository;

  GetEnrichedFirmUseCase({required this.repository});

  Future<EnrichedFirm> call(String firmId) async {
    return await repository.getEnrichedFirm(firmId);
  }
}

class RefreshEnrichedFirmUseCase {
  final EnrichedFirmRepository repository;

  RefreshEnrichedFirmUseCase({required this.repository});

  Future<EnrichedFirm> call(String firmId) async {
    return await repository.refreshEnrichedFirm(firmId);
  }
} 