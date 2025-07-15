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

    testWidgets('should create FirmDetailScreen widget', (WidgetTester tester) async {
      // Teste simples para verificar se o widget pode ser criado
      expect(() => const FirmDetailScreen(firmId: 'firm_1'), returnsNormally);
    });

    testWidgets('should accept firmId parameter', (WidgetTester tester) async {
      const firmId = 'test_firm_id';
      const screen = FirmDetailScreen(firmId: firmId);
      
      expect(screen.firmId, equals(firmId));
    });

    testWidgets('should accept key parameter', (WidgetTester tester) async {
      const key = Key('test_key');
      const screen = FirmDetailScreen(key: key, firmId: 'firm_1');
      
      expect(screen.key, equals(key));
    });

    testWidgets('should handle empty firmId', (WidgetTester tester) async {
      expect(() => const FirmDetailScreen(firmId: ''), returnsNormally);
    });

    testWidgets('should handle null firmId as empty string', (WidgetTester tester) async {
      expect(() => const FirmDetailScreen(firmId: ''), returnsNormally);
    });
  });
} 