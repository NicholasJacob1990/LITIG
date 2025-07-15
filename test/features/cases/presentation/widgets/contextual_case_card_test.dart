import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/src/features/cases/presentation/widgets/contextual_case_card.dart';
import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/features/cases/domain/entities/contextual_case_data.dart';
import 'package:meu_app/src/features/cases/domain/entities/allocation_type.dart';
import 'package:meu_app/src/features/auth/domain/entities/user.dart';

void main() {
  group('ContextualCaseCard Widget Tests', () {
    late Case mockCase;
    late ContextualCaseData mockContextualData;
    late List<ContextualKPI> mockKPIs;
    late ContextualActions mockActions;
    late ContextualHighlight mockHighlight;
    late User mockUser;

    setUp(() {
      mockCase = Case(
        id: 'test_case_123',
        title: 'Caso de Teste',
        description: 'Descrição do caso de teste',
        status: 'Em Andamento',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'user_123',
        lawyer: null,
      );

      mockContextualData = ContextualCaseData(
        allocationType: AllocationType.platformMatchDirect,
        partnerId: null,
        delegatedBy: null,
        matchScore: 0.95,
        responseDeadline: DateTime.now().add(const Duration(hours: 24)),
        contextMetadata: {'source': 'algorithm', 'priority': 'high'},
      );

      mockKPIs = [
        ContextualKPI(
          id: 'conversion_rate',
          label: 'Taxa de Conversão',
          value: '85%',
          trend: 'up',
          description: 'Matches aceitos vs oferecidos',
        ),
        ContextualKPI(
          id: 'response_time',
          label: 'Tempo de Resposta',
          value: '2h',
          trend: 'stable',
          description: 'Tempo médio de resposta',
        ),
      ];

      mockActions = ContextualActions(
        primary: [
          ContextualAction(id: 'accept', label: 'Aceitar Caso', icon: 'check'),
          ContextualAction(id: 'negotiate', label: 'Negociar', icon: 'chat'),
        ],
        secondary: [
          ContextualAction(id: 'delegate', label: 'Delegar', icon: 'person_add'),
          ContextualAction(id: 'reject', label: 'Rejeitar', icon: 'close'),
        ],
      );

      mockHighlight = ContextualHighlight(
        text: 'Match Direto - Algoritmo IA',
        color: 'blue',
        priority: 'high',
      );

      mockUser = User(
        id: 'user_123',
        name: 'Usuário Teste',
        email: 'teste@exemplo.com',
        role: 'lawyer',
        profilePictureUrl: null,
      );
    });

    Widget createWidgetUnderTest({
      Function(String)? onActionTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ContextualCaseCard(
            caseData: mockCase,
            contextualData: mockContextualData,
            kpis: mockKPIs,
            actions: mockActions,
            highlight: mockHighlight,
            currentUser: mockUser,
            onActionTap: onActionTap,
          ),
        ),
      );
    }

    testWidgets('renders contextual case card with basic information', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verificar se o card é renderizado
      expect(find.byType(Card), findsOneWidget);
      
      // Verificar se o highlight é exibido
      expect(find.text('Match Direto - Algoritmo IA'), findsOneWidget);
      
      // Verificar se o título do caso é exibido
      expect(find.text('Caso de Teste'), findsOneWidget);
    });

    testWidgets('displays all KPIs correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verificar se os KPIs são exibidos
      expect(find.text('Taxa de Conversão'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Tempo de Resposta'), findsOneWidget);
      expect(find.text('2h'), findsOneWidget);
    });

    testWidgets('displays primary and secondary actions', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verificar se as ações primárias são exibidas
      expect(find.text('Aceitar Caso'), findsOneWidget);
      expect(find.text('Negociar'), findsOneWidget);
      
      // Verificar se as ações secundárias são exibidas
      expect(find.text('Delegar'), findsOneWidget);
      expect(find.text('Rejeitar'), findsOneWidget);
    });

    testWidgets('calls onActionTap when action button is pressed', (tester) async {
      String? tappedAction;
      
      await tester.pumpWidget(createWidgetUnderTest(
        onActionTap: (action) => tappedAction = action,
      ));

      // Encontrar e tocar no botão de ação
      final acceptButton = find.text('Aceitar Caso');
      expect(acceptButton, findsOneWidget);
      
      await tester.tap(acceptButton);
      await tester.pump();

      // Verificar se o callback foi chamado
      expect(tappedAction, equals('accept'));
    });

    testWidgets('displays different content for different allocation types', (tester) async {
      // Testar com tipo de alocação diferente
      final partnershipContextualData = ContextualCaseData(
        allocationType: AllocationType.platformMatchPartnership,
        partnerId: 'partner_123',
        delegatedBy: null,
        matchScore: null,
        responseDeadline: DateTime.now().add(const Duration(hours: 48)),
        contextMetadata: {'source': 'partnership', 'priority': 'medium'},
      );

      final partnershipHighlight = ContextualHighlight(
        text: 'Via Parceria - Colaboração',
        color: 'green',
        priority: 'medium',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ContextualCaseCard(
            caseData: mockCase,
            contextualData: partnershipContextualData,
            kpis: mockKPIs,
            actions: mockActions,
            highlight: partnershipHighlight,
            currentUser: mockUser,
          ),
        ),
      ));

      // Verificar se o highlight específico para parceria é exibido
      expect(find.text('Via Parceria - Colaboração'), findsOneWidget);
    });

    testWidgets('handles empty KPIs list gracefully', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ContextualCaseCard(
            caseData: mockCase,
            contextualData: mockContextualData,
            kpis: [], // Lista vazia
            actions: mockActions,
            highlight: mockHighlight,
            currentUser: mockUser,
          ),
        ),
      ));

      // Verificar se o card ainda é renderizado mesmo sem KPIs
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Caso de Teste'), findsOneWidget);
    });

    testWidgets('handles empty actions gracefully', (tester) async {
      final emptyActions = ContextualActions(
        primary: [],
        secondary: [],
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ContextualCaseCard(
            caseData: mockCase,
            contextualData: mockContextualData,
            kpis: mockKPIs,
            actions: emptyActions,
            highlight: mockHighlight,
            currentUser: mockUser,
          ),
        ),
      ));

      // Verificar se o card ainda é renderizado mesmo sem ações
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Caso de Teste'), findsOneWidget);
    });

    testWidgets('displays contextual information correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verificar se informações contextuais são exibidas
      expect(find.text('Match Direto - Algoritmo IA'), findsOneWidget);
      
      // Verificar se o card tem a aparência correta
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('respects material design guidelines', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verificar se o card tem margin e padding apropriados
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      
      final Card card = tester.widget(cardFinder);
      expect(card.margin, equals(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)));
    });

    testWidgets('supports accessibility features', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verificar se elementos têm semântica apropriada
      expect(find.byType(Card), findsOneWidget);
      
      // Verificar se textos são legíveis
      expect(find.text('Taxa de Conversão'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
    });
  });
} 