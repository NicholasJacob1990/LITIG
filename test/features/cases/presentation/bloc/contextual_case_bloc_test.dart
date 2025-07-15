import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/contextual_case_bloc.dart';
import 'package:meu_app/src/features/cases/domain/entities/contextual_case_data.dart';
import 'package:meu_app/src/features/cases/domain/entities/allocation_type.dart';

void main() {
  group('ContextualCaseBloc', () {
    late ContextualCaseBloc contextualCaseBloc;

    setUp(() {
      contextualCaseBloc = ContextualCaseBloc();
    });

    tearDown(() {
      contextualCaseBloc.close();
    });

    test('initial state is ContextualCaseInitial', () {
      expect(contextualCaseBloc.state, equals(ContextualCaseInitial()));
    });

    group('FetchContextualCaseData', () {
      blocTest<ContextualCaseBloc, ContextualCaseState>(
        'emits [ContextualCaseLoading, ContextualCaseDataLoaded] when data is fetched successfully',
        build: () => contextualCaseBloc,
        act: (bloc) => bloc.add(
          const FetchContextualCaseData(
            caseId: 'test_case_123',
            userId: 'test_user_456',
          ),
        ),
        expect: () => [
          ContextualCaseLoading(),
          isA<ContextualCaseDataLoaded>(),
        ],
      );

      blocTest<ContextualCaseBloc, ContextualCaseState>(
        'emitted ContextualCaseDataLoaded contains expected data structure',
        build: () => contextualCaseBloc,
        act: (bloc) => bloc.add(
          const FetchContextualCaseData(
            caseId: 'test_case_123',
            userId: 'test_user_456',
          ),
        ),
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<ContextualCaseDataLoaded>());
          
          final loadedState = state as ContextualCaseDataLoaded;
          expect(loadedState.contextualData.allocationType, equals(AllocationType.platformMatchDirect));
          expect(loadedState.kpis, isNotEmpty);
          expect(loadedState.actions.primary, isNotEmpty);
          expect(loadedState.highlight.text, equals('Match Direto - Algoritmo IA'));
        },
      );
    });

    group('FetchContextualKPIs', () {
      blocTest<ContextualCaseBloc, ContextualCaseState>(
        'emits [ContextualCaseLoading, ContextualKPIsLoaded] when KPIs are fetched successfully',
        build: () => contextualCaseBloc,
        act: (bloc) => bloc.add(
          const FetchContextualKPIs(
            caseId: 'test_case_123',
            userId: 'test_user_456',
          ),
        ),
        expect: () => [
          ContextualCaseLoading(),
          isA<ContextualKPIsLoaded>(),
        ],
      );

      blocTest<ContextualCaseBloc, ContextualCaseState>(
        'emitted ContextualKPIsLoaded contains expected KPI data',
        build: () => contextualCaseBloc,
        act: (bloc) => bloc.add(
          const FetchContextualKPIs(
            caseId: 'test_case_123',
            userId: 'test_user_456',
          ),
        ),
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<ContextualKPIsLoaded>());
          
          final loadedState = state as ContextualKPIsLoaded;
          expect(loadedState.caseId, equals('test_case_123'));
          expect(loadedState.kpis, isNotEmpty);
          expect(loadedState.kpis.first.id, equals('success_rate'));
          expect(loadedState.kpis.first.value, equals('92%'));
        },
      );
    });

    group('FetchContextualActions', () {
      blocTest<ContextualCaseBloc, ContextualCaseState>(
        'emits [ContextualCaseLoading, ContextualActionsLoaded] when actions are fetched successfully',
        build: () => contextualCaseBloc,
        act: (bloc) => bloc.add(
          const FetchContextualActions(
            caseId: 'test_case_123',
            userId: 'test_user_456',
          ),
        ),
        expect: () => [
          ContextualCaseLoading(),
          isA<ContextualActionsLoaded>(),
        ],
      );

      blocTest<ContextualCaseBloc, ContextualCaseState>(
        'emitted ContextualActionsLoaded contains expected action data',
        build: () => contextualCaseBloc,
        act: (bloc) => bloc.add(
          const FetchContextualActions(
            caseId: 'test_case_123',
            userId: 'test_user_456',
          ),
        ),
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<ContextualActionsLoaded>());
          
          final loadedState = state as ContextualActionsLoaded;
          expect(loadedState.caseId, equals('test_case_123'));
          expect(loadedState.actions.primary, isNotEmpty);
          expect(loadedState.actions.primary.first.id, equals('view_details'));
          expect(loadedState.actions.primary.first.label, equals('Ver Detalhes'));
        },
      );
    });

    group('SetAllocationTypeEvent', () {
      blocTest<ContextualCaseBloc, ContextualCaseState>(
        'emits [ContextualCaseLoading, AllocationTypeSet] when allocation type is set successfully',
        build: () => contextualCaseBloc,
        act: (bloc) => bloc.add(
          const SetAllocationTypeEvent(
            caseId: 'test_case_123',
            allocationType: AllocationType.platformMatchPartnership,
            metadata: {'test': 'data'},
          ),
        ),
        expect: () => [
          ContextualCaseLoading(),
          isA<AllocationTypeSet>(),
        ],
      );

      blocTest<ContextualCaseBloc, ContextualCaseState>(
        'emitted AllocationTypeSet contains expected data',
        build: () => contextualCaseBloc,
        act: (bloc) => bloc.add(
          const SetAllocationTypeEvent(
            caseId: 'test_case_123',
            allocationType: AllocationType.platformMatchPartnership,
            metadata: {'test': 'data'},
          ),
        ),
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<AllocationTypeSet>());
          
          final setStateData = state as AllocationTypeSet;
          expect(setStateData.caseId, equals('test_case_123'));
          expect(setStateData.allocationType, equals(AllocationType.platformMatchPartnership));
          expect(setStateData.message, equals('Tipo de alocação definido com sucesso'));
        },
      );
    });

    group('FetchCasesByAllocation', () {
      blocTest<ContextualCaseBloc, ContextualCaseState>(
        'emits [ContextualCaseLoading, CasesByAllocationLoaded] when cases by allocation are fetched successfully',
        build: () => contextualCaseBloc,
        act: (bloc) => bloc.add(
          const FetchCasesByAllocation(userId: 'test_user_456'),
        ),
        expect: () => [
          ContextualCaseLoading(),
          isA<CasesByAllocationLoaded>(),
        ],
      );

      blocTest<ContextualCaseBloc, ContextualCaseState>(
        'emitted CasesByAllocationLoaded contains all allocation types',
        build: () => contextualCaseBloc,
        act: (bloc) => bloc.add(
          const FetchCasesByAllocation(userId: 'test_user_456'),
        ),
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<CasesByAllocationLoaded>());
          
          final loadedState = state as CasesByAllocationLoaded;
          expect(loadedState.casesByAllocation.keys, contains(AllocationType.platformMatchDirect));
          expect(loadedState.casesByAllocation.keys, contains(AllocationType.platformMatchPartnership));
          expect(loadedState.casesByAllocation.keys, contains(AllocationType.partnershipProactiveSearch));
          expect(loadedState.casesByAllocation.keys, contains(AllocationType.partnershipPlatformSuggestion));
          expect(loadedState.casesByAllocation.keys, contains(AllocationType.internalDelegation));
        },
      );
    });

    group('ExecuteContextualAction', () {
      blocTest<ContextualCaseBloc, ContextualCaseState>(
        'emits [ContextualCaseLoading, ContextualActionExecuted] when action is executed successfully',
        build: () => contextualCaseBloc,
        act: (bloc) => bloc.add(
          const ExecuteContextualAction(
            caseId: 'test_case_123',
            actionId: 'accept',
            parameters: {'timestamp': '2025-01-31T10:00:00Z'},
          ),
        ),
        expect: () => [
          ContextualCaseLoading(),
          isA<ContextualActionExecuted>(),
        ],
      );

      blocTest<ContextualCaseBloc, ContextualCaseState>(
        'emitted ContextualActionExecuted contains expected execution data',
        build: () => contextualCaseBloc,
        act: (bloc) => bloc.add(
          const ExecuteContextualAction(
            caseId: 'test_case_123',
            actionId: 'accept',
            parameters: {'timestamp': '2025-01-31T10:00:00Z'},
          ),
        ),
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<ContextualActionExecuted>());
          
          final executedState = state as ContextualActionExecuted;
          expect(executedState.caseId, equals('test_case_123'));
          expect(executedState.actionId, equals('accept'));
          expect(executedState.message, equals('Ação executada com sucesso'));
          expect(executedState.result, isNotNull);
          expect(executedState.result!['status'], equals('success'));
        },
      );
    });

    group('Error Handling', () {
      // Nota: Como estamos usando mock data, não há erros reais para testar
      // Em uma implementação real com repositório, testaríamos cenários de erro
      test('bloc handles mock data without errors', () {
        expect(contextualCaseBloc.state, equals(ContextualCaseInitial()));
      });
    });

    group('State Transitions', () {
      blocTest<ContextualCaseBloc, ContextualCaseState>(
        'multiple events can be processed sequentially',
        build: () => contextualCaseBloc,
        act: (bloc) {
          bloc.add(const FetchContextualKPIs(caseId: 'case1', userId: 'user1'));
          bloc.add(const FetchContextualActions(caseId: 'case1', userId: 'user1'));
          bloc.add(const ExecuteContextualAction(caseId: 'case1', actionId: 'test'));
        },
        expect: () => [
          ContextualCaseLoading(),
          isA<ContextualKPIsLoaded>(),
          ContextualCaseLoading(),
          isA<ContextualActionsLoaded>(),
          ContextualCaseLoading(),
          isA<ContextualActionExecuted>(),
        ],
      );
    });
  });
} 