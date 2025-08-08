import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meu_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Partnership Flow E2E Tests', () {
    testWidgets('Lawyer searches and partners with law firm', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Login como advogado de captação
      await _loginAsLawyer(tester);

      // Navegar para busca de parcerias
      await _navigateToPartnershipSearch(tester);

      // Buscar escritórios
      await _searchLawFirms(tester);

      // Selecionar escritório
      await _selectLawFirm(tester);

      // Enviar proposta de parceria
      await _sendPartnershipProposal(tester);

      // Verificar proposta enviada
      await _verifyProposalSent(tester);
    });

    testWidgets('Lawyer views partnership dashboard', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _loginAsLawyer(tester);
      
      // Navegar para dashboard de parcerias
      await _navigateToPartnershipDashboard(tester);

      // Verificar parcerias ativas
      await _verifyActivePartnerships(tester);

      // Verificar propostas enviadas
      await _verifyProposalsSent(tester);

      // Verificar propostas recebidas
      await _verifyProposalsReceived(tester);
    });

    testWidgets('Associate lawyer views firm information', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login como advogado associado
      await _loginAsAssociateLawyer(tester);

      // Navegar para dashboard
      await _navigateToDashboard(tester);

      // Verificar informações do escritório
      await _verifyFirmInformation(tester);

      // Navegar para perfil
      await _navigateToProfile(tester);

      // Verificar vínculo com escritório no perfil
      await _verifyFirmLinkInProfile(tester);
    });
  });
}

// HELPER FUNCTIONS

Future<void> _loginAsLawyer(WidgetTester tester) async {
  // Simular login de advogado de captação
  await tester.enterText(find.byType(TextFormField).first, 'advogado@test.com');
  await tester.enterText(find.byType(TextFormField).last, 'password123');
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
}

Future<void> _loginAsAssociateLawyer(WidgetTester tester) async {
  // Simular login de advogado associado
  await tester.enterText(find.byType(TextFormField).first, 'associado@test.com');
  await tester.enterText(find.byType(TextFormField).last, 'password123');
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
}

Future<void> _navigateToPartnershipSearch(WidgetTester tester) async {
  // Navegar para busca de parcerias
  await tester.tap(find.text('Parcerias'));
  await tester.pumpAndSettle();
  
  // Aba removida: "Buscar Parcerias". Usar a aba "Busca por IA".
  await tester.tap(find.text('Busca por IA'));
  await tester.pumpAndSettle();
}

Future<void> _searchLawFirms(WidgetTester tester) async {
  // Verificar se há escritórios na lista
  expect(find.textContaining('Escritório'), findsWidgets);
  
  // Usar filtros se disponíveis
  if (find.byIcon(Icons.filter_list).evaluate().isNotEmpty) {
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    
    // Aplicar filtro por especialidade
    await tester.tap(find.text('Direito Empresarial'));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
  }
}

Future<void> _selectLawFirm(WidgetTester tester) async {
  // Selecionar primeiro escritório da lista
  await tester.tap(find.textContaining('Escritório').first);
  await tester.pumpAndSettle();
  
  // Verificar se está na tela de detalhes
  expect(find.text('Detalhes do Escritório'), findsOneWidget);
}

Future<void> _sendPartnershipProposal(WidgetTester tester) async {
  // Enviar proposta de parceria
  await tester.tap(find.text('Propor Parceria'));
  await tester.pumpAndSettle();
  
  // Preencher mensagem da proposta
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Mensagem'),
    'Gostaria de estabelecer uma parceria estratégica',
  );
  
  // Enviar proposta
  await tester.tap(find.text('Enviar Proposta'));
  await tester.pumpAndSettle();
}

Future<void> _verifyProposalSent(WidgetTester tester) async {
  // Verificar mensagem de sucesso
  expect(find.text('Proposta enviada com sucesso'), findsOneWidget);
}

Future<void> _navigateToPartnershipDashboard(WidgetTester tester) async {
  // Navegar para dashboard de parcerias
  await tester.tap(find.text('Parcerias'));
  await tester.pumpAndSettle();
}

Future<void> _verifyActivePartnerships(WidgetTester tester) async {
  // Verificar aba de parcerias ativas
  await tester.tap(find.text('Ativas'));
  await tester.pumpAndSettle();
  
  // Verificar se há parcerias ativas listadas
  expect(find.textContaining('Parceria com'), findsWidgets);
}

Future<void> _verifyProposalsSent(WidgetTester tester) async {
  // Verificar aba de propostas enviadas
  await tester.tap(find.text('Enviadas'));
  await tester.pumpAndSettle();
  
  // Verificar se há propostas enviadas
  expect(find.textContaining('Proposta para'), findsWidgets);
}

Future<void> _verifyProposalsReceived(WidgetTester tester) async {
  // Verificar aba de propostas recebidas
  await tester.tap(find.text('Recebidas'));
  await tester.pumpAndSettle();
  
  // Verificar se há propostas recebidas
  expect(find.textContaining('Proposta de'), findsWidgets);
}

Future<void> _navigateToDashboard(WidgetTester tester) async {
  // Navegar para dashboard
  await tester.tap(find.text('Dashboard'));
  await tester.pumpAndSettle();
}

Future<void> _verifyFirmInformation(WidgetTester tester) async {
  // Verificar se há seção de escritório no dashboard
  expect(find.text('Meu Escritório'), findsOneWidget);
  expect(find.textContaining('advogados'), findsOneWidget);
  expect(find.textContaining('Taxa de Sucesso'), findsOneWidget);
}

Future<void> _navigateToProfile(WidgetTester tester) async {
  // Navegar para perfil
  await tester.tap(find.text('Perfil'));
  await tester.pumpAndSettle();
}

Future<void> _verifyFirmLinkInProfile(WidgetTester tester) async {
  // Verificar seção de escritório no perfil
  expect(find.text('Escritório'), findsOneWidget);
  expect(find.textContaining('Função:'), findsOneWidget);
  expect(find.textContaining('Equipe:'), findsOneWidget);
} 