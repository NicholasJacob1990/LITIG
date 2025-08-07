import 'package:meu_app/src/core/utils/result.dart';
import 'package:meu_app/src/features/partnerships/domain/repositories/partnership_repository.dart';

class RejectPartnership {
  final PartnershipRepository repository;

  RejectPartnership(this.repository);

  Future<Result<void>> call(String partnershipId) async {
    return await repository.rejectPartnership(partnershipId);
  }
}