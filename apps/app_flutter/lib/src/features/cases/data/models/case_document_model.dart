import 'package:meu_app/src/features/cases/domain/entities/case_document.dart';

class CaseDocumentModel extends CaseDocument {
  const CaseDocumentModel({
    required super.name,
    required super.size,
    required super.date,
    required super.type,
    required super.category,
  });

  factory CaseDocumentModel.fromJson(Map<String, dynamic> json) {
    return CaseDocumentModel(
      name: json['name'] as String? ?? 'Documento sem nome',
      size: json['size'] as String? ?? '0 KB',
      date: json['date'] as String? ?? 'Data não disponível',
      type: json['type'] as String? ?? 'unknown',
      category: json['category'] as String? ?? 'Geral',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
      'date': date,
      'type': type,
      'category': category,
    };
  }
} 