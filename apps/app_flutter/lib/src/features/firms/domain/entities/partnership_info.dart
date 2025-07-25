import 'package:equatable/equatable.dart';

enum PartnershipType { 
  strategic, 
  commercial, 
  referral, 
  international, 
  technology,
  academic
}

enum PartnershipStatus { active, inactive, pending, suspended }

class PartnershipInfo extends Equatable {
  final String id;
  final String partnerName;
  final String partnerLogo;
  final PartnershipType type;
  final PartnershipStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final String description;
  final List<String> benefits;
  final List<String> sharedAreas;
  final String contactPerson;
  final String contactEmail;
  final double collaborationScore;

  const PartnershipInfo({
    required this.id,
    required this.partnerName,
    required this.partnerLogo,
    required this.type,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.description,
    required this.benefits,
    required this.sharedAreas,
    required this.contactPerson,
    required this.contactEmail,
    required this.collaborationScore,
  });

  @override
  List<Object?> get props => [
        id,
        partnerName,
        partnerLogo,
        type,
        status,
        startDate,
        endDate,
        description,
        benefits,
        sharedAreas,
        contactPerson,
        contactEmail,
        collaborationScore,
      ];
}

extension PartnershipTypeExtension on PartnershipType {
  String get displayName {
    switch (this) {
      case PartnershipType.strategic:
        return 'Estratégica';
      case PartnershipType.commercial:
        return 'Comercial';
      case PartnershipType.referral:
        return 'Indicação';
      case PartnershipType.international:
        return 'Internacional';
      case PartnershipType.technology:
        return 'Tecnologia';
      case PartnershipType.academic:
        return 'Acadêmica';
    }
  }
}

extension PartnershipStatusExtension on PartnershipStatus {
  String get displayName {
    switch (this) {
      case PartnershipStatus.active:
        return 'Ativa';
      case PartnershipStatus.inactive:
        return 'Inativa';
      case PartnershipStatus.pending:
        return 'Pendente';
      case PartnershipStatus.suspended:
        return 'Suspensa';
    }
  }
} 