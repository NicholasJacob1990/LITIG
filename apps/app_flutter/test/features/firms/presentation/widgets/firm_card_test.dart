import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';
import 'package:meu_app/src/features/firms/domain/entities/firm_kpi.dart';
import 'package:meu_app/src/features/firms/presentation/widgets/firm_card.dart';

void main() {
  group('FirmCard Widget Tests', () {
    late LawFirm mockFirm;
    late LawFirm mockFirmWithKpis;
    late LawFirm mockFirmWithoutLocation;

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
        name: 'Advocacia Premium Ltda',
        teamSize: 50,
        mainLat: -23.5505,
        mainLon: -46.6333,
        createdAt: DateTime.parse('2020-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
        kpis: FirmKPI(
          firmId: 'firm_2',
          successRate: 0.85,
          nps: 0.72,
          reputationScore: 0.90,
          diversityIndex: 0.65,
          activeCases: 42,
          updatedAt: DateTime.now(),
        ),
      );

      mockFirmWithoutLocation = LawFirm(
        id: 'firm_3',
        name: 'Consultoria Jurídica',
        teamSize: 10,
        createdAt: DateTime.parse('2023-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('should display firm basic information', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(FirmCard(firm: mockFirm)));

      expect(find.text('Escritório Silva & Associados'), findsOneWidget);
      expect(find.text('25 advogados'), findsOneWidget);
      expect(find.byIcon(Icons.business), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
    });

    testWidgets('should display firm with KPIs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(FirmCard(firm: mockFirmWithKpis)));

      expect(find.text('Advocacia Premium Ltda'), findsOneWidget);
      expect(find.text('50 advogados'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.star), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.folder), findsAtLeastNWidgets(1));
    });

    testWidgets('should display location when available', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(FirmCard(firm: mockFirm)));

      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.textContaining('Lat:'), findsOneWidget);
    });

    testWidgets('should handle missing location gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(FirmCard(firm: mockFirmWithoutLocation)));

      expect(find.text('Consultoria Jurídica'), findsOneWidget);
      expect(find.text('10 advogados'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsNothing);
    });

    testWidgets('should handle tap callbacks', (WidgetTester tester) async {
      bool onTapCalled = false;
      await tester.pumpWidget(createTestWidget(
        FirmCard(
          firm: mockFirm,
          onTap: () => onTapCalled = true,
        ),
      ));

      await tester.tap(find.byType(Card)); // Alterado para byType(Card)
      await tester.pump();
      expect(onTapCalled, isTrue);
    });

    testWidgets('should display large firm indicator for firms with 50+ lawyers', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(FirmCard(firm: mockFirmWithKpis)));

      expect(find.text('Advocacia Premium Ltda'), findsOneWidget);
      expect(find.text('50 advogados'), findsOneWidget);
    });

    testWidgets('should display firm card in compact mode', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        FirmCard(firm: mockFirm, isCompact: true),
      ));

      expect(find.text('Escritório Silva & Associados'), findsOneWidget);
      expect(find.text('25 advogados'), findsOneWidget);
    });
  });
} 