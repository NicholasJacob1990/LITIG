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

  @override
  List<Object?> get props => [name, url];
} 