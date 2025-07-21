import 'package:equatable/equatable.dart';

class ProcessStatus extends Equatable {
  final String currentPhase;
  final String description;
  final double progressPercentage;
  final List<ProcessPhase> phases;

  const ProcessStatus({
    required this.currentPhase,
    required this.description,
    required this.progressPercentage,
    required this.phases,
  });

  factory ProcessStatus.fromJson(Map<String, dynamic> json) {
    return ProcessStatus(
      currentPhase: json['current_phase'] ?? '',
      description: json['description'] ?? '',
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      phases: (json['phases'] as List?)?.map((p) => ProcessPhase.fromJson(p)).toList() ?? [],
    );
  }

  @override
  List<Object?> get props => [currentPhase, description, progressPercentage, phases];
}

class ProcessPhase extends Equatable {
  final String name;
  final String description;
  final bool isCompleted;
  final bool isCurrent;
  final DateTime? completedAt;
  final List<PhaseDocument> documents;

  const ProcessPhase({
    required this.name,
    required this.description,
    required this.isCompleted,
    required this.isCurrent,
    this.completedAt,
    this.documents = const [],
  });

  factory ProcessPhase.fromJson(Map<String, dynamic> json) {
    return ProcessPhase(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      isCurrent: json['is_current'] ?? false,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      documents: (json['documents'] as List?)?.map((d) => PhaseDocument.fromJson(d)).toList() ?? [],
    );
  }

  @override
  List<Object?> get props => [name, description, isCompleted, isCurrent, completedAt, documents];
}

class PhaseDocument extends Equatable {
  final String name;
  final String url;

  const PhaseDocument({
    required this.name,
    required this.url,
  });

  factory PhaseDocument.fromJson(Map<String, dynamic> json) {
    return PhaseDocument(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }

  @override
  List<Object?> get props => [name, url];
} 