import 'package:equatable/equatable.dart';

class ClusterDetail extends Equatable {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final List<String> topSkills;
  final double averageRating;
  final String category;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const ClusterDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.topSkills,
    required this.averageRating,
    required this.category,
    required this.createdAt,
    required this.metadata,
  });

  factory ClusterDetail.fromJson(Map<String, dynamic> json) {
    return ClusterDetail(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      memberCount: json['member_count'] ?? 0,
      topSkills: List<String>.from(json['top_skills'] ?? []),
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'member_count': memberCount,
      'top_skills': topSkills,
      'average_rating': averageRating,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        memberCount,
        topSkills,
        averageRating,
        category,
        createdAt,
        metadata,
      ];
}