import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

import '../../../../../../../apps/app_flutter/lib/src/features/firms/domain/entities/enriched_firm.dart';
import '../../../../../../../apps/app_flutter/lib/src/features/firms/domain/usecases/get_enriched_firm.dart';
import '../../../../../../../apps/app_flutter/lib/src/features/firms/presentation/bloc/firm_profile_bloc.dart';
import '../../../../../../../apps/app_flutter/lib/src/features/firms/presentation/bloc/firm_profile_event.dart';
import '../../../../../../../apps/app_flutter/lib/src/features/firms/presentation/bloc/firm_profile_state.dart';
import '../../../../../../../apps/app_flutter/lib/src/core/error/failures.dart';

import 'firm_profile_bloc_test.mocks.dart';

@GenerateMocks([GetEnrichedFirm, RefreshEnrichedFirm])
void main() {
  late FirmProfileBloc bloc;
  late MockGetEnrichedFirm mockGetEnrichedFirm;
  late MockRefreshEnrichedFirm mockRefreshEnrichedFirm;

  setUp(() {
    mockGetEnrichedFirm = MockGetEnrichedFirm();
    mockRefreshEnrichedFirm = MockRefreshEnrichedFirm();
    bloc = FirmProfileBloc(
      getEnrichedFirm: mockGetEnrichedFirm,
      refreshEnrichedFirm: mockRefreshEnrichedFirm,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('FirmProfileBloc', () {
    const tFirmId = 'test_firm_id';
    final tEnrichedFirm = _createMockEnrichedFirm();

    test('initial state should be FirmProfileInitial', () {
      expect(bloc.state, equals(FirmProfileInitial()));
    });

    group('LoadFirmProfile', () {
      blocTest<FirmProfileBloc, FirmProfileState>(
        'should emit [FirmProfileLoading, FirmProfileLoaded] when data is gotten successfully',
        build: () {
          when(mockGetEnrichedFirm(any))
              .thenAnswer((_) async => Right(tEnrichedFirm));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadFirmProfile(tFirmId)),
        expect: () => [
          FirmProfileLoading(),
          FirmProfileLoaded(enrichedFirm: tEnrichedFirm),
        ],
        verify: (_) {
          verify(mockGetEnrichedFirm(tFirmId));
        },
      );

      blocTest<FirmProfileBloc, FirmProfileState>(
        'should emit [FirmProfileLoading, FirmProfileError] when getting data fails',
        build: () {
          when(mockGetEnrichedFirm(any))
              .thenAnswer((_) async => const Left(ServerFailure('Server error')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadFirmProfile(tFirmId)),
        expect: () => [
          FirmProfileLoading(),
          const FirmProfileError(message: 'Server error'),
        ],
        verify: (_) {
          verify(mockGetEnrichedFirm(tFirmId));
        },
      );

      blocTest<FirmProfileBloc, FirmProfileState>(
        'should emit [FirmProfileLoading, FirmProfileError] when getting data fails with network error',
        build: () {
          when(mockGetEnrichedFirm(any))
              .thenAnswer((_) async => const Left(NetworkFailure('No internet connection')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadFirmProfile(tFirmId)),
        expect: () => [
          FirmProfileLoading(),
          const FirmProfileError(message: 'No internet connection'),
        ],
        verify: (_) {
          verify(mockGetEnrichedFirm(tFirmId));
        },
      );
    });

    group('RefreshFirmProfile', () {
      blocTest<FirmProfileBloc, FirmProfileState>(
        'should emit [FirmProfileLoading, FirmProfileLoaded] when refresh is successful',
        build: () {
          when(mockRefreshEnrichedFirm(any))
              .thenAnswer((_) async => Right(tEnrichedFirm));
          return bloc;
        },
        act: (bloc) => bloc.add(const RefreshFirmProfile(tFirmId)),
        expect: () => [
          FirmProfileLoading(),
          FirmProfileLoaded(enrichedFirm: tEnrichedFirm),
        ],
        verify: (_) {
          verify(mockRefreshEnrichedFirm(tFirmId));
        },
      );

      blocTest<FirmProfileBloc, FirmProfileState>(
        'should emit [FirmProfileLoading, FirmProfileError] when refresh fails',
        build: () {
          when(mockRefreshEnrichedFirm(any))
              .thenAnswer((_) async => const Left(CacheFailure('Cache error')));
          return bloc;
        },
        act: (bloc) => bloc.add(const RefreshFirmProfile(tFirmId)),
        expect: () => [
          FirmProfileLoading(),
          const FirmProfileError(message: 'Cache error'),
        ],
        verify: (_) {
          verify(mockRefreshEnrichedFirm(tFirmId));
        },
      );

      blocTest<FirmProfileBloc, FirmProfileState>(
        'should maintain previous state and show refresh error when refresh fails from loaded state',
        build: () {
          when(mockGetEnrichedFirm(any))
              .thenAnswer((_) async => Right(tEnrichedFirm));
          when(mockRefreshEnrichedFirm(any))
              .thenAnswer((_) async => const Left(ServerFailure('Refresh failed')));
          return bloc;
        },
        seed: () => FirmProfileLoaded(enrichedFirm: tEnrichedFirm),
        act: (bloc) => bloc.add(const RefreshFirmProfile(tFirmId)),
        expect: () => [
          FirmProfileLoading(),
          const FirmProfileError(message: 'Refresh failed'),
        ],
        verify: (_) {
          verify(mockRefreshEnrichedFirm(tFirmId));
        },
      );
    });

    group('LoadFirmTeam', () {
      final tTeamData = FirmTeamData(
        totalLawyers: 45,
        partners: 8,
        associates: 25,
        juniors: 12,
        specialistsByArea: const {
          'Direito Empresarial': 15,
          'Direito Tributário': 12,
          'M&A': 8,
          'Compliance': 10,
        },
        averageExperience: 8.5,
        barAssociations: const ['OAB-SP', 'OAB-RJ'],
        certifications: const ['ISO 27001', 'Legal 500'],
      );

      blocTest<FirmProfileBloc, FirmProfileState>(
        'should emit [FirmProfileLoading, FirmProfileTeamLoaded] when team data is loaded successfully',
        build: () {
          when(mockGetEnrichedFirm.getTeamData(any))
              .thenAnswer((_) async => Right(tTeamData));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadFirmTeam(tFirmId)),
        expect: () => [
          FirmProfileLoading(),
          FirmProfileTeamLoaded(teamData: tTeamData),
        ],
        verify: (_) {
          verify(mockGetEnrichedFirm.getTeamData(tFirmId));
        },
      );

      blocTest<FirmProfileBloc, FirmProfileState>(
        'should emit [FirmProfileLoading, FirmProfileError] when team data loading fails',
        build: () {
          when(mockGetEnrichedFirm.getTeamData(any))
              .thenAnswer((_) async => const Left(ServerFailure('Team data not found')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadFirmTeam(tFirmId)),
        expect: () => [
          FirmProfileLoading(),
          const FirmProfileError(message: 'Team data not found'),
        ],
        verify: (_) {
          verify(mockGetEnrichedFirm.getTeamData(tFirmId));
        },
      );
    });

    group('LoadFirmFinancial', () {
      final tFinancialData = FirmFinancialSummary(
        annualRevenue: 25600000,
        profitMargin: 0.30,
        ebitda: 9600000,
        averageTicket: 185000,
        revenueGrowth: 15.2,
        clientRetentionRate: 0.92,
        revenueByArea: const {
          'Direito Empresarial': 8960000,
          'M&A': 6400000,
          'Direito Tributário': 4608000,
          'Compliance': 3200000,
          'Trabalho': 2432000,
        },
        yearOverYearMetrics: const {
          '2024': 25600000,
          '2023': 22200000,
          '2022': 19800000,
        },
      );

      blocTest<FirmProfileBloc, FirmProfileState>(
        'should emit [FirmProfileLoading, FirmProfileFinancialLoaded] when financial data is loaded successfully',
        build: () {
          when(mockGetEnrichedFirm.getFinancialData(any))
              .thenAnswer((_) async => Right(tFinancialData));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadFirmFinancial(tFirmId)),
        expect: () => [
          FirmProfileLoading(),
          FirmProfileFinancialLoaded(financialData: tFinancialData),
        ],
        verify: (_) {
          verify(mockGetEnrichedFirm.getFinancialData(tFirmId));
        },
      );

      blocTest<FirmProfileBloc, FirmProfileState>(
        'should emit [FirmProfileLoading, FirmProfileError] when financial data loading fails',
        build: () {
          when(mockGetEnrichedFirm.getFinancialData(any))
              .thenAnswer((_) async => const Left(AuthorizationFailure('Access denied to financial data')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadFirmFinancial(tFirmId)),
        expect: () => [
          FirmProfileLoading(),
          const FirmProfileError(message: 'Access denied to financial data'),
        ],
        verify: (_) {
          verify(mockGetEnrichedFirm.getFinancialData(tFirmId));
        },
      );
    });

    group('Multiple Events', () {
      blocTest<FirmProfileBloc, FirmProfileState>(
        'should handle multiple sequential events correctly',
        build: () {
          when(mockGetEnrichedFirm(any))
              .thenAnswer((_) async => Right(tEnrichedFirm));
          when(mockRefreshEnrichedFirm(any))
              .thenAnswer((_) async => Right(tEnrichedFirm));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const LoadFirmProfile(tFirmId));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const RefreshFirmProfile(tFirmId));
        },
        expect: () => [
          FirmProfileLoading(),
          FirmProfileLoaded(enrichedFirm: tEnrichedFirm),
          FirmProfileLoading(),
          FirmProfileLoaded(enrichedFirm: tEnrichedFirm),
        ],
        verify: (_) {
          verify(mockGetEnrichedFirm(tFirmId));
          verify(mockRefreshEnrichedFirm(tFirmId));
        },
      );
    });

    group('Edge Cases', () {
      blocTest<FirmProfileBloc, FirmProfileState>(
        'should handle empty firm ID gracefully',
        build: () {
          when(mockGetEnrichedFirm(any))
              .thenAnswer((_) async => const Left(ValidationFailure('Invalid firm ID')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadFirmProfile('')),
        expect: () => [
          FirmProfileLoading(),
          const FirmProfileError(message: 'Invalid firm ID'),
        ],
        verify: (_) {
          verify(mockGetEnrichedFirm(''));
        },
      );

      blocTest<FirmProfileBloc, FirmProfileState>(
        'should handle network timeout gracefully',
        build: () {
          when(mockGetEnrichedFirm(any))
              .thenAnswer((_) async => const Left(NetworkFailure('Request timeout')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadFirmProfile(tFirmId)),
        expect: () => [
          FirmProfileLoading(),
          const FirmProfileError(message: 'Request timeout'),
        ],
        verify: (_) {
          verify(mockGetEnrichedFirm(tFirmId));
        },
      );
    });
  });
}

EnrichedFirm _createMockEnrichedFirm() {
  return EnrichedFirm(
    id: 'test_firm_id',
    name: 'Test Law Firm',
    description: 'A test law firm for unit testing',
    specializations: const ['Corporate Law', 'Tax Law'],
    location: 'São Paulo, SP',
    foundedYear: 1995,
    size: FirmSize.large,
    rating: 4.5,
    caseSuccessRate: 0.87,
    averageResponseTime: Duration(hours: 4),
    priceRange: PriceRange.premium,
    languages: const ['Portuguese', 'English'],
    certifications: const ['ISO 27001', 'Legal 500'],
    contactInfo: const FirmContactInfo(
      email: 'contact@testfirm.com',
      phone: '+55 11 99999-9999',
      website: 'https://testfirm.com',
      address: 'Av. Paulista, 1000 - São Paulo, SP',
    ),
    teamData: FirmTeamData(
      totalLawyers: 45,
      partners: 8,
      associates: 25,
      juniors: 12,
      specialistsByArea: const {
        'Corporate Law': 15,
        'Tax Law': 12,
        'M&A': 8,
        'Compliance': 10,
      },
      averageExperience: 8.5,
      barAssociations: const ['OAB-SP', 'OAB-RJ'],
      certifications: const ['ISO 27001', 'Legal 500'],
    ),
    transparencyReport: const FirmTransparencyReport(
      dataSources: [
        DataSourceInfo(
          sourceName: 'LinkedIn',
          lastUpdated: '2024-01-15T10:30:00Z',
          qualityScore: 0.92,
          dataPoints: 150,
          errors: [],
        ),
      ],
      dataQualityScore: 0.92,
      lastConsolidated: '2024-01-15T10:30:00Z',
      privacyPolicy: 'All data collected in compliance with LGPD',
    ),
    financialSummary: FirmFinancialSummary(
      annualRevenue: 25600000,
      profitMargin: 0.30,
      ebitda: 9600000,
      averageTicket: 185000,
      revenueGrowth: 15.2,
      clientRetentionRate: 0.92,
      revenueByArea: const {
        'Corporate Law': 8960000,
        'M&A': 6400000,
        'Tax Law': 4608000,
        'Compliance': 3200000,
        'Labor': 2432000,
      },
      yearOverYearMetrics: const {
        '2024': 25600000,
        '2023': 22200000,
        '2022': 19800000,
      },
    ),
    lastUpdated: DateTime.parse('2024-01-15T10:30:00Z'),
  );
} 