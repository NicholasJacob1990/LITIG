import 'package:meu_app/src/features/partnerships/data/models/partnership_model.dart';

abstract class PartnershipRemoteDataSource {
  Future<List<PartnershipModel>> fetchPartnerships();
} 