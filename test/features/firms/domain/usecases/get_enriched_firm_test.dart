import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

import '../../../../../../../apps/app_flutter/lib/src/features/firms/domain/entities/enriched_firm.dart';
import '../../../../../../../apps/app_flutter/lib/src/features/firms/domain/repositories/enriched_firm_repository.dart';
import '../../../../../../../apps/app_flutter/lib/src/features/firms/domain/usecases/get_enriched_firm.dart';
import '../../../../../../../apps/app_flutter/lib/src/core/error/failures.dart';

import 'get_enriched_firm_test.mocks.dart';

@GenerateMocks([EnrichedFirmRepository])
void main() {
  late GetEnrichedFirm usecase;
  late RefreshEnrichedFirm refreshUsecase;
  late MockEnrichedFirmRepository mockRepository;

  setUp(() {
    mockRepository = MockEnrichedFirmRepository();
    usecase = GetEnrichedFirm(mockRepository);
    refreshUsecase = RefreshEnrichedFirm(mockRepository);
  });

  group('GetEnrichedFirm', () {
    const tFirmId = 'test_firm_id';
    final tEnrichedFirm = _createMockEnrichedFirm();

    test('should get enriched firm from the repository when call is successful', () async {
      // arrange
      when(mockRepository.getEnrichedFirm(any))
          .thenAnswer((_) async => Right(tEnrichedFirm));

      // act
      final result = await usecase(tFirmId);

      // assert
      expect(result, Right(tEnrichedFirm));
      verify(mockRepository.getEnrichedFirm(tFirmId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return server failure when the call to repository is unsuccessful', () async {
      // arrange
      when(mockRepository.getEnrichedFirm(any))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      // act
      final result = await usecase(tFirmId);

      // assert
      expect(result, const Left(ServerFailure('Server error')));
      verify(mockRepository.getEnrichedFirm(tFirmId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return network failure when there is no internet connection', () async {
      // arrange
      when(mockRepository.getEnrichedFirm(any))
          .thenAnswer((_) async => const Left(NetworkFailure('No internet connection')));

      // act
      final result = await usecase(tFirmId);

      // assert
      expect(result, const Left(NetworkFailure('No internet connection')));
      verify(mockRepository.getEnrichedFirm(tFirmId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return not found failure when firm does not exist', () async {
      // arrange
      when(mockRepository.getEnrichedFirm(any))
          .thenAnswer((_) async => const Left(NotFoundFailure('Firm not found')));

      // act
      final result = await usecase(tFirmId);

      // assert
      expect(result, const Left(NotFoundFailure('Firm not found')));
      verify(mockRepository.getEnrichedFirm(tFirmId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return validation failure when firm ID is invalid', () async {
      // arrange
      when(mockRepository.getEnrichedFirm(any))
          .thenAnswer((_) async => const Left(ValidationFailure('Invalid firm ID')));

      // act
      final result = await usecase('');

      // assert
      expect(result, const Left(ValidationFailure('Invalid firm ID')));
      verify(mockRepository.getEnrichedFirm(''));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return authorization failure when access is denied', () async {
      // arrange
      when(mockRepository.getEnrichedFirm(any))
          .thenAnswer((_) async => const Left(AuthorizationFailure('Access denied')));

      // act
      final result = await usecase(tFirmId);

      // assert
      expect(result, const Left(AuthorizationFailure('Access denied')));
      verify(mockRepository.getEnrichedFirm(tFirmId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return cache failure when cache operation fails', () async {
      // arrange
      when(mockRepository.getEnrichedFirm(any))
          .thenAnswer((_) async => const Left(CacheFailure('Cache error')));

      // act
      final result = await usecase(tFirmId);

      // assert
      expect(result, const Left(CacheFailure('Cache error')));
      verify(mockRepository.getEnrichedFirm(tFirmId));
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('RefreshEnrichedFirm', () {
    const tFirmId = 'test_firm_id';
    final tEnrichedFirm = _createMockEnrichedFirm();

    test('should refresh enriched firm from the repository when call is successful', () async {
      // arrange
      when(mockRepository.refreshEnrichedFirm(any))
          .thenAnswer((_) async => Right(tEnrichedFirm));

      // act
      final result = await refreshUsecase(tFirmId);

      // assert
      expect(result, Right(tEnrichedFirm));
      verify(mockRepository.refreshEnrichedFirm(tFirmId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return server failure when the refresh call is unsuccessful', () async {
      // arrange
      when(mockRepository.refreshEnrichedFirm(any))
          .thenAnswer((_) async => const Left(ServerFailure('Refresh failed')));

      // act
      final result = await refreshUsecase(tFirmId);

      // assert
      expect(result, const Left(ServerFailure('Refresh failed')));
      verify(mockRepository.refreshEnrichedFirm(tFirmId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return network failure when refresh fails due to network', () async {
      // arrange
      when(mockRepository.refreshEnrichedFirm(any))
          .thenAnswer((_) async => const Left(NetworkFailure('Network error during refresh')));

      // act
      final result = await refreshUsecase(tFirmId);

      // assert
      expect(result, const Left(NetworkFailure('Network error during refresh')));
      verify(mockRepository.refreshEnrichedFirm(tFirmId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return cache failure when refresh cache operation fails', () async {
      // arrange
      when(mockRepository.refreshEnrichedFirm(any))
          .thenAnswer((_) async => const Left(CacheFailure('Cache refresh failed')));

      // act
      final result = await refreshUsecase(tFirmId);

      // assert
      expect(result, const Left(CacheFailure('Cache refresh failed')));
      verify(mockRepository.refreshEnrichedFirm(tFirmId));
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('GetEnrichedFirm - Team Data', () {
    const tFirmId = 'test_firm_id';
    final tTeamData = FirmTeamData(
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
    );

    test('should get team data from the repository when call is successful', () async {
      // arrange
      when(mockRepository.getTeamData(any))
          .thenAnswer((_) async => Right(tTeamData));

      // act
      final result = await usecase.getTeamData(tFirmId);

      // assert
      expect(result, Right(tTeamData));
      verify(mockRepository.getTeamData(tFirmId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return server failure when team data call is unsuccessful', () async {
      // arrange
      when(mockRepository.getTeamData(any))
          .thenAnswer((_) async => const Left(ServerFailure('Team data not available')));

      // act
      final result = await usecase.getTeamData(tFirmId);

      // assert
      expect(result, const Left(ServerFailure('Team data not available')));
      verify(mockRepository.getTeamData(tFirmId));
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('GetEnrichedFirm - Financial Data', () {
    const tFirmId = 'test_firm_id';
    final tFinancialData = FirmFinancialSummary(
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
    );

    test('should get financial data from the repository when call is successful', () async {
      // arrange
      when(mockRepository.getFinancialData(any))
          .thenAnswer((_) async => Right(tFinancialData));

      // act
      final result = await usecase.getFinancialData(tFirmId);

      // assert
      expect(result, Right(tFinancialData));
      verify(mockRepository.getFinancialData(tFirmId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return authorization failure when financial data access is denied', () async {
      // arrange
      when(mockRepository.getFinancialData(any))
          .thenAnswer((_) async => const Left(AuthorizationFailure('Access denied to financial data')));

      // act
      final result = await usecase.getFinancialData(tFirmId);

      // assert
      expect(result, const Left(AuthorizationFailure('Access denied to financial data')));
      verify(mockRepository.getFinancialData(tFirmId));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return server failure when financial data is not available', () async {
      // arrange
      when(mockRepository.getFinancialData(any))
          .thenAnswer((_) async => const Left(ServerFailure('Financial data not available')));

      // act
      final result = await usecase.getFinancialData(tFirmId);

      // assert
      expect(result, const Left(ServerFailure('Financial data not available')));
      verify(mockRepository.getFinancialData(tFirmId));
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('Edge Cases and Performance', () {
    test('should handle multiple sequential calls correctly', () async {
      // arrange
      const tFirmId1 = 'firm_1';
      const tFirmId2 = 'firm_2';
      final tFirm1 = _createMockEnrichedFirm();
      final tFirm2 = _createMockEnrichedFirm();
      
      when(mockRepository.getEnrichedFirm(tFirmId1))
          .thenAnswer((_) async => Right(tFirm1));
      when(mockRepository.getEnrichedFirm(tFirmId2))
          .thenAnswer((_) async => Right(tFirm2));

      // act
      final result1 = await usecase(tFirmId1);
      final result2 = await usecase(tFirmId2);

      // assert
      expect(result1, Right(tFirm1));
      expect(result2, Right(tFirm2));
      verify(mockRepository.getEnrichedFirm(tFirmId1));
      verify(mockRepository.getEnrichedFirm(tFirmId2));
    });

    test('should handle concurrent calls to same firm correctly', () async {
      // arrange
      const tFirmId = 'test_firm_id';
      final tEnrichedFirm = _createMockEnrichedFirm();
      
      when(mockRepository.getEnrichedFirm(any))
          .thenAnswer((_) async => Right(tEnrichedFirm));

      // act
      final futures = List.generate(5, (_) => usecase(tFirmId));
      final results = await Future.wait(futures);

      // assert
      for (final result in results) {
        expect(result, Right(tEnrichedFirm));
      }
      verify(mockRepository.getEnrichedFirm(tFirmId)).called(5);
    });

    test('should handle very long firm IDs correctly', () async {
      // arrange
      final longFirmId = 'a' * 1000; // Very long ID
      final tEnrichedFirm = _createMockEnrichedFirm();
      
      when(mockRepository.getEnrichedFirm(any))
          .thenAnswer((_) async => Right(tEnrichedFirm));

      // act
      final result = await usecase(longFirmId);

      // assert
      expect(result, Right(tEnrichedFirm));
      verify(mockRepository.getEnrichedFirm(longFirmId));
    });

    test('should handle special characters in firm ID correctly', () async {
      // arrange
      const specialFirmId = 'firm-123_test@domain.com';
      final tEnrichedFirm = _createMockEnrichedFirm();
      
      when(mockRepository.getEnrichedFirm(any))
          .thenAnswer((_) async => Right(tEnrichedFirm));

      // act
      final result = await usecase(specialFirmId);

      // assert
      expect(result, Right(tEnrichedFirm));
      verify(mockRepository.getEnrichedFirm(specialFirmId));
    });
  });
}

EnrichedFirm _createMockEnrichedFirm() {
  return EnrichedFirm(
    id: 'test_firm_id',
    name: 'Test Law Firm',
    description: 'A test law firm for unit testing purposes',
    specializations: const ['Corporate Law', 'Tax Law', 'M&A'],
    location: 'São Paulo, SP, Brazil',
    foundedYear: 1995,
    size: FirmSize.large,
    rating: 4.5,
    caseSuccessRate: 0.87,
    averageResponseTime: const Duration(hours: 4),
    priceRange: PriceRange.premium,
    languages: const ['Portuguese', 'English', 'Spanish'],
    certifications: const ['ISO 27001', 'Legal 500', 'Chambers Global'],
    contactInfo: const FirmContactInfo(
      email: 'contact@testfirm.com.br',
      phone: '+55 11 99999-9999',
      website: 'https://www.testfirm.com.br',
      address: 'Av. Paulista, 1000, 15º andar - São Paulo, SP',
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
      barAssociations: const ['OAB-SP', 'OAB-RJ', 'OAB-MG'],
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
        DataSourceInfo(
          sourceName: 'Official Registry',
          lastUpdated: '2024-01-14T15:45:00Z',
          qualityScore: 0.98,
          dataPoints: 75,
          errors: [],
        ),
      ],
      dataQualityScore: 0.95,
      lastConsolidated: '2024-01-15T10:30:00Z',
      privacyPolicy: 'All data collected and processed in compliance with LGPD (Brazilian Data Protection Law)',
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
        'Labor Law': 2432000,
      },
      yearOverYearMetrics: const {
        '2024': 25600000,
        '2023': 22200000,
        '2022': 19800000,
        '2021': 17600000,
      },
    ),
    lastUpdated: DateTime.parse('2024-01-15T10:30:00Z'),
  );
} 