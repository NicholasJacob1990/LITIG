import '../../domain/entities/enriched_lawyer.dart';
import '../../domain/entities/linkedin_profile.dart';
import '../../domain/entities/academic_profile.dart';
import '../../domain/entities/data_source_info.dart';
import '../../domain/entities/matched_lawyer.dart';

class EnrichedLawyerModel {
  final String id;
  final String nome;
  final String avatarUrl;
  final List<String> especialidades;
  final double fair;
  final LawyerFeaturesModel features;
  final String? bio;
  final LinkedInProfileModel? linkedinProfile;
  final AcademicProfileModel? academicProfile;
  final Map<String, DataSourceInfoModel> dataSources;
  final double overallQualityScore;
  final double completenessScore;
  final DateTime lastConsolidated;

  EnrichedLawyerModel({
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

  factory EnrichedLawyerModel.fromJson(Map<String, dynamic> json) {
    return EnrichedLawyerModel(
      id: json['id'] as String,
      nome: json['nome'] as String,
      avatarUrl: json['avatar_url'] as String,
      especialidades: List<String>.from(json['especialidades'] ?? []),
      fair: (json['fair'] as num).toDouble(),
      features: LawyerFeaturesModel.fromJson(json['features'] ?? {}),
      bio: json['bio'] as String?,
      linkedinProfile: json['linkedin_profile'] != null
          ? LinkedInProfileModel.fromJson(json['linkedin_profile'])
          : null,
      academicProfile: json['academic_profile'] != null
          ? AcademicProfileModel.fromJson(json['academic_profile'])
          : null,
      dataSources: (json['data_sources'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(
              key, DataSourceInfoModel.fromJson(value as Map<String, dynamic>))),
      overallQualityScore: (json['overall_quality_score'] as num).toDouble(),
      completenessScore: (json['completeness_score'] as num).toDouble(),
      lastConsolidated: DateTime.parse(json['last_consolidated'] as String),
    );
  }

  EnrichedLawyer toEntity() {
    return EnrichedLawyer(
      id: id,
      nome: nome,
      avatarUrl: avatarUrl,
      especialidades: especialidades,
      fair: fair,
      features: features.toEntity(),
      bio: bio,
      linkedinProfile: linkedinProfile?.toEntity(),
      academicProfile: academicProfile?.toEntity(),
      dataSources: dataSources.map((key, value) => MapEntry(key, value.toEntity())),
      overallQualityScore: overallQualityScore,
      completenessScore: completenessScore,
      lastConsolidated: lastConsolidated,
    );
  }
}

class LawyerFeaturesModel {
  final double successRate;
  final double softSkills;
  final int responseTime;

  LawyerFeaturesModel({
    required this.successRate,
    required this.softSkills,
    required this.responseTime,
  });

  factory LawyerFeaturesModel.fromJson(Map<String, dynamic> json) {
    return LawyerFeaturesModel(
      successRate: (json['success_rate'] as num?)?.toDouble() ?? 0.0,
      softSkills: (json['soft_skills'] as num?)?.toDouble() ?? 0.0,
      responseTime: (json['response_time'] as num?)?.toInt() ?? 24,
    );
  }

  LawyerFeatures toEntity() {
    return LawyerFeatures(
      successRate: successRate,
      softSkills: softSkills,
      responseTime: responseTime,
    );
  }
}

class LinkedInProfileModel {
  final String profileUrl;
  final String? headline;
  final String? summary;
  final String? location;
  final String? industry;
  final int connections;
  final int followers;
  final List<LinkedInExperienceModel> experience;
  final List<LinkedInEducationModel> education;
  final List<LinkedInSkillModel> skills;
  final double dataQualityScore;
  final DateTime lastUpdated;

  LinkedInProfileModel({
    required this.profileUrl,
    this.headline,
    this.summary,
    this.location,
    this.industry,
    required this.connections,
    required this.followers,
    required this.experience,
    required this.education,
    required this.skills,
    required this.dataQualityScore,
    required this.lastUpdated,
  });

  factory LinkedInProfileModel.fromJson(Map<String, dynamic> json) {
    return LinkedInProfileModel(
      profileUrl: json['profile_url'] as String,
      headline: json['headline'] as String?,
      summary: json['summary'] as String?,
      location: json['location'] as String?,
      industry: json['industry'] as String?,
      connections: json['connections'] as int? ?? 0,
      followers: json['followers'] as int? ?? 0,
      experience: (json['experience'] as List<dynamic>? ?? [])
          .map((e) => LinkedInExperienceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      education: (json['education'] as List<dynamic>? ?? [])
          .map((e) => LinkedInEducationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      skills: (json['skills'] as List<dynamic>? ?? [])
          .map((e) => LinkedInSkillModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      dataQualityScore: (json['data_quality_score'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  LinkedInProfile toEntity() {
    return LinkedInProfile(
      profileUrl: profileUrl,
      headline: headline,
      summary: summary,
      location: location,
      industry: industry,
      connections: connections,
      followers: followers,
      experience: experience.map((e) => e.toEntity()).toList(),
      education: education.map((e) => e.toEntity()).toList(),
      skills: skills.map((e) => e.toEntity()).toList(),
      dataQualityScore: dataQualityScore,
      lastUpdated: lastUpdated,
    );
  }
}

class LinkedInExperienceModel {
  final String title;
  final String companyName;
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;

  LinkedInExperienceModel({
    required this.title,
    required this.companyName,
    this.location,
    this.startDate,
    this.endDate,
    this.description,
  });

  factory LinkedInExperienceModel.fromJson(Map<String, dynamic> json) {
    return LinkedInExperienceModel(
      title: json['title'] as String,
      companyName: json['company_name'] as String,
      location: json['location'] as String?,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      description: json['description'] as String?,
    );
  }

  LinkedInExperience toEntity() {
    return LinkedInExperience(
      title: title,
      companyName: companyName,
      location: location,
      startDate: startDate,
      endDate: endDate,
      description: description,
    );
  }
}

class LinkedInEducationModel {
  final String institution;
  final String? degreeName;
  final String? fieldOfStudy;
  final DateTime? startDate;
  final DateTime? endDate;

  LinkedInEducationModel({
    required this.institution,
    this.degreeName,
    this.fieldOfStudy,
    this.startDate,
    this.endDate,
  });

  factory LinkedInEducationModel.fromJson(Map<String, dynamic> json) {
    return LinkedInEducationModel(
      institution: json['institution'] as String,
      degreeName: json['degree_name'] as String?,
      fieldOfStudy: json['field_of_study'] as String?,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
    );
  }

  LinkedInEducation toEntity() {
    return LinkedInEducation(
      institution: institution,
      degreeName: degreeName,
      fieldOfStudy: fieldOfStudy,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

class LinkedInSkillModel {
  final String name;
  final int? endorsementCount;

  LinkedInSkillModel({
    required this.name,
    this.endorsementCount,
  });

  factory LinkedInSkillModel.fromJson(Map<String, dynamic> json) {
    return LinkedInSkillModel(
      name: json['name'] as String,
      endorsementCount: json['endorsement_count'] as int?,
    );
  }

  LinkedInSkill toEntity() {
    return LinkedInSkill(
      name: name,
      endorsementCount: endorsementCount,
    );
  }
}

class AcademicProfileModel {
  final List<AcademicDegreeModel> degrees;
  final List<AcademicPublicationModel> publications;
  final List<String> researchAreas;
  final double dataQualityScore;
  final DateTime lastUpdated;

  AcademicProfileModel({
    required this.degrees,
    required this.publications,
    required this.researchAreas,
    required this.dataQualityScore,
    required this.lastUpdated,
  });

  factory AcademicProfileModel.fromJson(Map<String, dynamic> json) {
    return AcademicProfileModel(
      degrees: (json['degrees'] as List<dynamic>? ?? [])
          .map((e) => AcademicDegreeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      publications: (json['publications'] as List<dynamic>? ?? [])
          .map((e) => AcademicPublicationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      researchAreas: List<String>.from(json['research_areas'] ?? []),
      dataQualityScore: (json['data_quality_score'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  AcademicProfile toEntity() {
    return AcademicProfile(
      degrees: degrees.map((e) => e.toEntity()).toList(),
      publications: publications.map((e) => e.toEntity()).toList(),
      researchAreas: researchAreas,
      dataQualityScore: dataQualityScore,
      lastUpdated: lastUpdated,
    );
  }
}

class AcademicDegreeModel {
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final int? conclusionYear;
  final bool isFromTopInstitution;

  AcademicDegreeModel({
    required this.institution,
    required this.degree,
    required this.fieldOfStudy,
    this.conclusionYear,
    this.isFromTopInstitution = false,
  });

  factory AcademicDegreeModel.fromJson(Map<String, dynamic> json) {
    return AcademicDegreeModel(
      institution: json['institution'] as String,
      degree: json['degree'] as String,
      fieldOfStudy: json['field_of_study'] as String,
      conclusionYear: json['conclusion_year'] as int?,
      isFromTopInstitution: json['is_from_top_institution'] as bool? ?? false,
    );
  }

  AcademicDegree toEntity() {
    return AcademicDegree(
      institution: institution,
      degree: degree,
      fieldOfStudy: fieldOfStudy,
      conclusionYear: conclusionYear,
      isFromTopInstitution: isFromTopInstitution,
    );
  }
}

class AcademicPublicationModel {
  final String title;
  final String journalOrConference;
  final int? year;
  final int? citationCount;
  final String? publicationUrl;

  AcademicPublicationModel({
    required this.title,
    required this.journalOrConference,
    this.year,
    this.citationCount,
    this.publicationUrl,
  });

  factory AcademicPublicationModel.fromJson(Map<String, dynamic> json) {
    return AcademicPublicationModel(
      title: json['title'] as String,
      journalOrConference: json['journal_or_conference'] as String,
      year: json['year'] as int?,
      citationCount: json['citation_count'] as int?,
      publicationUrl: json['publication_url'] as String?,
    );
  }

  AcademicPublication toEntity() {
    return AcademicPublication(
      title: title,
      journalOrConference: journalOrConference,
      year: year,
      citationCount: citationCount,
      publicationUrl: publicationUrl,
    );
  }
}

class DataSourceInfoModel {
  final String sourceName;
  final DateTime lastUpdated;
  final double qualityScore;
  final bool hasError;
  final String? errorMessage;

  DataSourceInfoModel({
    required this.sourceName,
    required this.lastUpdated,
    required this.qualityScore,
    this.hasError = false,
    this.errorMessage,
  });

  factory DataSourceInfoModel.fromJson(Map<String, dynamic> json) {
    return DataSourceInfoModel(
      sourceName: json['source_name'] as String,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      qualityScore: (json['quality_score'] as num).toDouble(),
      hasError: json['has_error'] as bool? ?? false,
      errorMessage: json['error_message'] as String?,
    );
  }

  DataSourceInfo toEntity() {
    return DataSourceInfo(
      sourceName: sourceName,
      lastUpdated: lastUpdated,
      qualityScore: qualityScore,
      hasError: hasError,
      errorMessage: errorMessage,
    );
  }
} 