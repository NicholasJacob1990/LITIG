# Plano de Ação - Perfil Completo do Cliente LITIG-1

## 📋 Sumário Executivo

Este documento apresenta um plano de ação detalhado para implementar um **perfil completo do cliente** no sistema LITIG-1, transformando a interface atual em uma experiência jurídica abrangente e compliant com LGPD.

### 🎯 Objetivo Principal
Criar um perfil de cliente robusto que contenha todas as informações jurídicas essenciais, contratos vigentes, documentos, preferências e configurações de privacidade necessárias para uma prestação de serviços jurídicos de excelência.

### 📊 Estado Atual vs. Estado Desejado

| **Componente** | **Estado Atual** | **Estado Desejado** | **Prioridade** |
|----------------|------------------|---------------------|----------------|
| Dados Básicos | ✅ 30% Implementado | ✅ 100% Completo | 🔴 Alta |
| Contratos Vigentes | ⚠️ Backend OK, Frontend 0% | ✅ Interface Completa | 🔴 Alta |
| Documentos | ❌ 0% Implementado | ✅ Upload e Gestão | 🔴 Alta |
| Comunicação | ❌ 0% Implementado | ✅ Preferências Completas | 🔴 Alta |
| Financeiro | ⚠️ Backend OK, Frontend 20% | ✅ Dashboard Completo | 🟡 Média |
| LGPD | ⚠️ 25% Implementado | ✅ Compliance Total | 🟡 Média |

---

## 🏗️ Arquitetura e Estrutura

### 📱 Nova Estrutura do Menu Perfil

```
👤 PERFIL DO CLIENTE
├── 📊 Dashboard (Métricas e KPIs)
├── 📝 Dados Pessoais
│   ├── 🆔 Informações Básicas
│   ├── 📄 Documentos de Identificação
│   ├── 📍 Endereços
│   └── 📞 Contatos
├── 📄 Contratos e Serviços
│   ├── 📋 Contratos Vigentes
│   ├── ⏳ Propostas Pendentes
│   ├── 📜 Histórico de Contratos
│   └── 🔄 Renovações
├── 💰 Dashboard Financeiro
│   ├── 💳 Pagamentos em Aberto
│   ├── 📊 Histórico de Pagamentos
│   ├── 🧾 Notas Fiscais
│   └── 📈 Análise de Gastos
├── 📞 Comunicação
│   ├── 🎯 Preferências de Contato
│   ├── ⏰ Disponibilidade
│   ├── 🔔 Configurações de Notificação
│   └── 📱 Canais Autorizados
├── 🔒 Privacidade e Segurança
│   ├── 🛡️ Configurações LGPD
│   ├── 🔑 Controle de Acesso
│   ├── 📋 Histórico de Consentimentos
│   └── 🗂️ Portabilidade de Dados
└── ⚙️ Configurações Gerais
    ├── 🎨 Aparência e Tema
    ├── 🌐 Idioma e Região
    ├── 📧 Configurações de Email
    └── 🆘 Ajuda e Suporte
```

---

## 🚀 Fase 1: Fundações (Sprints 1-3) - Prioridade Alta

### **Sprint 1: Dados Pessoais Completos**

#### **📝 1.1 Expansão do Modelo de Dados**

**Arquivo**: `apps/app_flutter/lib/src/features/profile/domain/entities/client_profile.dart`

```dart
class ClientProfile {
  final String id;
  final ClientType type; // PF ou PJ
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
}

// Dados específicos por tipo
class PersonalData {
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
    // Implementar todos os campos opcionais
  });
}

class ContactData {
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
}

class Address {
  final String id;
  final AddressType type; // residential, commercial, billing
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
}

enum AddressType { residential, commercial, billing, correspondence }
```

#### **📄 1.2 Sistema de Documentos**

**Arquivo**: `apps/app_flutter/lib/src/features/profile/domain/entities/document.dart`

```dart
class Document {
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
  pending,      // Aguardando verificação
  verified,     // Verificado e aprovado
  rejected,     // Rejeitado
  expired,      // Documento expirado
  archived      // Arquivado
}
```

#### **🏗️ 1.3 Interface de Dados Pessoais**

**Arquivo**: `apps/app_flutter/lib/src/features/profile/presentation/screens/personal_data_screen.dart`

```dart
class PersonalDataScreen extends StatefulWidget {
  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dados Pessoais'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _savePersonalData,
          ),
        ],
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return PersonalDataSkeletonLoader();
          }
          
          if (state is ProfileLoaded) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Header com tipo de cliente
                    ClientTypeHeader(clientType: state.profile.type),
                    
                    SizedBox(height: 24),
                    
                    // Seções condicionais baseadas no tipo
                    if (state.profile.type == ClientType.individual) 
                      PersonalDataFormPF(
                        personalData: state.profile.personalData,
                        onChanged: _updatePersonalData,
                      )
                    else 
                      PersonalDataFormPJ(
                        personalData: state.profile.personalData,
                        onChanged: _updatePersonalData,
                      ),
                    
                    SizedBox(height: 24),
                    
                    // Dados de contato
                    ContactDataForm(
                      contactData: state.profile.contactData,
                      onChanged: _updateContactData,
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Endereços
                    AddressesSection(
                      addresses: state.profile.addresses,
                      onChanged: _updateAddresses,
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Botões de ação
                    PersonalDataActions(
                      onSave: _savePersonalData,
                      onCancel: _cancelChanges,
                    ),
                  ],
                ),
              ),
            );
          }
          
          return PersonalDataErrorWidget();
        },
      ),
    );
  }
}

// Formulário específico para Pessoa Física
class PersonalDataFormPF extends StatelessWidget {
  final PersonalData personalData;
  final ValueChanged<PersonalData> onChanged;
  
  const PersonalDataFormPF({
    Key? key,
    required this.personalData,
    required this.onChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dados Pessoais', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            
            // CPF
            CPFFormField(
              initialValue: personalData.cpf,
              onChanged: (cpf) => _updateCPF(cpf),
              validator: (value) => CPFValidator.validate(value),
            ),
            
            SizedBox(height: 16),
            
            // RG
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: RGFormField(
                    initialValue: personalData.rg,
                    onChanged: (rg) => _updateRG(rg),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: RGIssuingBodyFormField(
                    initialValue: personalData.rgIssuingBody,
                    onChanged: (body) => _updateRGIssuingBody(body),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Data de nascimento
            DatePickerFormField(
              label: 'Data de Nascimento',
              initialValue: personalData.birthDate,
              onChanged: (date) => _updateBirthDate(date),
              validator: (date) => BirthDateValidator.validate(date),
            ),
            
            SizedBox(height: 16),
            
            // Estado civil
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Estado Civil'),
              value: personalData.maritalStatus,
              items: [
                'Solteiro(a)',
                'Casado(a)',
                'Divorciado(a)',
                'Viúvo(a)',
                'União Estável',
                'Separado(a)',
              ].map((status) => DropdownMenuItem(
                value: status,
                child: Text(status),
              )).toList(),
              onChanged: (status) => _updateMaritalStatus(status),
            ),
            
            SizedBox(height: 16),
            
            // Profissão
            TextFormField(
              decoration: InputDecoration(labelText: 'Profissão'),
              initialValue: personalData.profession,
              onChanged: (profession) => _updateProfession(profession),
            ),
            
            SizedBox(height: 16),
            
            // Nome da mãe
            TextFormField(
              decoration: InputDecoration(labelText: 'Nome da Mãe'),
              initialValue: personalData.motherName,
              onChanged: (name) => _updateMotherName(name),
            ),
          ],
        ),
      ),
    );
  }
}

// Formulário específico para Pessoa Jurídica
class PersonalDataFormPJ extends StatelessWidget {
  final PersonalData personalData;
  final ValueChanged<PersonalData> onChanged;
  
  const PersonalDataFormPJ({
    Key? key,
    required this.personalData,
    required this.onChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dados da Empresa', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            
            // CNPJ
            CNPJFormField(
              initialValue: personalData.cnpj,
              onChanged: (cnpj) => _updateCNPJ(cnpj),
              validator: (value) => CNPJValidator.validate(value),
            ),
            
            SizedBox(height: 16),
            
            // Inscrições
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Inscrição Estadual'),
                    initialValue: personalData.stateRegistration,
                    onChanged: (value) => _updateStateRegistration(value),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Inscrição Municipal'),
                    initialValue: personalData.municipalRegistration,
                    onChanged: (value) => _updateMunicipalRegistration(value),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Representante Legal
            TextFormField(
              decoration: InputDecoration(labelText: 'Representante Legal'),
              initialValue: personalData.legalRepresentative,
              onChanged: (value) => _updateLegalRepresentative(value),
              validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
            ),
            
            SizedBox(height: 16),
            
            // Porte da empresa
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Porte da Empresa'),
              value: personalData.companySize,
              items: [
                'Microempresa (ME)',
                'Empresa de Pequeno Porte (EPP)',
                'Média Empresa',
                'Grande Empresa',
              ].map((size) => DropdownMenuItem(
                value: size,
                child: Text(size),
              )).toList(),
              onChanged: (size) => _updateCompanySize(size),
            ),
            
            SizedBox(height: 16),
            
            // Setor de atuação
            BusinessSectorFormField(
              initialValue: personalData.businessSector,
              onChanged: (sector) => _updateBusinessSector(sector),
            ),
            
            SizedBox(height: 16),
            
            // Data de fundação
            DatePickerFormField(
              label: 'Data de Fundação',
              initialValue: personalData.foundingDate,
              onChanged: (date) => _updateFoundingDate(date),
            ),
          ],
        ),
      ),
    );
  }
}
```

### **Sprint 2: Sistema de Documentos**

#### **📤 2.1 Upload de Documentos**

**Arquivo**: `apps/app_flutter/lib/src/features/profile/presentation/screens/documents_screen.dart`

```dart
class DocumentsScreen extends StatefulWidget {
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documentos'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddDocumentDialog,
          ),
        ],
      ),
      body: BlocBuilder<DocumentsBloc, DocumentsState>(
        builder: (context, state) {
          if (state is DocumentsLoading) {
            return DocumentsSkeletonLoader();
          }
          
          if (state is DocumentsLoaded) {
            return Column(
              children: [
                // Status geral dos documentos
                DocumentsStatusCard(
                  totalDocuments: state.documents.length,
                  verifiedDocuments: state.documents.where((d) => d.status == DocumentStatus.verified).length,
                  pendingDocuments: state.documents.where((d) => d.status == DocumentStatus.pending).length,
                  expiredDocuments: state.documents.where((d) => d.status == DocumentStatus.expired).length,
                ),
                
                // Documentos obrigatórios por tipo de cliente
                RequiredDocumentsSection(
                  clientType: state.clientType,
                  documents: state.documents,
                  onUploadDocument: _uploadDocument,
                ),
                
                // Lista de documentos
                Expanded(
                  child: DocumentsList(
                    documents: state.documents,
                    onViewDocument: _viewDocument,
                    onDeleteDocument: _deleteDocument,
                    onReplaceDocument: _replaceDocument,
                  ),
                ),
              ],
            );
          }
          
          return DocumentsErrorWidget();
        },
      ),
    );
  }
  
  void _showAddDocumentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddDocumentDialog(
        clientType: context.read<ProfileBloc>().state.profile?.type,
        onDocumentAdded: (document) => _uploadDocument(document),
      ),
    );
  }
}

class RequiredDocumentsSection extends StatelessWidget {
  final ClientType clientType;
  final List<Document> documents;
  final Function(DocumentType) onUploadDocument;
  
  const RequiredDocumentsSection({
    Key? key,
    required this.clientType,
    required this.documents,
    required this.onUploadDocument,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final requiredDocs = _getRequiredDocuments();
    
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documentos Obrigatórios', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            
            ...requiredDocs.map((docType) {
              final hasDocument = documents.any((d) => d.type == docType);
              final document = documents.firstWhereOrNull((d) => d.type == docType);
              
              return RequiredDocumentItem(
                documentType: docType,
                hasDocument: hasDocument,
                document: document,
                onUpload: () => onUploadDocument(docType),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  List<DocumentType> _getRequiredDocuments() {
    switch (clientType) {
      case ClientType.individual:
        return [
          DocumentType.cpf,
          DocumentType.rg,
          DocumentType.addressProof,
        ];
      case ClientType.corporate:
        return [
          DocumentType.cnpj,
          DocumentType.articlesOfIncorporation,
          DocumentType.addressProof,
        ];
    }
  }
}

class RequiredDocumentItem extends StatelessWidget {
  final DocumentType documentType;
  final bool hasDocument;
  final Document? document;
  final VoidCallback onUpload;
  
  const RequiredDocumentItem({
    Key? key,
    required this.documentType,
    required this.hasDocument,
    this.document,
    required this.onUpload,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Ícone de status
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getStatusIcon(),
              color: _getStatusColor(),
            ),
          ),
          
          SizedBox(width: 12),
          
          // Informações do documento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDocumentName(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 4),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (document?.expirationDate != null) ...[ 
                  SizedBox(height: 4),
                  Text(
                    'Vence em: ${DateFormat('dd/MM/yyyy').format(document!.expirationDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isExpiringSoon() ? Colors.orange : Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Botão de ação
          if (!hasDocument)
            ElevatedButton.icon(
              icon: Icon(Icons.upload),
              label: Text('Enviar'),
              onPressed: onUpload,
            )
          else
            PopupMenuButton<String>(
              onSelected: (action) => _handleAction(action),
              itemBuilder: (context) => [
                PopupMenuItem(value: 'view', child: Text('Visualizar')),
                PopupMenuItem(value: 'replace', child: Text('Substituir')),
                if (document?.status == DocumentStatus.rejected)
                  PopupMenuItem(value: 'resubmit', child: Text('Reenviar')),
              ],
            ),
        ],
      ),
    );
  }
}
```

#### **📁 2.2 Gerenciamento de Arquivos**

**Arquivo**: `apps/app_flutter/lib/src/features/profile/data/repositories/document_repository_impl.dart`

```dart
class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDataSource remoteDataSource;
  final DocumentLocalDataSource localDataSource;
  final FileService fileService;
  
  const DocumentRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.fileService,
  });
  
  @override
  Future<Either<Failure, Document>> uploadDocument({
    required String clientId,
    required DocumentType type,
    required File file,
    required String originalFileName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validações
      final validationResult = await _validateDocument(file, type);
      if (validationResult.isLeft()) {
        return validationResult;
      }
      
      // Compressão/otimização se necessário
      final optimizedFile = await _optimizeFile(file, type);
      
      // Gerar nome único
      final fileName = _generateFileName(clientId, type, originalFileName);
      
      // Upload para storage
      final fileUrl = await fileService.uploadFile(
        file: optimizedFile,
        path: 'documents/$clientId/$fileName',
        metadata: {
          'client_id': clientId,
          'document_type': type.name,
          'original_name': originalFileName,
          ...?metadata,
        },
      );
      
      // Criar registro no banco
      final document = await remoteDataSource.createDocument(
        clientId: clientId,
        type: type,
        fileName: fileName,
        originalFileName: originalFileName,
        filePath: fileUrl,
        mimeType: _getMimeType(file),
        fileSize: await file.length(),
        metadata: metadata,
      );
      
      // Cache local
      await localDataSource.cacheDocument(document);
      
      return Right(document);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  Future<Either<Failure, void>> _validateDocument(File file, DocumentType type) async {
    // Verificar tamanho do arquivo
    final fileSize = await file.length();
    const maxSize = 10 * 1024 * 1024; // 10MB
    
    if (fileSize > maxSize) {
      return Left(ValidationFailure('Arquivo muito grande. Máximo 10MB.'));
    }
    
    // Verificar tipo de arquivo
    final allowedTypes = _getAllowedMimeTypes(type);
    final mimeType = _getMimeType(file);
    
    if (!allowedTypes.contains(mimeType)) {
      return Left(ValidationFailure('Tipo de arquivo não permitido.'));
    }
    
    // Verificar integridade (vírus, etc.)
    final isSecure = await _scanFile(file);
    if (!isSecure) {
      return Left(SecurityFailure('Arquivo contém conteúdo suspeito.'));
    }
    
    return Right(null);
  }
  
  Future<File> _optimizeFile(File file, DocumentType type) async {
    final mimeType = _getMimeType(file);
    
    // Otimização para imagens
    if (mimeType.startsWith('image/')) {
      return await ImageOptimizer.optimize(
        file,
        maxWidth: 2048,
        maxHeight: 2048,
        quality: 85,
      );
    }
    
    // Otimização para PDFs
    if (mimeType == 'application/pdf') {
      return await PDFOptimizer.optimize(file);
    }
    
    return file;
  }
}
```

### **Sprint 3: Preferências de Comunicação**

#### **📞 3.1 Interface de Comunicação**

**Arquivo**: `apps/app_flutter/lib/src/features/profile/presentation/screens/communication_preferences_screen.dart`

```dart
class CommunicationPreferencesScreen extends StatefulWidget {
  @override
  State<CommunicationPreferencesScreen> createState() => _CommunicationPreferencesScreenState();
}

class _CommunicationPreferencesScreenState extends State<CommunicationPreferencesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preferências de Comunicação'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _savePreferences,
          ),
        ],
      ),
      body: BlocBuilder<CommunicationBloc, CommunicationState>(
        builder: (context, state) {
          if (state is CommunicationLoading) {
            return CommunicationSkeletonLoader();
          }
          
          if (state is CommunicationLoaded) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Canais preferenciais
                  PreferredChannelsSection(
                    preferences: state.preferences,
                    onChanged: _updatePreferences,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Horários de disponibilidade
                  AvailabilitySection(
                    availability: state.preferences.availability,
                    onChanged: _updateAvailability,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Configurações de notificação
                  NotificationSettingsSection(
                    settings: state.preferences.notificationSettings,
                    onChanged: _updateNotificationSettings,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Autorizações específicas
                  AuthorizationsSection(
                    authorizations: state.preferences.authorizations,
                    onChanged: _updateAuthorizations,
                  ),
                ],
              ),
            );
          }
          
          return CommunicationErrorWidget();
        },
      ),
    );
  }
}

class PreferredChannelsSection extends StatelessWidget {
  final CommunicationPreferences preferences;
  final ValueChanged<CommunicationPreferences> onChanged;
  
  const PreferredChannelsSection({
    Key? key,
    required this.preferences,
    required this.onChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Canais Preferenciais', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            
            Text('Selecione por ordem de preferência:', style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: 12),
            
            // Lista reordenável de canais
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: preferences.preferredChannels.length,
              onReorder: _reorderChannels,
              itemBuilder: (context, index) {
                final channel = preferences.preferredChannels[index];
                return PreferredChannelItem(
                  key: ValueKey(channel.type),
                  channel: channel,
                  position: index + 1,
                  onToggle: (enabled) => _toggleChannel(channel.type, enabled),
                  onConfigureDetails: () => _configureChannelDetails(channel.type),
                );
              },
            ),
            
            SizedBox(height: 16),
            
            // Adicionar novo canal
            OutlinedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Adicionar Canal'),
              onPressed: _showAddChannelDialog,
            ),
          ],
        ),
      ),
    );
  }
}

class PreferredChannelItem extends StatelessWidget {
  final PreferredChannel channel;
  final int position;
  final ValueChanged<bool> onToggle;
  final VoidCallback onConfigureDetails;
  
  const PreferredChannelItem({
    Key? key,
    required this.channel,
    required this.position,
    required this.onToggle,
    required this.onConfigureDetails,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Número da posição
            CircleAvatar(
              radius: 12,
              backgroundColor: channel.isEnabled ? Theme.of(context).primaryColor : Colors.grey,
              child: Text(
                '$position',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 8),
            // Ícone do canal
            Icon(_getChannelIcon(channel.type)),
          ],
        ),
        title: Text(_getChannelName(channel.type)),
        subtitle: Text(_getChannelDescription(channel)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Switch de ativação
            Switch(
              value: channel.isEnabled,
              onChanged: onToggle,
            ),
            // Botão de configuração
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: channel.isEnabled ? onConfigureDetails : null,
            ),
            // Handle para reordenação
            Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }
}

class AvailabilitySection extends StatelessWidget {
  final ClientAvailability availability;
  final ValueChanged<ClientAvailability> onChanged;
  
  const AvailabilitySection({
    Key? key,
    required this.availability,
    required this.onChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Horários de Disponibilidade', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            
            // Timezone
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Fuso Horário'),
              value: availability.timezone,
              items: [
                'America/Sao_Paulo',
                'America/Manaus',
                'America/Fortaleza',
                'America/Rio_Branco',
              ].map((tz) => DropdownMenuItem(
                value: tz,
                child: Text(_getTimezoneName(tz)),
              )).toList(),
              onChanged: (tz) => _updateTimezone(tz),
            ),
            
            SizedBox(height: 16),
            
            // Horários por dia da semana
            ...WeekDay.values.map((day) => AvailabilityDayItem(
              day: day,
              timeSlots: availability.getTimeSlotsForDay(day),
              onChanged: (slots) => _updateDayAvailability(day, slots),
            )),
            
            SizedBox(height: 16),
            
            // Configurações especiais
            SwitchListTile(
              title: Text('Aceitar contatos em feriados'),
              value: availability.acceptHolidays,
              onChanged: (value) => _updateAcceptHolidays(value),
            ),
            
            SwitchListTile(
              title: Text('Aceitar contatos de emergência fora do horário'),
              value: availability.acceptEmergencyOutsideHours,
              onChanged: (value) => _updateAcceptEmergency(value),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🚀 Fase 2: Contratos e Financeiro (Sprints 4-6) - Prioridade Alta

### **Sprint 4: Interface de Contratos Vigentes**

#### **📄 4.1 Tela de Contratos**

**Arquivo**: `apps/app_flutter/lib/src/features/profile/presentation/screens/contracts_screen.dart`

```dart
class ContractsScreen extends StatefulWidget {
  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contratos e Serviços'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Vigentes', icon: Icon(Icons.verified)),
            Tab(text: 'Pendentes', icon: Icon(Icons.pending)),
            Tab(text: 'Histórico', icon: Icon(Icons.history)),
            Tab(text: 'Renovações', icon: Icon(Icons.refresh)),
          ],
        ),
      ),
      body: BlocBuilder<ContractsBloc, ContractsState>(
        builder: (context, state) {
          if (state is ContractsLoading) {
            return ContractsSkeletonLoader();
          }
          
          if (state is ContractsLoaded) {
            return Column(
              children: [
                // Resumo de contratos
                ContractsSummaryCard(
                  activeContracts: state.activeContracts.length,
                  pendingContracts: state.pendingContracts.length,
                  totalValue: state.totalContractValue,
                  monthlyValue: state.monthlyContractValue,
                ),
                
                // Conteúdo das abas
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Contratos vigentes
                      ActiveContractsTab(contracts: state.activeContracts),
                      
                      // Contratos pendentes
                      PendingContractsTab(contracts: state.pendingContracts),
                      
                      // Histórico
                      ContractHistoryTab(contracts: state.historicalContracts),
                      
                      // Renovações
                      ContractRenewalsTab(contracts: state.renewalContracts),
                    ],
                  ),
                ),
              ],
            );
          }
          
          return ContractsErrorWidget();
        },
      ),
    );
  }
}

class ActiveContractsTab extends StatelessWidget {
  final List<Contract> contracts;
  
  const ActiveContractsTab({Key? key, required this.contracts}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (contracts.isEmpty) {
      return EmptyContractsWidget(
        title: 'Nenhum contrato vigente',
        message: 'Você não possui contratos ativos no momento.',
        action: EmptyStateAction(
          label: 'Buscar Advogados',
          onPressed: () => context.push('/lawyers'),
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: contracts.length,
      itemBuilder: (context, index) {
        final contract = contracts[index];
        return ActiveContractCard(
          contract: contract,
          onView: () => _viewContract(contract),
          onDownload: () => _downloadContract(contract),
          onContact: () => _contactLawyer(contract),
          onTerminate: () => _terminateContract(contract),
        );
      },
    );
  }
}

class ActiveContractCard extends StatelessWidget {
  final Contract contract;
  final VoidCallback onView;
  final VoidCallback onDownload;
  final VoidCallback onContact;
  final VoidCallback onTerminate;
  
  const ActiveContractCard({
    Key? key,
    required this.contract,
    required this.onView,
    required this.onDownload,
    required this.onContact,
    required this.onTerminate,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do contrato
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.caseName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Contrato #${contract.id.substring(0, 8)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ContractStatusChip(status: contract.status),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Informações do advogado
            LawyerInfoSection(
              lawyer: contract.lawyer,
              showContactButton: true,
              onContact: onContact,
            ),
            
            SizedBox(height: 16),
            
            // Informações financeiras
            ContractFinancialInfo(
              feeModel: contract.feeModel,
              totalValue: contract.totalValue,
              paidValue: contract.paidValue,
              pendingValue: contract.pendingValue,
            ),
            
            SizedBox(height: 16),
            
            // Datas importantes
            ContractDatesInfo(
              startDate: contract.startDate,
              endDate: contract.endDate,
              renewalDate: contract.renewalDate,
            ),
            
            SizedBox(height: 16),
            
            // Ações
            Row(
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.visibility),
                  label: Text('Visualizar'),
                  onPressed: onView,
                ),
                SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: Icon(Icons.download),
                  label: Text('Download'),
                  onPressed: onDownload,
                ),
                Spacer(),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleAction(action),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'modify', child: Text('Solicitar Alteração')),
                    PopupMenuItem(value: 'terminate', child: Text('Encerrar Contrato')),
                    PopupMenuItem(value: 'renew', child: Text('Renovar')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### **Sprint 5: Dashboard Financeiro**

#### **💰 5.1 Interface Financeira**

**Arquivo**: `apps/app_flutter/lib/src/features/profile/presentation/screens/financial_dashboard_screen.dart`

```dart
class FinancialDashboardScreen extends StatefulWidget {
  @override
  State<FinancialDashboardScreen> createState() => _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Financeiro'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportFinancialReport,
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: BlocBuilder<FinancialBloc, FinancialState>(
        builder: (context, state) {
          if (state is FinancialLoading) {
            return FinancialSkeletonLoader();
          }
          
          if (state is FinancialLoaded) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Resumo financeiro
                  FinancialSummaryCard(
                    totalInvested: state.summary.totalInvested,
                    totalPending: state.summary.totalPending,
                    totalPaid: state.summary.totalPaid,
                    monthlyAverage: state.summary.monthlyAverage,
                    roi: state.summary.roi,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Gráfico de gastos por período
                  FinancialChart(
                    data: state.monthlyData,
                    period: state.selectedPeriod,
                    onPeriodChanged: _changePeriod,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Pagamentos em aberto
                  PendingPaymentsSection(
                    payments: state.pendingPayments,
                    onPaymentAction: _handlePaymentAction,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Histórico de pagamentos
                  PaymentHistorySection(
                    payments: state.paymentHistory,
                    onViewDetails: _viewPaymentDetails,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Análise de gastos por área jurídica
                  LegalAreaAnalysis(
                    areaData: state.areaAnalysis,
                  ),
                ],
              ),
            );
          }
          
          return FinancialErrorWidget();
        },
      ),
    );
  }
}

class FinancialSummaryCard extends StatelessWidget {
  final double totalInvested;
  final double totalPending;
  final double totalPaid;
  final double monthlyAverage;
  final double roi;
  
  const FinancialSummaryCard({
    Key? key,
    required this.totalInvested,
    required this.totalPending,
    required this.totalPaid,
    required this.monthlyAverage,
    required this.roi,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo Financeiro', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            
            // KPIs principais
            Row(
              children: [
                Expanded(
                  child: FinancialKPICard(
                    title: 'Total Investido',
                    value: _formatCurrency(totalInvested),
                    icon: Icons.account_balance_wallet,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: FinancialKPICard(
                    title: 'Em Aberto',
                    value: _formatCurrency(totalPending),
                    icon: Icons.schedule,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: FinancialKPICard(
                    title: 'Pago',
                    value: _formatCurrency(totalPaid),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: FinancialKPICard(
                    title: 'ROI Médio',
                    value: '${roi.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    color: roi > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Média mensal
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text('Média mensal: ${_formatCurrency(monthlyAverage)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PendingPaymentsSection extends StatelessWidget {
  final List<Payment> payments;
  final Function(Payment, PaymentAction) onPaymentAction;
  
  const PendingPaymentsSection({
    Key? key,
    required this.payments,
    required this.onPaymentAction,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Pagamentos em Aberto', style: Theme.of(context).textTheme.titleLarge),
                Spacer(),
                if (payments.isNotEmpty)
                  Chip(
                    label: Text('${payments.length}'),
                    backgroundColor: Colors.orange[100],
                  ),
              ],
            ),
            
            SizedBox(height: 16),
            
            if (payments.isEmpty)
              EmptyPaymentsWidget()
            else
              ...payments.map((payment) => PendingPaymentItem(
                payment: payment,
                onAction: (action) => onPaymentAction(payment, action),
              )),
          ],
        ),
      ),
    );
  }
}

class PendingPaymentItem extends StatelessWidget {
  final Payment payment;
  final Function(PaymentAction) onAction;
  
  const PendingPaymentItem({
    Key? key,
    required this.payment,
    required this.onAction,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.description,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Vencimento: ${DateFormat('dd/MM/yyyy').format(payment.dueDate)}',
                      style: TextStyle(
                        color: _isOverdue(payment.dueDate) ? Colors.red : Colors.grey[600],
                        fontWeight: _isOverdue(payment.dueDate) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatCurrency(payment.amount),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Informações do advogado/caso
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(payment.lawyerName.substring(0, 1)),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payment.lawyerName),
                    Text(
                      payment.caseName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Ações
          Row(
            children: [
              OutlinedButton.icon(
                icon: Icon(Icons.visibility),
                label: Text('Detalhes'),
                onPressed: () => onAction(PaymentAction.viewDetails),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.payment),
                label: Text('Pagar'),
                onPressed: () => onAction(PaymentAction.pay),
              ),
              Spacer(),
              PopupMenuButton<PaymentAction>(
                onSelected: onAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: PaymentAction.downloadInvoice,
                    child: Text('Baixar Fatura'),
                  ),
                  PopupMenuItem(
                    value: PaymentAction.negotiate,
                    child: Text('Negociar'),
                  ),
                  PopupMenuItem(
                    value: PaymentAction.dispute,
                    child: Text('Contestar'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### **Sprint 6: Integrações de Pagamento**

#### **💳 6.1 Sistema de Pagamentos**

**Arquivo**: `apps/app_flutter/lib/src/features/profile/presentation/screens/payment_screen.dart`

```dart
class PaymentScreen extends StatefulWidget {
  final Payment payment;
  
  const PaymentScreen({Key? key, required this.payment}) : super(key: key);
  
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pagamento'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Resumo do pagamento
            PaymentSummaryCard(payment: widget.payment),
            
            SizedBox(height: 24),
            
            // Métodos de pagamento
            PaymentMethodsSection(
              selectedMethod: _selectedMethod,
              onMethodSelected: (method) => setState(() => _selectedMethod = method),
            ),
            
            SizedBox(height: 24),
            
            // Formulário específico do método selecionado
            if (_selectedMethod != null)
              PaymentFormSection(
                method: _selectedMethod!,
                payment: widget.payment,
                onFormChanged: _updatePaymentForm,
              ),
            
            SizedBox(height: 24),
            
            // Termos e condições
            PaymentTermsSection(),
            
            SizedBox(height: 32),
            
            // Botão de pagamento
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _canProceedWithPayment() ? _processPayment : null,
                child: _isProcessing
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Efetuar Pagamento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    
    try {
      final result = await context.read<PaymentBloc>().processPayment(
        payment: widget.payment,
        method: _selectedMethod!,
        formData: _paymentFormData,
      );
      
      if (result.isSuccess) {
        _showPaymentSuccessDialog();
      } else {
        _showPaymentErrorDialog(result.error);
      }
    } catch (e) {
      _showPaymentErrorDialog(e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}

class PaymentMethodsSection extends StatelessWidget {
  final PaymentMethod? selectedMethod;
  final ValueChanged<PaymentMethod> onMethodSelected;
  
  const PaymentMethodsSection({
    Key? key,
    required this.selectedMethod,
    required this.onMethodSelected,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Método de Pagamento', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            
            // PIX
            PaymentMethodOption(
              method: PaymentMethod.pix,
              title: 'PIX',
              subtitle: 'Pagamento instantâneo',
              icon: Icons.qr_code,
              isSelected: selectedMethod == PaymentMethod.pix,
              onSelected: () => onMethodSelected(PaymentMethod.pix),
              benefits: ['Instantâneo', 'Sem taxas', 'Disponível 24h'],
            ),
            
            SizedBox(height: 12),
            
            // Cartão de crédito
            PaymentMethodOption(
              method: PaymentMethod.creditCard,
              title: 'Cartão de Crédito',
              subtitle: 'Até 12x sem juros',
              icon: Icons.credit_card,
              isSelected: selectedMethod == PaymentMethod.creditCard,
              onSelected: () => onMethodSelected(PaymentMethod.creditCard),
              benefits: ['Parcelamento', 'Proteção ao comprador', 'Pontos/milhas'],
            ),
            
            SizedBox(height: 12),
            
            // Boleto bancário
            PaymentMethodOption(
              method: PaymentMethod.bankSlip,
              title: 'Boleto Bancário',
              subtitle: 'Vencimento em 3 dias úteis',
              icon: Icons.receipt,
              isSelected: selectedMethod == PaymentMethod.bankSlip,
              onSelected: () => onMethodSelected(PaymentMethod.bankSlip),
              benefits: ['Sem cartão necessário', 'Pagamento em qualquer banco'],
            ),
            
            SizedBox(height: 12),
            
            // Transferência bancária
            PaymentMethodOption(
              method: PaymentMethod.bankTransfer,
              title: 'Transferência Bancária',
              subtitle: 'TEF ou TED',
              icon: Icons.account_balance,
              isSelected: selectedMethod == PaymentMethod.bankTransfer,
              onSelected: () => onMethodSelected(PaymentMethod.bankTransfer),
              benefits: ['Seguro', 'Comprovante bancário'],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🚀 Fase 3: Privacidade e Configurações (Sprints 7-9) - Prioridade Média

### **Sprint 7: Configurações LGPD**

#### **🔒 7.1 Interface LGPD**

**Arquivo**: `apps/app_flutter/lib/src/features/profile/presentation/screens/privacy_settings_screen.dart`

```dart
class PrivacySettingsScreen extends StatefulWidget {
  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacidade e Proteção de Dados'),
        backgroundColor: Colors.purple[700],
      ),
      body: BlocBuilder<PrivacyBloc, PrivacyState>(
        builder: (context, state) {
          if (state is PrivacyLoading) {
            return PrivacySkeletonLoader();
          }
          
          if (state is PrivacyLoaded) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header LGPD
                  LGPDHeaderCard(),
                  
                  SizedBox(height: 24),
                  
                  // Consentimentos
                  ConsentManagementSection(
                    consents: state.consents,
                    onConsentChanged: _updateConsent,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Finalidades de uso
                  DataUsagePurposesSection(
                    purposes: state.dataUsagePurposes,
                    onPurposeChanged: _updatePurpose,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Compartilhamento com terceiros
                  ThirdPartyDataSharingSection(
                    sharing: state.thirdPartySharing,
                    onSharingChanged: _updateSharing,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Direitos do titular
                  DataSubjectRightsSection(
                    onExerciseRight: _exerciseDataRight,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Histórico de atividades
                  PrivacyActivitySection(
                    activities: state.privacyActivities,
                  ),
                ],
              ),
            );
          }
          
          return PrivacyErrorWidget();
        },
      ),
    );
  }
}

class LGPDHeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.purple[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.security,
              size: 48,
              color: Colors.purple[700],
            ),
            SizedBox(height: 16),
            Text(
              'Proteção de Dados - LGPD',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.purple[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Seus dados pessoais são protegidos conforme a Lei Geral de Proteção de Dados (Lei 13.709/2018). '
              'Você tem controle total sobre como suas informações são coletadas, processadas e compartilhadas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.purple[800]),
            ),
            SizedBox(height: 16),
            OutlinedButton.icon(
              icon: Icon(Icons.info_outline),
              label: Text('Saiba mais sobre a LGPD'),
              onPressed: () => _showLGPDInfo(),
            ),
          ],
        ),
      ),
    );
  }
}

class ConsentManagementSection extends StatelessWidget {
  final List<DataConsent> consents;
  final Function(DataConsent, bool) onConsentChanged;
  
  const ConsentManagementSection({
    Key? key,
    required this.consents,
    required this.onConsentChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consentimentos', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text(
              'Gerencie suas autorizações para processamento de dados pessoais.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            
            ...consents.map((consent) => ConsentItem(
              consent: consent,
              onChanged: (value) => onConsentChanged(consent, value),
            )),
          ],
        ),
      ),
    );
  }
}

class ConsentItem extends StatelessWidget {
  final DataConsent consent;
  final ValueChanged<bool> onChanged;
  
  const ConsentItem({
    Key? key,
    required this.consent,
    required this.onChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consent.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 4),
                    Text(
                      consent.description,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Switch(
                value: consent.isGranted,
                onChanged: consent.isRequired ? null : onChanged,
              ),
            ],
          ),
          
          if (consent.isRequired) ...[ 
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Consentimento obrigatório para o funcionamento do serviço.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (consent.legalBasis != null) ...[ 
            SizedBox(height: 8),
            Text(
              'Base legal: ${consent.legalBasis}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          
          // Data de consentimento
          SizedBox(height: 8),
          Text(
            'Consentimento ${consent.isGranted ? "concedido" : "negado"} em ${DateFormat('dd/MM/yyyy HH:mm').format(consent.consentDate)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class DataSubjectRightsSection extends StatelessWidget {
  final Function(DataSubjectRight) onExerciseRight;
  
  const DataSubjectRightsSection({
    Key? key,
    required this.onExerciseRight,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seus Direitos como Titular de Dados', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text(
              'A LGPD garante diversos direitos sobre seus dados pessoais.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            
            // Direito de acesso
            DataRightOption(
              icon: Icons.visibility,
              title: 'Acessar meus dados',
              description: 'Solicitar uma cópia de todos os dados pessoais que processamos sobre você.',
              onTap: () => onExerciseRight(DataSubjectRight.access),
            ),
            
            // Direito de retificação
            DataRightOption(
              icon: Icons.edit,
              title: 'Corrigir meus dados',
              description: 'Solicitar correção de dados pessoais inexatos ou incompletos.',
              onTap: () => onExerciseRight(DataSubjectRight.rectification),
            ),
            
            // Direito de exclusão
            DataRightOption(
              icon: Icons.delete_forever,
              title: 'Excluir meus dados',
              description: 'Solicitar a exclusão de dados pessoais quando não há necessidade de processamento.',
              onTap: () => onExerciseRight(DataSubjectRight.erasure),
              isDestructive: true,
            ),
            
            // Direito de portabilidade
            DataRightOption(
              icon: Icons.file_download,
              title: 'Exportar meus dados',
              description: 'Obter seus dados em formato estruturado e legível por máquina.',
              onTap: () => onExerciseRight(DataSubjectRight.portability),
            ),
            
            // Direito de oposição
            DataRightOption(
              icon: Icons.block,
              title: 'Opor-se ao processamento',
              description: 'Opor-se ao processamento de dados pessoais em situações específicas.',
              onTap: () => onExerciseRight(DataSubjectRight.objection),
            ),
            
            // Direito de limitação
            DataRightOption(
              icon: Icons.pause_circle,
              title: 'Limitar processamento',
              description: 'Solicitar limitação do processamento em circunstâncias específicas.',
              onTap: () => onExerciseRight(DataSubjectRight.restriction),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🚀 Fase 4: Melhorias e Otimizações (Sprints 10-12) - Prioridade Baixa

### **Sprint 10: Configurações Avançadas**

#### **⚙️ 10.1 Configurações Gerais**

**Arquivo**: `apps/app_flutter/lib/src/features/profile/presentation/screens/advanced_settings_screen.dart`

```dart
class AdvancedSettingsScreen extends StatefulWidget {
  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações Avançadas'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoaded) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Aparência e tema
                  AppearanceSettingsSection(
                    settings: state.appearanceSettings,
                    onSettingsChanged: _updateAppearanceSettings,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Idioma e região
                  LanguageRegionSection(
                    settings: state.languageSettings,
                    onSettingsChanged: _updateLanguageSettings,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Notificações avançadas
                  AdvancedNotificationsSection(
                    settings: state.notificationSettings,
                    onSettingsChanged: _updateNotificationSettings,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Segurança
                  SecuritySettingsSection(
                    settings: state.securitySettings,
                    onSettingsChanged: _updateSecuritySettings,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Backup e sincronização
                  BackupSyncSection(
                    settings: state.backupSettings,
                    onSettingsChanged: _updateBackupSettings,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Integrações
                  IntegrationsSection(
                    integrations: state.integrations,
                    onIntegrationChanged: _updateIntegration,
                  ),
                ],
              ),
            );
          }
          
          return SettingsSkeletonLoader();
        },
      ),
    );
  }
}
```

### **Sprint 11: Integrações Sociais**

#### **🔗 11.1 Login Social Completo**

**Arquivo**: `apps/app_flutter/lib/src/features/profile/presentation/screens/social_integrations_screen.dart`

```dart
class SocialIntegrationsScreen extends StatefulWidget {
  @override
  State<SocialIntegrationsScreen> createState() => _SocialIntegrationsScreenState();
}

class _SocialIntegrationsScreenState extends State<SocialIntegrationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Integrações Sociais'),
      ),
      body: BlocBuilder<SocialIntegrationsBloc, SocialIntegrationsState>(
        builder: (context, state) {
          if (state is SocialIntegrationsLoaded) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header explicativo
                  SocialIntegrationsHeader(),
                  
                  SizedBox(height: 24),
                  
                  // Google
                  SocialIntegrationCard(
                    provider: SocialProvider.google,
                    isConnected: state.isGoogleConnected,
                    userInfo: state.googleUserInfo,
                    onConnect: _connectGoogle,
                    onDisconnect: _disconnectGoogle,
                  ),
                  
                  SizedBox(height: 16),
                  
                  // LinkedIn
                  SocialIntegrationCard(
                    provider: SocialProvider.linkedin,
                    isConnected: state.isLinkedInConnected,
                    userInfo: state.linkedInUserInfo,
                    onConnect: _connectLinkedIn,
                    onDisconnect: _disconnectLinkedIn,
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Facebook
                  SocialIntegrationCard(
                    provider: SocialProvider.facebook,
                    isConnected: state.isFacebookConnected,
                    userInfo: state.facebookUserInfo,
                    onConnect: _connectFacebook,
                    onDisconnect: _disconnectFacebook,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Configurações de privacidade social
                  SocialPrivacySettings(
                    settings: state.privacySettings,
                    onSettingsChanged: _updatePrivacySettings,
                  ),
                ],
              ),
            );
          }
          
          return SocialIntegrationsSkeletonLoader();
        },
      ),
    );
  }
}
```

### **Sprint 12: Testes e Otimizações**

#### **🧪 12.1 Testes Automatizados**

**Arquivo**: `apps/app_flutter/test/features/profile/profile_integration_test.dart`

```dart
void main() {
  group('Profile Integration Tests', () {
    late ProfileRepository profileRepository;
    late ProfileBloc profileBloc;
    
    setUp(() {
      profileRepository = MockProfileRepository();
      profileBloc = ProfileBloc(profileRepository: profileRepository);
    });
    
    testWidgets('should complete full profile flow for PF client', (tester) async {
      // Arrange
      when(() => profileRepository.getProfile(any()))
          .thenAnswer((_) async => Right(mockPFProfile));
      
      // Act & Assert
      await tester.pumpWidget(ProfileTestApp(bloc: profileBloc));
      
      // Test personal data completion
      await _testPersonalDataFlow(tester, ClientType.individual);
      
      // Test document upload
      await _testDocumentUploadFlow(tester);
      
      // Test communication preferences
      await _testCommunicationPreferencesFlow(tester);
      
      // Test privacy settings
      await _testPrivacySettingsFlow(tester);
      
      // Verify profile completion
      expect(find.text('Perfil 100% completo'), findsOneWidget);
    });
    
    testWidgets('should complete full profile flow for PJ client', (tester) async {
      // Similar test for PJ...
    });
  });
}
```

---

## 📊 Métricas de Sucesso e KPIs

### **📈 Métricas Quantitativas**

| **Métrica** | **Meta** | **Método de Medição** |
|-------------|----------|----------------------|
| Taxa de Conclusão do Perfil | 85% | Perfis com todos os campos obrigatórios preenchidos |
| Upload de Documentos | 90% | Clientes com documentos básicos enviados |
| Tempo de Preenchimento | < 15 min | Tempo médio para completar perfil inicial |
| Taxa de Erro no Upload | < 5% | Uploads que falham por problemas técnicos |
| Satisfação com Interface | > 4.5/5 | Pesquisa pós-uso |
| Adesão a Backups Automáticos | 70% | Clientes que ativam backup de documentos |

### **🎯 Métricas Qualitativas**

- **Facilidade de uso**: Interface intuitiva para todos os perfis de usuário
- **Compliance LGPD**: 100% conforme com requisitos legais
- **Segurança**: Zero vazamentos de dados em auditorias
- **Acessibilidade**: Conforme WCAG 2.1 AA
- **Performance**: Carregamento < 3s para todas as seções

---

## 🗓️ Cronograma de Implementação

### **📅 Timeline Detalhado (12 Sprints - 24 semanas)**

```
JANEIRO 2025
Sem 1-2: Sprint 1 - Dados Pessoais Completos
Sem 3-4: Sprint 2 - Sistema de Documentos

FEVEREIRO 2025  
Sem 5-6: Sprint 3 - Preferências de Comunicação
Sem 7-8: Sprint 4 - Interface de Contratos Vigentes

MARÇO 2025
Sem 9-10: Sprint 5 - Dashboard Financeiro
Sem 11-12: Sprint 6 - Integrações de Pagamento

ABRIL 2025
Sem 13-14: Sprint 7 - Configurações LGPD
Sem 15-16: Sprint 8 - Testes e Correções

MAIO 2025
Sem 17-18: Sprint 9 - Documentação e Treinamento
Sem 19-20: Sprint 10 - Configurações Avançadas

JUNHO 2025
Sem 21-22: Sprint 11 - Integrações Sociais
Sem 23-24: Sprint 12 - Testes Finais e Otimizações
```

---

## 🔧 Considerações Técnicas

### **🏗️ Arquitetura**

- **Clean Architecture**: Manter separação clara entre camadas
- **BLoC Pattern**: Gerenciamento de estado consistente
- **Repository Pattern**: Abstração de dados
- **Dependency Injection**: GetIt para injeção de dependências

### **📱 UI/UX**

- **Material Design 3**: Componentes modernos e acessíveis
- **Responsive Design**: Adaptação para mobile, tablet e desktop
- **Dark Mode**: Suporte completo a tema escuro
- **Skeleton Loading**: Estados de carregamento elegantes
- **Error Handling**: Tratamento gracioso de erros

### **🔒 Segurança**

- **Encryption**: AES-256 para dados sensíveis
- **HTTPS**: Todas as comunicações criptografadas
- **Sanitization**: Validação rigorosa de inputs
- **Audit Trail**: Log completo de ações críticas
- **LGPD Compliance**: Conformidade total com regulamentação

### **🚀 Performance**

- **Lazy Loading**: Carregamento sob demanda
- **Caching**: Cache inteligente de dados
- **Image Optimization**: Compressão automática
- **Database Indexing**: Índices otimizados
- **CDN**: Distribuição de assets estáticos

---

## 📋 Checklist de Entrega

### **✅ Fase 1 - Fundações**
- [ ] Modelo de dados expandido (PersonalData, ContactData, Address, Document)
- [ ] Interface de dados pessoais PF/PJ
- [ ] Sistema de upload de documentos
- [ ] Validação e otimização de arquivos
- [ ] Preferências de comunicação
- [ ] Testes unitários das entidades

### **✅ Fase 2 - Contratos e Financeiro**
- [ ] Interface de contratos vigentes
- [ ] Dashboard financeiro
- [ ] Sistema de pagamentos
- [ ] Integração com APIs de pagamento
- [ ] Relatórios financeiros
- [ ] Testes de integração

### **✅ Fase 3 - Privacidade e Configurações**
- [ ] Interface LGPD completa
- [ ] Gerenciamento de consentimentos
- [ ] Exercício de direitos do titular
- [ ] Configurações avançadas
- [ ] Auditoria de privacidade
- [ ] Compliance testing

### **✅ Fase 4 - Melhorias e Otimizações**
- [ ] Integrações sociais completas
- [ ] Configurações avançadas
- [ ] Otimizações de performance
- [ ] Testes automatizados completos
- [ ] Documentação técnica
- [ ] Treinamento da equipe

---

## 🎯 Conclusão

Este plano de ação transforma o perfil básico atual em uma **experiência completa e profissional** para clientes jurídicos, oferecendo:

### **🌟 Benefícios Principais:**

1. **Experiência Completa**: Perfil 360° com todos os dados necessários
2. **Compliance Total**: Conformidade LGPD e regulamentações jurídicas
3. **Segurança Máxima**: Proteção de dados sensíveis e documentos
4. **Transparência Financeira**: Visibilidade completa de contratos e pagamentos
5. **Comunicação Eficiente**: Preferências personalizadas por cliente
6. **Facilidade de Uso**: Interface intuitiva e acessível

### **📈 Impacto Esperado:**

- **85% de conclusão** de perfis completos
- **90% de satisfação** dos clientes
- **Redução de 60%** no tempo de onboarding
- **Zero incidentes** de segurança/privacidade
- **Aumento de 40%** na retenção de clientes

Este plano estabelece o LITIG-1 como **referência em gestão de perfil jurídico**, oferecendo a experiência mais completa e segura do mercado legal brasileiro.

---

**Documento criado em**: 20 de Janeiro de 2025  
**Versão**: 1.0 - Plano de Ação Completo  
**Próxima Revisão**: Sprint 3 (Final de Fevereiro 2025)