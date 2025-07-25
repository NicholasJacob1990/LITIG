import 'package:equatable/equatable.dart';

class LinkedInProfile extends Equatable {
  final String profileUrl;
  final String? headline;
  final String? summary;
  final String? location;
  final String? industry;
  final int connections;
  final int followers;
  final List<LinkedInExperience> experience;
  final List<LinkedInEducation> education;
  final List<LinkedInSkill> skills;
  final double dataQualityScore;
  final DateTime lastUpdated;

  const LinkedInProfile({
    required this.profileUrl,
    this.headline,
    this.summary,
    this.location,
    this.industry,
    required this.connections,
    required this.followers,
    this.experience = const [],
    this.education = const [],
    this.skills = const [],
    required this.dataQualityScore,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        profileUrl,
        headline,
        summary,
        location,
        industry,
        connections,
        followers,
        experience,
        education,
        skills,
        dataQualityScore,
        lastUpdated,
      ];
}

class LinkedInExperience extends Equatable {
  final String title;
  final String companyName;
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;

  const LinkedInExperience({
    required this.title,
    required this.companyName,
    this.location,
    this.startDate,
    this.endDate,
    this.description,
  });

  @override
  List<Object?> get props =>
      [title, companyName, location, startDate, endDate, description];
}

class LinkedInEducation extends Equatable {
  final String institution;
  final String? degreeName;
  final String? fieldOfStudy;
  final DateTime? startDate;
  final DateTime? endDate;

  const LinkedInEducation({
    required this.institution,
    this.degreeName,
    this.fieldOfStudy,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props =>
      [institution, degreeName, fieldOfStudy, startDate, endDate];
}

class LinkedInSkill extends Equatable {
  final String name;
  final int? endorsementCount;

  const LinkedInSkill({required this.name, this.endorsementCount});

  @override
  List<Object?> get props => [name, endorsementCount];
} 

class LinkedInProfile extends Equatable {
  final String profileUrl;
  final String? headline;
  final String? summary;
  final String? location;
  final String? industry;
  final int connections;
  final int followers;
  final List<LinkedInExperience> experience;
  final List<LinkedInEducation> education;
  final List<LinkedInSkill> skills;
  final double dataQualityScore;
  final DateTime lastUpdated;

  const LinkedInProfile({
    required this.profileUrl,
    this.headline,
    this.summary,
    this.location,
    this.industry,
    required this.connections,
    required this.followers,
    this.experience = const [],
    this.education = const [],
    this.skills = const [],
    required this.dataQualityScore,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        profileUrl,
        headline,
        summary,
        location,
        industry,
        connections,
        followers,
        experience,
        education,
        skills,
        dataQualityScore,
        lastUpdated,
      ];
}

class LinkedInExperience extends Equatable {
  final String title;
  final String companyName;
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;

  const LinkedInExperience({
    required this.title,
    required this.companyName,
    this.location,
    this.startDate,
    this.endDate,
    this.description,
  });

  @override
  List<Object?> get props =>
      [title, companyName, location, startDate, endDate, description];
}

class LinkedInEducation extends Equatable {
  final String institution;
  final String? degreeName;
  final String? fieldOfStudy;
  final DateTime? startDate;
  final DateTime? endDate;

  const LinkedInEducation({
    required this.institution,
    this.degreeName,
    this.fieldOfStudy,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props =>
      [institution, degreeName, fieldOfStudy, startDate, endDate];
}

class LinkedInSkill extends Equatable {
  final String name;
  final int? endorsementCount;

  const LinkedInSkill({required this.name, this.endorsementCount});

  @override
  List<Object?> get props => [name, endorsementCount];
} 