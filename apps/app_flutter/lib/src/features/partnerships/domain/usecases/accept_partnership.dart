import 'package:meu_app/src/core/utils/result.dart';
import 'package:meu_app/src/features/partnerships/domain/repositories/partnership_repository.dart';

class AcceptPartnership {
  final PartnershipRepository repository;

  AcceptPartnership(this.repository);

  Future<Result<void>> call(String partnershipId) async {
    return await repository.acceptPartnership(partnershipId);
  }
}