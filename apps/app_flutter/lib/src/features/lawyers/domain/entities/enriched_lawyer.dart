import 'package:equatable/equatable.dart';

import 'academic_profile.dart';
import 'data_source_info.dart';
import 'linkedin_profile.dart';
import 'matched_lawyer.dart'; // Reutilizando a base

class EnrichedLawyer extends Equatable {
  final String id;
  final String nome;
  final String avatarUrl;
  final List<String> especialidades;
  final double fair; // Match score
  final LawyerFeatures features;

  // Novos campos enriquecidos
  final String? bio;
  final LinkedInProfile? linkedinProfile;
  final AcademicProfile? academicProfile;
  final Map<String, DataSourceInfo> dataSources;
  final double overallQualityScore;
  final double completenessScore;
  final DateTime lastConsolidated;

  const EnrichedLawyer({
    required this.id,
    required this.nome,
    required this.avatarUrl,
    required this.especialidades,
    required this.fair,
    required this.features,
    this.bio,
    this.linkedinProfile,
    this.academicProfile,
    required this.dataSources,
    required this.overallQualityScore,
    required this.completenessScore,
    required this.lastConsolidated,
  });

  @override
  List<Object?> get props => [
        id,
        nome,
        avatarUrl,
        especialidades,
        fair,
        features,
        bio,
        linkedinProfile,
        academicProfile,
        dataSources,
        overallQualityScore,
        completenessScore,
        lastConsolidated,
      ];
} 

import 'academic_profile.dart';
import 'data_source_info.dart';
import 'linkedin_profile.dart';
import 'matched_lawyer.dart'; // Reutilizando a base

class EnrichedLawyer extends Equatable {
  final String id;
  final String nome;
  final String avatarUrl;
  final List<String> especialidades;
  final double fair; // Match score
  final LawyerFeatures features;

  // Novos campos enriquecidos
  final String? bio;
  final LinkedInProfile? linkedinProfile;
  final AcademicProfile? academicProfile;
  final Map<String, DataSourceInfo> dataSources;
  final double overallQualityScore;
  final double completenessScore;
  final DateTime lastConsolidated;

  const EnrichedLawyer({
    required this.id,
    required this.nome,
    required this.avatarUrl,
    required this.especialidades,
    required this.fair,
    required this.features,
    this.bio,
    this.linkedinProfile,
    this.academicProfile,
    required this.dataSources,
    required this.overallQualityScore,
    required this.completenessScore,
    required this.lastConsolidated,
  });

  @override
  List<Object?> get props => [
        id,
        nome,
        avatarUrl,
        especialidades,
        fair,
        features,
        bio,
        linkedinProfile,
        academicProfile,
        dataSources,
        overallQualityScore,
        completenessScore,
        lastConsolidated,
      ];
} 