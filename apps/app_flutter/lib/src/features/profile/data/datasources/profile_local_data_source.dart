import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/client_profile.dart';

abstract class ProfileLocalDataSource {
  Future<ClientProfile?> getProfile(String userId);
  Future<void> cacheProfile(ClientProfile profile);
  Future<void> removeProfile(String userId);
  Future<List<Document>> getDocuments(String clientId);
  Future<void> cacheDocument(Document document);
  Future<void> removeDocument(String documentId);
  Future<void> cacheCommunicationPreferences(String clientId, CommunicationPreferences preferences);
  Future<void> cachePrivacySettings(String clientId, PrivacySettings settings);
  Future<void> clearCache();
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  static const String _profilePrefix = 'profile_';
  static const String _documentsPrefix = 'documents_';
  static const String _communicationPrefix = 'communication_';
  static const String _privacyPrefix = 'privacy_';
  
  @override
  Future<ClientProfile?> getProfile(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('$_profilePrefix$userId');
      
      if (profileJson != null) {
        final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
        return _mapToClientProfile(profileMap);
      }
      
      return null;
    } catch (e) {
      // Log error and return null
      print('Error getting cached profile: $e');
      return null;
    }
  }

  @override
  Future<void> cacheProfile(ClientProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileMap = _clientProfileToMap(profile);
      final profileJson = jsonEncode(profileMap);
      
      await prefs.setString('$_profilePrefix${profile.id}', profileJson);
    } catch (e) {
      print('Error caching profile: $e');
      // Don't throw - caching is optional
    }
  }

  @override
  Future<void> removeProfile(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_profilePrefix$userId');
    } catch (e) {
      print('Error removing cached profile: $e');
    }
  }

  @override
  Future<List<Document>> getDocuments(String clientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final documentsJson = prefs.getString('$_documentsPrefix$clientId');
      
      if (documentsJson != null) {
        final documentsList = jsonDecode(documentsJson) as List<dynamic>;
        return documentsList
            .map((doc) => _mapToDocument(doc as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting cached documents: $e');
      return [];
    }
  }

  @override
  Future<void> cacheDocument(Document document) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing documents for this client
      final clientId = _extractClientIdFromDocument(document);
      final existingDocs = await getDocuments(clientId);
      
      // Update or add the document
      final updatedDocs = existingDocs.where((d) => d.id != document.id).toList();
      updatedDocs.add(document);
      
      // Save back to cache
      final documentsListMap = updatedDocs.map((doc) => _documentToMap(doc)).toList();
      final documentsJson = jsonEncode(documentsListMap);
      
      await prefs.setString('$_documentsPrefix$clientId', documentsJson);
    } catch (e) {
      print('Error caching document: $e');
    }
  }

  @override
  Future<void> removeDocument(String documentId) async {
    try {
      // This is a simplified implementation
      // In a real app, you'd need to know which client the document belongs to
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_documentsPrefix)) {
          final documentsJson = prefs.getString(key);
          if (documentsJson != null) {
            final documentsList = jsonDecode(documentsJson) as List<dynamic>;
            final updatedDocs = documentsList
                .where((doc) => doc['id'] != documentId)
                .toList();
            
            if (updatedDocs.length != documentsList.length) {
              // Document was found and removed
              await prefs.setString(key, jsonEncode(updatedDocs));
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error removing cached document: $e');
    }
  }

  @override
  Future<void> cacheCommunicationPreferences(String clientId, CommunicationPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesMap = _communicationPreferencesToMap(preferences);
      final preferencesJson = jsonEncode(preferencesMap);
      
      await prefs.setString('$_communicationPrefix$clientId', preferencesJson);
    } catch (e) {
      print('Error caching communication preferences: $e');
    }
  }

  @override
  Future<void> cachePrivacySettings(String clientId, PrivacySettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsMap = _privacySettingsToMap(settings);
      final settingsJson = jsonEncode(settingsMap);
      
      await prefs.setString('$_privacyPrefix$clientId', settingsJson);
    } catch (e) {
      print('Error caching privacy settings: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final profileKeys = keys.where((key) =>
          key.startsWith(_profilePrefix) ||
          key.startsWith(_documentsPrefix) ||
          key.startsWith(_communicationPrefix) ||
          key.startsWith(_privacyPrefix));
      
      for (final key in profileKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Helper methods for serialization/deserialization

  Map<String, dynamic> _clientProfileToMap(ClientProfile profile) {
    return {
      'id': profile.id,
      'type': profile.type.name,
      'personalData': _personalDataToMap(profile.personalData),
      'contactData': _contactDataToMap(profile.contactData),
      'addresses': profile.addresses.map((addr) => _addressToMap(addr)).toList(),
      'documents': profile.documents.map((doc) => _documentToMap(doc)).toList(),
      'communicationPreferences': _communicationPreferencesToMap(profile.communicationPreferences),
      'privacySettings': _privacySettingsToMap(profile.privacySettings),
      'createdAt': profile.createdAt.toIso8601String(),
      'updatedAt': profile.updatedAt.toIso8601String(),
    };
  }

  ClientProfile _mapToClientProfile(Map<String, dynamic> map) {
    return ClientProfile(
      id: map['id'] as String,
      type: ClientType.values.firstWhere((e) => e.name == map['type']),
      personalData: _mapToPersonalData(map['personalData'] as Map<String, dynamic>),
      contactData: _mapToContactData(map['contactData'] as Map<String, dynamic>),
      addresses: (map['addresses'] as List<dynamic>)
          .map((addr) => _mapToAddress(addr as Map<String, dynamic>))
          .toList(),
      documents: (map['documents'] as List<dynamic>)
          .map((doc) => _mapToDocument(doc as Map<String, dynamic>))
          .toList(),
      communicationPreferences: _mapToCommunicationPreferences(
          map['communicationPreferences'] as Map<String, dynamic>),
      privacySettings: _mapToPrivacySettings(map['privacySettings'] as Map<String, dynamic>),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> _personalDataToMap(PersonalData data) {
    return {
      'cpf': data.cpf,
      'rg': data.rg,
      'rgIssuingBody': data.rgIssuingBody,
      'birthDate': data.birthDate?.toIso8601String(),
      'maritalStatus': data.maritalStatus,
      'profession': data.profession,
      'nationality': data.nationality,
      'motherName': data.motherName,
      'fatherName': data.fatherName,
      'cnpj': data.cnpj,
      'stateRegistration': data.stateRegistration,
      'municipalRegistration': data.municipalRegistration,
      'legalRepresentative': data.legalRepresentative,
      'companySize': data.companySize,
      'businessSector': data.businessSector,
      'foundingDate': data.foundingDate?.toIso8601String(),
    };
  }

  PersonalData _mapToPersonalData(Map<String, dynamic> map) {
    return PersonalData(
      cpf: map['cpf'] as String?,
      rg: map['rg'] as String?,
      rgIssuingBody: map['rgIssuingBody'] as String?,
      birthDate: map['birthDate'] != null ? DateTime.parse(map['birthDate'] as String) : null,
      maritalStatus: map['maritalStatus'] as String?,
      profession: map['profession'] as String?,
      nationality: map['nationality'] as String?,
      motherName: map['motherName'] as String?,
      fatherName: map['fatherName'] as String?,
      cnpj: map['cnpj'] as String?,
      stateRegistration: map['stateRegistration'] as String?,
      municipalRegistration: map['municipalRegistration'] as String?,
      legalRepresentative: map['legalRepresentative'] as String?,
      companySize: map['companySize'] as String?,
      businessSector: map['businessSector'] as String?,
      foundingDate: map['foundingDate'] != null ? DateTime.parse(map['foundingDate'] as String) : null,
    );
  }

  Map<String, dynamic> _contactDataToMap(ContactData data) {
    return {
      'primaryPhone': data.primaryPhone,
      'secondaryPhone': data.secondaryPhone,
      'whatsappNumber': data.whatsappNumber,
      'emergencyContact': data.emergencyContact,
      'emergencyPhone': data.emergencyPhone,
      'whatsappAuthorized': data.whatsappAuthorized,
      'smsAuthorized': data.smsAuthorized,
      'preferredTimes': data.preferredTimes.map((time) => {
        'day': time.day.name,
        'startTime': time.startTime,
        'endTime': time.endTime,
      }).toList(),
    };
  }

  ContactData _mapToContactData(Map<String, dynamic> map) {
    return ContactData(
      primaryPhone: map['primaryPhone'] as String?,
      secondaryPhone: map['secondaryPhone'] as String?,
      whatsappNumber: map['whatsappNumber'] as String?,
      emergencyContact: map['emergencyContact'] as String?,
      emergencyPhone: map['emergencyPhone'] as String?,
      whatsappAuthorized: map['whatsappAuthorized'] as bool? ?? false,
      smsAuthorized: map['smsAuthorized'] as bool? ?? false,
      preferredTimes: (map['preferredTimes'] as List<dynamic>? ?? [])
          .map((time) => PreferredContactTime(
                day: WeekDay.values.firstWhere((e) => e.name == time['day']),
                startTime: time['startTime'] as String,
                endTime: time['endTime'] as String,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> _addressToMap(Address address) {
    return {
      'id': address.id,
      'type': address.type.name,
      'zipCode': address.zipCode,
      'street': address.street,
      'number': address.number,
      'complement': address.complement,
      'neighborhood': address.neighborhood,
      'city': address.city,
      'state': address.state,
      'country': address.country,
      'isPrimary': address.isPrimary,
      'isActive': address.isActive,
    };
  }

  Address _mapToAddress(Map<String, dynamic> map) {
    return Address(
      id: map['id'] as String,
      type: AddressType.values.firstWhere((e) => e.name == map['type']),
      zipCode: map['zipCode'] as String,
      street: map['street'] as String,
      number: map['number'] as String,
      complement: map['complement'] as String?,
      neighborhood: map['neighborhood'] as String,
      city: map['city'] as String,
      state: map['state'] as String,
      country: map['country'] as String? ?? 'Brasil',
      isPrimary: map['isPrimary'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _documentToMap(Document document) {
    return {
      'id': document.id,
      'type': document.type.name,
      'fileName': document.fileName,
      'originalFileName': document.originalFileName,
      'filePath': document.filePath,
      'mimeType': document.mimeType,
      'fileSize': document.fileSize,
      'status': document.status.name,
      'uploadedAt': document.uploadedAt.toIso8601String(),
      'verifiedAt': document.verifiedAt?.toIso8601String(),
      'verificationNotes': document.verificationNotes,
      'expirationDate': document.expirationDate?.toIso8601String(),
      'metadata': document.metadata,
    };
  }

  Document _mapToDocument(Map<String, dynamic> map) {
    return Document(
      id: map['id'] as String,
      type: DocumentType.values.firstWhere((e) => e.name == map['type']),
      fileName: map['fileName'] as String,
      originalFileName: map['originalFileName'] as String,
      filePath: map['filePath'] as String,
      mimeType: map['mimeType'] as String,
      fileSize: map['fileSize'] as int,
      status: DocumentStatus.values.firstWhere((e) => e.name == map['status']),
      uploadedAt: DateTime.parse(map['uploadedAt'] as String),
      verifiedAt: map['verifiedAt'] != null ? DateTime.parse(map['verifiedAt'] as String) : null,
      verificationNotes: map['verificationNotes'] as String?,
      expirationDate: map['expirationDate'] != null ? DateTime.parse(map['expirationDate'] as String) : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> _communicationPreferencesToMap(CommunicationPreferences preferences) {
    return {
      'preferredChannels': preferences.preferredChannels.map((channel) => {
        'type': channel.type.name,
        'isEnabled': channel.isEnabled,
        'priority': channel.priority,
        'configuration': channel.configuration,
      }).toList(),
      'availability': {
        'timezone': preferences.availability.timezone,
        'weeklySchedule': preferences.availability.weeklySchedule.map((key, value) => MapEntry(
          key.name,
          value.map((slot) => {'startTime': slot.startTime, 'endTime': slot.endTime}).toList(),
        )),
        'acceptHolidays': preferences.availability.acceptHolidays,
        'acceptEmergencyOutsideHours': preferences.availability.acceptEmergencyOutsideHours,
      },
      'notificationSettings': preferences.notificationSettings,
      'authorizations': preferences.authorizations,
    };
  }

  CommunicationPreferences _mapToCommunicationPreferences(Map<String, dynamic> map) {
    return CommunicationPreferences(
      preferredChannels: (map['preferredChannels'] as List<dynamic>)
          .map((channel) => PreferredChannel(
                type: ChannelType.values.firstWhere((e) => e.name == channel['type']),
                isEnabled: channel['isEnabled'] as bool,
                priority: channel['priority'] as int,
                configuration: channel['configuration'] as Map<String, dynamic>?,
              ))
          .toList(),
      availability: ClientAvailability(
        timezone: map['availability']['timezone'] as String,
        weeklySchedule: (map['availability']['weeklySchedule'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            WeekDay.values.firstWhere((e) => e.name == key),
            (value as List<dynamic>)
                .map((slot) => TimeSlot(
                      startTime: slot['startTime'] as String,
                      endTime: slot['endTime'] as String,
                    ))
                .toList(),
          ),
        ),
        acceptHolidays: map['availability']['acceptHolidays'] as bool,
        acceptEmergencyOutsideHours: map['availability']['acceptEmergencyOutsideHours'] as bool,
      ),
      notificationSettings: Map<String, bool>.from(map['notificationSettings'] as Map<String, dynamic>),
      authorizations: Map<String, bool>.from(map['authorizations'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> _privacySettingsToMap(PrivacySettings settings) {
    return {
      'dataUsageConsents': settings.dataUsageConsents,
      'thirdPartySharing': settings.thirdPartySharing,
      'allowDataExport': settings.allowDataExport,
      'allowDataDeletion': settings.allowDataDeletion,
      'lastUpdated': settings.lastUpdated.toIso8601String(),
    };
  }

  PrivacySettings _mapToPrivacySettings(Map<String, dynamic> map) {
    return PrivacySettings(
      dataUsageConsents: Map<String, bool>.from(map['dataUsageConsents'] as Map<String, dynamic>),
      thirdPartySharing: Map<String, bool>.from(map['thirdPartySharing'] as Map<String, dynamic>),
      allowDataExport: map['allowDataExport'] as bool,
      allowDataDeletion: map['allowDataDeletion'] as bool,
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }

  String _extractClientIdFromDocument(Document document) {
    // In a real implementation, you might extract this from the file path or metadata
    // For now, return a mock client ID
    return 'client_123';
  }
}