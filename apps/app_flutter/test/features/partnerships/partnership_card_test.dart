import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/lawyer.dart';
import 'package:meu_app/src/features/partnerships/domain/entities/partnership.dart';
import 'package:meu_app/src/features/partnerships/presentation/widgets/partnership_card.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() {
  setUpAll(() {
    // Initialize timeago locales for testing
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
    timeago.setDefaultLocale('pt_BR');
  });

  const testLawyer = Lawyer(
    id: 'lawyer-1',
    name: 'Dr. Teste da Silva',
    avatarUrl: 'https://i.pravatar.cc/150?img=4',
    oab: 'SP123456',
  );

  final testPartnership = Partnership(
    id: 'partner-1',
    title: 'Caso de Teste Complexo',
    type: PartnershipType.caseSharing,
    status: PartnershipStatus.active,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    partner: testLawyer,
    partnerType: PartnerEntityType.lawyer,
  );

  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  testWidgets('PartnershipCard should display partner name and title', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createTestableWidget(PartnershipCard(partnership: testPartnership)));

    // Act
    final partnerNameFinder = find.text('Dr. Teste da Silva');
    final titleFinder = find.text('Caso de Teste Complexo');
    final statusFinder = find.text('Ativa');

    // Assert
    expect(partnerNameFinder, findsOneWidget);
    expect(titleFinder, findsOneWidget);
    expect(statusFinder, findsOneWidget);
  });
} 