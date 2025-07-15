enum PartnershipType {
  consultoria,
  peticaoTecnica,
  audiencia,
  atuacaoTotal,
  parceriaRecorrente,
}

enum PartnershipStatus {
  pendente,
  aceita,
  rejeitada,
  contratoPendente,
  ativa,
  finalizada,
  cancelada,
}

class Partnership {
  final String id;
  final String creatorId;
  final String partnerId;
  final String? caseId;
  final PartnershipType type;
  final PartnershipStatus status;
  final String honorarios;
  final String? proposalMessage;
  final String? contractUrl;
  final DateTime? contractAcceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? creatorName;
  final String? partnerName;
  final String? caseTitle;

  const Partnership({
    required this.id,
    required this.creatorId,
    required this.partnerId,
    this.caseId,
    required this.type,
    required this.status,
    required this.honorarios,
    this.proposalMessage,
    this.contractUrl,
    this.contractAcceptedAt,
    required this.createdAt,
    required this.updatedAt,
    this.creatorName,
    this.partnerName,
    this.caseTitle,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Partnership && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  Partnership copyWith({
    String? id,
    String? creatorId,
    String? partnerId,
    String? caseId,
    PartnershipType? type,
    PartnershipStatus? status,
    String? honorarios,
    String? proposalMessage,
    String? contractUrl,
    DateTime? contractAcceptedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? creatorName,
    String? partnerName,
    String? caseTitle,
  }) {
    return Partnership(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      partnerId: partnerId ?? this.partnerId,
      caseId: caseId ?? this.caseId,
      type: type ?? this.type,
      status: status ?? this.status,
      honorarios: honorarios ?? this.honorarios,
      proposalMessage: proposalMessage ?? this.proposalMessage,
      contractUrl: contractUrl ?? this.contractUrl,
      contractAcceptedAt: contractAcceptedAt ?? this.contractAcceptedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      creatorName: creatorName ?? this.creatorName,
      partnerName: partnerName ?? this.partnerName,
      caseTitle: caseTitle ?? this.caseTitle,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case PartnershipType.consultoria:
        return 'Consultoria';
      case PartnershipType.peticaoTecnica:
        return 'Petição Técnica';
      case PartnershipType.audiencia:
        return 'Audiência';
      case PartnershipType.atuacaoTotal:
        return 'Atuação Total';
      case PartnershipType.parceriaRecorrente:
        return 'Parceria Recorrente';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case PartnershipStatus.pendente:
        return 'Pendente';
      case PartnershipStatus.aceita:
        return 'Aceita';
      case PartnershipStatus.rejeitada:
        return 'Rejeitada';
      case PartnershipStatus.contratoPendente:
        return 'Contrato Pendente';
      case PartnershipStatus.ativa:
        return 'Ativa';
      case PartnershipStatus.finalizada:
        return 'Finalizada';
      case PartnershipStatus.cancelada:
        return 'Cancelada';
    }
  }

  bool get isActive => status == PartnershipStatus.ativa;
  bool get isPending => status == PartnershipStatus.pendente;
  bool get needsContract => status == PartnershipStatus.contratoPendente;
  bool get isCompleted => status == PartnershipStatus.finalizada;
} 