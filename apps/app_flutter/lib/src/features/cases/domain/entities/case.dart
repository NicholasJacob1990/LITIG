import 'package:equatable/equatable.dart';
import 'package:meu_app/src/features/cases/domain/entities/lawyer_info.dart';

class Case extends Equatable {
  final String id;
  final String title;
  final String status;
  final String? lawyerName;
  final String? lawyerId;
  final DateTime createdAt;
  final LawyerInfo? lawyer; // Reutilizando a entidade existente

  const Case({
    required this.id,
    required this.title,
    required this.status,
    this.lawyerName,
    this.lawyerId,
    required this.createdAt,
    this.lawyer,
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
    );
  }

  @override
  List<Object?> get props => [id, title, status, lawyerName, lawyerId, createdAt, lawyer];
} 