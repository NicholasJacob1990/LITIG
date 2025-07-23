import 'package:flutter/material.dart';

/// Análise de match específica por tipo de advogado
abstract class MatchAnalysis {
  final double matchScore; // Score geral do match 0-100
  final String matchReason; // Explicação do match
  final List<String> strengths; // Pontos fortes para o caso
  final List<String> considerations; // Pontos de atenção
  final String recommendation; // Recomendação estratégica

  const MatchAnalysis({
    required this.matchScore,
    required this.matchReason,
    required this.strengths,
    required this.considerations,
    required this.recommendation,
  });

  /// Classificação do match
  String get matchLevel {
    if (matchScore >= 85) return 'Excelente';
    if (matchScore >= 70) return 'Muito Bom';
    if (matchScore >= 50) return 'Bom';
    if (matchScore >= 30) return 'Regular';
    return 'Baixo';
  }

  /// Cor do match
  Color get matchColor {
    if (matchScore >= 85) return Colors.green;
    if (matchScore >= 70) return Colors.lightGreen;
    if (matchScore >= 50) return Colors.orange;
    if (matchScore >= 30) return Colors.deepOrange;
    return Colors.red;
  }
}

/// Análise para ASSOCIADOS (lawyer_associated)
class InternalMatchAnalysis extends MatchAnalysis {
  final String delegatedBy; // Quem delegou
  final String learningObjectives; // Objetivos de aprendizado
  final String supervisorNotes; // Notas do supervisor
  final List<String> resources; // Recursos disponíveis
  final String escalationPath; // Quando/como escalar

  const InternalMatchAnalysis({
    required super.matchScore,
    required super.matchReason,
    required super.strengths,
    required super.considerations,
    required super.recommendation,
    required this.delegatedBy,
    required this.learningObjectives,
    required this.supervisorNotes,
    required this.resources,
    required this.escalationPath,
  });
}

/// Análise para SUPER ASSOCIADOS (lawyer_platform_associate)
class AlgorithmMatchAnalysis extends MatchAnalysis {
  final double algorithmScore; // Score específico do algoritmo
  final String matchExplanation; // Explicação detalhada do algoritmo
  final List<String> competitors; // Concorrentes considerados
  final double conversionRate; // Taxa de conversão esperada
  final String clientExpectation; // O que o cliente espera

  const AlgorithmMatchAnalysis({
    required super.matchScore,
    required super.matchReason,
    required super.strengths,
    required super.considerations,
    required super.recommendation,
    required this.algorithmScore,
    required this.matchExplanation,
    required this.competitors,
    required this.conversionRate,
    required this.clientExpectation,
  });
}

/// Análise para CONTRATANTES (lawyer_individual, lawyer_office)
class BusinessMatchAnalysis extends MatchAnalysis {
  final String caseSource; // algorithm, direct_capture
  final double businessFit; // Fit comercial 0-100
  final String acquisitionCost; // Custo de aquisição
  final double profitabilityScore; // Score de lucratividade
  final List<String> upsellOpportunities; // Oportunidades futuras

  const BusinessMatchAnalysis({
    required super.matchScore,
    required super.matchReason,
    required super.strengths,
    required super.considerations,
    required super.recommendation,
    required this.caseSource,
    required this.businessFit,
    required this.acquisitionCost,
    required this.profitabilityScore,
    required this.upsellOpportunities,
  });
}