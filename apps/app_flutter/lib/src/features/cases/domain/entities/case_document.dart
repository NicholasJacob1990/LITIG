import 'package:equatable/equatable.dart';

class CaseDocument extends Equatable {
  final String name;
  final String size;
  final String date;
  final String type;
  final String category;

  const CaseDocument({
    required this.name,
    required this.size,
    required this.date,
    required this.type,
    required this.category,
  });

  factory CaseDocument.fromJson(Map<String, dynamic> json) {
    return CaseDocument(
      name: json['name'] ?? '',
      size: json['size'] ?? '',
      date: json['date'] ?? '',
      type: json['type'] ?? '',
      category: json['category'] ?? '',
    );
  }

  @override
  List<Object?> get props => [name, size, date, type, category];
} 