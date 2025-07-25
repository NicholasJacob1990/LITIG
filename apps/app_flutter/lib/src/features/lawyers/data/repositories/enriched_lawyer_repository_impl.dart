import '../../domain/entities/enriched_lawyer.dart';
import '../../domain/repositories/enriched_lawyer_repository.dart';
import '../datasources/enriched_lawyer_data_source.dart';

class EnrichedLawyerRepositoryImpl implements EnrichedLawyerRepository {
  final EnrichedLawyerDataSource dataSource;

  EnrichedLawyerRepositoryImpl({required this.dataSource});

  @override
  Future<EnrichedLawyer> getEnrichedLawyer(String lawyerId) async {
    try {
      return await dataSource.getEnrichedLawyer(lawyerId);
    } catch (e) {
      throw Exception('Failed to get enriched lawyer data: $e');
    }
  }

  @override
  Future<EnrichedLawyer> refreshEnrichedLawyer(String lawyerId) async {
    try {
      return await dataSource.refreshEnrichedLawyer(lawyerId);
    } catch (e) {
      throw Exception('Failed to refresh enriched lawyer data: $e');
    }
  }
} 
import '../../domain/repositories/enriched_lawyer_repository.dart';
import '../datasources/enriched_lawyer_data_source.dart';

class EnrichedLawyerRepositoryImpl implements EnrichedLawyerRepository {
  final EnrichedLawyerDataSource dataSource;

  EnrichedLawyerRepositoryImpl({required this.dataSource});

  @override
  Future<EnrichedLawyer> getEnrichedLawyer(String lawyerId) async {
    try {
      return await dataSource.getEnrichedLawyer(lawyerId);
    } catch (e) {
      throw Exception('Failed to get enriched lawyer data: $e');
    }
  }

  @override
  Future<EnrichedLawyer> refreshEnrichedLawyer(String lawyerId) async {
    try {
      return await dataSource.refreshEnrichedLawyer(lawyerId);
    } catch (e) {
      throw Exception('Failed to refresh enriched lawyer data: $e');
    }
  }
} 