import 'package:meu_app/src/core/utils/result.dart';
import 'package:meu_app/src/features/partnerships/domain/entities/partnership.dart';

abstract class PartnershipRepository {
  Future<Result<List<Partnership>>> fetchPartnerships();
  
  /// 🆕 Busca recomendações de parceria com modelo híbrido
  Future<Map<String, dynamic>> getEnhancedPartnershipRecommendations({
    required String lawyerId,
    bool expandSearch = false,
    int limit = 10,
    double minConfidence = 0.6,
  });
  
  /// 🆕 Cria convite de parceria para perfil externo
  Future<Map<String, dynamic>> createPartnershipInvitation({
    required Map<String, dynamic> externalProfile,
    required Map<String, dynamic> partnershipContext,
  });
  
  /// 🆕 Lista convites enviados pelo advogado
  Future<Map<String, dynamic>> getMyInvitations({
    String? status,
    int limit = 20,
  });
  
  /// 🆕 Busca estatísticas de convites
  Future<Map<String, dynamic>> getInvitationStatistics();
  
  /// Aceita uma parceria
  Future<Result<void>> acceptPartnership(String partnershipId);
  
  /// Rejeita uma parceria
  Future<Result<void>> rejectPartnership(String partnershipId);
  
  /// Atualiza status de parceria
  Future<Result<Partnership>> updatePartnershipStatus(String partnershipId, String status);
} 