import 'package:flutter/material.dart';

// Este arquivo contém funções auxiliares de apresentação para o FirmCard,
// separando a lógica de formatação e decisão de cores da estrutura do widget.

Color getSuccessRateColor(double rate) {
  if (rate >= 0.8) return Colors.green;
  if (rate >= 0.6) return Colors.orange;
  return Colors.red;
}

Color getNpsColor(double nps) {
  // O valor do NPS no KPI parece ser 0-100, então a lógica está correta.
  if (nps >= 70) return Colors.green;
  if (nps >= 30) return Colors.orange;
  return Colors.red;
}

Color getReputationScoreColor(double score) {
  // Score vem como 0-100
  if (score >= 80) return Colors.green;
  if (score >= 60) return Colors.orange;
  return Colors.red;
}

String formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String formatDateTime(DateTime dateTime) {
  final date = formatDate(dateTime);
  final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  return '$date $time';
} 