import '../entities/enriched_lawyer.dart';
import '../repositories/enriched_lawyer_repository.dart';

class GetEnrichedLawyerUseCase {
  final EnrichedLawyerRepository repository;

  GetEnrichedLawyerUseCase({required this.repository});

  Future<EnrichedLawyer> call(String lawyerId) async {
    return await repository.getEnrichedLawyer(lawyerId);
  }
}

class RefreshEnrichedLawyerUseCase {
  final EnrichedLawyerRepository repository;

  RefreshEnrichedLawyerUseCase({required this.repository});

  Future<EnrichedLawyer> call(String lawyerId) async {
    return await repository.refreshEnrichedLawyer(lawyerId);
  }
} 