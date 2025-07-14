import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_bloc.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_event.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_state.dart';
import 'package:meu_app/src/features/partnerships/data/partnership_service.dart';
import 'package:meu_app/src/core/models/partnership.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';

import 'partnerships_bloc_test.mocks.dart';

@GenerateMocks([PartnershipService, Dio])
void main() {
  late MockPartnershipService mockPartnershipService;
  late PartnershipsBloc partnershipsBloc;

  setUp(() {
    mockPartnershipService = MockPartnershipService();
    partnershipsBloc = PartnershipsBloc(mockPartnershipService);
  });

  tearDown(() {
    partnershipsBloc.close();
  });

  group('PartnershipsBloc', () {
    final tPartnership = Partnership(
      id: '1',
      creatorId: 'c1',
      partnerId: 'p1',
      type: PartnershipType.consultoria,
      status: PartnershipStatus.pendente,
      honorarios: 'A combinar',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    blocTest<PartnershipsBloc, PartnershipsState>(
      'emits [loading, loaded] when fetch succeeds.',
      build: () {
        when(mockPartnershipService.fetchMyPartnerships()).thenAnswer(
          (_) async => {'sent': [tPartnership], 'received': []},
        );
        return partnershipsBloc;
      },
      act: (bloc) => bloc.add(const PartnershipsEvent.fetch()),
      expect: () => [
        const PartnershipsState.loading(),
        PartnershipsState.loaded(sent: [tPartnership], received: []),
      ],
      verify: (_) {
        verify(mockPartnershipService.fetchMyPartnerships());
      },
    );

    blocTest<PartnershipsBloc, PartnershipsState>(
      'emits [loading, error] when fetch fails.',
      build: () {
        when(mockPartnershipService.fetchMyPartnerships())
            .thenThrow(Exception('Falha na API'));
        return partnershipsBloc;
      },
      act: (bloc) => bloc.add(const PartnershipsEvent.fetch()),
      expect: () => [
        const PartnershipsState.loading(),
        const PartnershipsState.error('Exception: Falha na API'),
      ],
    );
  });
} 