import '../entities/enriched_lawyer.dart';

abstract class EnrichedLawyerRepository {
  Future<EnrichedLawyer> getEnrichedLawyer(String lawyerId);
  Future<EnrichedLawyer> refreshEnrichedLawyer(String lawyerId);
} 

abstract class EnrichedLawyerRepository {
  Future<EnrichedLawyer> getEnrichedLawyer(String lawyerId);
  Future<EnrichedLawyer> refreshEnrichedLawyer(String lawyerId);
} 