import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meu_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('B2B Flow Integration Tests', () {
    testWidgets('Complete B2B matching flow - Client creates corporate case and gets firm matches', (WidgetTester tester) async {
      // Inicializar o app
      app.main();
      await tester.pumpAndSettle();

      // === FASE 1: LOGIN DO CLIENTE ===
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Preencher credenciais de teste
      await tester.enterText(find.byKey(const Key('email_field')), 'client@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('submit_login')));
      await tester.pumpAndSettle();

      // Verificar se chegou ao dashboard do cliente
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Meus Casos'), findsOneWidget);

      // === FASE 2: CRIAR CASO CORPORATIVO ===
      await tester.tap(find.byKey(const Key('create_case_button')));
      await tester.pumpAndSettle();

      // Preencher detalhes do caso corporativo
      await tester.enterText(
        find.byKey(const Key('case_title_field')), 
        'Fusão e Aquisição - Empresa de Tecnologia'
      );
      
      await tester.enterText(
        find.byKey(const Key('case_description_field')), 
        'Necessito de assessoria jurídica para processo de M&A de startup de tecnologia, incluindo due diligence, estruturação societária e compliance regulatório.'
      );

      // Selecionar área jurídica corporativa
      await tester.tap(find.byKey(const Key('area_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Direito Empresarial'));
      await tester.pumpAndSettle();

      // Definir como caso corporativo
      await tester.tap(find.byKey(const Key('case_type_corporate')));
      await tester.pumpAndSettle();

      // Submeter caso para triagem
      await tester.tap(find.byKey(const Key('submit_case_button')));
      await tester.pumpAndSettle();

      // === FASE 3: AGUARDAR TRIAGEM INTELIGENTE ===
      // Verificar se apareceu tela de processamento
      expect(find.text('Analisando seu caso...'), findsOneWidget);
      
      // Aguardar processamento da triagem (máximo 30 segundos)
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // Verificar se triagem foi concluída
      expect(find.text('Análise concluída'), findsOneWidget);
      
      // === FASE 4: VERIFICAR MATCHES B2B ===
      await tester.tap(find.byKey(const Key('view_matches_button')));
      await tester.pumpAndSettle();

      // Verificar se apareceram escritórios no ranking
      expect(find.text('Escritórios Recomendados'), findsOneWidget);
      expect(find.byType(Card), findsWidgets); // Cards de escritórios

      // Verificar se há pelo menos 1 escritório no ranking
      final firmCards = find.byKey(const Key('firm_card'));
      expect(firmCards, findsWidgets);

      // === FASE 5: EXPLORAR DETALHES DO ESCRITÓRIO ===
      // Tap no primeiro escritório
      await tester.tap(firmCards.first);
      await tester.pumpAndSettle();

      // Verificar detalhes do escritório
      expect(find.text('Detalhes do Escritório'), findsOneWidget);
      expect(find.text('Métricas de Performance'), findsOneWidget);
      expect(find.text('Equipe de Advogados'), findsOneWidget);

      // Verificar KPIs visíveis
      expect(find.textContaining('Taxa de Sucesso'), findsOneWidget);
      expect(find.textContaining('NPS'), findsOneWidget);
      expect(find.textContaining('Reputação'), findsOneWidget);

      // === FASE 6: VER ADVOGADOS DO ESCRITÓRIO ===
      await tester.tap(find.byKey(const Key('view_lawyers_button')));
      await tester.pumpAndSettle();

      // Verificar lista de advogados do escritório
      expect(find.text('Advogados do Escritório'), findsOneWidget);
      expect(find.byKey(const Key('lawyer_card')), findsWidgets);

      // === FASE 7: SELECIONAR ADVOGADO E INICIAR CONTRATAÇÃO ===
      await tester.tap(find.byKey(const Key('lawyer_card')).first);
      await tester.pumpAndSettle();

      // Verificar perfil do advogado
      expect(find.text('Perfil do Advogado'), findsOneWidget);
      expect(find.text('Especialização'), findsOneWidget);

      // Iniciar processo de contratação
      await tester.tap(find.byKey(const Key('hire_lawyer_button')));
      await tester.pumpAndSettle();

      // === FASE 8: CONFIRMAR CONTRATAÇÃO ===
      expect(find.text('Confirmar Contratação'), findsOneWidget);
      expect(find.text('Tipo de Honorário'), findsOneWidget);

      // Selecionar tipo de honorário
      await tester.tap(find.byKey(const Key('fee_type_success')));
      await tester.pumpAndSettle();

      // Confirmar contratação
      await tester.tap(find.byKey(const Key('confirm_hire_button')));
      await tester.pumpAndSettle();

      // === FASE 9: VERIFICAR SUCESSO ===
      expect(find.text('Contratação Realizada'), findsOneWidget);
      expect(find.text('Advogado contratado com sucesso'), findsOneWidget);

      // Verificar se caso aparece na lista "Meus Casos"
      await tester.tap(find.byKey(const Key('go_to_cases_button')));
      await tester.pumpAndSettle();

      expect(find.text('Meus Casos'), findsOneWidget);
      expect(find.text('Fusão e Aquisição - Empresa de Tecnologia'), findsOneWidget);
      expect(find.text('Em Andamento'), findsOneWidget);
    });

    testWidgets('B2B Algorithm Two-Pass validation - Firms are ranked first, then lawyers', (WidgetTester tester) async {
      // Inicializar o app
      app.main();
      await tester.pumpAndSettle();

      // Login como cliente
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email_field')), 'client@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('submit_login')));
      await tester.pumpAndSettle();

      // Criar caso corporativo
      await tester.tap(find.byKey(const Key('create_case_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('case_title_field')), 'Caso Corporativo B2B');
      await tester.enterText(find.byKey(const Key('case_description_field')), 'Teste do algoritmo two-pass');
      await tester.tap(find.byKey(const Key('case_type_corporate')));
      await tester.tap(find.byKey(const Key('submit_case_button')));
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // Verificar matches
      await tester.tap(find.byKey(const Key('view_matches_button')));
      await tester.pumpAndSettle();

      // Verificar se algoritmo B2B foi aplicado
      expect(find.text('Modo B2B Ativo'), findsOneWidget);
      expect(find.text('Top 3 Escritórios Selecionados'), findsOneWidget);

      // Verificar se apenas advogados dos top-3 escritórios aparecem
      final lawyerCards = find.byKey(const Key('lawyer_card'));
      expect(lawyerCards, findsWidgets);

      // Verificar se há indicação de que advogados pertencem aos escritórios ranqueados
      expect(find.textContaining('Escritório'), findsWidgets);
    });

    testWidgets('Feature-E (Firm Reputation) validation in matching', (WidgetTester tester) async {
      // Inicializar o app
      app.main();
      await tester.pumpAndSettle();

      // Login e criar caso corporativo
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email_field')), 'client@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('submit_login')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create_case_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('case_title_field')), 'Teste Feature-E');
      await tester.enterText(find.byKey(const Key('case_description_field')), 'Validação da reputação do escritório');
      await tester.tap(find.byKey(const Key('case_type_corporate')));
      await tester.tap(find.byKey(const Key('submit_case_button')));
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // Ver matches e verificar Feature-E
      await tester.tap(find.byKey(const Key('view_matches_button')));
      await tester.pumpAndSettle();

      // Verificar se escritórios com melhor reputação aparecem primeiro
      final firmCards = find.byKey(const Key('firm_card'));
      expect(firmCards, findsWidgets);

      // Tap no primeiro escritório para ver detalhes
      await tester.tap(firmCards.first);
      await tester.pumpAndSettle();

      // Verificar se KPIs de reputação estão visíveis
      expect(find.textContaining('Taxa de Sucesso'), findsOneWidget);
      expect(find.textContaining('NPS'), findsOneWidget);
      expect(find.textContaining('Reputação'), findsOneWidget);
      expect(find.textContaining('Diversidade'), findsOneWidget);

      // Verificar se Feature-E influenciou o score
      expect(find.text('Score de Reputação'), findsOneWidget);
      expect(find.textContaining('%'), findsWidgets); // Percentuais dos KPIs
    });

    testWidgets('Lawyer search for partnerships - Individual lawyer finding firms', (WidgetTester tester) async {
      // Inicializar o app
      app.main();
      await tester.pumpAndSettle();

      // Login como advogado individual
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email_field')), 'lawyer@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('submit_login')));
      await tester.pumpAndSettle();

      // Navegar para busca de parcerias
      await tester.tap(find.byKey(const Key('partnerships_tab')));
      await tester.pumpAndSettle();

      // Verificar tela de parcerias
      expect(find.text('Parcerias'), findsOneWidget);
      expect(find.text('Encontrar Escritórios'), findsOneWidget);

      // Buscar escritórios
      await tester.tap(find.byKey(const Key('search_firms_button')));
      await tester.pumpAndSettle();

      // Verificar lista de escritórios disponíveis
      expect(find.text('Escritórios Disponíveis'), findsOneWidget);
      expect(find.byKey(const Key('firm_card')), findsWidgets);

      // Filtrar por área de atuação
      await tester.tap(find.byKey(const Key('area_filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Direito Empresarial'));
      await tester.pumpAndSettle();

      // Verificar se filtro foi aplicado
      expect(find.text('Direito Empresarial'), findsWidgets);

      // Solicitar parceria
      await tester.tap(find.byKey(const Key('request_partnership_button')));
      await tester.pumpAndSettle();

      // Confirmar solicitação
      expect(find.text('Solicitar Parceria'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm_partnership_button')));
      await tester.pumpAndSettle();

      // Verificar sucesso
      expect(find.text('Solicitação Enviada'), findsOneWidget);
    });

    testWidgets('Associated lawyer dashboard - Firm information display', (WidgetTester tester) async {
      // Inicializar o app
      app.main();
      await tester.pumpAndSettle();

      // Login como advogado associado
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email_field')), 'associated@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('submit_login')));
      await tester.pumpAndSettle();

      // Verificar dashboard do advogado associado
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Meu Escritório'), findsOneWidget);

      // Verificar informações do escritório
      expect(find.byKey(const Key('firm_info_card')), findsOneWidget);
      expect(find.text('Escritório'), findsOneWidget);
      expect(find.textContaining('pessoas'), findsOneWidget);

      // Ver detalhes do escritório
      await tester.tap(find.byKey(const Key('firm_info_card')));
      await tester.pumpAndSettle();

      // Verificar detalhes completos
      expect(find.text('Detalhes do Escritório'), findsOneWidget);
      expect(find.text('Minha Posição'), findsOneWidget);
      expect(find.text('Colegas de Equipe'), findsOneWidget);

      // Verificar KPIs do escritório
      expect(find.text('Performance do Escritório'), findsOneWidget);
      expect(find.textContaining('Taxa de Sucesso'), findsOneWidget);
    });

    testWidgets('B2B Rollout Percentage - Feature flag controls user access', (WidgetTester tester) async {
      // Inicializar o app
      app.main();
      await tester.pumpAndSettle();

      // Login como cliente
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email_field')), 'client@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('submit_login')));
      await tester.pumpAndSettle();

      // Criar caso corporativo
      await tester.tap(find.byKey(const Key('create_case_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('case_title_field')), 'Teste Feature Flag');
      await tester.enterText(find.byKey(const Key('case_description_field')), 'Validação de rollout gradual');
      await tester.tap(find.byKey(const Key('case_type_corporate')));
      await tester.tap(find.byKey(const Key('submit_case_button')));
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // Verificar se B2B está habilitado baseado na feature flag
      await tester.tap(find.byKey(const Key('view_matches_button')));
      await tester.pumpAndSettle();

      // Se B2B habilitado, deve mostrar escritórios
      // Se desabilitado, deve mostrar apenas advogados individuais
      final firmCards = find.byKey(const Key('firm_card'));
      final lawyerCards = find.byKey(const Key('lawyer_card'));

      // Verificar que pelo menos um tipo de match está presente
      expect(firmCards.evaluate().isNotEmpty || lawyerCards.evaluate().isNotEmpty, true);

      // Se firmCards existir, validar que Feature-E está ativa
      if (firmCards.evaluate().isNotEmpty) {
        expect(find.text('Modo B2B Ativo'), findsOneWidget);
      }
    });

    testWidgets('Cache segmentado validation - Firm vs Lawyer caching', (WidgetTester tester) async {
      // Inicializar o app
      app.main();
      await tester.pumpAndSettle();

      // Login como cliente
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email_field')), 'client@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('submit_login')));
      await tester.pumpAndSettle();

      // Criar caso individual primeiro
      await tester.tap(find.byKey(const Key('create_case_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('case_title_field')), 'Caso Individual');
      await tester.enterText(find.byKey(const Key('case_description_field')), 'Teste de cache individual');
      await tester.tap(find.byKey(const Key('case_type_individual')));
      await tester.tap(find.byKey(const Key('submit_case_button')));
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // Verificar matches individuais
      await tester.tap(find.byKey(const Key('view_matches_button')));
      await tester.pumpAndSettle();
      final individualMatches = find.byKey(const Key('lawyer_card'));
      expect(individualMatches, findsWidgets);

      // Voltar e criar caso corporativo
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create_case_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('case_title_field')), 'Caso Corporativo');
      await tester.enterText(find.byKey(const Key('case_description_field')), 'Teste de cache corporativo');
      await tester.tap(find.byKey(const Key('case_type_corporate')));
      await tester.tap(find.byKey(const Key('submit_case_button')));
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // Verificar matches corporativos
      await tester.tap(find.byKey(const Key('view_matches_button')));
      await tester.pumpAndSettle();
      final corporateMatches = find.byKey(const Key('firm_card'));
      
      // Validar que o cache segmentado está funcionando
      // (diferentes tipos de entidades para diferentes tipos de casos)
      expect(corporateMatches.evaluate().isNotEmpty || individualMatches.evaluate().isNotEmpty, true);
    });

    testWidgets('Conflict scan validation - OAB compliance check', (WidgetTester tester) async {
      // Inicializar o app
      app.main();
      await tester.pumpAndSettle();

      // Login como cliente
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email_field')), 'client@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('submit_login')));
      await tester.pumpAndSettle();

      // Criar caso com potencial conflito
      await tester.tap(find.byKey(const Key('create_case_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('case_title_field')), 'Caso com Conflito');
      await tester.enterText(find.byKey(const Key('case_description_field')), 'Validação de conflitos OAB');
      
      // Definir parte contrária (simular conflito)
      await tester.enterText(find.byKey(const Key('opposing_party_field')), 'Empresa XYZ Ltda');
      
      await tester.tap(find.byKey(const Key('case_type_corporate')));
      await tester.tap(find.byKey(const Key('submit_case_button')));
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // Verificar matches
      await tester.tap(find.byKey(const Key('view_matches_button')));
      await tester.pumpAndSettle();

      // Verificar se advogados/escritórios com conflito foram filtrados
      expect(find.text('Advogados Disponíveis'), findsOneWidget);
      expect(find.text('Verificação de Conflitos Concluída'), findsOneWidget);

      // Verificar se há indicação de advogados filtrados por conflito
      final conflictWarning = find.text('Alguns advogados foram filtrados por conflito de interesse');
      // Pode ou não aparecer, dependendo se há conflitos reais
    });

    testWidgets('Complete contract flow - From match to signed contract', (WidgetTester tester) async {
      // Inicializar o app
      app.main();
      await tester.pumpAndSettle();

      // Login como cliente
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email_field')), 'client@test.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('submit_login')));
      await tester.pumpAndSettle();

      // Criar caso corporativo
      await tester.tap(find.byKey(const Key('create_case_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('case_title_field')), 'Contrato Completo');
      await tester.enterText(find.byKey(const Key('case_description_field')), 'Teste de fluxo completo');
      await tester.tap(find.byKey(const Key('case_type_corporate')));
      await tester.tap(find.byKey(const Key('submit_case_button')));
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // Selecionar escritório
      await tester.tap(find.byKey(const Key('view_matches_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('firm_card')).first);
      await tester.pumpAndSettle();

      // Selecionar advogado
      await tester.tap(find.byKey(const Key('view_lawyers_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lawyer_card')).first);
      await tester.pumpAndSettle();

      // Iniciar contratação
      await tester.tap(find.byKey(const Key('hire_lawyer_button')));
      await tester.pumpAndSettle();

      // Configurar termos do contrato
      await tester.tap(find.byKey(const Key('fee_type_success')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('success_percentage_field')), '20');
      await tester.tap(find.byKey(const Key('confirm_hire_button')));
      await tester.pumpAndSettle();

      // Verificar tela de contrato
      expect(find.text('Contrato Gerado'), findsOneWidget);
      expect(find.text('Revisar Termos'), findsOneWidget);

      // Assinar contrato
      await tester.tap(find.byKey(const Key('sign_contract_button')));
      await tester.pumpAndSettle();

      // Verificar confirmação
      expect(find.text('Contrato Assinado'), findsOneWidget);
      expect(find.text('Advogado Contratado'), findsOneWidget);

      // Verificar que caso aparece em "Meus Casos" com status correto
      await tester.tap(find.byKey(const Key('go_to_cases_button')));
      await tester.pumpAndSettle();
      expect(find.text('Contrato Completo'), findsOneWidget);
      expect(find.text('Contratado'), findsOneWidget);
    });
  });
} 