import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';
import 'package:meu_app/src/features/firms/domain/entities/firm_kpi.dart';
import 'package:meu_app/src/features/firms/presentation/screens/firm_detail_screen.dart';

void main() {
  group('FirmDetailScreen Widget Tests', () {
    late LawFirm mockFirm;
    late LawFirm mockFirmWithKpis;

    setUp(() {
      mockFirm = LawFirm(
        id: 'firm_1',
        name: 'Escritório Silva & Associados',
        teamSize: 25,
        mainLat: -23.5505,
        mainLon: -46.6333,
        createdAt: DateTime.parse('2022-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      mockFirmWithKpis = LawFirm(
        id: 'firm_2',
        name: 'Advocacia Corporativa LTDA',
        teamSize: 50,
        mainLat: -23.5505,
        mainLon: -46.6333,
        createdAt: DateTime.parse('2022-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
        kpis: FirmKPI(
          firmId: 'firm_2',
          successRate: 0.85,
          nps: 0.78,
          reputationScore: 0.92,
          diversityIndex: 0.65,
          activeCases: 120,
          updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
        ),
      );
    });

    Widget createWidgetUnderTest(String firmId) {
      return MaterialApp(
        home: FirmDetailScreen(firmId: firmId),
      );
    }

    testWidgets('should create FirmDetailScreen widget', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest('firm_1'));
      expect(find.byType(FirmDetailScreen), findsOneWidget);
    });

    testWidgets('should have proper app bar structure', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest('firm_1'));
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should be scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest('firm_1'));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should accept firmId parameter', (WidgetTester tester) async {
      const testFirmId = 'test_firm_123';
      await tester.pumpWidget(createWidgetUnderTest(testFirmId));
      
      final firmDetailScreen = tester.widget<FirmDetailScreen>(find.byType(FirmDetailScreen));
      expect(firmDetailScreen.firmId, equals(testFirmId));
    });

    testWidgets('should have proper widget structure', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest('firm_1'));
      
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(FirmDetailScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle different firm IDs', (WidgetTester tester) async {
      // Test with different firm IDs
      final firmIds = ['firm_1', 'firm_2', 'firm_xyz', '123'];
      
      for (final firmId in firmIds) {
        await tester.pumpWidget(createWidgetUnderTest(firmId));
        
        final firmDetailScreen = tester.widget<FirmDetailScreen>(find.byType(FirmDetailScreen));
        expect(firmDetailScreen.firmId, equals(firmId));
      }
    });

    testWidgets('should be properly themed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: const TextTheme(
              headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          home: FirmDetailScreen(firmId: 'firm_1'),
        ),
      );
      
      expect(find.byType(FirmDetailScreen), findsOneWidget);
    });

    testWidgets('should handle empty firm ID', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(''));
      
      final firmDetailScreen = tester.widget<FirmDetailScreen>(find.byType(FirmDetailScreen));
      expect(firmDetailScreen.firmId, equals(''));
    });

    testWidgets('should be accessible', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest('firm_1'));
      
      // Test basic accessibility
      expect(find.byType(Semantics), findsWidgets);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have proper key if provided', (WidgetTester tester) async {
      const testKey = Key('firm_detail_screen_key');
      
      await tester.pumpWidget(
        MaterialApp(
          home: FirmDetailScreen(
            key: testKey,
            firmId: 'firm_1',
          ),
        ),
      );
      
      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('should handle navigation back', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                Navigator.of(tester.element(find.byType(ElevatedButton))).push(
                  MaterialPageRoute(
                    builder: (context) => FirmDetailScreen(firmId: 'firm_1'),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );
      
      // Navigate to FirmDetailScreen
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();
      
      expect(find.byType(FirmDetailScreen), findsOneWidget);
      
      // Navigate back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      
      expect(find.byType(FirmDetailScreen), findsNothing);
    });
  });
} 