import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/lawyer.dart';

/// O tipo da parceria jurídica.
enum PartnershipType {
  /// Um advogado atua como correspondente para outro.
  correspondent,
  /// Um especialista fornece um parecer técnico.
  expertOpinion,
  /// Um caso é dividido entre dois ou mais parceiros.
  caseSharing,
}

/// O status atual de uma parceria.
enum PartnershipStatus {
  /// A parceria está pendente de aceitação.
  pending,
  /// A parceria está ativa e em andamento.
  active,
  /// Os termos da parceria estão em negociação.
  negotiation,
  /// A parceria foi concluída.
  closed,
  /// A parceria foi rejeitada por uma das partes.
  rejected,
}

/// O tipo da entidade parceira (advogado ou escritório).
enum PartnerEntityType {
  /// O parceiro é um advogado individual.
  lawyer,
  /// O parceiro é um escritório de advocacia.
  firm,
}

/// Representa uma parceria jurídica entre duas entidades.
///
/// A parceria pode ser entre advogados ou entre um advogado e um escritório.
class Partnership extends Equatable {
  /// ID único da parceria.
  final String id;
  /// Título ou resumo da parceria.
  final String title;
  /// O tipo da parceria (ex: correspondente, parecerista).
  final PartnershipType type;
  /// O status atual da parceria (ex: ativa, pendente).
  final PartnershipStatus status;
  /// A data em que a parceria foi criada.
  final DateTime createdAt;
  /// Data da última atualização.
  final DateTime? updatedAt;
  
  /// Identidade/direção da parceria
  final String? creatorId;
  final String? partnerId;
  
  /// ID do caso vinculado quando a parceria está ligada a um caso do app.
  /// Pode ser `null` quando a parceria é externa.
  final String? linkedCaseId;
  
  /// Título do caso vinculado (opcional, para exibição rápida).
  final String? linkedCaseTitle;
  /// Tipo do caso vinculado (quando disponível)
  final String? linkedCaseType;
  /// Status do caso vinculado (quando disponível)
  final String? linkedCaseStatus;
  
  /// URL do contrato (quando existente).
  final String? contractUrl;
  /// Data de aceite do contrato (quando existente)
  final DateTime? contractAcceptedAt;
  
  /// Texto livre de honorários (quando disponível).
  final String? honorarios;
  
  /// Mensagem de proposta (quando disponível).
  final String? proposalMessage;

  /// Comunicação e SLA
  final int? unreadCount;
  final DateTime? lastActivityAt;
  final DateTime? slaDueAt;

  /// Financeiro
  final String? feeModel; // fixed/hourly/split etc.
  final double? feeSplitPercent; // 0-100

  /// Compliance / Jurisdição
  final String? ndaStatus; // pending/signed/none
  final String? jurisdiction; // comarca/UF
  final String? externalCaseNumber;

  /// Localização do parceiro (quando aplicável)
  final String? partnerUf;
  final String? partnerCity;
  
  /// A entidade parceira, que pode ser um [Lawyer] ou uma [LawFirm].
  final dynamic partner; 
  /// O tipo da entidade parceira, para facilitar o type casting.
  final PartnerEntityType partnerType;

  const Partnership({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.creatorId,
    this.partnerId,
    this.linkedCaseId,
    this.linkedCaseTitle,
    this.linkedCaseType,
    this.linkedCaseStatus,
    this.contractUrl,
    this.contractAcceptedAt,
    this.honorarios,
    this.proposalMessage,
    this.unreadCount,
    this.lastActivityAt,
    this.slaDueAt,
    this.feeModel,
    this.feeSplitPercent,
    this.ndaStatus,
    this.jurisdiction,
    this.externalCaseNumber,
    this.partnerUf,
    this.partnerCity,
    required this.partner,
    required this.partnerType,
  }) : assert(partner is Lawyer || partner is LawFirm, 'Partner must be a Lawyer or a LawFirm');

  /// Getter de conveniência para obter o parceiro como um [Lawyer].
  /// Retorna `null` se o parceiro não for um advogado.
  Lawyer? get partnerAsLawyer {
    if (partner is Lawyer) {
      return partner as Lawyer;
    }
    return null;
  }

  /// Getter de conveniência para obter o parceiro como uma [LawFirm].
  /// Retorna `null` se o parceiro não for um escritório.
  LawFirm? get partnerAsFirm {
    if (partner is LawFirm) {
      return partner as LawFirm;
    }
    return null;
  }

  /// Retorna o nome do parceiro, seja ele um advogado ou um escritório.
  String get partnerName {
    if (partner is Lawyer) {
      return (partner as Lawyer).name;
    } else if (partner is LawFirm) {
      return (partner as LawFirm).name;
    }
    return 'Parceiro desconhecido';
  }

  /// Retorna a URL do avatar do parceiro.
  /// Para escritórios, retorna uma URL de placeholder.
  String get partnerAvatarUrl {
    if (partner is Lawyer) {
      return (partner as Lawyer).avatarUrl;
    }
    // LawFirm doesn't have a standard avatar, return a placeholder.
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(partnerName)}&background=0D8ABC&color=fff';
  }

  /// Indica se a parceria é externa (sem vínculo a caso do app).
  bool get isExternalPartnership => linkedCaseId == null || linkedCaseId!.isEmpty;

  /// Direção da parceria relativa a um usuário atual
  /// Retorna 'sent' se o usuário é o criador; 'received' se é o parceiro; null caso indeterminado
  String? directionForUser(String currentUserId) {
    if (creatorId == currentUserId) return 'sent';
    if (partnerId == currentUserId) return 'received';
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        status,
        createdAt,
        updatedAt,
        creatorId,
        partnerId,
        linkedCaseId,
        linkedCaseTitle,
        linkedCaseType,
        linkedCaseStatus,
        contractUrl,
        contractAcceptedAt,
        honorarios,
        proposalMessage,
        unreadCount,
        lastActivityAt,
        slaDueAt,
        feeModel,
        feeSplitPercent,
        ndaStatus,
        jurisdiction,
        externalCaseNumber,
        partnerUf,
        partnerCity,
        partner,
        partnerType,
      ];
} 