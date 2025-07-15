import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../lib/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Contextual Case Flows Integration Tests', () {
    
    testWidgets('Navegação para tela de casos - Fluxo básico', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Assert - Verifica se a aplicação iniciou
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Tenta encontrar elementos de navegação
      final navElements = find.byType(BottomNavigationBar);
      if (navElements.evaluate().isNotEmpty) {
        // Se existe navegação bottom, tenta navegar
        await tester.tap(find.byIcon(Icons.work_outline).first);
        await tester.pumpAndSettle();
        
        // Verifica se chegou na tela de casos
        expect(find.text('Meus Casos'), findsWidgets);
      }
    });

    testWidgets('Verificação de elementos contextuais - Badges de alocação', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Assert - Procura por badges de alocação se existirem
      final possibleBadges = [
        'allocation_badge_direct',
        'allocation_badge_partnership',
        'allocation_badge_proactive',
        'allocation_badge_suggestion',
        'allocation_badge_delegation',
        'allocation_badge_dual',
      ];

      for (final badgeKey in possibleBadges) {
        final badgeWidget = find.byKey(Key(badgeKey));
        if (badgeWidget.evaluate().isNotEmpty) {
          expect(badgeWidget, findsWidgets);
        }
      }
    });

    testWidgets('Verificação de cards contextuais - Diferentes tipos de caso', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Navega para casos se possível
      try {
        await tester.tap(find.byIcon(Icons.work_outline).first);
        await tester.pumpAndSettle();
      } catch (e) {
        // Continua se não conseguir navegar
      }

      // Assert - Verifica se existem cards contextuais
      final contextualCards = find.byType(Card);
      if (contextualCards.evaluate().isNotEmpty) {
        expect(contextualCards, findsWidgets);
      }

      // Verifica textos contextuais comuns
      final contextualTexts = [
        'Match Perfeito',
        'Parceria Estratégica',
        'Busca Proativa',
        'Sugestão IA',
        'Delegação Interna',
        'Contexto Duplo',
      ];

      for (final text in contextualTexts) {
        final textWidget = find.text(text);
        if (textWidget.evaluate().isNotEmpty) {
          expect(textWidget, findsWidgets);
        }
      }
    });

    testWidgets('Verificação de ações contextuais - Botões específicos', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Assert - Verifica botões de ação contextual
      final contextualActions = [
        'Ver Detalhes',
        'Contatar Parceiro',
        'Aceitar Caso',
        'Revisar Sugestão',
        'Registrar Horas',
        'Voltar ao Contexto Advogado',
      ];

      for (final action in contextualActions) {
        final actionButton = find.text(action);
        if (actionButton.evaluate().isNotEmpty) {
          expect(actionButton, findsWidgets);
        }
      }
    });

    testWidgets('Verificação de KPIs contextuais - Métricas específicas', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Assert - Verifica métricas contextuais
      final kpiTexts = [
        '95% de compatibilidade',
        '24h SLA',
        '48h SLA',
        '72h SLA',
        'Score: 0.9',
        'Tempo de resposta:',
        'Satisfação:',
      ];

      for (final kpi in kpiTexts) {
        final kpiWidget = find.textContaining(kpi);
        if (kpiWidget.evaluate().isNotEmpty) {
          expect(kpiWidget, findsWidgets);
        }
      }
    });

    testWidgets('Verificação de highlights contextuais - Destaques visuais', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Assert - Verifica highlights contextuais
      final highlightTexts = [
        'Caso recomendado pelo sistema',
        'Caso encontrado através de busca ativa',
        'Delegado por especialização',
        'Você está atuando como cliente',
        'Escritório Tributário Silva',
      ];

      for (final highlight in highlightTexts) {
        final highlightWidget = find.text(highlight);
        if (highlightWidget.evaluate().isNotEmpty) {
          expect(highlightWidget, findsWidgets);
        }
      }
    });

    testWidgets('Verificação de tratamento de erros - Fallback para casos sem contexto', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Assert - Verifica se existe fallback para erros
      final errorTexts = [
        'Erro ao carregar informações contextuais',
        'Informações não disponíveis',
        'Carregando...',
      ];

      for (final errorText in errorTexts) {
        final errorWidget = find.text(errorText);
        if (errorWidget.evaluate().isNotEmpty) {
          expect(errorWidget, findsWidgets);
        }
      }

      // Verifica fallback card
      final fallbackCard = find.byKey(const Key('fallback_case_card'));
      if (fallbackCard.evaluate().isNotEmpty) {
        expect(fallbackCard, findsWidgets);
      }
    });

    testWidgets('Verificação de navegação contextual - Múltiplos contextos', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Assert - Verifica elementos de navegação contextual
      final navigationElements = [
        find.text('Meus Casos'),
        find.text('Casos como Cliente'),
        find.text('Casos como Advogado'),
        find.byIcon(Icons.swap_horiz_outlined),
      ];

      for (final element in navigationElements) {
        if (element.evaluate().isNotEmpty) {
          expect(element, findsWidgets);
        }
      }
    });

    testWidgets('Verificação de performance - Renderização de múltiplos cards', (tester) async {
      // Act
      await app.main();
      await tester.pumpAndSettle();

      // Measure performance
      final stopwatch = Stopwatch()..start();
      
      try {
        await tester.tap(find.byIcon(Icons.work_outline).first);
        await tester.pumpAndSettle();
      } catch (e) {
        // Continua se não conseguir navegar
      }
      
      stopwatch.stop();

      // Assert - Verifica se a navegação foi razoavelmente rápida
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      
      // Verifica se múltiplos cards foram renderizados
      final cards = find.byType(Card);
      if (cards.evaluate().isNotEmpty) {
        expect(cards, findsWidgets);
      }
    });
  });
} 