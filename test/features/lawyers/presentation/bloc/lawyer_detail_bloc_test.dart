import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

import '../../../../../../../apps/app_flutter/lib/src/features/lawyers/domain/entities/enriched_lawyer.dart';
import '../../../../../../../apps/app_flutter/lib/src/features/lawyers/domain/entities/linkedin_profile.dart';
import '../../../../../../../apps/app_flutter/lib/src/features/lawyers/domain/entities/academic_profile.dart';
import '../../../../../../../apps/app_flutter/lib/src/features/lawyers/domain/entities/data_source_info.dart';
import '../../../../../../../apps/app_flutter/lib/src/features/lawyers/domain/usecases/get_enriched_lawyer.dart';
import '../../../../../../../apps/app_flutter/lib/src/features/lawyers/presentation/bloc/lawyer_detail_bloc.dart';
import '../../../../../../../apps/app_flutter/lib/src/features/lawyers/presentation/bloc/lawyer_detail_event.dart';
import '../../../../../../../apps/app_flutter/lib/src/features/lawyers/presentation/bloc/lawyer_detail_state.dart';
import '../../../../../../../apps/app_flutter/lib/src/core/error/failures.dart';

import 'lawyer_detail_bloc_test.mocks.dart';

@GenerateMocks([GetEnrichedLawyer, RefreshEnrichedLawyer])
void main() {
  late LawyerDetailBloc bloc;
  late MockGetEnrichedLawyer mockGetEnrichedLawyer;
  late MockRefreshEnrichedLawyer mockRefreshEnrichedLawyer;

  setUp(() {
    mockGetEnrichedLawyer = MockGetEnrichedLawyer();
    mockRefreshEnrichedLawyer = MockRefreshEnrichedLawyer();
    bloc = LawyerDetailBloc(
      getEnrichedLawyer: mockGetEnrichedLawyer,
      refreshEnrichedLawyer: mockRefreshEnrichedLawyer,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('LawyerDetailBloc', () {
    const tLawyerId = 'test_lawyer_id';
    final tEnrichedLawyer = _createMockEnrichedLawyer();

    test('initial state should be LawyerDetailInitial', () {
      expect(bloc.state, equals(LawyerDetailInitial()));
    });

    group('LoadLawyerDetail', () {
      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should emit [LawyerDetailLoading, LawyerDetailLoaded] when data is gotten successfully',
        build: () {
          when(mockGetEnrichedLawyer(any))
              .thenAnswer((_) async => Right(tEnrichedLawyer));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLawyerDetail(tLawyerId)),
        expect: () => [
          LawyerDetailLoading(),
          LawyerDetailLoaded(enrichedLawyer: tEnrichedLawyer),
        ],
        verify: (_) {
          verify(mockGetEnrichedLawyer(tLawyerId));
        },
      );

      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should emit [LawyerDetailLoading, LawyerDetailError] when getting data fails',
        build: () {
          when(mockGetEnrichedLawyer(any))
              .thenAnswer((_) async => const Left(ServerFailure('Server error')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLawyerDetail(tLawyerId)),
        expect: () => [
          LawyerDetailLoading(),
          const LawyerDetailError(message: 'Server error'),
        ],
        verify: (_) {
          verify(mockGetEnrichedLawyer(tLawyerId));
        },
      );

      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should emit [LawyerDetailLoading, LawyerDetailError] when getting data fails with network error',
        build: () {
          when(mockGetEnrichedLawyer(any))
              .thenAnswer((_) async => const Left(NetworkFailure('No internet connection')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLawyerDetail(tLawyerId)),
        expect: () => [
          LawyerDetailLoading(),
          const LawyerDetailError(message: 'No internet connection'),
        ],
        verify: (_) {
          verify(mockGetEnrichedLawyer(tLawyerId));
        },
      );

      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should emit [LawyerDetailLoading, LawyerDetailError] when lawyer not found',
        build: () {
          when(mockGetEnrichedLawyer(any))
              .thenAnswer((_) async => const Left(NotFoundFailure('Lawyer not found')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLawyerDetail(tLawyerId)),
        expect: () => [
          LawyerDetailLoading(),
          const LawyerDetailError(message: 'Lawyer not found'),
        ],
        verify: (_) {
          verify(mockGetEnrichedLawyer(tLawyerId));
        },
      );
    });

    group('RefreshLawyerDetail', () {
      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should emit [LawyerDetailLoading, LawyerDetailLoaded] when refresh is successful',
        build: () {
          when(mockRefreshEnrichedLawyer(any))
              .thenAnswer((_) async => Right(tEnrichedLawyer));
          return bloc;
        },
        act: (bloc) => bloc.add(const RefreshLawyerDetail(tLawyerId)),
        expect: () => [
          LawyerDetailLoading(),
          LawyerDetailLoaded(enrichedLawyer: tEnrichedLawyer),
        ],
        verify: (_) {
          verify(mockRefreshEnrichedLawyer(tLawyerId));
        },
      );

      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should emit [LawyerDetailLoading, LawyerDetailError] when refresh fails',
        build: () {
          when(mockRefreshEnrichedLawyer(any))
              .thenAnswer((_) async => const Left(CacheFailure('Cache error')));
          return bloc;
        },
        act: (bloc) => bloc.add(const RefreshLawyerDetail(tLawyerId)),
        expect: () => [
          LawyerDetailLoading(),
          const LawyerDetailError(message: 'Cache error'),
        ],
        verify: (_) {
          verify(mockRefreshEnrichedLawyer(tLawyerId));
        },
      );

      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should refresh from loaded state successfully',
        build: () {
          when(mockRefreshEnrichedLawyer(any))
              .thenAnswer((_) async => Right(tEnrichedLawyer));
          return bloc;
        },
        seed: () => LawyerDetailLoaded(enrichedLawyer: tEnrichedLawyer),
        act: (bloc) => bloc.add(const RefreshLawyerDetail(tLawyerId)),
        expect: () => [
          LawyerDetailLoading(),
          LawyerDetailLoaded(enrichedLawyer: tEnrichedLawyer),
        ],
        verify: (_) {
          verify(mockRefreshEnrichedLawyer(tLawyerId));
        },
      );
    });

    group('LoadLinkedInProfile', () {
      final tLinkedInProfile = LinkedInProfile(
        profileUrl: 'https://linkedin.com/in/test-lawyer',
        headline: 'Senior Corporate Lawyer',
        summary: 'Experienced lawyer in corporate law',
        location: 'São Paulo, SP',
        industry: 'Legal Services',
        connectionCount: 500,
        education: const [
          LinkedInEducation(
            institution: 'University of São Paulo',
            degreeName: 'Bachelor of Laws',
            fieldOfStudy: 'Law',
            startDate: '2010-01-01',
            endDate: '2014-12-31',
          ),
        ],
        experience: const [
          LinkedInExperience(
            title: 'Senior Associate',
            company: 'Big Law Firm',
            startDate: '2018-01-01',
            endDate: null,
            description: 'Corporate law practice',
          ),
        ],
        skills: const [
          LinkedInSkill(
            name: 'Corporate Law',
            endorsementCount: 25,
          ),
          LinkedInSkill(
            name: 'Contract Negotiation',
            endorsementCount: 18,
          ),
        ],
        dataQualityScore: 0.92,
        lastUpdated: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should emit [LawyerDetailLoading, LawyerDetailLinkedInLoaded] when LinkedIn data is loaded successfully',
        build: () {
          when(mockGetEnrichedLawyer.getLinkedInProfile(any))
              .thenAnswer((_) async => Right(tLinkedInProfile));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLinkedInProfile(tLawyerId)),
        expect: () => [
          LawyerDetailLoading(),
          LawyerDetailLinkedInLoaded(linkedInProfile: tLinkedInProfile),
        ],
        verify: (_) {
          verify(mockGetEnrichedLawyer.getLinkedInProfile(tLawyerId));
        },
      );

      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should emit [LawyerDetailLoading, LawyerDetailError] when LinkedIn data loading fails',
        build: () {
          when(mockGetEnrichedLawyer.getLinkedInProfile(any))
              .thenAnswer((_) async => const Left(ServerFailure('LinkedIn data not available')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLinkedInProfile(tLawyerId)),
        expect: () => [
          LawyerDetailLoading(),
          const LawyerDetailError(message: 'LinkedIn data not available'),
        ],
        verify: (_) {
          verify(mockGetEnrichedLawyer.getLinkedInProfile(tLawyerId));
        },
      );
    });

    group('LoadAcademicProfile', () {
      final tAcademicProfile = AcademicProfile(
        degrees: const [
          AcademicDegree(
            institution: 'University of São Paulo',
            degreeName: 'Bachelor of Laws',
            fieldOfStudy: 'Law',
            graduationYear: 2014,
            gpa: 8.5,
            honors: ['Magna Cum Laude'],
          ),
        ],
        publications: const [
          AcademicPublication(
            title: 'Corporate Governance in Brazil',
            journal: 'Legal Review',
            year: 2020,
            authors: ['Test Lawyer', 'Co-Author'],
            abstract: 'Study on corporate governance practices',
          ),
        ],
        certifications: const ['OAB-SP Certificate'],
        academicAchievements: const ['Dean\'s List 2013'],
        researchAreas: const ['Corporate Law', 'M&A'],
        dataQualityScore: 0.88,
        lastUpdated: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should emit [LawyerDetailLoading, LawyerDetailAcademicLoaded] when academic data is loaded successfully',
        build: () {
          when(mockGetEnrichedLawyer.getAcademicProfile(any))
              .thenAnswer((_) async => Right(tAcademicProfile));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadAcademicProfile(tLawyerId)),
        expect: () => [
          LawyerDetailLoading(),
          LawyerDetailAcademicLoaded(academicProfile: tAcademicProfile),
        ],
        verify: (_) {
          verify(mockGetEnrichedLawyer.getAcademicProfile(tLawyerId));
        },
      );

      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should emit [LawyerDetailLoading, LawyerDetailError] when academic data loading fails',
        build: () {
          when(mockGetEnrichedLawyer.getAcademicProfile(any))
              .thenAnswer((_) async => const Left(ServerFailure('Academic data not available')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadAcademicProfile(tLawyerId)),
        expect: () => [
          LawyerDetailLoading(),
          const LawyerDetailError(message: 'Academic data not available'),
        ],
        verify: (_) {
          verify(mockGetEnrichedLawyer.getAcademicProfile(tLawyerId));
        },
      );
    });

    group('Multiple Events', () {
      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should handle multiple sequential events correctly',
        build: () {
          when(mockGetEnrichedLawyer(any))
              .thenAnswer((_) async => Right(tEnrichedLawyer));
          when(mockRefreshEnrichedLawyer(any))
              .thenAnswer((_) async => Right(tEnrichedLawyer));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const LoadLawyerDetail(tLawyerId));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const RefreshLawyerDetail(tLawyerId));
        },
        expect: () => [
          LawyerDetailLoading(),
          LawyerDetailLoaded(enrichedLawyer: tEnrichedLawyer),
          LawyerDetailLoading(),
          LawyerDetailLoaded(enrichedLawyer: tEnrichedLawyer),
        ],
        verify: (_) {
          verify(mockGetEnrichedLawyer(tLawyerId));
          verify(mockRefreshEnrichedLawyer(tLawyerId));
        },
      );
    });

    group('Edge Cases', () {
      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should handle empty lawyer ID gracefully',
        build: () {
          when(mockGetEnrichedLawyer(any))
              .thenAnswer((_) async => const Left(ValidationFailure('Invalid lawyer ID')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLawyerDetail('')),
        expect: () => [
          LawyerDetailLoading(),
          const LawyerDetailError(message: 'Invalid lawyer ID'),
        ],
        verify: (_) {
          verify(mockGetEnrichedLawyer(''));
        },
      );

      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should handle null lawyer ID gracefully',
        build: () {
          when(mockGetEnrichedLawyer(any))
              .thenAnswer((_) async => const Left(ValidationFailure('Lawyer ID cannot be null')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLawyerDetail('null')),
        expect: () => [
          LawyerDetailLoading(),
          const LawyerDetailError(message: 'Lawyer ID cannot be null'),
        ],
        verify: (_) {
          verify(mockGetEnrichedLawyer('null'));
        },
      );

      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should handle authorization error gracefully',
        build: () {
          when(mockGetEnrichedLawyer(any))
              .thenAnswer((_) async => const Left(AuthorizationFailure('Access denied')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLawyerDetail(tLawyerId)),
        expect: () => [
          LawyerDetailLoading(),
          const LawyerDetailError(message: 'Access denied'),
        ],
        verify: (_) {
          verify(mockGetEnrichedLawyer(tLawyerId));
        },
      );

      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should handle timeout error gracefully',
        build: () {
          when(mockGetEnrichedLawyer(any))
              .thenAnswer((_) async => const Left(NetworkFailure('Request timeout')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadLawyerDetail(tLawyerId)),
        expect: () => [
          LawyerDetailLoading(),
          const LawyerDetailError(message: 'Request timeout'),
        ],
        verify: (_) {
          verify(mockGetEnrichedLawyer(tLawyerId));
        },
      );
    });

    group('State Transitions', () {
      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should transition from error state to loaded state when retry succeeds',
        build: () {
          when(mockGetEnrichedLawyer(any))
              .thenAnswer((_) async => Right(tEnrichedLawyer));
          return bloc;
        },
        seed: () => const LawyerDetailError(message: 'Previous error'),
        act: (bloc) => bloc.add(const LoadLawyerDetail(tLawyerId)),
        expect: () => [
          LawyerDetailLoading(),
          LawyerDetailLoaded(enrichedLawyer: tEnrichedLawyer),
        ],
        verify: (_) {
          verify(mockGetEnrichedLawyer(tLawyerId));
        },
      );

      blocTest<LawyerDetailBloc, LawyerDetailState>(
        'should maintain loaded state when refresh succeeds',
        build: () {
          when(mockRefreshEnrichedLawyer(any))
              .thenAnswer((_) async => Right(tEnrichedLawyer));
          return bloc;
        },
        seed: () => LawyerDetailLoaded(enrichedLawyer: tEnrichedLawyer),
        act: (bloc) => bloc.add(const RefreshLawyerDetail(tLawyerId)),
        expect: () => [
          LawyerDetailLoading(),
          LawyerDetailLoaded(enrichedLawyer: tEnrichedLawyer),
        ],
        verify: (_) {
          verify(mockRefreshEnrichedLawyer(tLawyerId));
        },
      );
    });
  });
}

EnrichedLawyer _createMockEnrichedLawyer() {
  final linkedInProfile = LinkedInProfile(
    profileUrl: 'https://linkedin.com/in/test-lawyer',
    headline: 'Senior Corporate Lawyer',
    summary: 'Experienced lawyer in corporate law',
    location: 'São Paulo, SP',
    industry: 'Legal Services',
    connectionCount: 500,
    education: const [
      LinkedInEducation(
        institution: 'University of São Paulo',
        degreeName: 'Bachelor of Laws',
        fieldOfStudy: 'Law',
        startDate: '2010-01-01',
        endDate: '2014-12-31',
      ),
    ],
    experience: const [
      LinkedInExperience(
        title: 'Senior Associate',
        company: 'Big Law Firm',
        startDate: '2018-01-01',
        endDate: null,
        description: 'Corporate law practice',
      ),
    ],
    skills: const [
      LinkedInSkill(
        name: 'Corporate Law',
        endorsementCount: 25,
      ),
    ],
    dataQualityScore: 0.92,
    lastUpdated: DateTime.parse('2024-01-15T10:30:00Z'),
  );

  final academicProfile = AcademicProfile(
    degrees: const [
      AcademicDegree(
        institution: 'University of São Paulo',
        degreeName: 'Bachelor of Laws',
        fieldOfStudy: 'Law',
        graduationYear: 2014,
        gpa: 8.5,
        honors: ['Magna Cum Laude'],
      ),
    ],
    publications: const [
      AcademicPublication(
        title: 'Corporate Governance in Brazil',
        journal: 'Legal Review',
        year: 2020,
        authors: ['Test Lawyer'],
        abstract: 'Study on corporate governance practices',
      ),
    ],
    certifications: const ['OAB-SP Certificate'],
    academicAchievements: const ['Dean\'s List 2013'],
    researchAreas: const ['Corporate Law', 'M&A'],
    dataQualityScore: 0.88,
    lastUpdated: DateTime.parse('2024-01-15T10:30:00Z'),
  );

  const dataSources = [
    DataSourceInfo(
      sourceName: 'LinkedIn',
      lastUpdated: DateTime.parse('2024-01-15T10:30:00Z'),
      qualityScore: 0.92,
      errors: [],
    ),
    DataSourceInfo(
      sourceName: 'Academic Database',
      lastUpdated: DateTime.parse('2024-01-15T10:30:00Z'),
      qualityScore: 0.88,
      errors: [],
    ),
  ];

  return EnrichedLawyer(
    id: 'test_lawyer_id',
    name: 'Test Lawyer',
    email: 'test@lawyer.com',
    phone: '+55 11 99999-9999',
    oabNumber: 'OAB/SP 123456',
    specializations: const ['Corporate Law', 'M&A'],
    experience: 10,
    education: 'University of São Paulo - Bachelor of Laws',
    location: 'São Paulo, SP',
    languages: const ['Portuguese', 'English'],
    bio: 'Experienced corporate lawyer',
    linkedinProfile: linkedInProfile,
    academicProfile: academicProfile,
    dataSources: dataSources,
    overallQualityScore: 0.90,
    lastConsolidated: DateTime.parse('2024-01-15T10:30:00Z'),
  );
} 