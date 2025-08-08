/*
EXEMPLO DE USO: Sistema Integrado de Notificações de Casos com Email

Este arquivo demonstra como usar o sistema completo de notificações
que inclui notificações no app + envio automático de emails.
*/

import 'package:meu_app/injection_container.dart';
import 'case_notification_service.dart';

class CaseNotificationExample {
  
  /// Exemplo: Notificar atribuição de caso com email
  static Future<void> exemploNotificarCasoAtribuido() async {
    final caseNotificationService = getIt<CaseNotificationService>();
    
    // Enviar notificação completa (app + email)
    await caseNotificationService.notifyCaseAssigned(
      caseId: 'case_12345',
      caseTitle: 'Ação Trabalhista - João Silva',
      lawyerId: 'lawyer_67890',
      clientName: 'João Silva',
      userEmail: 'advogado@escritorio.com', // ⚡ Email será enviado automaticamente
      userName: 'Dr. Maria Fernanda',
    );
    
    /*
    🔥 O QUE ACONTECE:
    1. ✅ Notificação criada no app (banco local)
    2. ✅ Email HTML enviado automaticamente via backend
    3. ✅ Email contém:
       - Título: "🎯 Novo Caso Atribuído"
       - Detalhes do caso e cliente
       - Link para visualizar o caso
       - Template HTML responsivo
    */
  }
  
  /// Exemplo: Múltiplas notificações em sequência
  static Future<void> exemploFluxoCompleto() async {
    final service = getIt<CaseNotificationService>();
    
    const caseId = 'case_workflow_001';
    const userEmail = 'advogado@litig.com';
    const userName = 'Dr. João Santos';
    
    // 1. Caso atribuído
    await service.notifyCaseAssigned(
      caseId: caseId,
      caseTitle: 'Revisão Contratual - Empresa XYZ',
      lawyerId: 'lawyer_001',
      clientName: 'Empresa XYZ Ltda',
      userEmail: userEmail,
      userName: userName,
    );
    
    // 2. Documento carregado (simulação após algum tempo)
    await Future.delayed(const Duration(seconds: 2));
    await service.notifyDocumentUploaded(
      caseId: caseId,
      caseTitle: 'Revisão Contratual - Empresa XYZ',
      userId: 'lawyer_001',
      documentName: 'contrato_revisado_v2.pdf',
      uploaderName: 'Cliente XYZ',
      userEmail: userEmail,
      userName: userName,
    );
    
    // 3. Documento aprovado
    await Future.delayed(const Duration(seconds: 2));
    await service.notifyDocumentApproved(
      caseId: caseId,
      caseTitle: 'Revisão Contratual - Empresa XYZ',
      userId: 'lawyer_001',
      documentName: 'contrato_revisado_v2.pdf',
      approverName: 'Dr. João Santos',
      userEmail: userEmail,
      userName: userName,
    );
    
    // 4. Caso concluído
    await Future.delayed(const Duration(seconds: 2));
    await service.notifyCaseCompleted(
      caseId: caseId,
      caseTitle: 'Revisão Contratual - Empresa XYZ',
      userId: 'lawyer_001',
      completedBy: 'Dr. João Santos',
      userEmail: userEmail,
      userName: userName,
    );
    
    /*
    🎯 RESULTADO:
    - 4 notificações no app
    - 4 emails HTML enviados automaticamente
    - Cada email com conteúdo específico e contextual
    - Logs detalhados de cada operação
    */
  }
  
  /// Exemplo: Notificação sem email (apenas app)
  static Future<void> exemploSemEmail() async {
    final service = getIt<CaseNotificationService>();
    
    // Não fornecer userEmail e userName = apenas notificação no app
    await service.notifyCaseAssigned(
      caseId: 'case_local_only',
      caseTitle: 'Caso Local',
      lawyerId: 'lawyer_test',
      clientName: 'Cliente Test',
      // userEmail: null, // ❌ Sem email
      // userName: null,  // ❌ Sem email
    );
    
    /*
    ℹ️ RESULTADO:
    - ✅ Notificação criada no app
    - ❌ Email não enviado (dados não fornecidos)
    */
  }
  
  /// Exemplo: Teste do sistema de emails
  static Future<void> testarSistemaEmail() async {
    final service = getIt<CaseNotificationService>();
    
    try {
      // Usar o remote data source diretamente para teste
      final remoteDataSource = getIt<CaseNotificationService>()._remoteDataSource;
      
      final sucesso = await remoteDataSource.testCaseNotification();
      
      if (sucesso) {
        print('✅ Sistema de email funcionando!');
      } else {
        print('❌ Falha no sistema de email');
      }
      
    } catch (e) {
      print('🚨 Erro no teste: $e');
    }
  }
}

/*
📋 CHECKLIST DE CONFIGURAÇÃO:

Backend:
✅ EmailService configurado com SendGrid/SMTP
✅ CaseNotificationEmailService criado
✅ Rota /api/v1/case-notifications/send ativa
✅ Templates HTML para cada tipo de notificação

Frontend:
✅ CaseNotificationService integrado
✅ CaseNotificationRemoteDataSource criado
✅ Dependências registradas no injection_container
✅ Métodos atualizados para aceitar email/userName

Para Usar:
1. Configure SENDGRID_API_KEY no backend
2. Ajuste baseUrl no injection_container (localhost vs produção)
3. Chame os métodos com userEmail e userName preenchidos
4. Monitore logs para verificar envio de emails

Tipos de Email Suportados:
🎯 caseAssigned - Caso atribuído
🔄 caseStatusChanged - Status alterado
📄 documentUploaded - Documento enviado
✅ documentApproved - Documento aprovado
❌ documentRejected - Documento rejeitado
💬 newCaseMessage - Nova mensagem
⏰ caseDeadlineApproaching - Prazo próximo
🎉 caseCompleted - Caso concluído
⚖️ hearingScheduled - Audiência marcada
↔️ caseTransferred - Caso transferido
*/