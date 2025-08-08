import 'package:equatable/equatable.dart';

class AcceptedCasePreview extends Equatable {
  final String id;
  final String status;
  final DateTime createdAt;
  final String? title;
  final String? area;
  final String? subarea;
  final String? accessLevel; // full/preview
  final DateTime? acceptedAt;

  const AcceptedCasePreview({
    required this.id,
    required this.status,
    required this.createdAt,
    this.title,
    this.area,
    this.subarea,
    this.accessLevel,
    this.acceptedAt,
  });

  factory AcceptedCasePreview.fromMap(Map<String, dynamic> map) {
    return AcceptedCasePreview(
      id: map['id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'ABERTO',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      title: map['title']?.toString(),
      area: map['area']?.toString(),
      subarea: map['subarea']?.toString(),
      accessLevel: map['access_level']?.toString(),
      acceptedAt: map['accepted_at'] != null ? DateTime.tryParse(map['accepted_at'].toString()) : null,
    );
  }

  @override
  List<Object?> get props => [id, status, createdAt, title, area, subarea, accessLevel, acceptedAt];
}


