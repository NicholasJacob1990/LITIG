import '../../domain/entities/partnership.dart';

class PartnershipModel extends Partnership {
  const PartnershipModel({
    required super.id,
    required super.creatorId,
    required super.partnerId,
    super.caseId,
    required super.type,
    required super.status,
    required super.honorarios,
    super.proposalMessage,
    super.contractUrl,
    super.contractAcceptedAt,
    required super.createdAt,
    required super.updatedAt,
    super.creatorName,
    super.partnerName,
    super.caseTitle,
  });

  factory PartnershipModel.fromJson(Map<String, dynamic> json) {
    return PartnershipModel(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      partnerId: json['partner_id'] as String,
      caseId: json['case_id'] as String?,
      type: _parsePartnershipType(json['type'] as String),
      status: _parsePartnershipStatus(json['status'] as String),
      honorarios: json['honorarios'] as String,
      proposalMessage: json['proposal_message'] as String?,
      contractUrl: json['contract_url'] as String?,
      contractAcceptedAt: json['contract_accepted_at'] != null
          ? DateTime.parse(json['contract_accepted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      creatorName: json['creator_name'] as String?,
      partnerName: json['partner_name'] as String?,
      caseTitle: json['case_title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'partner_id': partnerId,
      'case_id': caseId,
      'type': _partnershipTypeToString(type),
      'status': _partnershipStatusToString(status),
      'honorarios': honorarios,
      'proposal_message': proposalMessage,
      'contract_url': contractUrl,
      'contract_accepted_at': contractAcceptedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'creator_name': creatorName,
      'partner_name': partnerName,
      'case_title': caseTitle,
    };
  }

  static PartnershipType _parsePartnershipType(String type) {
    switch (type) {
      case 'consultoria':
        return PartnershipType.consultoria;
      case 'peticao_tecnica':
        return PartnershipType.peticaoTecnica;
      case 'audiencia':
        return PartnershipType.audiencia;
      case 'atuacao_total':
        return PartnershipType.atuacaoTotal;
      case 'parceria_recorrente':
        return PartnershipType.parceriaRecorrente;
      default:
        return PartnershipType.consultoria;
    }
  }

  static PartnershipStatus _parsePartnershipStatus(String status) {
    switch (status) {
      case 'pendente':
        return PartnershipStatus.pendente;
      case 'aceita':
        return PartnershipStatus.aceita;
      case 'rejeitada':
        return PartnershipStatus.rejeitada;
      case 'contrato_pendente':
        return PartnershipStatus.contratoPendente;
      case 'ativa':
        return PartnershipStatus.ativa;
      case 'finalizada':
        return PartnershipStatus.finalizada;
      case 'cancelada':
        return PartnershipStatus.cancelada;
      default:
        return PartnershipStatus.pendente;
    }
  }

  static String _partnershipTypeToString(PartnershipType type) {
    switch (type) {
      case PartnershipType.consultoria:
        return 'consultoria';
      case PartnershipType.peticaoTecnica:
        return 'peticao_tecnica';
      case PartnershipType.audiencia:
        return 'audiencia';
      case PartnershipType.atuacaoTotal:
        return 'atuacao_total';
      case PartnershipType.parceriaRecorrente:
        return 'parceria_recorrente';
    }
  }

  static String _partnershipStatusToString(PartnershipStatus status) {
    switch (status) {
      case PartnershipStatus.pendente:
        return 'pendente';
      case PartnershipStatus.aceita:
        return 'aceita';
      case PartnershipStatus.rejeitada:
        return 'rejeitada';
      case PartnershipStatus.contratoPendente:
        return 'contrato_pendente';
      case PartnershipStatus.ativa:
        return 'ativa';
      case PartnershipStatus.finalizada:
        return 'finalizada';
      case PartnershipStatus.cancelada:
        return 'cancelada';
    }
  }

  Partnership toEntity() {
    return Partnership(
      id: id,
      creatorId: creatorId,
      partnerId: partnerId,
      caseId: caseId,
      type: type,
      status: status,
      honorarios: honorarios,
      proposalMessage: proposalMessage,
      contractUrl: contractUrl,
      contractAcceptedAt: contractAcceptedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      creatorName: creatorName,
      partnerName: partnerName,
      caseTitle: caseTitle,
    );
  }
} 