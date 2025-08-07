"""
Serviço para envio de emails de notificações de casos.
Conecta o sistema de notificações de casos ao sistema de emails.
"""
import asyncio
import logging
from typing import Optional, Dict, Any
from datetime import datetime
from services.email_service import EmailService

logger = logging.getLogger(__name__)

class CaseNotificationEmailService:
    def __init__(self):
        self.email_service = EmailService()
        
    async def send_case_notification_email(
        self,
        notification_type: str,
        user_email: str,
        user_name: str,
        case_data: Dict[str, Any],
        notification_data: Dict[str, Any]
    ) -> bool:
        """
        Envia email baseado no tipo de notificação de caso.
        """
        try:
            # Gerar título e conteúdo baseado no tipo
            title, message, action_url = self._generate_email_content(
                notification_type, user_name, case_data, notification_data
            )
            
            # Enviar email usando o EmailService existente
            success = await self.email_service.send_notification(
                to=user_email,
                title=title,
                message=message,
                action_url=action_url
            )
            
            logger.info(f"Email de notificação enviado - Tipo: {notification_type}, "
                       f"Email: {user_email}, Sucesso: {success}")
            
            return success
            
        except Exception as e:
            logger.error(f"Erro ao enviar email de notificação: {e}")
            return False
    
    def _generate_email_content(
        self,
        notification_type: str,
        user_name: str,
        case_data: Dict[str, Any],
        notification_data: Dict[str, Any]
    ) -> tuple[str, str, Optional[str]]:
        """
        Gera título, mensagem e URL de ação baseado no tipo de notificação.
        """
        case_title = case_data.get('title', 'Caso')
        case_id = case_data.get('id', '')
        client_name = case_data.get('client_name', 'Cliente')
        
        # URL base para ações (pode vir de variável de ambiente)
        base_url = "https://app.litig.com.br"
        action_url = f"{base_url}/case-detail/{case_id}" if case_id else None
        
        # Gerar conteúdo específico por tipo
        content_map = {
            'caseAssigned': {
                'title': '🎯 Novo Caso Atribuído',
                'message': f"""
                <p>Olá <strong>{user_name}</strong>,</p>
                
                <p>Um novo caso foi atribuído a você:</p>
                
                <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="color: #2563eb; margin-top: 0;">📋 {case_title}</h3>
                    <p><strong>Cliente:</strong> {client_name}</p>
                    <p><strong>Data de Atribuição:</strong> {datetime.now().strftime('%d/%m/%Y às %H:%M')}</p>
                </div>
                
                <p>Clique no botão abaixo para visualizar os detalhes do caso e começar a trabalhar.</p>
                
                <p>Atenciosamente,<br>
                Equipe LITIG</p>
                """
            },
            
            'caseStatusChanged': {
                'title': '🔄 Status do Caso Atualizado',
                'message': f"""
                <p>Olá <strong>{user_name}</strong>,</p>
                
                <p>O status de um dos seus casos foi atualizado:</p>
                
                <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="color: #2563eb; margin-top: 0;">📋 {case_title}</h3>
                    <p><strong>Status Anterior:</strong> {notification_data.get('old_status', 'N/A')}</p>
                    <p><strong>Novo Status:</strong> {notification_data.get('new_status', 'N/A')}</p>
                    <p><strong>Data da Alteração:</strong> {datetime.now().strftime('%d/%m/%Y às %H:%M')}</p>
                </div>
                
                <p>Clique no botão abaixo para visualizar as atualizações do caso.</p>
                
                <p>Atenciosamente,<br>
                Equipe LITIG</p>
                """
            },
            
            'documentUploaded': {
                'title': '📄 Novo Documento Carregado',
                'message': f"""
                <p>Olá <strong>{user_name}</strong>,</p>
                
                <p>Um novo documento foi carregado no caso:</p>
                
                <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="color: #2563eb; margin-top: 0;">📋 {case_title}</h3>
                    <p><strong>Documento:</strong> {notification_data.get('document_name', 'N/A')}</p>
                    <p><strong>Carregado por:</strong> {notification_data.get('uploader_name', 'N/A')}</p>
                    <p><strong>Data:</strong> {datetime.now().strftime('%d/%m/%Y às %H:%M')}</p>
                </div>
                
                <p>Clique no botão abaixo para acessar os documentos do caso.</p>
                
                <p>Atenciosamente,<br>
                Equipe LITIG</p>
                """
            },
            
            'documentApproved': {
                'title': '✅ Documento Aprovado',
                'message': f"""
                <p>Olá <strong>{user_name}</strong>,</p>
                
                <p>Um documento foi aprovado no caso:</p>
                
                <div style="background-color: #f0f9ff; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #10b981;">
                    <h3 style="color: #059669; margin-top: 0;">📋 {case_title}</h3>
                    <p><strong>Documento:</strong> {notification_data.get('document_name', 'N/A')}</p>
                    <p><strong>Aprovado por:</strong> {notification_data.get('approver_name', 'N/A')}</p>
                    <p><strong>Data:</strong> {datetime.now().strftime('%d/%m/%Y às %H:%M')}</p>
                </div>
                
                <p>Parabéns! O documento foi aprovado e você pode prosseguir com as próximas etapas.</p>
                
                <p>Atenciosamente,<br>
                Equipe LITIG</p>
                """
            },
            
            'documentRejected': {
                'title': '❌ Documento Rejeitado',
                'message': f"""
                <p>Olá <strong>{user_name}</strong>,</p>
                
                <p>Um documento foi rejeitado no caso e requer sua atenção:</p>
                
                <div style="background-color: #fef2f2; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ef4444;">
                    <h3 style="color: #dc2626; margin-top: 0;">📋 {case_title}</h3>
                    <p><strong>Documento:</strong> {notification_data.get('document_name', 'N/A')}</p>
                    <p><strong>Rejeitado por:</strong> {notification_data.get('reviewer_name', 'N/A')}</p>
                    <p><strong>Motivo:</strong> {notification_data.get('rejection_reason', 'N/A')}</p>
                    <p><strong>Data:</strong> {datetime.now().strftime('%d/%m/%Y às %H:%M')}</p>
                </div>
                
                <p><strong>Ação Necessária:</strong> Por favor, revise o documento e faça as correções solicitadas.</p>
                
                <p>Atenciosamente,<br>
                Equipe LITIG</p>
                """
            },
            
            'newCaseMessage': {
                'title': '💬 Nova Mensagem no Caso',
                'message': f"""
                <p>Olá <strong>{user_name}</strong>,</p>
                
                <p>Você recebeu uma nova mensagem no caso:</p>
                
                <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="color: #2563eb; margin-top: 0;">📋 {case_title}</h3>
                    <p><strong>De:</strong> {notification_data.get('sender_name', 'N/A')}</p>
                    <p><strong>Prévia:</strong> "{notification_data.get('message_preview', 'N/A')}"</p>
                    <p><strong>Data:</strong> {datetime.now().strftime('%d/%m/%Y às %H:%M')}</p>
                </div>
                
                <p>Clique no botão abaixo para ler e responder à mensagem.</p>
                
                <p>Atenciosamente,<br>
                Equipe LITIG</p>
                """
            },
            
            'caseDeadlineApproaching': {
                'title': '⏰ Prazo Próximo - Ação Necessária',
                'message': f"""
                <p>Olá <strong>{user_name}</strong>,</p>
                
                <p><strong>⚠️ ALERTA DE PRAZO:</strong> Um prazo está se aproximando!</p>
                
                <div style="background-color: #fff7ed; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #f59e0b;">
                    <h3 style="color: #d97706; margin-top: 0;">📋 {case_title}</h3>
                    <p><strong>Tarefa:</strong> {notification_data.get('task_description', 'N/A')}</p>
                    <p><strong>Prazo:</strong> {notification_data.get('deadline', 'N/A')}</p>
                    <p><strong>Dias Restantes:</strong> {notification_data.get('days_until_deadline', 'N/A')}</p>
                </div>
                
                <p><strong>⚡ Ação Urgente Necessária:</strong> Por favor, tome as providências necessárias o mais breve possível.</p>
                
                <p>Atenciosamente,<br>
                Equipe LITIG</p>
                """
            },
            
            'caseCompleted': {
                'title': '🎉 Caso Concluído com Sucesso',
                'message': f"""
                <p>Olá <strong>{user_name}</strong>,</p>
                
                <p>Parabéns! Um caso foi concluído com sucesso:</p>
                
                <div style="background-color: #f0f9ff; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #10b981;">
                    <h3 style="color: #059669; margin-top: 0;">📋 {case_title}</h3>
                    <p><strong>Concluído por:</strong> {notification_data.get('completed_by', 'N/A')}</p>
                    <p><strong>Data de Conclusão:</strong> {datetime.now().strftime('%d/%m/%Y às %H:%M')}</p>
                    <p><strong>Cliente:</strong> {client_name}</p>
                </div>
                
                <p>🎊 Excelente trabalho! O caso foi finalizado e o cliente foi notificado.</p>
                
                <p>Atenciosamente,<br>
                Equipe LITIG</p>
                """
            },
            
            'hearingScheduled': {
                'title': '⚖️ Audiência Marcada',
                'message': f"""
                <p>Olá <strong>{user_name}</strong>,</p>
                
                <p>Uma audiência foi marcada para o caso:</p>
                
                <div style="background-color: #fff7ed; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #f59e0b;">
                    <h3 style="color: #d97706; margin-top: 0;">📋 {case_title}</h3>
                    <p><strong>Data da Audiência:</strong> {notification_data.get('hearing_date', 'N/A')}</p>
                    <p><strong>Local:</strong> {notification_data.get('location', 'N/A')}</p>
                    <p><strong>Cliente:</strong> {client_name}</p>
                </div>
                
                <p><strong>📅 Importante:</strong> Adicione esta audiência ao seu calendário e prepare a documentação necessária.</p>
                
                <p>Atenciosamente,<br>
                Equipe LITIG</p>
                """
            },
            
            'caseTransferred': {
                'title': '↔️ Caso Transferido',
                'message': f"""
                <p>Olá <strong>{user_name}</strong>,</p>
                
                <p>Um caso foi transferido:</p>
                
                <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="color: #2563eb; margin-top: 0;">📋 {case_title}</h3>
                    <p><strong>De:</strong> {notification_data.get('from_lawyer', 'N/A')}</p>
                    <p><strong>Para:</strong> {notification_data.get('to_lawyer', 'N/A')}</p>
                    <p><strong>Motivo:</strong> {notification_data.get('transfer_reason', 'N/A')}</p>
                    <p><strong>Data:</strong> {datetime.now().strftime('%d/%m/%Y às %H:%M')}</p>
                </div>
                
                <p>Todas as partes envolvidas foram notificadas sobre a transferência.</p>
                
                <p>Atenciosamente,<br>
                Equipe LITIG</p>
                """
            },
            
            # Notificações específicas de ofertas
            'newOffer': {
                'title': '📋 Nova Oferta de Caso',
                'message': f"""
                <p>Olá <strong>{user_name}</strong>,</p>
                
                <p>Você recebeu uma nova oferta de caso:</p>
                
                <div style="background-color: #f0f9ff; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #3b82f6;">
                    <h3 style="color: #1d4ed8; margin-top: 0;">📋 {case_title}</h3>
                    <p><strong>Área do Direito:</strong> {notification_data.get('legal_area', 'N/A')}</p>
                    <p><strong>Cliente:</strong> {client_name}</p>
                    <p><strong>Data da Oferta:</strong> {datetime.now().strftime('%d/%m/%Y às %H:%M')}</p>
                </div>
                
                <p><strong>⚡ Ação Necessária:</strong> Acesse o aplicativo para visualizar os detalhes completos da oferta e decidir se aceita o caso.</p>
                
                <p>Atenciosamente,<br>
                Equipe LITIG</p>
                """
            },
            
            'offerAccepted': {
                'title': '🎉 Seu Caso foi Aceito!',
                'message': f"""
                <p>Olá <strong>{user_name}</strong>,</p>
                
                <p>Excelente notícia! Seu caso foi aceito por um advogado:</p>
                
                <div style="background-color: #f0f9ff; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #10b981;">
                    <h3 style="color: #059669; margin-top: 0;">🎯 {case_title}</h3>
                    <p><strong>Advogado Responsável:</strong> {notification_data.get('lawyer_name', 'Advogado')}</p>
                    <p><strong>Data de Aceitação:</strong> {datetime.now().strftime('%d/%m/%Y às %H:%M')}</p>
                </div>
                
                <p><strong>🔥 Próximos Passos:</strong></p>
                <ul>
                    <li>O contrato será enviado em breve para sua aprovação</li>
                    <li>O advogado entrará em contato para alinhar os detalhes</li>
                    <li>Você pode acompanhar o progresso pelo aplicativo</li>
                </ul>
                
                <p>Parabéns por ter encontrado o advogado ideal para seu caso!</p>
                
                <p>Atenciosamente,<br>
                Equipe LITIG</p>
                """
            }
        }
        
        # Buscar conteúdo ou usar padrão
        content = content_map.get(notification_type, {
            'title': '🔔 Nova Notificação de Caso',
            'message': f"""
            <p>Olá <strong>{user_name}</strong>,</p>
            
            <p>Você recebeu uma nova notificação relacionada ao caso <strong>{case_title}</strong>.</p>
            
            <p>Clique no botão abaixo para visualizar os detalhes.</p>
            
            <p>Atenciosamente,<br>
            Equipe LITIG</p>
            """
        })
        
        return content['title'], content['message'], action_url

# Instância global do serviço
case_notification_email_service = CaseNotificationEmailService()