import 'package:equatable/equatable.dart';

class AcademicProfile extends Equatable {
  final List<AcademicDegree> degrees;
  final List<AcademicPublication> publications;
  final List<String> researchAreas;
  final double dataQualityScore;
  final DateTime lastUpdated;

  const AcademicProfile({
    this.degrees = const [],
    this.publications = const [],
    this.researchAreas = const [],
    required this.dataQualityScore,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props =>
      [degrees, publications, researchAreas, dataQualityScore, lastUpdated];
}

class AcademicDegree extends Equatable {
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final int? conclusionYear;
  final bool isFromTopInstitution;

  const AcademicDegree({
    required this.institution,
    required this.degree,
    required this.fieldOfStudy,
    this.conclusionYear,
    this.isFromTopInstitution = false,
  });

  @override
  List<Object?> get props =>
      [institution, degree, fieldOfStudy, conclusionYear, isFromTopInstitution];
}

class AcademicPublication extends Equatable {
  final String title;
  final String journalOrConference;
  final int? year;
  final int? citationCount;
  final String? publicationUrl;

  const AcademicPublication({
    required this.title,
    required this.journalOrConference,
    this.year,
    this.citationCount,
    this.publicationUrl,
  });

  @override
  List<Object?> get props =>
      [title, journalOrConference, year, citationCount, publicationUrl];
} 