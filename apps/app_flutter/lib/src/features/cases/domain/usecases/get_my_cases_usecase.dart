import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/features/cases/domain/repositories/cases_repository.dart';
import '../../../../core/utils/logger.dart';

class GetMyCasesUseCase {
  final CasesRepository repository;

  GetMyCasesUseCase(this.repository);

  Future<List<Case>> call({String? userId, String? userRole}) async {
    AppLogger.info('=== GET MY CASES USE CASE ===');
    AppLogger.info('Calling repository with userId: $userId, userRole: $userRole');
    
    final cases = await repository.getMyCases(userId: userId, userRole: userRole);
    
    AppLogger.info('Repository returned ${cases.length} cases');
    for (final caseItem in cases) {
      AppLogger.info('UseCase - Case: ${caseItem.id} - ${caseItem.title} - allocationType: ${caseItem.allocationType}');
    }
    
    return cases;
  }
} 