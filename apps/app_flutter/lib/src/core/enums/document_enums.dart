// Core enums for document management
// Corresponds to backend migration 20250104000000_expand_document_types.sql

import 'package:flutter/material.dart';

/// Categorias de documentos para organização da UI
enum DocumentCategory {
  processual('processual', 'Documentos Processuais', Icons.gavel, Colors.blue),
  probatorio('probatorio', 'Provas e Evidências', Icons.description, Colors.green),
  contratual('contratual', 'Contratos e Acordos', Icons.handshake, Colors.orange),
  identificacao('identificacao', 'Identificação e Comprovação', Icons.badge, Colors.purple),
  administrativo('administrativo', 'Documentos Administrativos', Icons.business, Colors.teal),
  digital('digital', 'Era Digital', Icons.computer, Colors.indigo),
  interno('interno', 'Trabalho Interno', Icons.work, Colors.brown),
  financeiro('financeiro', 'Financeiros e Comprovantes', Icons.account_balance, Colors.amber),
  outros('outros', 'Outros', Icons.folder, Colors.grey);

  const DocumentCategory(this.code, this.label, this.icon, this.color);
  
  final String code;
  final String label;
  final IconData icon;
  final Color color;

  /// Retorna a categoria baseada no código
  static DocumentCategory fromCode(String code) {
    return DocumentCategory.values.firstWhere(
      (category) => category.code == code,
      orElse: () => DocumentCategory.outros,
    );
  }
}

/// Tipos de documentos expandidos (42 tipos)
enum DocumentType {
  // Categoria 1: Documentos Processuais (12 tipos)
  petition('petition', 'Petição', 'Petições iniciais e intermediárias', DocumentCategory.processual),
  appeal('appeal', 'Recurso', 'Recursos ordinários, especiais e extraordinários', DocumentCategory.processual),
  interlocutoryAppeal('interlocutory_appeal', 'Agravo', 'Agravo de instrumento contra decisões interlocutórias', DocumentCategory.processual),
  motion('motion', 'Petição Incidental', 'Requerimentos e petições durante o processo', DocumentCategory.processual),
  powerOfAttorney('power_of_attorney', 'Procuração', 'Procuração para representação processual', DocumentCategory.processual),
  judicialDecision('judicial_decision', 'Decisão Judicial', 'Sentenças, despachos e acórdãos', DocumentCategory.processual),
  hearingDocument('hearing_document', 'Documento de Audiência', 'Atas de audiência e transcrições', DocumentCategory.processual),
  proceduralCommunication('procedural_communication', 'Comunicação Processual', 'Citações, intimações e notificações', DocumentCategory.processual),
  proofOfFiling('proof_of_filing', 'Comprovante de Protocolo', 'Comprovantes de protocolo de petições', DocumentCategory.processual),
  officialLetter('official_letter', 'Ofício/Mandado', 'Ofícios e mandados judiciais', DocumentCategory.processual),
  expertReport('expert_report', 'Laudo Pericial', 'Laudos periciais técnicos', DocumentCategory.processual),
  witnessTestimony('witness_testimony', 'Depoimento', 'Depoimentos e declarações de testemunhas', DocumentCategory.processual),

  // Categoria 2: Provas e Evidências (10 tipos)
  evidence('evidence', 'Evidência', 'Documentos probatórios gerais', DocumentCategory.probatorio),
  medicalReport('medical_report', 'Relatório Médico', 'Relatórios médicos para casos de acidente/INSS', DocumentCategory.probatorio),
  financialStatement('financial_statement', 'Demonstrativo Financeiro', 'Demonstrativos financeiros para casos empresariais', DocumentCategory.probatorio),
  forensicReport('forensic_report', 'Laudo Criminal', 'Laudos criminais e periciais forenses', DocumentCategory.probatorio),
  auditReport('audit_report', 'Relatório de Auditoria', 'Relatórios de auditoria fiscal e trabalhista', DocumentCategory.probatorio),
  photographicEvidence('photographic_evidence', 'Prova Fotográfica', 'Evidências fotográficas', DocumentCategory.probatorio),
  audioEvidence('audio_evidence', 'Prova Sonora', 'Gravações de áudio como prova', DocumentCategory.probatorio),
  videoEvidence('video_evidence', 'Prova Audiovisual', 'Gravações de vídeo como prova', DocumentCategory.probatorio),
  digitalEvidence('digital_evidence', 'Evidência Digital', 'Evidências digitais e forenses computacionais', DocumentCategory.probatorio),
  evidenceMedia('evidence_media', 'Mídia Probatória', 'Outras mídias como evidência', DocumentCategory.probatorio),

  // Categoria 3: Documentos Contratuais (8 tipos)
  contract('contract', 'Contrato', 'Contratos gerais', DocumentCategory.contratual),
  employmentContract('employment_contract', 'Contrato de Trabalho', 'Contratos de trabalho CLT', DocumentCategory.contratual),
  serviceAgreement('service_agreement', 'Acordo de Serviços', 'Contratos de prestação de serviços', DocumentCategory.contratual),
  insurancePolicy('insurance_policy', 'Apólice de Seguro', 'Apólices de seguro para sinistros', DocumentCategory.contratual),
  leaseAgreement('lease_agreement', 'Contrato de Locação', 'Contratos de locação imobiliária', DocumentCategory.contratual),
  purchaseAgreement('purchase_agreement', 'Contrato de Compra e Venda', 'Contratos de compra e venda', DocumentCategory.contratual),
  partnershipAgreement('partnership_agreement', 'Acordo de Parceria', 'Contratos de sociedade e parceria', DocumentCategory.contratual),
  legalContract('legal_contract', 'Contrato de Honorários', 'Contratos de honorários advocatícios', DocumentCategory.contratual),

  // Categoria 4: Documentos de Identificação (7 tipos)
  identification('identification', 'Identificação', 'Documentos de identificação gerais', DocumentCategory.identificacao),
  personalIdentification('personal_identification', 'Identificação Pessoal', 'RG, CPF, CNH específicos', DocumentCategory.identificacao),
  proofOfResidence('proof_of_residence', 'Comprovante de Residência', 'Comprovantes de residência', DocumentCategory.identificacao),
  corporateDocuments('corporate_documents', 'Documentos Societários', 'Contrato social, atas societárias', DocumentCategory.identificacao),
  propertyDeed('property_deed', 'Escritura de Imóvel', 'Escrituras de imóveis', DocumentCategory.identificacao),
  vehicleRegistration('vehicle_registration', 'Documento de Veículo', 'Documentos de veículos', DocumentCategory.identificacao),
  incomeProof('income_proof', 'Comprovante de Renda', 'Comprovantes de renda para cálculos', DocumentCategory.identificacao),

  // Categoria 5: Documentos Administrativos (5 tipos)
  administrativeCitation('administrative_citation', 'Notificação Administrativa', 'Notificações de órgãos administrativos', DocumentCategory.administrativo),
  taxAssessment('tax_assessment', 'Auto de Infração Fiscal', 'Autos de infração fiscal', DocumentCategory.administrativo),
  laborInspection('labor_inspection', 'Auto de Infração Trabalhista', 'Autos de infração trabalhista', DocumentCategory.administrativo),
  regulatoryDecision('regulatory_decision', 'Decisão Regulatória', 'Decisões de órgãos reguladores (ANATEL, ANVISA)', DocumentCategory.administrativo),
  administrative('administrative', 'Documento Administrativo', 'Documentos administrativos diversos', DocumentCategory.administrativo),

  // Categoria 6: Era Digital e Modernos (6 tipos)
  electronicSignature('electronic_signature', 'Assinatura Eletrônica', 'Assinaturas eletrônicas ICP-Brasil', DocumentCategory.digital),
  blockchainEvidence('blockchain_evidence', 'Prova Blockchain', 'Provas baseadas em blockchain e hash', DocumentCategory.digital),
  emailEvidence('email_evidence', 'Prova de E-mail', 'E-mails como evidência', DocumentCategory.digital),
  whatsappEvidence('whatsapp_evidence', 'Prova de WhatsApp', 'Conversas de WhatsApp como prova', DocumentCategory.digital),
  socialMediaEvidence('social_media_evidence', 'Prova de Redes Sociais', 'Evidências de redes sociais', DocumentCategory.digital),
  digitalTimestamp('digital_timestamp', 'Carimbo Temporal', 'Carimbos temporais digitais', DocumentCategory.digital),

  // Categoria 7: Documentos Internos do Advogado (4 tipos)
  legalAnalysis('legal_analysis', 'Análise Jurídica', 'Pareceres e análises jurídicas', DocumentCategory.interno),
  researchMaterial('research_material', 'Material de Pesquisa', 'Pesquisa doutrinária e jurisprudencial', DocumentCategory.interno),
  draft('draft', 'Rascunho', 'Rascunhos de documentos', DocumentCategory.interno),
  internalNote('internal_note', 'Anotação Interna', 'Anotações internas sobre o caso', DocumentCategory.interno),

  // Categoria 8: Financeiros e Comprovantes (3 tipos)
  receipt('receipt', 'Recibo', 'Recibos e comprovantes de pagamento', DocumentCategory.financeiro),
  financialDocument('financial_document', 'Documento Financeiro', 'Extratos, holerites e documentos financeiros', DocumentCategory.financeiro),
  bankStatement('bank_statement', 'Extrato Bancário', 'Extratos bancários específicos', DocumentCategory.financeiro),

  // Categoria 9: Outros
  other('other', 'Outro', 'Documentos não categorizados', DocumentCategory.outros);

  const DocumentType(this.value, this.displayName, this.description, this.category);
  
  final String value;
  final String displayName;
  final String description;
  final DocumentCategory category;

  /// Retorna o tipo baseado no valor string
  static DocumentType fromValue(String value) {
    return DocumentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DocumentType.other,
    );
  }

  /// Retorna todos os tipos de uma categoria específica
  static List<DocumentType> getTypesByCategory(DocumentCategory category) {
    return DocumentType.values.where((type) => type.category == category).toList();
  }

  /// Retorna tipos sugeridos por área jurídica
  static List<DocumentType> getSuggestedForArea(String area) {
    switch (area.toLowerCase()) {
      case 'trabalhista':
        return [
          DocumentType.employmentContract,
          DocumentType.medicalReport,
          DocumentType.incomeProof,
          DocumentType.financialDocument,
          DocumentType.auditReport,
          DocumentType.laborInspection,
        ];
      case 'civil':
        return [
          DocumentType.contract,
          DocumentType.leaseAgreement,
          DocumentType.purchaseAgreement,
          DocumentType.propertyDeed,
          DocumentType.vehicleRegistration,
          DocumentType.expertReport,
        ];
      case 'criminal':
        return [
          DocumentType.forensicReport,
          DocumentType.vehicleRegistration,
          DocumentType.photographicEvidence,
          DocumentType.audioEvidence,
          DocumentType.videoEvidence,
        ];
      case 'previdenciário':
        return [
          DocumentType.medicalReport,
          DocumentType.incomeProof,
          DocumentType.financialDocument,
          DocumentType.expertReport,
        ];
      case 'empresarial':
        return [
          DocumentType.corporateDocuments,
          DocumentType.partnershipAgreement,
          DocumentType.serviceAgreement,
          DocumentType.financialStatement,
          DocumentType.auditReport,
        ];
      case 'tributário':
        return [
          DocumentType.taxAssessment,
          DocumentType.auditReport,
          DocumentType.financialStatement,
          DocumentType.bankStatement,
        ];
      case 'consumidor':
        return [
          DocumentType.contract,
          DocumentType.purchaseAgreement,
          DocumentType.insurancePolicy,
          DocumentType.receipt,
        ];
      case 'administrativo':
        return [
          DocumentType.administrativeCitation,
          DocumentType.regulatoryDecision,
          DocumentType.administrative,
        ];
      default:
        return [
          DocumentType.powerOfAttorney,
          DocumentType.petition,
          DocumentType.identification,
          DocumentType.proofOfResidence,
        ];
    }
  }

  /// Retorna tipos obrigatórios por área jurídica
  static List<DocumentType> getRequiredForArea(String area) {
    switch (area.toLowerCase()) {
      case 'civil':
      case 'trabalhista':
      case 'criminal':
        return [DocumentType.powerOfAttorney];
      default:
        return [];
    }
  }
}

/// Extensão para facilitar o uso dos tipos de documento
extension DocumentTypeExtension on DocumentType {
  /// Verifica se é obrigatório para uma área específica
  bool isRequiredForArea(String area) {
    return DocumentType.getRequiredForArea(area).contains(this);
  }

  /// Verifica se é sugerido para uma área específica
  bool isSuggestedForArea(String area) {
    return DocumentType.getSuggestedForArea(area).contains(this);
  }

  /// Retorna ícone específico para o tipo de documento
  IconData get specificIcon {
    switch (this) {
      case DocumentType.petition:
        return Icons.description;
      case DocumentType.appeal:
        return Icons.trending_up;
      case DocumentType.powerOfAttorney:
        return Icons.how_to_reg;
      case DocumentType.contract:
        return Icons.article;
      case DocumentType.evidence:
        return Icons.folder_special;
      case DocumentType.medicalReport:
        return Icons.medical_services;
      case DocumentType.photographicEvidence:
        return Icons.photo;
      case DocumentType.audioEvidence:
        return Icons.audiotrack;
      case DocumentType.videoEvidence:
        return Icons.videocam;
      case DocumentType.emailEvidence:
        return Icons.email;
      case DocumentType.whatsappEvidence:
        return Icons.message;
      case DocumentType.receipt:
        return Icons.receipt;
      case DocumentType.identification:
        return Icons.badge;
      default:
        return category.icon;
    }
  }
} 