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

  @override
  List<Object?> get props => [id, title, type, status, createdAt, partner, partnerType];
} 