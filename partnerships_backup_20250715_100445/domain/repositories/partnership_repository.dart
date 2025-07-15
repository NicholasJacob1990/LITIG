import 'package:meu_app/src/core/utils/result.dart';
import 'package:meu_app/src/features/partnerships/domain/entities/partnership.dart';

abstract class PartnershipRepository {
  Future<Result<List<Partnership>>> fetchPartnerships();
} 