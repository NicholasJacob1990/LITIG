import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meu_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('B2B Integration Tests', () {
    testWidgets('Complete B2B flow: Client finds and contracts law firm', (WidgetTester tester) async {
      // Inicializar o app
      app.main();
      await tester.pumpAndSettle();

      // Aguardar carregamento inicial
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verificar se a tela de splash aparece
      expect(find.text('LITGO'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Simular login como cliente
      await _simulateClientLogin(tester);

      // Navegar para a tela de advogados/escritórios
      await _navigateToLawyersScreen(tester);

      // Buscar por escritórios
      await _searchForLawFirms(tester);

      // Selecionar um escritório
      await _selectLawFirm(tester);

      // Verificar detalhes do escritório
      await _verifyFirmDetails(tester);

      // Navegar para casos e verificar recomendação
      await _navigateToCasesAndVerifyRecommendation(tester);

      // Simular contratação do escritório
      await _simulateHiring(tester);

      // Verificar confirmação da contratação
      await _verifyHiringConfirmation(tester);
    });

    testWidgets('B2B flow: Lawyer views firm details from dashboard', (WidgetTester tester) async {
      // Inicializar o app
      app.main();
      await tester.pumpAndSettle();

      // Aguardar carregamento inicial
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Simular login como advogado associado
      await _simulateAssociateLawyerLogin(tester);

      // Verificar dashboard com informações do escritório
      await _verifyDashboardFirmInfo(tester);

      // Navegar para detalhes do escritório
      await _navigateToFirmDetailsFromDashboard(tester);

      // Verificar informações completas do escritório
      await _verifyCompleteFirmDetails(tester);

      // Navegar para lista de colegas
      await _navigateToColleaguesList(tester);

      // Verificar lista de advogados do escritório
      await _verifyFirmLawyers(tester);
    });

    testWidgets('B2B flow: Partnership creation and management', (WidgetTester tester) async {
      // Inicializar o app
      app.main();
      await tester.pumpAndSettle();

      // Aguardar carregamento inicial
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Simular login como advogado de captação
      await _simulateCaptationLawyerLogin(tester);

      // Navegar para busca de parceiros
      await _navigateToPartnerSearch(tester);

      // Buscar escritórios para parceria
      await _searchForPartnerFirms(tester);

      // Selecionar escritório e criar parceria
      await _createPartnership(tester);

      // Navegar para tela de parcerias
      await _navigateToPartnerships(tester);

      // Verificar parceria criada
      await _verifyPartnershipCreated(tester);

      // Simular ações de parceria (aceitar, rejeitar, etc.)
      await _simulatePartnershipActions(tester);
    });
  });
}

Future<void> _simulateClientLogin(WidgetTester tester) async {
  // Procurar por campos de login
  await tester.pumpAndSettle();
  
  if (find.text('Login').evaluate().isNotEmpty) {
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
  }

  // Simular entrada de credenciais
  final emailField = find.byType(TextFormField).first;
  final passwordField = find.byType(TextFormField).last;

  if (emailField.evaluate().isNotEmpty && passwordField.evaluate().isNotEmpty) {
    await tester.enterText(emailField, 'cliente@test.com');
    await tester.enterText(passwordField, 'password123');
    await tester.pumpAndSettle();

    // Tentar fazer login
    final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
    if (loginButton.evaluate().isNotEmpty) {
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }
  }
}

Future<void> _simulateAssociateLawyerLogin(WidgetTester tester) async {
  await tester.pumpAndSettle();
  
  if (find.text('Login').evaluate().isNotEmpty) {
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
  }

  // Simular entrada de credenciais de advogado associado
  final emailField = find.byType(TextFormField).first;
  final passwordField = find.byType(TextFormField).last;

  if (emailField.evaluate().isNotEmpty && passwordField.evaluate().isNotEmpty) {
    await tester.enterText(emailField, 'advogado.associado@test.com');
    await tester.enterText(passwordField, 'password123');
    await tester.pumpAndSettle();

    final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
    if (loginButton.evaluate().isNotEmpty) {
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }
  }
}

Future<void> _simulateCaptationLawyerLogin(WidgetTester tester) async {
  await tester.pumpAndSettle();
  
  if (find.text('Login').evaluate().isNotEmpty) {
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
  }

  // Simular entrada de credenciais de advogado de captação
  final emailField = find.byType(TextFormField).first;
  final passwordField = find.byType(TextFormField).last;

  if (emailField.evaluate().isNotEmpty && passwordField.evaluate().isNotEmpty) {
    await tester.enterText(emailField, 'advogado.captacao@test.com');
    await tester.enterText(passwordField, 'password123');
    await tester.pumpAndSettle();

    final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
    if (loginButton.evaluate().isNotEmpty) {
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }
  }
}

Future<void> _navigateToLawyersScreen(WidgetTester tester) async {
  // Procurar pela aba de advogados na navegação inferior
  final lawyersTab = find.text('Advogados');
  if (lawyersTab.evaluate().isNotEmpty) {
    await tester.tap(lawyersTab);
    await tester.pumpAndSettle();
  }

  // Verificar se chegou na tela de advogados
  expect(find.text('Advogados'), findsAtLeastNWidgets(1));
}

Future<void> _searchForLawFirms(WidgetTester tester) async {
  // Procurar por campo de busca
  final searchField = find.byType(TextField);
  if (searchField.evaluate().isNotEmpty) {
    await tester.enterText(searchField.first, 'escritório');
    await tester.pumpAndSettle();
  }

  // Aguardar resultados de busca
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Verificar se há resultados (escritórios ou advogados)
  expect(find.byType(Card), findsAtLeastNWidgets(1));
}

Future<void> _selectLawFirm(WidgetTester tester) async {
  // Procurar por um card de escritório
  final firmCard = find.byType(Card).first;
  if (firmCard.evaluate().isNotEmpty) {
    await tester.tap(firmCard);
    await tester.pumpAndSettle();
  }
}

Future<void> _verifyFirmDetails(WidgetTester tester) async {
  // Verificar se está na tela de detalhes do escritório
  expect(find.byType(AppBar), findsOneWidget);
  expect(find.byType(Scaffold), findsOneWidget);
  
  // Verificar elementos típicos de uma tela de detalhes
  expect(find.byIcon(Icons.business), findsAtLeastNWidgets(1));
}

Future<void> _navigateToCasesAndVerifyRecommendation(WidgetTester tester) async {
  // Navegar para a aba de casos
  final casesTab = find.text('Meus Casos');
  if (casesTab.evaluate().isNotEmpty) {
    await tester.tap(casesTab);
    await tester.pumpAndSettle();
  }

  // Verificar se há recomendações de escritórios nos casos
  await tester.pumpAndSettle(const Duration(seconds: 2));
  
  // Procurar por indicações de escritórios recomendados
  expect(find.byType(Card), findsAtLeastNWidgets(1));
}

Future<void> _simulateHiring(WidgetTester tester) async {
  // Procurar por botão de contratação
  final hireButton = find.widgetWithText(ElevatedButton, 'Contratar');
  if (hireButton.evaluate().isNotEmpty) {
    await tester.tap(hireButton);
    await tester.pumpAndSettle();
  }

  // Simular confirmação de contratação
  final confirmButton = find.widgetWithText(ElevatedButton, 'Confirmar');
  if (confirmButton.evaluate().isNotEmpty) {
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
  }
}

Future<void> _verifyHiringConfirmation(WidgetTester tester) async {
  // Verificar mensagem de confirmação
  expect(find.textContaining('sucesso'), findsAtLeastNWidgets(1));
}

Future<void> _verifyDashboardFirmInfo(WidgetTester tester) async {
  // Verificar se há informações do escritório no dashboard
  expect(find.text('Meu Escritório'), findsAtLeastNWidgets(1));
  expect(find.byIcon(Icons.business), findsAtLeastNWidgets(1));
}

Future<void> _navigateToFirmDetailsFromDashboard(WidgetTester tester) async {
  // Procurar por botão de ver detalhes do escritório
  final detailsButton = find.widgetWithText(OutlinedButton, 'Ver Detalhes');
  if (detailsButton.evaluate().isNotEmpty) {
    await tester.tap(detailsButton);
    await tester.pumpAndSettle();
  }
}

Future<void> _verifyCompleteFirmDetails(WidgetTester tester) async {
  // Verificar informações completas do escritório
  expect(find.byType(AppBar), findsOneWidget);
  expect(find.byType(TabBar), findsAtLeastNWidgets(1));
}

Future<void> _navigateToColleaguesList(WidgetTester tester) async {
  // Navegar para a aba de advogados
  final lawyersTab = find.text('Advogados');
  if (lawyersTab.evaluate().isNotEmpty) {
    await tester.tap(lawyersTab);
    await tester.pumpAndSettle();
  }
}

Future<void> _verifyFirmLawyers(WidgetTester tester) async {
  // Verificar lista de advogados do escritório
  expect(find.byType(ListView), findsAtLeastNWidgets(1));
}

Future<void> _navigateToPartnerSearch(WidgetTester tester) async {
  // Navegar para busca de parceiros
  final partnersTab = find.text('Parceiros');
  if (partnersTab.evaluate().isNotEmpty) {
    await tester.tap(partnersTab);
    await tester.pumpAndSettle();
  }
}

Future<void> _searchForPartnerFirms(WidgetTester tester) async {
  // Buscar por escritórios para parceria
  final searchField = find.byType(TextField);
  if (searchField.evaluate().isNotEmpty) {
    await tester.enterText(searchField.first, 'parceria');
    await tester.pumpAndSettle();
  }
}

Future<void> _createPartnership(WidgetTester tester) async {
  // Selecionar escritório e criar parceria
  final firmCard = find.byType(Card).first;
  if (firmCard.evaluate().isNotEmpty) {
    await tester.tap(firmCard);
    await tester.pumpAndSettle();
  }

  // Procurar por botão de criar parceria
  final partnerButton = find.widgetWithText(ElevatedButton, 'Criar Parceria');
  if (partnerButton.evaluate().isNotEmpty) {
    await tester.tap(partnerButton);
    await tester.pumpAndSettle();
  }
}

Future<void> _navigateToPartnerships(WidgetTester tester) async {
  // Navegar para tela de parcerias
  final partnershipsTab = find.text('Parcerias');
  if (partnershipsTab.evaluate().isNotEmpty) {
    await tester.tap(partnershipsTab);
    await tester.pumpAndSettle();
  }
}

Future<void> _verifyPartnershipCreated(WidgetTester tester) async {
  // Verificar se a parceria foi criada
  expect(find.byType(Card), findsAtLeastNWidgets(1));
}

Future<void> _simulatePartnershipActions(WidgetTester tester) async {
  // Simular ações de parceria (aceitar, rejeitar, etc.)
  final actionButton = find.widgetWithText(ElevatedButton, 'Aceitar');
  if (actionButton.evaluate().isNotEmpty) {
    await tester.tap(actionButton);
    await tester.pumpAndSettle();
  }
} 