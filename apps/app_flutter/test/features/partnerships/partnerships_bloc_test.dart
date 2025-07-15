import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:meu_app/src/core/utils/result.dart';
import 'package:meu_app/src/core/error/failures.dart';
import 'package:meu_app/src/features/partnerships/domain/entities/partnership.dart';
import 'package:meu_app/src/features/partnerships/domain/usecases/get_partnerships.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_bloc.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_event.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_state.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/lawyer.dart';

class MockGetPartnerships extends Mock implements GetPartnerships {}

void main() {
  late PartnershipsBloc bloc;
  late MockGetPartnerships mockGetPartnerships;

  setUp(() {
    mockGetPartnerships = MockGetPartnerships();
    bloc = PartnershipsBloc(getPartnerships: mockGetPartnerships);
  });

  tearDown(() {
    bloc.close();
  });

  group('PartnershipsBloc', () {
    const testLawyer = Lawyer(
      id: 'lawyer-1',
      name: 'Dr. João Silva',
      avatarUrl: 'https://i.pravatar.cc/150?img=1',
      oab: 'SP123456',
    );

    final testPartnerships = [
      Partnership(
        id: 'partnership-1',
        title: 'Parceria Trabalhista',
        type: PartnershipType.correspondent,
        status: PartnershipStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        partner: testLawyer,
        partnerType: PartnerEntityType.lawyer,
      ),
      Partnership(
        id: 'partnership-2',
        title: 'Consultoria Tributária',
        type: PartnershipType.expertOpinion,
        status: PartnershipStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        partner: testLawyer,
        partnerType: PartnerEntityType.lawyer,
      ),
    ];

    test('initial state should be PartnershipsInitial', () {
      expect(bloc.state, equals(PartnershipsInitial()));
    });

    group('FetchPartnerships', () {
      blocTest<PartnershipsBloc, PartnershipsState>(
        'should emit [PartnershipsLoading, PartnershipsLoaded] when data is gotten successfully',
        build: () {
          when(() => mockGetPartnerships.call())
              .thenAnswer((_) async => Result.success(testPartnerships));
          return bloc;
        },
        act: (bloc) => bloc.add(FetchPartnerships()),
        expect: () => [
          PartnershipsLoading(),
          PartnershipsLoaded(testPartnerships),
        ],
        verify: (_) {
          verify(() => mockGetPartnerships.call()).called(1);
        },
      );

      blocTest<PartnershipsBloc, PartnershipsState>(
        'should emit [PartnershipsLoading, PartnershipsError] when getting data fails',
        build: () {
          when(() => mockGetPartnerships.call())
              .thenAnswer((_) async => const Result.failure(
                ServerFailure(message: 'Erro no servidor')));
          return bloc;
        },
        act: (bloc) => bloc.add(FetchPartnerships()),
        expect: () => [
          PartnershipsLoading(),
          const PartnershipsError('Erro no servidor'),
        ],
        verify: (_) {
          verify(() => mockGetPartnerships.call()).called(1);
        },
      );

      blocTest<PartnershipsBloc, PartnershipsState>(
        'should emit [PartnershipsLoading, PartnershipsError] when connection fails',
        build: () {
          when(() => mockGetPartnerships.call())
              .thenAnswer((_) async => const Result.failure(
                ConnectionFailure(message: 'Sem conexão com a internet')));
          return bloc;
        },
        act: (bloc) => bloc.add(FetchPartnerships()),
        expect: () => [
          PartnershipsLoading(),
          const PartnershipsError('Sem conexão com a internet'),
        ],
        verify: (_) {
          verify(() => mockGetPartnerships.call()).called(1);
        },
      );

      blocTest<PartnershipsBloc, PartnershipsState>(
        'should emit [PartnershipsLoading, PartnershipsLoaded] with empty list when no partnerships exist',
        build: () {
          when(() => mockGetPartnerships.call())
              .thenAnswer((_) async => const Result.success(<Partnership>[]));
          return bloc;
        },
        act: (bloc) => bloc.add(FetchPartnerships()),
        expect: () => [
          PartnershipsLoading(),
          const PartnershipsLoaded([]),
        ],
        verify: (_) {
          verify(() => mockGetPartnerships.call()).called(1);
        },
      );
    });

    group('Multiple events', () {
      blocTest<PartnershipsBloc, PartnershipsState>(
        'should handle multiple FetchPartnerships events correctly',
        build: () {
          when(() => mockGetPartnerships.call())
              .thenAnswer((_) async => Result.success(testPartnerships));
          return bloc;
        },
        act: (bloc) {
          bloc.add(FetchPartnerships());
          bloc.add(FetchPartnerships());
        },
        expect: () => [
          PartnershipsLoading(),
          PartnershipsLoaded(testPartnerships),
          PartnershipsLoading(),
          PartnershipsLoaded(testPartnerships),
        ],
        verify: (_) {
          verify(() => mockGetPartnerships.call()).called(2);
        },
      );
    });
  });
}
