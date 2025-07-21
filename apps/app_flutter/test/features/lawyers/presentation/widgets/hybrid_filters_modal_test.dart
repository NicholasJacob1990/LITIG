import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:meu_app/src/features/lawyers/presentation/bloc/hybrid_match_bloc.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/hybrid_filters_modal.dart';

// Mock do BLoC usando bloc_test
class MockHybridMatchBloc extends MockBloc<HybridMatchEvent, HybridMatchState> 
  implements HybridMatchBloc {}

void main() {
  late MockHybridMatchBloc mockHybridMatchBloc;

  setUp(() {
    mockHybridMatchBloc = MockHybridMatchBloc();
    // Emite um estado inicial válido
    whenListen(
      mockHybridMatchBloc,
      Stream.fromIterable([HybridMatchInitial()]),
      initialState: HybridMatchInitial(),
    );
  });

  group('HybridFiltersModal Responsiveness Test', () {
    
    Future<void> pumpModal(WidgetTester tester, Size size) async {
      await tester.pumpWidget(
        BlocProvider<HybridMatchBloc>.value(
          value: mockHybridMatchBloc,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const HybridFiltersModal(),
                    ),
                    child: const Text('Abrir Filtro'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Filtro'));
      await tester.pumpAndSettle();
    }

    testWidgets('should not overflow on a small phone screen', (tester) async {
      // iPhone SE (1st gen)
      const size = Size(320, 568);
      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await pumpModal(tester, size);

      expect(tester.takeException(), isNull);
    });

    testWidgets('should not overflow on a standard phone screen', (tester) async {
      // iPhone 13
      const size = Size(390, 844);
      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 3.0;
      
      await pumpModal(tester, size);

      expect(tester.takeException(), isNull);
    });

    testWidgets('should not overflow on a large phone screen', (tester) async {
      // iPhone 13 Pro Max
      const size = Size(428, 926);
      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 3.0;

      await pumpModal(tester, size);

      expect(tester.takeException(), isNull);
    });

    testWidgets('should not overflow on a small tablet screen', (tester) async {
      // iPad Mini
      const size = Size(768, 1024);
      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 2.0;

      await pumpModal(tester, size);

      expect(tester.takeException(), isNull);
    });
  });
} 
 