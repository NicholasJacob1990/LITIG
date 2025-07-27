import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';

/// Resultado do matching que inclui tanto advogados quanto escritórios
class MatchResult extends Equatable {
  /// Lista de advogados ranqueados pelo algoritmo
  final List<MatchedLawyer> lawyers;
  
  /// Lista de escritórios ranqueados pelo algoritmo
  final List<LawFirm> firms;
  
  /// Metadados do matching
  final String caseId;
  final String matchId;
  final int totalLawyersEvaluated;
  final String algorithmVersion;
  final double executionTimeMs;

  const MatchResult({
    required this.lawyers,
    required this.firms,
    required this.caseId,
    required this.matchId,
    required this.totalLawyersEvaluated,
    required this.algorithmVersion,
    required this.executionTimeMs,
  });

  /// Verifica se há resultados (advogados ou escritórios)
  bool get hasResults => lawyers.isNotEmpty || firms.isNotEmpty;
  
  /// Número total de resultados
  int get totalResults => lawyers.length + firms.length;
  
  /// Verifica se há apenas advogados
  bool get hasOnlyLawyers => lawyers.isNotEmpty && firms.isEmpty;
  
  /// Verifica se há apenas escritórios
  bool get hasOnlyFirms => firms.isNotEmpty && lawyers.isEmpty;
  
  /// Verifica se há resultados mistos (advogados e escritórios)
  bool get hasMixedResults => lawyers.isNotEmpty && firms.isNotEmpty;

  @override
  List<Object?> get props => [
        lawyers,
        firms,
        caseId,
        matchId,
        totalLawyersEvaluated,
        algorithmVersion,
        executionTimeMs,
      ];

  /// Cria uma cópia com campos atualizados
  MatchResult copyWith({
    List<MatchedLawyer>? lawyers,
    List<LawFirm>? firms,
    String? caseId,
    String? matchId,
    int? totalLawyersEvaluated,
    String? algorithmVersion,
    double? executionTimeMs,
  }) {
    return MatchResult(
      lawyers: lawyers ?? this.lawyers,
      firms: firms ?? this.firms,
      caseId: caseId ?? this.caseId,
      matchId: matchId ?? this.matchId,
      totalLawyersEvaluated: totalLawyersEvaluated ?? this.totalLawyersEvaluated,
      algorithmVersion: algorithmVersion ?? this.algorithmVersion,
      executionTimeMs: executionTimeMs ?? this.executionTimeMs,
    );
  }

  @override
  String toString() {
    return 'MatchResult(lawyers: ${lawyers.length}, firms: ${firms.length}, caseId: $caseId)';
  }
} 