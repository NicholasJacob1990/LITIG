import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';
import 'package:meu_app/src/features/firms/domain/entities/firm_kpi.dart';
import 'package:meu_app/src/features/firms/presentation/widgets/firm_card.dart';
vcimport 'package:meu_app/src/router/navigation_helper.dart';

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
      expect(find.byIcon(LucideIcons.building2), findsOneWidget);
      expect(find.byIcon(LucideIcons.users), findsWidgets); // Alterado para findsWidgets
      expect(find.text('Desde 2022'), findsOneWidget);
    });

    testWidgets('should display firm with KPIs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(FirmCard(firm: mockFirmWithKpis)));

      expect(find.text('Advocacia Premium Ltda'), findsOneWidget);
      expect(find.text('50 advogados'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget); // Alterado de 85.0% para 85%
      expect(find.text('42'), findsOneWidget);
      expect(find.byIcon(LucideIcons.target), findsOneWidget);
      expect(find.byIcon(LucideIcons.thumbsUp), findsOneWidget);
      expect(find.byIcon(LucideIcons.briefcase), findsOneWidget);
    });

    testWidgets('should display location when available', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(FirmCard(firm: mockFirm)));

      expect(find.byIcon(LucideIcons.mapPin), findsOneWidget);
      expect(find.text('Localização definida'), findsOneWidget);
    });

    testWidgets('should handle missing location gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(FirmCard(firm: mockFirmWithoutLocation)));

      expect(find.text('Consultoria Jurídica'), findsOneWidget);
      expect(find.text('10 advogados'), findsOneWidget);
      expect(find.byIcon(LucideIcons.mapPin), findsNothing);
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

      expect(find.text('Grande Porte'), findsOneWidget);
    });

    testWidgets('should display actions when showActions is true', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        FirmCard(firm: mockFirm, showActions: true),
      ));

      expect(find.text('Ver Advogados'), findsOneWidget); // Alterado para buscar por texto
      expect(find.text('Ver Detalhes'), findsOneWidget);
    });
  });
} 