import 'package:meu_app/src/core/utils/result.dart';
import 'package:meu_app/src/features/partnerships/domain/entities/partnership.dart';
import 'package:meu_app/src/features/partnerships/domain/repositories/partnership_repository.dart';

/// Use case para buscar parcerias
class GetPartnerships {
  final PartnershipRepository repository;

  const GetPartnerships(this.repository);

  /// Executa a busca de parcerias
  Future<Result<List<Partnership>>> call() async {
    return await repository.fetchPartnerships();
  }
} 