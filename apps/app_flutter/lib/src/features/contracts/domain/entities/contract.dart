import 'package:equatable/equatable.dart';

class Contract extends Equatable {
  final String id;
  final String caseId;
  final String lawyerId;
  final String clientId;
  final String status;
  final Map<String, dynamic> feeModel;
  final DateTime createdAt;
  final DateTime? signedClient;
  final DateTime? signedLawyer;
  final String? docUrl;
  final DateTime updatedAt;
  
  // Dados relacionados (opcionais)
  final String? caseTitle;
  final String? caseArea;
  final String? lawyerName;
  final String? clientName;

  const Contract({
    required this.id,
    required this.caseId,
    required this.lawyerId,
    required this.clientId,
    required this.status,
    required this.feeModel,
    required this.createdAt,
    this.signedClient,
    this.signedLawyer,
    this.docUrl,
    required this.updatedAt,
    this.caseTitle,
    this.caseArea,
    this.lawyerName,
    this.clientName,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'] as String,
      caseId: json['case_id'] as String,
      lawyerId: json['lawyer_id'] as String,
      clientId: json['client_id'] as String,
      status: json['status'] as String,
      feeModel: Map<String, dynamic>.from(json['fee_model'] as Map),
      createdAt: DateTime.parse(json['created_at'] as String),
      signedClient: json['signed_client'] != null 
          ? DateTime.parse(json['signed_client'] as String) 
          : null,
      signedLawyer: json['signed_lawyer'] != null 
          ? DateTime.parse(json['signed_lawyer'] as String) 
          : null,
      docUrl: json['doc_url'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      caseTitle: json['case_title'] as String?,
      caseArea: json['case_area'] as String?,
      lawyerName: json['lawyer_name'] as String?,
      clientName: json['client_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_id': caseId,
      'lawyer_id': lawyerId,
      'client_id': clientId,
      'status': status,
      'fee_model': feeModel,
      'created_at': createdAt.toIso8601String(),
      'signed_client': signedClient?.toIso8601String(),
      'signed_lawyer': signedLawyer?.toIso8601String(),
      'doc_url': docUrl,
      'updated_at': updatedAt.toIso8601String(),
      'case_title': caseTitle,
      'case_area': caseArea,
      'lawyer_name': lawyerName,
      'client_name': clientName,
    };
  }

  Contract copyWith({
    String? id,
    String? caseId,
    String? lawyerId,
    String? clientId,
    String? status,
    Map<String, dynamic>? feeModel,
    DateTime? createdAt,
    DateTime? signedClient,
    DateTime? signedLawyer,
    String? docUrl,
    DateTime? updatedAt,
    String? caseTitle,
    String? caseArea,
    String? lawyerName,
    String? clientName,
  }) {
    return Contract(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      lawyerId: lawyerId ?? this.lawyerId,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      feeModel: feeModel ?? this.feeModel,
      createdAt: createdAt ?? this.createdAt,
      signedClient: signedClient ?? this.signedClient,
      signedLawyer: signedLawyer ?? this.signedLawyer,
      docUrl: docUrl ?? this.docUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      caseTitle: caseTitle ?? this.caseTitle,
      caseArea: caseArea ?? this.caseArea,
      lawyerName: lawyerName ?? this.lawyerName,
      clientName: clientName ?? this.clientName,
    );
  }

  bool get isPendingSignature => status == 'pending-signature';
  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed';
  bool get isCanceled => status == 'canceled';
  bool get isSignedByClient => signedClient != null;
  bool get isSignedByLawyer => signedLawyer != null;
  bool get isFullySigned => isSignedByClient && isSignedByLawyer;

  String get feeModelDescription {
    final type = feeModel['type'] as String?;
    switch (type) {
      case 'success':
        final percent = feeModel['percent'] as num?;
        return 'Êxito: ${percent?.toStringAsFixed(1)}%';
      case 'fixed':
        final value = feeModel['value'] as num?;
        return 'Fixo: R\$ ${value?.toStringAsFixed(2)}';
      case 'hourly':
        final rate = feeModel['rate'] as num?;
        return 'Por Hora: R\$ ${rate?.toStringAsFixed(2)}/h';
      default:
        return 'Tipo não especificado';
    }
  }

  @override
  List<Object?> get props => [
    id,
    caseId,
    lawyerId,
    clientId,
    status,
    feeModel,
    createdAt,
    signedClient,
    signedLawyer,
    docUrl,
    updatedAt,
    caseTitle,
    caseArea,
    lawyerName,
    clientName,
  ];
} 