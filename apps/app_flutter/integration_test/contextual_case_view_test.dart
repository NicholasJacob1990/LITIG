import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meu_app/main.dart' as app;
import 'package:meu_app/src/features/auth/domain/entities/user.dart';
import 'package:meu_app/src/features/cases/domain/entities/allocation_type.dart';
import 'package:meu_app/src/features/cases/domain/entities/contextual_case_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sistema de Visão Contextual de Casos - Testes de Integração', () {
    testWidgets('Cliente deve ver experiência original preservada', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como cliente
      await _loginAsClient(tester);
      
      // Navegar para casos
      await _navigateToCases(tester);
      
      // Verificar que cliente vê CaseCard normal (não contextual)
      expect(find.byType(CaseCard), findsAtLeastNWidgets(1));
      expect(find.byType(ContextualCaseCard), findsNothing);
      
      // Entrar em um caso específico
      await tester.tap(find.byType(CaseCard).first);
      await tester.pumpAndSettle();
      
      // Verificar seções originais do cliente
      expect(find.text('Advogado Responsável'), findsOneWidget);
      expect(find.text('Informações da Consulta'), findsOneWidget);
      expect(find.text('Pré-Análise'), findsOneWidget);
      expect(find.text('Próximos Passos'), findsOneWidget);
      expect(find.text('Documentos'), findsOneWidget);
      expect(find.text('Status do Processo'), findsOneWidget);
      
      // Não deve haver seções contextuais de advogados
      expect(find.text('Escalação e Suporte'), findsNothing);
      expect(find.text('Análise Competitiva'), findsNothing);
      expect(find.text('Controle de Qualidade'), findsNothing);
    });

    testWidgets('Advogado Associado deve ver contexto de delegação interna', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como advogado associado
      await _loginAsAssociatedLawyer(tester);
      
      // Navegar para casos
      await _navigateToCases(tester);
      
      // Verificar que advogado vê ContextualCaseCard
      expect(find.byType(ContextualCaseCard), findsAtLeastNWidgets(1));
      
      // Verificar card específico para delegação interna
      expect(find.text('👨‍💼 Delegado por'), findsWidgets);
      expect(find.text('Horas Orçadas'), findsWidgets);
      expect(find.text('Registrar Horas'), findsWidgets);
      
      // Entrar em um caso específico
      await tester.tap(find.byType(ContextualCaseCard).first);
      await tester.pumpAndSettle();
      
      // Verificar seções contextuais de advogado associado
      expect(find.text('Equipe Interna'), findsOneWidget);
      expect(find.text('Informações da Atribuição'), findsOneWidget);
      expect(find.text('Breakdown de Tarefas'), findsOneWidget);
      expect(find.text('Documentos de Trabalho'), findsOneWidget);
      expect(find.text('Controle de Tempo'), findsOneWidget);
      expect(find.text('Escalação e Suporte'), findsOneWidget);
      
      // Não deve haver seções de outros perfis
      expect(find.text('Análise Competitiva'), findsNothing);
      expect(find.text('Controle de Qualidade'), findsNothing);
    });

    testWidgets('Advogado Contratante deve ver contexto de negócio', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como advogado contratante
      await _loginAsContractingLawyer(tester);
      
      // Navegar para casos
      await _navigateToCases(tester);
      
      // Verificar que advogado vê ContextualCaseCard
      expect(find.byType(ContextualCaseCard), findsAtLeastNWidgets(1));
      
      // Entrar em um caso específico
      await tester.tap(find.byType(ContextualCaseCard).first);
      await tester.pumpAndSettle();
      
      // Verificar seções contextuais de advogado contratante
      expect(find.text('Contato do Cliente'), findsOneWidget);
      expect(find.text('Oportunidade de Negócio'), findsOneWidget);
      expect(find.text('Complexidade do Caso'), findsOneWidget);
      expect(find.text('Explicação do Match'), findsOneWidget);
      expect(find.text('Documentos Estratégicos'), findsOneWidget);
      expect(find.text('Análise de Rentabilidade'), findsOneWidget);
      expect(find.text('Análise Competitiva'), findsOneWidget);
      
      // Não deve haver seções de outros perfis
      expect(find.text('Escalação e Suporte'), findsNothing);
      expect(find.text('Controle de Qualidade'), findsNothing);
    });

    testWidgets('Super Associado deve ver contexto de plataforma', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como super associado
      await _loginAsSuperAssociate(tester);
      
      // Navegar para casos
      await _navigateToCases(tester);
      
      // Verificar card específico para plataforma
      expect(find.text('🎯 Match direto para você'), findsWidgets);
      expect(find.text('Complexidade'), findsWidgets);
      expect(find.text('Aceitar Caso'), findsWidgets);
      
      // Entrar em um caso específico
      await tester.tap(find.byType(ContextualCaseCard).first);
      await tester.pumpAndSettle();
      
      // Verificar seções contextuais de super associado
      expect(find.text('Oportunidade na Plataforma'), findsOneWidget);
      expect(find.text('Explicação do Match'), findsOneWidget);
      expect(find.text('Framework de Entrega'), findsOneWidget);
      expect(find.text('Documentos da Plataforma'), findsOneWidget);
      expect(find.text('Controle de Qualidade'), findsOneWidget);
      expect(find.text('Próximas Oportunidades'), findsOneWidget);
      
      // Não deve haver seções de outros perfis
      expect(find.text('Escalação e Suporte'), findsNothing);
      expect(find.text('Análise Competitiva'), findsNothing);
    });

    testWidgets('Factory deve retornar fallback seguro para dados ausentes', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como advogado mas sem dados contextuais
      await _loginAsLawyerWithoutContextualData(tester);
      
      // Navegar para casos
      await _navigateToCases(tester);
      
      // Entrar em um caso específico
      await tester.tap(find.byType(CaseCard).first);
      await tester.pumpAndSettle();
      
      // Deve usar fallback para experiência do cliente
      expect(find.text('Advogado Responsável'), findsOneWidget);
      expect(find.text('Informações da Consulta'), findsOneWidget);
      expect(find.text('Pré-Análise'), findsOneWidget);
      expect(find.text('Próximos Passos'), findsOneWidget);
      expect(find.text('Documentos'), findsOneWidget);
      expect(find.text('Status do Processo'), findsOneWidget);
    });

    testWidgets('Ações contextuais devem funcionar corretamente', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como advogado associado
      await _loginAsAssociatedLawyer(tester);
      
      // Navegar para casos
      await _navigateToCases(tester);
      
      // Testar ação "Registrar Horas"
      await tester.tap(find.text('Registrar Horas'));
      await tester.pumpAndSettle();
      
      // Verificar feedback
      expect(find.text('Registrando horas...'), findsOneWidget);
      
      // Testar ação "Atualizar Status"
      await tester.tap(find.text('Atualizar Status'));
      await tester.pumpAndSettle();
      
      // Verificar feedback
      expect(find.text('Status atualizado!'), findsOneWidget);
    });

    testWidgets('Loading states devem ser exibidos corretamente', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como advogado
      await _loginAsContractingLawyer(tester);
      
      // Navegar para casos
      await _navigateToCases(tester);
      
      // Entrar em um caso específico
      await tester.tap(find.byType(ContextualCaseCard).first);
      await tester.pump(); // Não esperar settle para capturar loading
      
      // Verificar loading de dados contextuais
      expect(find.text('Carregando dados contextuais...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      
      // Esperar carregamento completar
      await tester.pumpAndSettle();
      
      // Loading deve ter desaparecido
      expect(find.text('Carregando dados contextuais...'), findsNothing);
    });

    testWidgets('Sistema deve manter consistência visual entre perfis', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Testar consistência para cliente
      await _loginAsClient(tester);
      await _navigateToCases(tester);
      await tester.tap(find.byType(CaseCard).first);
      await tester.pumpAndSettle();
      
      // Verificar elementos de design consistentes
      expect(find.byType(Card), findsWidgets);
      expect(find.byType(SizedBox), findsWidgets);
      
      // Voltar e testar com advogado associado
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _logoutAndLoginAsAssociatedLawyer(tester);
      await _navigateToCases(tester);
      await tester.tap(find.byType(ContextualCaseCard).first);
      await tester.pumpAndSettle();
      
      // Verificar mesmos elementos de design
      expect(find.byType(Card), findsWidgets);
      expect(find.byType(SizedBox), findsWidgets);
      
      // Verificar que badges contextuais estão presentes
      expect(find.text('Escritório'), findsWidgets);
      expect(find.text('Negócio'), findsNothing); // Não deve ter badge de negócio
    });
  });
}

// Funções auxiliares para simulação de login e navegação

Future<void> _loginAsClient(WidgetTester tester) async {
  // Simular login como cliente
  // TODO: Implementar simulação de login baseada na estrutura atual de auth
}

Future<void> _loginAsAssociatedLawyer(WidgetTester tester) async {
  // Simular login como advogado associado
  // TODO: Implementar simulação com role = 'lawyer_associated'
}

Future<void> _loginAsContractingLawyer(WidgetTester tester) async {
  // Simular login como advogado contratante
  // TODO: Implementar simulação com role = 'lawyer_individual' ou 'lawyer_office'
}

Future<void> _loginAsSuperAssociate(WidgetTester tester) async {
  // Simular login como super associado
  // TODO: Implementar simulação com role = 'lawyer_platform_associate'
}

Future<void> _loginAsLawyerWithoutContextualData(WidgetTester tester) async {
  // Simular login como advogado mas forçar erro/ausência de dados contextuais
  // TODO: Implementar simulação de erro na API contextual
}

Future<void> _navigateToCases(WidgetTester tester) async {
  // Navegar para a tela de casos baseado no perfil do usuário
  await tester.tap(find.text('Meus Casos'));
  await tester.pumpAndSettle();
}

Future<void> _logoutAndLoginAsAssociatedLawyer(WidgetTester tester) async {
  // Fazer logout e login como advogado associado
  // TODO: Implementar troca de usuário em runtime
}

// Mocks e dados de teste

class MockUser extends User {
  MockUser({
    required String super.role,
    required super.id,
    required String super.fullName,
  }) : super(
    email: 'test@example.com',
    createdAt: DateTime.now(),
    permissions: _getPermissionsForRole(role),
  );

  static List<String> _getPermissionsForRole(String role) {
    switch (role) {
      case 'client':
        return ['view_cases', 'create_cases'];
      case 'lawyer_associated':
        return ['view_cases', 'manage_tasks', 'log_hours'];
      case 'lawyer_individual':
      case 'lawyer_office':
        return ['view_cases', 'manage_business', 'view_analytics'];
      case 'lawyer_platform_associate':
        return ['view_cases', 'manage_quality', 'view_opportunities'];
      default:
        return [];
    }
  }
}

class MockContextualCaseData extends ContextualCaseData {
  const MockContextualCaseData({
    required super.allocationType,
    super.delegatedByName,
    super.hoursBudgeted,
    super.hourlyRate,
  });
} 
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meu_app/main.dart' as app;
import 'package:meu_app/src/features/auth/domain/entities/user.dart';
import 'package:meu_app/src/features/cases/domain/entities/allocation_type.dart';
import 'package:meu_app/src/features/cases/domain/entities/contextual_case_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sistema de Visão Contextual de Casos - Testes de Integração', () {
    testWidgets('Cliente deve ver experiência original preservada', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como cliente
      await _loginAsClient(tester);
      
      // Navegar para casos
      await _navigateToCases(tester);
      
      // Verificar que cliente vê CaseCard normal (não contextual)
      expect(find.byType(CaseCard), findsAtLeastNWidgets(1));
      expect(find.byType(ContextualCaseCard), findsNothing);
      
      // Entrar em um caso específico
      await tester.tap(find.byType(CaseCard).first);
      await tester.pumpAndSettle();
      
      // Verificar seções originais do cliente
      expect(find.text('Advogado Responsável'), findsOneWidget);
      expect(find.text('Informações da Consulta'), findsOneWidget);
      expect(find.text('Pré-Análise'), findsOneWidget);
      expect(find.text('Próximos Passos'), findsOneWidget);
      expect(find.text('Documentos'), findsOneWidget);
      expect(find.text('Status do Processo'), findsOneWidget);
      
      // Não deve haver seções contextuais de advogados
      expect(find.text('Escalação e Suporte'), findsNothing);
      expect(find.text('Análise Competitiva'), findsNothing);
      expect(find.text('Controle de Qualidade'), findsNothing);
    });

    testWidgets('Advogado Associado deve ver contexto de delegação interna', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como advogado associado
      await _loginAsAssociatedLawyer(tester);
      
      // Navegar para casos
      await _navigateToCases(tester);
      
      // Verificar que advogado vê ContextualCaseCard
      expect(find.byType(ContextualCaseCard), findsAtLeastNWidgets(1));
      
      // Verificar card específico para delegação interna
      expect(find.text('👨‍💼 Delegado por'), findsWidgets);
      expect(find.text('Horas Orçadas'), findsWidgets);
      expect(find.text('Registrar Horas'), findsWidgets);
      
      // Entrar em um caso específico
      await tester.tap(find.byType(ContextualCaseCard).first);
      await tester.pumpAndSettle();
      
      // Verificar seções contextuais de advogado associado
      expect(find.text('Equipe Interna'), findsOneWidget);
      expect(find.text('Informações da Atribuição'), findsOneWidget);
      expect(find.text('Breakdown de Tarefas'), findsOneWidget);
      expect(find.text('Documentos de Trabalho'), findsOneWidget);
      expect(find.text('Controle de Tempo'), findsOneWidget);
      expect(find.text('Escalação e Suporte'), findsOneWidget);
      
      // Não deve haver seções de outros perfis
      expect(find.text('Análise Competitiva'), findsNothing);
      expect(find.text('Controle de Qualidade'), findsNothing);
    });

    testWidgets('Advogado Contratante deve ver contexto de negócio', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como advogado contratante
      await _loginAsContractingLawyer(tester);
      
      // Navegar para casos
      await _navigateToCases(tester);
      
      // Verificar que advogado vê ContextualCaseCard
      expect(find.byType(ContextualCaseCard), findsAtLeastNWidgets(1));
      
      // Entrar em um caso específico
      await tester.tap(find.byType(ContextualCaseCard).first);
      await tester.pumpAndSettle();
      
      // Verificar seções contextuais de advogado contratante
      expect(find.text('Contato do Cliente'), findsOneWidget);
      expect(find.text('Oportunidade de Negócio'), findsOneWidget);
      expect(find.text('Complexidade do Caso'), findsOneWidget);
      expect(find.text('Explicação do Match'), findsOneWidget);
      expect(find.text('Documentos Estratégicos'), findsOneWidget);
      expect(find.text('Análise de Rentabilidade'), findsOneWidget);
      expect(find.text('Análise Competitiva'), findsOneWidget);
      
      // Não deve haver seções de outros perfis
      expect(find.text('Escalação e Suporte'), findsNothing);
      expect(find.text('Controle de Qualidade'), findsNothing);
    });

    testWidgets('Super Associado deve ver contexto de plataforma', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como super associado
      await _loginAsSuperAssociate(tester);
      
      // Navegar para casos
      await _navigateToCases(tester);
      
      // Verificar card específico para plataforma
      expect(find.text('🎯 Match direto para você'), findsWidgets);
      expect(find.text('Complexidade'), findsWidgets);
      expect(find.text('Aceitar Caso'), findsWidgets);
      
      // Entrar em um caso específico
      await tester.tap(find.byType(ContextualCaseCard).first);
      await tester.pumpAndSettle();
      
      // Verificar seções contextuais de super associado
      expect(find.text('Oportunidade na Plataforma'), findsOneWidget);
      expect(find.text('Explicação do Match'), findsOneWidget);
      expect(find.text('Framework de Entrega'), findsOneWidget);
      expect(find.text('Documentos da Plataforma'), findsOneWidget);
      expect(find.text('Controle de Qualidade'), findsOneWidget);
      expect(find.text('Próximas Oportunidades'), findsOneWidget);
      
      // Não deve haver seções de outros perfis
      expect(find.text('Escalação e Suporte'), findsNothing);
      expect(find.text('Análise Competitiva'), findsNothing);
    });

    testWidgets('Factory deve retornar fallback seguro para dados ausentes', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como advogado mas sem dados contextuais
      await _loginAsLawyerWithoutContextualData(tester);
      
      // Navegar para casos
      await _navigateToCases(tester);
      
      // Entrar em um caso específico
      await tester.tap(find.byType(CaseCard).first);
      await tester.pumpAndSettle();
      
      // Deve usar fallback para experiência do cliente
      expect(find.text('Advogado Responsável'), findsOneWidget);
      expect(find.text('Informações da Consulta'), findsOneWidget);
      expect(find.text('Pré-Análise'), findsOneWidget);
      expect(find.text('Próximos Passos'), findsOneWidget);
      expect(find.text('Documentos'), findsOneWidget);
      expect(find.text('Status do Processo'), findsOneWidget);
    });

    testWidgets('Ações contextuais devem funcionar corretamente', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como advogado associado
      await _loginAsAssociatedLawyer(tester);
      
      // Navegar para casos
      await _navigateToCases(tester);
      
      // Testar ação "Registrar Horas"
      await tester.tap(find.text('Registrar Horas'));
      await tester.pumpAndSettle();
      
      // Verificar feedback
      expect(find.text('Registrando horas...'), findsOneWidget);
      
      // Testar ação "Atualizar Status"
      await tester.tap(find.text('Atualizar Status'));
      await tester.pumpAndSettle();
      
      // Verificar feedback
      expect(find.text('Status atualizado!'), findsOneWidget);
    });

    testWidgets('Loading states devem ser exibidos corretamente', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Simular login como advogado
      await _loginAsContractingLawyer(tester);
      
      // Navegar para casos
      await _navigateToCases(tester);
      
      // Entrar em um caso específico
      await tester.tap(find.byType(ContextualCaseCard).first);
      await tester.pump(); // Não esperar settle para capturar loading
      
      // Verificar loading de dados contextuais
      expect(find.text('Carregando dados contextuais...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      
      // Esperar carregamento completar
      await tester.pumpAndSettle();
      
      // Loading deve ter desaparecido
      expect(find.text('Carregando dados contextuais...'), findsNothing);
    });

    testWidgets('Sistema deve manter consistência visual entre perfis', (WidgetTester tester) async {
      // Inicializar app
      app.main();
      await tester.pumpAndSettle();

      // Testar consistência para cliente
      await _loginAsClient(tester);
      await _navigateToCases(tester);
      await tester.tap(find.byType(CaseCard).first);
      await tester.pumpAndSettle();
      
      // Verificar elementos de design consistentes
      expect(find.byType(Card), findsWidgets);
      expect(find.byType(SizedBox), findsWidgets);
      
      // Voltar e testar com advogado associado
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _logoutAndLoginAsAssociatedLawyer(tester);
      await _navigateToCases(tester);
      await tester.tap(find.byType(ContextualCaseCard).first);
      await tester.pumpAndSettle();
      
      // Verificar mesmos elementos de design
      expect(find.byType(Card), findsWidgets);
      expect(find.byType(SizedBox), findsWidgets);
      
      // Verificar que badges contextuais estão presentes
      expect(find.text('Escritório'), findsWidgets);
      expect(find.text('Negócio'), findsNothing); // Não deve ter badge de negócio
    });
  });
}

// Funções auxiliares para simulação de login e navegação

Future<void> _loginAsClient(WidgetTester tester) async {
  // Simular login como cliente
  // TODO: Implementar simulação de login baseada na estrutura atual de auth
}

Future<void> _loginAsAssociatedLawyer(WidgetTester tester) async {
  // Simular login como advogado associado
  // TODO: Implementar simulação com role = 'lawyer_associated'
}

Future<void> _loginAsContractingLawyer(WidgetTester tester) async {
  // Simular login como advogado contratante
  // TODO: Implementar simulação com role = 'lawyer_individual' ou 'lawyer_office'
}

Future<void> _loginAsSuperAssociate(WidgetTester tester) async {
  // Simular login como super associado
  // TODO: Implementar simulação com role = 'lawyer_platform_associate'
}

Future<void> _loginAsLawyerWithoutContextualData(WidgetTester tester) async {
  // Simular login como advogado mas forçar erro/ausência de dados contextuais
  // TODO: Implementar simulação de erro na API contextual
}

Future<void> _navigateToCases(WidgetTester tester) async {
  // Navegar para a tela de casos baseado no perfil do usuário
  await tester.tap(find.text('Meus Casos'));
  await tester.pumpAndSettle();
}

Future<void> _logoutAndLoginAsAssociatedLawyer(WidgetTester tester) async {
  // Fazer logout e login como advogado associado
  // TODO: Implementar troca de usuário em runtime
}

// Mocks e dados de teste

class MockUser extends User {
  MockUser({
    required String super.role,
    required super.id,
    required String super.fullName,
  }) : super(
    email: 'test@example.com',
    createdAt: DateTime.now(),
    permissions: _getPermissionsForRole(role),
  );

  static List<String> _getPermissionsForRole(String role) {
    switch (role) {
      case 'client':
        return ['view_cases', 'create_cases'];
      case 'lawyer_associated':
        return ['view_cases', 'manage_tasks', 'log_hours'];
      case 'lawyer_individual':
      case 'lawyer_office':
        return ['view_cases', 'manage_business', 'view_analytics'];
      case 'lawyer_platform_associate':
        return ['view_cases', 'manage_quality', 'view_opportunities'];
      default:
        return [];
    }
  }
}

class MockContextualCaseData extends ContextualCaseData {
  const MockContextualCaseData({
    required super.allocationType,
    super.delegatedByName,
    super.hoursBudgeted,
    super.hourlyRate,
  });
} 