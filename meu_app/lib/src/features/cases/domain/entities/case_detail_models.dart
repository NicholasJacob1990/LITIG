import 'package:flutter/material.dart';

/// Modelo de dados principal para a tela de detalhes do caso.
class CaseDetail {
  final String title;
  final String caseNumber;
  final String status;
  final Lawyer lawyer;
  final ConsultationInfo consultationInfo;
  final PreAnalysis preAnalysis;
  final List<NextStep> nextSteps;
  final List<DocumentItem> documents;

  CaseDetail({
    required this.title,
    required this.caseNumber,
    required this.status,
    required this.lawyer,
    required this.consultationInfo,
    required this.preAnalysis,
    required this.nextSteps,
    required this.documents,
  });
}

/// Modelo para informações do advogado.
class Lawyer {
  final String avatarUrl;
  final String name;
  final String specialty;
  final double rating;
  final int experienceYears;
  Lawyer({
    required this.avatarUrl,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.experienceYears,
  });
}

/// Modelo para informações da consulta.
class ConsultationInfo {
  final String date;
  final String duration;
  final String mode;
  final String plan;
  ConsultationInfo({
    required this.date,
    required this.duration,
    required this.mode,
    required this.plan,
  });
}

/// Modelo para a seção de pré-análise da IA.
class PreAnalysis {
  final String priority;
  final String tag;
  final Color tagColor;
  final String estimatedTime;
  final int urgency;
  final String summary;
  final List<String> requiredDocs;
  final List<CostEstimate> costs;
  final String risk;
  PreAnalysis({
    required this.priority,
    required this.tag,
    required this.tagColor,
    required this.estimatedTime,
    required this.urgency,
    required this.summary,
    required this.requiredDocs,
    required this.costs,
    required this.risk,
  });
}

/// Modelo para a estimativa de custos.
class CostEstimate {
  final String label;
  final String value;
  CostEstimate({required this.label, required this.value});
}

/// Modelo para a seção de próximos passos.
class NextStep {
  final String title;
  final String description;
  final String dueDate;
  final String priority; // 'HIGH'|'MEDIUM'|'LOW'
  final String status;   // 'PENDING'|'DONE'
  NextStep({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
  });
}

/// Modelo para um item na lista de documentos.
class DocumentItem {
  final String name;
  final String sizeDate;
  DocumentItem({required this.name, required this.sizeDate});
} 