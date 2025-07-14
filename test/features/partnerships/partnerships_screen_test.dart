import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:meu_app/src/features/partnerships/presentation/screens/partnerships_screen.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_bloc.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_event.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_state.dart';
import 'package:meu_app/src/core/models/partnership.dart';
import 'package:mockito/mockito.dart';

// Mock do BLoC para testes de UI
class MockPartnershipsBloc extends MockBloc<PartnershipsEvent, PartnershipsState> implements PartnershipsBloc {}

void main() {
  late MockPartnershipsBloc mockPartnershipsBloc;

  setUp(() {
    mockPartnershipsBloc = MockPartnershipsBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<PartnershipsBloc>.value(
        value: mockPartnershipsBloc,
        child: const PartnershipsScreen(),
      ),
    );
  }

  testWidgets('shows loading indicator when state is loading', (tester) async {
    when(() => mockPartnershipsBloc.state).thenReturn(const PartnershipsState.loading());

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows partnerships when state is loaded', (tester) async {
    final partnership = Partnership(
      id: '1',
      creatorId: 'c1',
      partnerId: 'p1',
      type: PartnershipType.consultoria,
      status: PartnershipStatus.pendente,
      honorarios: 'A combinar',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      partnerName: 'Parceiro Teste',
    );

    when(() => mockPartnershipsBloc.state).thenReturn(
      PartnershipsState.loaded(sent: [], received: [partnership]),
    );

    await tester.pumpWidget(createWidgetUnderTest());

    // Procura pelas abas
    expect(find.text('Propostas Enviadas (0)'), findsOneWidget);
    expect(find.text('Propostas Recebidas (1)'), findsOneWidget);

    // TODO: Adicionar teste para verificar se o card da parceria é renderizado
  });

   testWidgets('shows error message when state is error', (tester) async {
    when(() => mockPartnershipsBloc.state).thenReturn(const PartnershipsState.error('Falha ao carregar'));

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Falha ao carregar'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
} 