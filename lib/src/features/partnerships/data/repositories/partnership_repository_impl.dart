import '../../domain/entities/partnership.dart';
import '../../domain/repositories/partnership_repository.dart';
import '../datasources/partnership_remote_data_source.dart';

class PartnershipRepositoryImpl implements PartnershipRepository {
  final PartnershipRemoteDataSource remoteDataSource;

  PartnershipRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<Partnership>> getMyPartnerships() async {
    try {
      final partnerships = await remoteDataSource.getMyPartnerships();
      return partnerships.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Erro ao carregar parcerias: $e');
    }
  }

  @override
  Future<List<Partnership>> getSentPartnerships() async {
    try {
      final partnerships = await remoteDataSource.getSentPartnerships();
      return partnerships.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Erro ao carregar parcerias enviadas: $e');
    }
  }

  @override
  Future<List<Partnership>> getReceivedPartnerships() async {
    try {
      final partnerships = await remoteDataSource.getReceivedPartnerships();
      return partnerships.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Erro ao carregar parcerias recebidas: $e');
    }
  }

  @override
  Future<Partnership> createPartnership({
    required String partnerId,
    String? caseId,
    required PartnershipType type,
    required String honorarios,
    String? proposalMessage,
  }) async {
    try {
      final partnership = await remoteDataSource.createPartnership(
        partnerId: partnerId,
        caseId: caseId,
        type: type,
        honorarios: honorarios,
        proposalMessage: proposalMessage,
      );
      return partnership.toEntity();
    } catch (e) {
      throw Exception('Erro ao criar parceria: $e');
    }
  }

  @override
  Future<void> acceptPartnership(String partnershipId) async {
    try {
      await remoteDataSource.acceptPartnership(partnershipId);
    } catch (e) {
      throw Exception('Erro ao aceitar parceria: $e');
    }
  }

  @override
  Future<void> rejectPartnership(String partnershipId) async {
    try {
      await remoteDataSource.rejectPartnership(partnershipId);
    } catch (e) {
      throw Exception('Erro ao rejeitar parceria: $e');
    }
  }

  @override
  Future<void> acceptContract(String partnershipId) async {
    try {
      await remoteDataSource.acceptContract(partnershipId);
    } catch (e) {
      throw Exception('Erro ao aceitar contrato: $e');
    }
  }

  @override
  Future<String> generateContract(String partnershipId) async {
    try {
      return await remoteDataSource.generateContract(partnershipId);
    } catch (e) {
      throw Exception('Erro ao gerar contrato: $e');
    }
  }
} 