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
    required super.partner,
    required super.partnerType,
  });

  /// Cria uma instância de [PartnershipModel] a partir de um mapa JSON.
  ///
  /// Lança uma [ServerException] se a deserialização falhar.
  factory PartnershipModel.fromJson(Map<String, dynamic> json) {
    try {
      final partnerTypeString = json['partnerType'];
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
        id: json['id'],
        title: json['title'],
        type: PartnershipType.values.firstWhere(
          (e) => e.toString() == 'PartnershipType.${json['type']}',
          orElse: () => PartnershipType.caseSharing,
        ),
        status: PartnershipStatus.values.firstWhere(
          (e) => e.toString() == 'PartnershipStatus.${json['status']}',
          orElse: () => PartnershipStatus.pending,
        ),
        createdAt: DateTime.parse(json['createdAt']),
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
      'partnerName': partnerName,
      'partnerAvatarUrl': partnerAvatarUrl,
    };
  }
} 