import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/features/cases/domain/repositories/cases_repository.dart';

class GetMyCasesUseCase {
  final CasesRepository repository;

  GetMyCasesUseCase(this.repository);

  Future<List<Case>> call() async {
    return await repository.getMyCases();
  }
} 