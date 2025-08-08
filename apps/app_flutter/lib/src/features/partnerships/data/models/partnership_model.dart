import 'package:meu_app/src/core/error/exceptions.dart';
import 'package:meu_app/src/features/firms/data/models/law_firm_model.dart';
import 'package:meu_app/src/features/lawyers/data/models/lawyer_model.dart';
import 'package:meu_app/src/features/partnerships/domain/entities/partnership.dart';

/// {@template partnership_model}
/// Modelo de dados para a entidade [Partnership].
///
/// Responsável pela deserialização de JSON para a entidade de domínio,
/// lidando com os diferentes tipos de parceiros (Lawyer ou LawFirm).
/// {@endtemplate}
class PartnershipModel extends Partnership {
  /// {@macro partnership_model}
  const PartnershipModel({
    required super.id,
    required super.title,
    required super.type,
    required super.status,
    required super.createdAt,
    super.updatedAt,
    super.creatorId,
    super.partnerId,
    super.linkedCaseId,
    super.linkedCaseTitle,
    super.linkedCaseType,
    super.linkedCaseStatus,
    super.contractUrl,
    super.contractAcceptedAt,
    super.honorarios,
    super.proposalMessage,
    super.unreadCount,
    super.lastActivityAt,
    super.slaDueAt,
    super.feeModel,
    super.feeSplitPercent,
    super.ndaStatus,
    super.jurisdiction,
    super.externalCaseNumber,
    super.partnerUf,
    super.partnerCity,
    required super.partner,
    required super.partnerType,
  });

  /// Cria uma instância de [PartnershipModel] a partir de um mapa JSON.
  ///
  /// Lança uma [ServerException] se a deserialização falhar.
  factory PartnershipModel.fromJson(Map<String, dynamic> json) {
    try {
      // Aceita tanto camelCase quanto snake_case
      final partnerTypeString = json['partnerType'] ?? json['partner_type'];
      final partnerData = json['partner'];
      PartnerEntityType partnerType;
      dynamic partner;

      if (partnerTypeString == 'firm') {
        partnerType = PartnerEntityType.firm;
        partner = LawFirmModel.fromJson(partnerData).toEntity();
      } else {
        partnerType = PartnerEntityType.lawyer;
        partner = LawyerModel.fromJson(partnerData).toEntity();
      }

      return PartnershipModel(
        id: json['id'] ?? json['uuid'] ?? json['partnership_id'],
        title: json['title'] ?? json['case_title'] ?? 'Parceria',
        type: PartnershipType.values.firstWhere(
          (e) {
            final raw = (json['type'] ?? '').toString();
            final normalized = raw.contains('.') ? raw.split('.').last : raw;
            return e.toString().split('.').last.toLowerCase() == normalized.toLowerCase();
          },
          orElse: () => PartnershipType.caseSharing,
        ),
        status: PartnershipStatus.values.firstWhere(
          (e) {
            final raw = (json['status'] ?? '').toString();
            final normalized = raw.contains('.') ? raw.split('.').last : raw;
            return e.toString().split('.').last.toLowerCase() == normalized.toLowerCase();
          },
          orElse: () => PartnershipStatus.pending,
        ),
        createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: (json['updatedAt'] ?? json['updated_at']) != null
            ? DateTime.parse(json['updatedAt'] ?? json['updated_at'])
            : null,
        creatorId: json['creatorId'] ?? json['creator_id'],
        partnerId: json['partnerId'] ?? json['partner_id'],
        linkedCaseId: json['linkedCaseId'] ?? json['case_id'],
        linkedCaseTitle: json['linkedCaseTitle'] ?? json['case_title'],
        linkedCaseType: json['linkedCaseType'] ?? json['case_type'],
        linkedCaseStatus: json['linkedCaseStatus'] ?? json['case_status'],
        contractUrl: json['contractUrl'] ?? json['contract_url'],
        contractAcceptedAt: (json['contractAcceptedAt'] ?? json['contract_accepted_at']) != null
            ? DateTime.parse(json['contractAcceptedAt'] ?? json['contract_accepted_at'])
            : null,
        honorarios: json['honorarios'],
        proposalMessage: json['proposalMessage'] ?? json['proposal_message'],
        unreadCount: json['unreadCount'] ?? json['unread_count'],
        lastActivityAt: (json['lastActivityAt'] ?? json['last_activity_at']) != null
            ? DateTime.parse(json['lastActivityAt'] ?? json['last_activity_at'])
            : null,
        slaDueAt: (json['slaDueAt'] ?? json['sla_due_at']) != null
            ? DateTime.parse(json['slaDueAt'] ?? json['sla_due_at'])
            : null,
        feeModel: json['feeModel'] ?? json['fee_model'],
        feeSplitPercent: (json['feeSplitPercent'] ?? json['fee_split_percent'])?.toDouble(),
        ndaStatus: json['ndaStatus'] ?? json['nda_status'],
        jurisdiction: json['jurisdiction'],
        externalCaseNumber: json['externalCaseNumber'] ?? json['external_case_number'],
        partnerUf: json['partnerUf'] ?? json['partner_uf'],
        partnerCity: json['partnerCity'] ?? json['partner_city'],
        partner: partner,
        partnerType: partnerType,
      );
    } catch (e) {
      throw ServerException(message: 'Erro ao deserializar parceria: ${e.toString()}');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'creatorId': creatorId,
      'partnerId': partnerId,
      'linkedCaseId': linkedCaseId,
      'linkedCaseTitle': linkedCaseTitle,
      'linkedCaseType': linkedCaseType,
      'linkedCaseStatus': linkedCaseStatus,
      'contractUrl': contractUrl,
      'contractAcceptedAt': contractAcceptedAt?.toIso8601String(),
      'honorarios': honorarios,
      'proposalMessage': proposalMessage,
      'unreadCount': unreadCount,
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'slaDueAt': slaDueAt?.toIso8601String(),
      'feeModel': feeModel,
      'feeSplitPercent': feeSplitPercent,
      'ndaStatus': ndaStatus,
      'jurisdiction': jurisdiction,
      'externalCaseNumber': externalCaseNumber,
      'partnerUf': partnerUf,
      'partnerCity': partnerCity,
      'partnerName': partnerName,
      'partnerAvatarUrl': partnerAvatarUrl,
    };
  }
} 