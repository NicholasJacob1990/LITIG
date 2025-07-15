import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/cases/domain/entities/lawyer_info.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';

class Case extends Equatable {
  final String id;
  final String title;
  final String status;
  final String? lawyerName;
  final String? lawyerId;
  final DateTime createdAt;
  final LawyerInfo? lawyer; // Reutilizando a entidade existente
  final LawFirm? recommendedFirm; // Escritório recomendado para o caso
  final double? firmMatchScore; // Score do match com o escritório
  final String? caseType; // Tipo do caso (CORPORATE, PERSONAL, etc.)
  final String? allocationType; // NOVO: Tipo de alocação (direct, partnership, etc.)

  const Case({
    required this.id,
    required this.title,
    required this.status,
    this.lawyerName,
    this.lawyerId,
    required this.createdAt,
    this.lawyer,
    this.recommendedFirm,
    this.firmMatchScore,
    this.caseType,
    this.allocationType, // NOVO
  });

  factory Case.fromJson(Map<String, dynamic> json) {
    return Case(
      id: json['id'],
      title: json['title'],
      status: json['status'],
      lawyerName: json['lawyer_name'],
      lawyerId: json['lawyer_id'],
      createdAt: DateTime.parse(json['created_at']),
      lawyer: json['lawyer'] != null ? LawyerInfo.fromJson(json['lawyer']) : null,
      // Por enquanto, recommendedFirm será null até implementarmos a integração completa
      recommendedFirm: null,
      firmMatchScore: json['firm_match_score']?.toDouble(),
      caseType: json['case_type'],
      allocationType: json['allocation_type'], // NOVO
    );
  }

  /// Factory method para criar Case com escritório recomendado
  factory Case.withRecommendedFirm({
    required Case originalCase,
    required LawFirm recommendedFirm,
    required double matchScore,
  }) {
    return Case(
      id: originalCase.id,
      title: originalCase.title,
      status: originalCase.status,
      lawyerName: originalCase.lawyerName,
      lawyerId: originalCase.lawyerId,
      createdAt: originalCase.createdAt,
      lawyer: originalCase.lawyer,
      recommendedFirm: recommendedFirm,
      firmMatchScore: matchScore,
      caseType: originalCase.caseType,
      allocationType: originalCase.allocationType, // NOVO
    );
  }

  /// Verifica se o caso é corporativo e deve mostrar recomendação de escritório
  bool get shouldShowFirmRecommendation => 
    caseType == 'CORPORATE' || 
    caseType == 'BUSINESS' || 
    recommendedFirm != null;

  /// Verifica se o caso tem complexidade alta (baseado no tipo)
  bool get isHighComplexity => 
    caseType == 'CORPORATE' || 
    caseType == 'BUSINESS' || 
    caseType == 'M&A' ||
    caseType == 'REGULATORY';

  @override
  List<Object?> get props => [
    id, title, status, lawyerName, lawyerId, createdAt, lawyer, 
    recommendedFirm, firmMatchScore, caseType, allocationType // NOVO e corrigido
  ];
} 