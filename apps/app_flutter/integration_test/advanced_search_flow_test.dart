import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meu_app/main.dart' as app;
import 'package:meu_app/src/features/partnerships/presentation/screens/lawyer_search_screen.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/preset_selector.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Advanced Search Flow Tests', () {
    testWidgets('Lawyer Search Screen - Preset Selection', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to lawyer search screen
      // This would need to be adjusted based on your actual navigation flow
      await tester.tap(find.text('Buscar Parceiros'));
      await tester.pumpAndSettle();

      // Verify search screen is displayed
      expect(find.byType(LawyerSearchScreen), findsOneWidget);

      // Test preset selection
      expect(find.text('Tipo de Busca:'), findsOneWidget);
      
      // Test selecting correspondent preset
      await tester.tap(find.text('Correspondente'));
      await tester.pumpAndSettle();
      
      // Verify location section appears
      expect(find.text('Localização para Correspondente'), findsOneWidget);
      expect(find.text('Usar Localização Atual'), findsOneWidget);

      // Test selecting expert preset
      await tester.tap(find.text('Especialista'));
      await tester.pumpAndSettle();
      
      // Verify location section disappears
      expect(find.text('Localização para Correspondente'), findsNothing);

      // Test search execution
      await tester.enterText(find.byType(TextField), 'Preciso de um advogado especialista em direito civil');
      await tester.tap(find.text('Buscar Especialista'));
      await tester.pumpAndSettle();

      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Client Preset Selector - Recommendation Types', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to lawyers screen (client view)
      // This would need to be adjusted based on your actual navigation flow
      await tester.tap(find.text('Advogados'));
      await tester.pumpAndSettle();

      // Verify preset selector is displayed
      expect(find.byType(PresetSelector), findsOneWidget);
      expect(find.text('Tipo de Recomendação'), findsOneWidget);

      // Test preset options
      expect(find.text('⭐ Recomendado'), findsOneWidget);
      expect(find.text('💰 Melhor Custo'), findsOneWidget);
      expect(find.text('🏆 Mais Experientes'), findsOneWidget);
      expect(find.text('⚡ Mais Rápidos'), findsOneWidget);
      expect(find.text('🏢 Escritórios'), findsOneWidget);

      // Test selecting economic preset
      await tester.tap(find.text('💰 Melhor Custo'));
      await tester.pumpAndSettle();
      
      // Verify description updates
      expect(find.text('Foco em economia e custo-benefício'), findsOneWidget);

      // Test selecting expert preset
      await tester.tap(find.text('🏆 Mais Experientes'));
      await tester.pumpAndSettle();
      
      // Verify description updates
      expect(find.text('Especialistas renomados na área'), findsOneWidget);
    });

    testWidgets('Location Services Integration', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to lawyer search screen
      await tester.tap(find.text('Buscar Parceiros'));
      await tester.pumpAndSettle();

      // Select correspondent preset
      await tester.tap(find.text('Correspondente'));
      await tester.pumpAndSettle();

      // Test location button
      expect(find.text('Usar Localização Atual'), findsOneWidget);
      
      // Note: Actual location testing would require mocking location services
      // This is a placeholder for location functionality testing
      await tester.tap(find.text('Usar Localização Atual'));
      await tester.pumpAndSettle();

      // Verify loading state or permission dialog
      // This would need to be adjusted based on permission handling
    });

    testWidgets('Search Results Display', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to lawyer search screen
      await tester.tap(find.text('Buscar Parceiros'));
      await tester.pumpAndSettle();

      // Perform search
      await tester.enterText(find.byType(TextField), 'Advogado especialista');
      await tester.tap(find.text('Buscar Parceiros'));
      await tester.pumpAndSettle();

      // Wait for search results
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify tabs are displayed
      expect(find.text('Advogados'), findsOneWidget);
      expect(find.text('Escritórios'), findsOneWidget);

      // Test tab switching
      await tester.tap(find.text('Escritórios'));
      await tester.pumpAndSettle();

      // Verify firms tab content
      // This would need to be adjusted based on actual firm display widgets
    });

    testWidgets('Error Handling', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to lawyer search screen
      await tester.tap(find.text('Buscar Parceiros'));
      await tester.pumpAndSettle();

      // Test search without text
      await tester.tap(find.text('Buscar Parceiros'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Por favor, descreva sua necessidade.'), findsOneWidget);

      // Test retry functionality
      await tester.enterText(find.byType(TextField), 'Test search');
      await tester.tap(find.text('Buscar Parceiros'));
      await tester.pumpAndSettle();

      // Simulate error state and test retry button
      // This would need to be adjusted based on actual error handling
    });

    testWidgets('Filters Integration', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to lawyer search screen
      await tester.tap(find.text('Buscar Parceiros'));
      await tester.pumpAndSettle();

      // Open filters modal
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      // Test filter options
      expect(find.text('Filtros de Busca'), findsOneWidget);
      expect(find.text('Advogados Individuais'), findsOneWidget);
      expect(find.text('Escritórios de Advocacia'), findsOneWidget);

      // Test specialty filter
      await tester.tap(find.text('Especialidade:'));
      await tester.pumpAndSettle();
      
      // Select specialty
      await tester.tap(find.text('Direito Civil'));
      await tester.pumpAndSettle();

      // Apply filters
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      // Verify filters are applied
      expect(find.text('Direito Civil'), findsOneWidget);
    });
  });
} 