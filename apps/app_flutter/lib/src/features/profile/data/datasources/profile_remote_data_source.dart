import '../../domain/entities/client_profile.dart';

abstract class ProfileRemoteDataSource {
  Future<ClientProfile> getProfile(String userId);
  Future<ClientProfile> updateProfile(ClientProfile profile);
  Future<Document> uploadDocument({
    required String clientId,
    required DocumentType type,
    required String filePath,
    required String originalFileName,
    Map<String, dynamic>? metadata,
  });
  Future<void> deleteDocument(String documentId);
  Future<List<Document>> getDocuments(String clientId);
  Future<Document> verifyDocument(String documentId);
  Future<void> updateCommunicationPreferences({
    required String clientId,
    required CommunicationPreferences preferences,
  });
  Future<void> updatePrivacySettings({
    required String clientId,
    required PrivacySettings settings,
  });
  Future<void> exerciseDataSubjectRight({
    required String clientId,
    required String rightType,
    Map<String, dynamic>? parameters,
  });
  Future<Map<String, dynamic>> exportClientData(String clientId);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  // Mock implementation - substitua por API real
  
  @override
  Future<ClientProfile> getProfile(String userId) async {
    // Simular delay de rede
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Retornar perfil mock
    return ClientProfile(
      id: userId,
      type: ClientType.individual,
      personalData: const PersonalData(
        cpf: '123.456.789-00',
        rg: '12.345.678-9',
        rgIssuingBody: 'SSP/SP',
        profession: 'Engenheiro',
        nationality: 'Brasileiro',
        motherName: 'Maria Silva',
      ),
      contactData: const ContactData(
        primaryPhone: '(11) 99999-9999',
        whatsappNumber: '(11) 99999-9999',
        whatsappAuthorized: true,
        smsAuthorized: true,
      ),
      addresses: const [
        Address(
          id: '1',
          type: AddressType.residential,
          zipCode: '01234-567',
          street: 'Rua das Flores',
          number: '123',
          neighborhood: 'Centro',
          city: 'São Paulo',
          state: 'SP',
          isPrimary: true,
        ),
      ],
      documents: const [],
      communicationPreferences: const CommunicationPreferences(
        preferredChannels: [
          PreferredChannel(
            type: ChannelType.email,
            isEnabled: true,
            priority: 1,
          ),
          PreferredChannel(
            type: ChannelType.whatsapp,
            isEnabled: true,
            priority: 2,
          ),
        ],
        availability: ClientAvailability(
          timezone: 'America/Sao_Paulo',
          weeklySchedule: {
            WeekDay.monday: [TimeSlot(startTime: '09:00', endTime: '18:00')],
            WeekDay.tuesday: [TimeSlot(startTime: '09:00', endTime: '18:00')],
            WeekDay.wednesday: [TimeSlot(startTime: '09:00', endTime: '18:00')],
            WeekDay.thursday: [TimeSlot(startTime: '09:00', endTime: '18:00')],
            WeekDay.friday: [TimeSlot(startTime: '09:00', endTime: '18:00')],
          },
          acceptHolidays: false,
          acceptEmergencyOutsideHours: true,
        ),
        notificationSettings: {
          'case_updates': true,
          'appointment_reminders': true,
          'document_requests': true,
          'payment_reminders': true,
          'news_updates': false,
        },
        authorizations: {
          'emergency_contact': true,
          'third_party_contact': false,
          'marketing_contact': false,
        },
      ),
      privacySettings: PrivacySettings(
        dataUsageConsents: const {
          'service_provision': true,
          'communications': true,
          'service_improvement': false,
          'analytics': false,
        },
        thirdPartySharing: const {
          'law_enforcement': true,
          'service_providers': true,
          'marketing_partners': false,
        },
        allowDataExport: true,
        allowDataDeletion: true,
        lastUpdated: DateTime.now(),
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<ClientProfile> updateProfile(ClientProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Simular update no servidor
    return profile.copyWith(updatedAt: DateTime.now());
  }

  @override
  Future<Document> uploadDocument({
    required String clientId,
    required DocumentType type,
    required String filePath,
    required String originalFileName,
    Map<String, dynamic>? metadata,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Simular upload
    return Document(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      fileName: 'uploaded_${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      originalFileName: originalFileName,
      filePath: 'https://storage.litig1.com/$clientId/${type.name}/$originalFileName',
      mimeType: _getMimeTypeFromFileName(originalFileName),
      fileSize: 1024000, // Mock size
      status: DocumentStatus.pending,
      uploadedAt: DateTime.now(),
      metadata: metadata,
    );
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simular exclusão
  }

  @override
  Future<List<Document>> getDocuments(String clientId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Retornar lista mock
    return [
      Document(
        id: '1',
        type: DocumentType.cpf,
        fileName: 'cpf_cliente.pdf',
        originalFileName: 'CPF_João_Silva.pdf',
        filePath: 'https://storage.litig1.com/$clientId/cpf/CPF_João_Silva.pdf',
        mimeType: 'application/pdf',
        fileSize: 256000,
        status: DocumentStatus.verified,
        uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
        verifiedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Document(
        id: '2',
        type: DocumentType.rg,
        fileName: 'rg_cliente.pdf',
        originalFileName: 'RG_João_Silva.pdf',
        filePath: 'https://storage.litig1.com/$clientId/rg/RG_João_Silva.pdf',
        mimeType: 'application/pdf',
        fileSize: 512000,
        status: DocumentStatus.pending,
        uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  @override
  Future<Document> verifyDocument(String documentId) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Mock document verification
    return Document(
      id: documentId,
      type: DocumentType.cpf,
      fileName: 'cpf_cliente.pdf',
      originalFileName: 'CPF_Cliente.pdf',
      filePath: 'https://storage.litig1.com/client/cpf/CPF_Cliente.pdf',
      mimeType: 'application/pdf',
      fileSize: 256000,
      status: DocumentStatus.verified,
      uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
      verifiedAt: DateTime.now(),
      verificationNotes: 'Documento verificado e aprovado automaticamente.',
    );
  }

  @override
  Future<void> updateCommunicationPreferences({
    required String clientId,
    required CommunicationPreferences preferences,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simular update
  }

  @override
  Future<void> updatePrivacySettings({
    required String clientId,
    required PrivacySettings settings,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simular update
  }

  @override
  Future<void> exerciseDataSubjectRight({
    required String clientId,
    required String rightType,
    Map<String, dynamic>? parameters,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    // Simular processamento do direito LGPD
  }

  @override
  Future<Map<String, dynamic>> exportClientData(String clientId) async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock data export
    return {
      'client_id': clientId,
      'export_date': DateTime.now().toIso8601String(),
      'data_types': ['personal_data', 'documents', 'communications', 'preferences'],
      'download_url': 'https://export.litig1.com/$clientId/data_export.zip',
      'expiry_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    };
  }

  String _getMimeTypeFromFileName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}

// Extension para copyWith em ClientProfile
extension ClientProfileCopyWith on ClientProfile {
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
}