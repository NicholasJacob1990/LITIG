import '../entities/partnership.dart';
import '../../../core/utils/result.dart';

abstract class PartnershipRepository {
  Future<Result<List<Partnership>>> getMyPartnerships();
  Future<Result<List<Partnership>>> getSentPartnerships();
  Future<Result<List<Partnership>>> getReceivedPartnerships();
  Future<Result<Partnership>> createPartnership({
    required String partnerId,
    String? caseId,
    required PartnershipType type,
    required String honorarios,
    String? proposalMessage,
  });
  Future<Result<void>> acceptPartnership(String partnershipId);
  Future<Result<void>> rejectPartnership(String partnershipId);
  Future<Result<void>> acceptContract(String partnershipId);
  Future<Result<String>> generateContract(String partnershipId);
} 