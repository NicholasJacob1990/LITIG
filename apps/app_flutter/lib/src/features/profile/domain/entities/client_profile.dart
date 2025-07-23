import 'package:equatable/equatable.dart';

enum ClientType { individual, corporate }

class ClientProfile extends Equatable {
  final String id;
  final ClientType type;
  final PersonalData personalData;
  final ContactData contactData;
  final List<Address> addresses;
  final List<Document> documents;
  final CommunicationPreferences communicationPreferences;
  final PrivacySettings privacySettings;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const ClientProfile({
    required this.id,
    required this.type,
    required this.personalData,
    required this.contactData,
    required this.addresses,
    required this.documents,
    required this.communicationPreferences,
    required this.privacySettings,
    required this.createdAt,
    required this.updatedAt,
  });

  ClientProfile copyWith({
    String? id,
    ClientType? type,
    PersonalData? personalData,
    ContactData? contactData,
    List<Address>? addresses,
    List<Document>? documents,
    CommunicationPreferences? communicationPreferences,
    PrivacySettings? privacySettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientProfile(
      id: id ?? this.id,
      type: type ?? this.type,
      personalData: personalData ?? this.personalData,
      contactData: contactData ?? this.contactData,
      addresses: addresses ?? this.addresses,
      documents: documents ?? this.documents,
      communicationPreferences: communicationPreferences ?? this.communicationPreferences,
      privacySettings: privacySettings ?? this.privacySettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    personalData,
    contactData,
    addresses,
    documents,
    communicationPreferences,
    privacySettings,
    createdAt,
    updatedAt,
  ];
}

class PersonalData extends Equatable {
  // Pessoa Física
  final String? cpf;
  final String? rg;
  final String? rgIssuingBody;
  final DateTime? birthDate;
  final String? maritalStatus;
  final String? profession;
  final String? nationality;
  final String? motherName;
  final String? fatherName;
  
  // Pessoa Jurídica
  final String? cnpj;
  final String? stateRegistration;
  final String? municipalRegistration;
  final String? legalRepresentative;
  final String? companySize;
  final String? businessSector;
  final DateTime? foundingDate;
  
  const PersonalData({
    this.cpf,
    this.rg,
    this.rgIssuingBody,
    this.birthDate,
    this.maritalStatus,
    this.profession,
    this.nationality,
    this.motherName,
    this.fatherName,
    this.cnpj,
    this.stateRegistration,
    this.municipalRegistration,
    this.legalRepresentative,
    this.companySize,
    this.businessSector,
    this.foundingDate,
  });

  @override
  List<Object?> get props => [
    cpf,
    rg,
    rgIssuingBody,
    birthDate,
    maritalStatus,
    profession,
    nationality,
    motherName,
    fatherName,
    cnpj,
    stateRegistration,
    municipalRegistration,
    legalRepresentative,
    companySize,
    businessSector,
    foundingDate,
  ];
}

class ContactData extends Equatable {
  final String? primaryPhone;
  final String? secondaryPhone;
  final String? whatsappNumber;
  final String? emergencyContact;
  final String? emergencyPhone;
  final bool whatsappAuthorized;
  final bool smsAuthorized;
  final List<PreferredContactTime> preferredTimes;
  
  const ContactData({
    this.primaryPhone,
    this.secondaryPhone,
    this.whatsappNumber,
    this.emergencyContact,
    this.emergencyPhone,
    this.whatsappAuthorized = false,
    this.smsAuthorized = false,
    this.preferredTimes = const [],
  });

  @override
  List<Object?> get props => [
    primaryPhone,
    secondaryPhone,
    whatsappNumber,
    emergencyContact,
    emergencyPhone,
    whatsappAuthorized,
    smsAuthorized,
    preferredTimes,
  ];
}

class Address extends Equatable {
  final String id;
  final AddressType type;
  final String zipCode;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String country;
  final bool isPrimary;
  final bool isActive;
  
  const Address({
    required this.id,
    required this.type,
    required this.zipCode,
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    this.country = 'Brasil',
    this.isPrimary = false,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    zipCode,
    street,
    number,
    complement,
    neighborhood,
    city,
    state,
    country,
    isPrimary,
    isActive,
  ];
}

enum AddressType { residential, commercial, billing, correspondence }

class Document extends Equatable {
  final String id;
  final DocumentType type;
  final String fileName;
  final String originalFileName;
  final String filePath;
  final String mimeType;
  final int fileSize;
  final DocumentStatus status;
  final DateTime uploadedAt;
  final DateTime? verifiedAt;
  final String? verificationNotes;
  final DateTime? expirationDate;
  final Map<String, dynamic>? metadata;
  
  const Document({
    required this.id,
    required this.type,
    required this.fileName,
    required this.originalFileName,
    required this.filePath,
    required this.mimeType,
    required this.fileSize,
    required this.status,
    required this.uploadedAt,
    this.verifiedAt,
    this.verificationNotes,
    this.expirationDate,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    fileName,
    originalFileName,
    filePath,
    mimeType,
    fileSize,
    status,
    uploadedAt,
    verifiedAt,
    verificationNotes,
    expirationDate,
    metadata,
  ];
}

enum DocumentType {
  // Pessoa Física
  cpf,
  rg,
  birthCertificate,
  marriageCertificate,
  addressProof,
  incomeProof,
  
  // Pessoa Jurídica
  cnpj,
  stateRegistration,
  articlesOfIncorporation,
  corporateByLaws,
  boardResolution,
  
  // Jurídicos
  powerOfAttorney,
  contract,
  courtDecision,
  petition,
  evidence,
  
  // Outros
  photo,
  signature,
  other
}

enum DocumentStatus {
  pending,
  verified,
  rejected,
  expired,
  archived
}

class CommunicationPreferences extends Equatable {
  final List<PreferredChannel> preferredChannels;
  final ClientAvailability availability;
  final Map<String, bool> notificationSettings;
  final Map<String, bool> authorizations;
  
  const CommunicationPreferences({
    required this.preferredChannels,
    required this.availability,
    required this.notificationSettings,
    required this.authorizations,
  });

  @override
  List<Object?> get props => [
    preferredChannels,
    availability,
    notificationSettings,
    authorizations,
  ];
}

class PreferredChannel extends Equatable {
  final ChannelType type;
  final bool isEnabled;
  final int priority;
  final Map<String, dynamic>? configuration;
  
  const PreferredChannel({
    required this.type,
    required this.isEnabled,
    required this.priority,
    this.configuration,
  });

  @override
  List<Object?> get props => [type, isEnabled, priority, configuration];
}

enum ChannelType {
  email,
  whatsapp,
  sms,
  phone,
  inAppNotification,
  pushNotification
}

class ClientAvailability extends Equatable {
  final String timezone;
  final Map<WeekDay, List<TimeSlot>> weeklySchedule;
  final bool acceptHolidays;
  final bool acceptEmergencyOutsideHours;
  
  const ClientAvailability({
    required this.timezone,
    required this.weeklySchedule,
    required this.acceptHolidays,
    required this.acceptEmergencyOutsideHours,
  });

  List<TimeSlot> getTimeSlotsForDay(WeekDay day) {
    return weeklySchedule[day] ?? [];
  }

  @override
  List<Object?> get props => [
    timezone,
    weeklySchedule,
    acceptHolidays,
    acceptEmergencyOutsideHours,
  ];
}

enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday
}

class TimeSlot extends Equatable {
  final String startTime;
  final String endTime;
  
  const TimeSlot({
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [startTime, endTime];
}

class PreferredContactTime extends Equatable {
  final WeekDay day;
  final String startTime;
  final String endTime;
  
  const PreferredContactTime({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [day, startTime, endTime];
}

class PrivacySettings extends Equatable {
  final Map<String, bool> dataUsageConsents;
  final Map<String, bool> thirdPartySharing;
  final bool allowDataExport;
  final bool allowDataDeletion;
  final DateTime lastUpdated;
  
  const PrivacySettings({
    required this.dataUsageConsents,
    required this.thirdPartySharing,
    required this.allowDataExport,
    required this.allowDataDeletion,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
    dataUsageConsents,
    thirdPartySharing,
    allowDataExport,
    allowDataDeletion,
    lastUpdated,
  ];
}