import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meu_app/main.dart' as app;
import 'package:meu_app/src/features/cases/presentation/widgets/case_card.dart';
import 'package:meu_app/src/features/cases/presentation/widgets/contextual_case_card.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Teste de Regressão - Experiência do Cliente', () {
    
    testWidgets('CRÍTICO: Cliente deve ver EXATAMENTE a mesma experiência de antes', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como cliente
      await _loginAsClient(tester);
      
      // TESTE 1: Lista de casos deve usar CaseCard normal
      await _navigateToCases(tester);
      
      // Verificação crítica: NÃO deve haver ContextualCaseCard para clientes
      expect(find.byType(ContextualCaseCard), findsNothing, 
        reason: 'FALHA CRÍTICA: Cliente está vendo cards contextuais - ZERO REGRESSÃO VIOLADA');
      
      // Deve haver pelo menos um CaseCard normal
      expect(find.byType(CaseCard), findsAtLeastNWidgets(1),
        reason: 'FALHA CRÍTICA: Cliente não está vendo CaseCard normal');
      
      // TESTE 2: Detalhes do caso devem ter seções originais
      await tester.tap(find.byType(CaseCard).first);
      await tester.pumpAndSettle();
      
      // Verificar TODAS as seções originais do cliente estão presentes
      final expectedClientSections = [
        'Advogado Responsável',
        'Informações da Consulta', 
        'Pré-Análise',
        'Próximos Passos',
        'Documentos',
        'Status do Processo',
      ];
      
      for (final section in expectedClientSections) {
        expect(find.text(section), findsOneWidget,
          reason: 'FALHA CRÍTICA: Seção "$section" não encontrada - experiência do cliente alterada');
      }
      
      // TESTE 3: NÃO deve haver seções contextuais de advogados
      final forbiddenLawyerSections = [
        'Escalação e Suporte',
        'Análise Competitiva', 
        'Controle de Qualidade',
        'Próximas Oportunidades',
        'Equipe Interna',
        'Informações da Atribuição',
        'Breakdown de Tarefas',
        'Documentos de Trabalho',
        'Controle de Tempo',
        'Contato do Cliente',
        'Oportunidade de Negócio',
        'Complexidade do Caso',
        'Explicação do Match',
        'Documentos Estratégicos',
        'Análise de Rentabilidade',
        'Oportunidade na Plataforma',
        'Framework de Entrega',
        'Documentos da Plataforma',
      ];
      
      for (final section in forbiddenLawyerSections) {
        expect(find.text(section), findsNothing,
          reason: 'FALHA CRÍTICA: Seção de advogado "$section" encontrada na experiência do cliente');
      }
      
      // TESTE 4: Badges contextuais NÃO devem aparecer para clientes
      final forbiddenBadges = [
        'Escritório',
        'Negócio', 
        'Plataforma',
        'Delegado por',
        'Match direto',
        'Caso captado via parceria',
      ];
      
      for (final badge in forbiddenBadges) {
        expect(find.textContaining(badge), findsNothing,
          reason: 'FALHA CRÍTICA: Badge contextual "$badge" encontrado na experiência do cliente');
      }
    });

    testWidgets('Navegação do cliente deve permanecer inalterada', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como cliente
      await _loginAsClient(tester);
      
      // Verificar tabs de navegação do cliente
      final expectedClientTabs = [
        'Início',
        'Meus Casos', 
        'Advogados',
        'Mensagens',
        'Serviços',
        'Perfil',
      ];
      
      for (final tab in expectedClientTabs) {
        expect(find.text(tab), findsOneWidget,
          reason: 'FALHA: Tab "$tab" não encontrada na navegação do cliente');
      }
      
      // Verificar que não há tabs de advogados
      final forbiddenLawyerTabs = [
        'Painel',
        'Agenda',
        'Ofertas',
        'Parceiros',
        'Parcerias',
      ];
      
      for (final tab in forbiddenLawyerTabs) {
        expect(find.text(tab), findsNothing,
          reason: 'FALHA: Tab de advogado "$tab" encontrada na navegação do cliente');
      }
    });

    testWidgets('Performance do cliente deve ser mantida', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como cliente
      await _loginAsClient(tester);
      
      // Medir tempo de carregamento da lista de casos
      final stopwatch = Stopwatch()..start();
      await _navigateToCases(tester);
      stopwatch.stop();
      
      // Verificar que não houve degradação de performance
      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
        reason: 'FALHA: Carregamento da lista de casos demorou mais que 3s para cliente');
      
      // Medir tempo de carregamento de detalhes do caso
      stopwatch.reset();
      stopwatch.start();
      await tester.tap(find.byType(CaseCard).first);
      await tester.pumpAndSettle();
      stopwatch.stop();
      
      // Verificar que detalhes carregam rapidamente
      expect(stopwatch.elapsedMilliseconds, lessThan(2000),
        reason: 'FALHA: Carregamento de detalhes do caso demorou mais que 2s para cliente');
    });

    testWidgets('Funcionalidades existentes do cliente devem funcionar', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como cliente
      await _loginAsClient(tester);
      await _navigateToCases(tester);
      
      // Testar ação "Ver Detalhes" 
      await tester.tap(find.text('Ver Detalhes'));
      await tester.pumpAndSettle();
      
      // Verificar que navegou para detalhes
      expect(find.text('Advogado Responsável'), findsOneWidget);
      
      // Voltar
      await tester.pageBack();
      await tester.pumpAndSettle();
      
      // Testar botão "Criar Novo Caso"
      await tester.tap(find.text('Criar Novo Caso'));
      await tester.pumpAndSettle();
      
      // Verificar navegação para triagem (ou tela correspondente)
      // TODO: Ajustar baseado na rota real implementada
    });

    testWidgets('Estados de erro do cliente devem ser preservados', (WidgetTester tester) async {
      // Inicializar app com erro simulado
      await _initializeAppWithError();
      await tester.pumpAndSettle();

      // Simular login como cliente
      await _loginAsClient(tester);
      await _navigateToCases(tester);
      
      // Verificar que tela de erro padrão é exibida
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Tentar Novamente'), findsOneWidget);
      
      // Testar botão de retry
      await tester.tap(find.text('Tentar Novamente'));
      await tester.pumpAndSettle();
      
      // Verificar que tentou carregar novamente
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Componentes visuais do cliente devem ser idênticos', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como cliente
      await _loginAsClient(tester);
      await _navigateToCases(tester);
      
      // Verificar elementos visuais do CaseCard
      final caseCard = find.byType(CaseCard).first;
      expect(caseCard, findsOneWidget);
      
      // Verificar estrutura interna do CaseCard
      await tester.tap(caseCard);
      await tester.pumpAndSettle();
      
      // Verificar que usa os mesmos widgets base
      expect(find.byType(Card), findsWidgets);
      expect(find.byType(ListTile), findsWidgets);
      expect(find.byType(Text), findsWidgets);
      expect(find.byType(Icon), findsWidgets);
      
      // Verificar que não há elementos contextuais novos
      expect(find.byType(Chip), findsNothing, // Badges contextuais
        reason: 'FALHA: Elementos contextuais encontrados na UI do cliente');
    });

    testWidgets('Dados exibidos para cliente devem ser os mesmos', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como cliente
      await _loginAsClient(tester);
      await _navigateToCases(tester);
      await tester.tap(find.byType(CaseCard).first);
      await tester.pumpAndSettle();
      
      // Verificar que dados apresentados são os esperados para cliente
      expect(find.textContaining('Status:'), findsWidgets);
      expect(find.textContaining('Advogado:'), findsWidgets);
      expect(find.textContaining('Data:'), findsWidgets);
      
      // Verificar que NÃO há dados contextuais de advogados
      expect(find.textContaining('Delegado por:'), findsNothing);
      expect(find.textContaining('Horas Orçadas:'), findsNothing);
      expect(find.textContaining('Match Score:'), findsNothing);
      expect(find.textContaining('Complexidade:'), findsNothing);
    });
  });
}

// Funções auxiliares específicas para teste de regressão

Future<void> _loginAsClient(WidgetTester tester) async {
  // Implementar login específico como cliente 
  // Garantir que role = 'client' ou equivalente
  // TODO: Implementar baseado na estrutura atual de auth
}

Future<void> _navigateToCases(WidgetTester tester) async {
  // Navegar especificamente para casos do cliente
  await tester.tap(find.text('Meus Casos'));
  await tester.pumpAndSettle();
}

Future<void> _initializeAppWithError() async {
  // Simular cenário de erro para testar tratamento de erro do cliente
  // TODO: Implementar simulação de erro de rede/API
}

/// Teste comparativo com snapshot
/// Este teste garante que a UI do cliente seja EXATAMENTE a mesma
testWidgets('SNAPSHOT: UI do cliente deve ser pixel-perfect idêntica', (WidgetTester tester) async {
  // TODO: Implementar teste de snapshot quando disponível
  // await expectGoldenMatches(find.byType(CaseCard), 'client_case_card.png');
  // await expectGoldenMatches(find.byType(CaseDetailScreen), 'client_case_detail.png');
});


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Teste de Regressão - Experiência do Cliente', () {
    
    testWidgets('CRÍTICO: Cliente deve ver EXATAMENTE a mesma experiência de antes', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como cliente
      await _loginAsClient(tester);
      
      // TESTE 1: Lista de casos deve usar CaseCard normal
      await _navigateToCases(tester);
      
      // Verificação crítica: NÃO deve haver ContextualCaseCard para clientes
      expect(find.byType(ContextualCaseCard), findsNothing, 
        reason: 'FALHA CRÍTICA: Cliente está vendo cards contextuais - ZERO REGRESSÃO VIOLADA');
      
      // Deve haver pelo menos um CaseCard normal
      expect(find.byType(CaseCard), findsAtLeastNWidgets(1),
        reason: 'FALHA CRÍTICA: Cliente não está vendo CaseCard normal');
      
      // TESTE 2: Detalhes do caso devem ter seções originais
      await tester.tap(find.byType(CaseCard).first);
      await tester.pumpAndSettle();
      
      // Verificar TODAS as seções originais do cliente estão presentes
      final expectedClientSections = [
        'Advogado Responsável',
        'Informações da Consulta', 
        'Pré-Análise',
        'Próximos Passos',
        'Documentos',
        'Status do Processo',
      ];
      
      for (final section in expectedClientSections) {
        expect(find.text(section), findsOneWidget,
          reason: 'FALHA CRÍTICA: Seção "$section" não encontrada - experiência do cliente alterada');
      }
      
      // TESTE 3: NÃO deve haver seções contextuais de advogados
      final forbiddenLawyerSections = [
        'Escalação e Suporte',
        'Análise Competitiva', 
        'Controle de Qualidade',
        'Próximas Oportunidades',
        'Equipe Interna',
        'Informações da Atribuição',
        'Breakdown de Tarefas',
        'Documentos de Trabalho',
        'Controle de Tempo',
        'Contato do Cliente',
        'Oportunidade de Negócio',
        'Complexidade do Caso',
        'Explicação do Match',
        'Documentos Estratégicos',
        'Análise de Rentabilidade',
        'Oportunidade na Plataforma',
        'Framework de Entrega',
        'Documentos da Plataforma',
      ];
      
      for (final section in forbiddenLawyerSections) {
        expect(find.text(section), findsNothing,
          reason: 'FALHA CRÍTICA: Seção de advogado "$section" encontrada na experiência do cliente');
      }
      
      // TESTE 4: Badges contextuais NÃO devem aparecer para clientes
      final forbiddenBadges = [
        'Escritório',
        'Negócio', 
        'Plataforma',
        'Delegado por',
        'Match direto',
        'Caso captado via parceria',
      ];
      
      for (final badge in forbiddenBadges) {
        expect(find.textContaining(badge), findsNothing,
          reason: 'FALHA CRÍTICA: Badge contextual "$badge" encontrado na experiência do cliente');
      }
    });

    testWidgets('Navegação do cliente deve permanecer inalterada', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como cliente
      await _loginAsClient(tester);
      
      // Verificar tabs de navegação do cliente
      final expectedClientTabs = [
        'Início',
        'Meus Casos', 
        'Advogados',
        'Mensagens',
        'Serviços',
        'Perfil',
      ];
      
      for (final tab in expectedClientTabs) {
        expect(find.text(tab), findsOneWidget,
          reason: 'FALHA: Tab "$tab" não encontrada na navegação do cliente');
      }
      
      // Verificar que não há tabs de advogados
      final forbiddenLawyerTabs = [
        'Painel',
        'Agenda',
        'Ofertas',
        'Parceiros',
        'Parcerias',
      ];
      
      for (final tab in forbiddenLawyerTabs) {
        expect(find.text(tab), findsNothing,
          reason: 'FALHA: Tab de advogado "$tab" encontrada na navegação do cliente');
      }
    });

    testWidgets('Performance do cliente deve ser mantida', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como cliente
      await _loginAsClient(tester);
      
      // Medir tempo de carregamento da lista de casos
      final stopwatch = Stopwatch()..start();
      await _navigateToCases(tester);
      stopwatch.stop();
      
      // Verificar que não houve degradação de performance
      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
        reason: 'FALHA: Carregamento da lista de casos demorou mais que 3s para cliente');
      
      // Medir tempo de carregamento de detalhes do caso
      stopwatch.reset();
      stopwatch.start();
      await tester.tap(find.byType(CaseCard).first);
      await tester.pumpAndSettle();
      stopwatch.stop();
      
      // Verificar que detalhes carregam rapidamente
      expect(stopwatch.elapsedMilliseconds, lessThan(2000),
        reason: 'FALHA: Carregamento de detalhes do caso demorou mais que 2s para cliente');
    });

    testWidgets('Funcionalidades existentes do cliente devem funcionar', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como cliente
      await _loginAsClient(tester);
      await _navigateToCases(tester);
      
      // Testar ação "Ver Detalhes" 
      await tester.tap(find.text('Ver Detalhes'));
      await tester.pumpAndSettle();
      
      // Verificar que navegou para detalhes
      expect(find.text('Advogado Responsável'), findsOneWidget);
      
      // Voltar
      await tester.pageBack();
      await tester.pumpAndSettle();
      
      // Testar botão "Criar Novo Caso"
      await tester.tap(find.text('Criar Novo Caso'));
      await tester.pumpAndSettle();
      
      // Verificar navegação para triagem (ou tela correspondente)
      // TODO: Ajustar baseado na rota real implementada
    });

    testWidgets('Estados de erro do cliente devem ser preservados', (WidgetTester tester) async {
      // Inicializar app com erro simulado
      await _initializeAppWithError();
      await tester.pumpAndSettle();

      // Simular login como cliente
      await _loginAsClient(tester);
      await _navigateToCases(tester);
      
      // Verificar que tela de erro padrão é exibida
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Tentar Novamente'), findsOneWidget);
      
      // Testar botão de retry
      await tester.tap(find.text('Tentar Novamente'));
      await tester.pumpAndSettle();
      
      // Verificar que tentou carregar novamente
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Componentes visuais do cliente devem ser idênticos', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como cliente
      await _loginAsClient(tester);
      await _navigateToCases(tester);
      
      // Verificar elementos visuais do CaseCard
      final caseCard = find.byType(CaseCard).first;
      expect(caseCard, findsOneWidget);
      
      // Verificar estrutura interna do CaseCard
      await tester.tap(caseCard);
      await tester.pumpAndSettle();
      
      // Verificar que usa os mesmos widgets base
      expect(find.byType(Card), findsWidgets);
      expect(find.byType(ListTile), findsWidgets);
      expect(find.byType(Text), findsWidgets);
      expect(find.byType(Icon), findsWidgets);
      
      // Verificar que não há elementos contextuais novos
      expect(find.byType(Chip), findsNothing, // Badges contextuais
        reason: 'FALHA: Elementos contextuais encontrados na UI do cliente');
    });

    testWidgets('Dados exibidos para cliente devem ser os mesmos', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como cliente
      await _loginAsClient(tester);
      await _navigateToCases(tester);
      await tester.tap(find.byType(CaseCard).first);
      await tester.pumpAndSettle();
      
      // Verificar que dados apresentados são os esperados para cliente
      expect(find.textContaining('Status:'), findsWidgets);
      expect(find.textContaining('Advogado:'), findsWidgets);
      expect(find.textContaining('Data:'), findsWidgets);
      
      // Verificar que NÃO há dados contextuais de advogados
      expect(find.textContaining('Delegado por:'), findsNothing);
      expect(find.textContaining('Horas Orçadas:'), findsNothing);
      expect(find.textContaining('Match Score:'), findsNothing);
      expect(find.textContaining('Complexidade:'), findsNothing);
    });
  });
}

// Funções auxiliares específicas para teste de regressão

Future<void> _loginAsClient(WidgetTester tester) async {
  // Implementar login específico como cliente 
  // Garantir que role = 'client' ou equivalente
  // TODO: Implementar baseado na estrutura atual de auth
}

Future<void> _navigateToCases(WidgetTester tester) async {
  // Navegar especificamente para casos do cliente
  await tester.tap(find.text('Meus Casos'));
  await tester.pumpAndSettle();
}

Future<void> _initializeAppWithError() async {
  // Simular cenário de erro para testar tratamento de erro do cliente
  // TODO: Implementar simulação de erro de rede/API
}

/// Teste comparativo com snapshot
/// Este teste garante que a UI do cliente seja EXATAMENTE a mesma
testWidgets('SNAPSHOT: UI do cliente deve ser pixel-perfect idêntica', (WidgetTester tester) async {
  // TODO: Implementar teste de snapshot quando disponível
  // await expectGoldenMatches(find.byType(CaseCard), 'client_case_card.png');
  // await expectGoldenMatches(find.byType(CaseDetailScreen), 'client_case_detail.png');
});

/// Documentação de critérios de aceitação
/// 
/// Este teste DEVE FALHAR se:
/// 1. Cliente vir qualquer ContextualCaseCard
/// 2. Cliente vir qualquer seção de advogado  
/// 3. Cliente vir qualquer badge contextual
/// 4. Navegação do cliente for alterada
/// 5. Performance do cliente for degradada
/// 6. Funcionalidades existentes pararem de funcionar
/// 7. Estados de erro mudarem
/// 8. Elementos visuais forem alterados
/// 9. Dados exibidos mudarem de formato
/// 
/// ZERO REGRESSÃO = Experiência EXATAMENTE igual a antes 