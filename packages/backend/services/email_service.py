"""
Serviço de envio de emails para notificações e relatórios.
Usa SMTP ou API de email conforme configuração.
"""
import os
import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import List, Optional
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

# Configurações de email
SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
EMAIL_FROM = os.getenv("EMAIL_FROM", "noreply@litgo.com")
EMAIL_ENABLED = os.getenv("EMAIL_ENABLED", "false").lower() == "true"


class EmailService:
    """Serviço para envio de emails."""

    def __init__(self):
        self.enabled = EMAIL_ENABLED
        if not self.enabled:
            logger.warning(
                "Serviço de email desabilitado. Configure EMAIL_ENABLED=true para habilitar.")

    async def send_email(
        self,
        to: List[str],
        subject: str,
        body: str,
        html: bool = False
    ) -> bool:
        """
        Envia um email simples.

        Args:
            to: Lista de destinatários
            subject: Assunto do email
            body: Corpo do email
            html: Se True, envia como HTML

        Returns:
            True se enviado com sucesso
        """
        if not self.enabled:
            logger.info(f"Email simulado - Para: {to}, Assunto: {subject}")
            return True

        try:
            msg = MIMEMultipart('alternative')
            msg['Subject'] = subject
            msg['From'] = EMAIL_FROM
            msg['To'] = ', '.join(to)

            # Adicionar corpo do email
            if html:
                part = MIMEText(body, 'html')
            else:
                part = MIMEText(body, 'plain')
            msg.attach(part)

            # Enviar email
            with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
                if SMTP_USER and SMTP_PASSWORD:
                    server.starttls()
                    server.login(SMTP_USER, SMTP_PASSWORD)

                server.send_message(msg)

            logger.info(f"Email enviado com sucesso para {to}")
            return True

        except Exception as e:
            logger.error(f"Erro ao enviar email: {e}")
            return False

    async def send_report(
        self,
        to: List[str],
        subject: str,
        html_content: str
    ) -> bool:
        """
        Envia um relatório em formato HTML.

        Args:
            to: Lista de destinatários
            subject: Assunto do email
            html_content: Conteúdo HTML do relatório

        Returns:
            True se enviado com sucesso
        """
        # Adicionar fallback de texto simples
        text_content = f"""
        {subject}
        
        Este é um relatório HTML. Por favor, visualize em um cliente de email que suporte HTML.
        
        --
        LITGO5 - Sistema de Matching Jurídico
        """

        if not self.enabled:
            logger.info(f"Relatório simulado - Para: {to}, Assunto: {subject}")
            logger.debug("Conteúdo HTML do relatório gerado com sucesso")
            return True

        try:
            msg = MIMEMultipart('alternative')
            msg['Subject'] = subject
            msg['From'] = EMAIL_FROM
            msg['To'] = ', '.join(to)

            # Parte texto
            part1 = MIMEText(text_content, 'plain')
            msg.attach(part1)

            # Parte HTML
            part2 = MIMEText(html_content, 'html')
            msg.attach(part2)

            # Enviar
            with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
                if SMTP_USER and SMTP_PASSWORD:
                    server.starttls()
                    server.login(SMTP_USER, SMTP_PASSWORD)

                server.send_message(msg)

            logger.info(f"Relatório enviado com sucesso para {to}")
            return True

        except Exception as e:
            logger.error(f"Erro ao enviar relatório: {e}")
            return False

    async def send_notification(
        self,
        to: str,
        title: str,
        message: str,
        action_url: Optional[str] = None
    ) -> bool:
        """
        Envia uma notificação por email.

        Args:
            to: Destinatário
            title: Título da notificação
            message: Mensagem
            action_url: URL opcional para ação

        Returns:
            True se enviado com sucesso
        """
        # Template HTML para notificação
        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; }}
                .notification {{ 
                    max-width: 600px; 
                    margin: 0 auto; 
                    padding: 20px;
                    background-color: #f5f5f5;
                    border-radius: 10px;
                }}
                .header {{ 
                    background-color: #3498db; 
                    color: white; 
                    padding: 20px;
                    border-radius: 10px 10px 0 0;
                    text-align: center;
                }}
                .content {{ 
                    background-color: white; 
                    padding: 30px;
                    border-radius: 0 0 10px 10px;
                }}
                .button {{
                    display: inline-block;
                    padding: 12px 24px;
                    background-color: #3498db;
                    color: white;
                    text-decoration: none;
                    border-radius: 5px;
                    margin-top: 20px;
                }}
                .footer {{
                    text-align: center;
                    color: #666;
                    font-size: 12px;
                    margin-top: 30px;
                }}
            </style>
        </head>
        <body>
            <div class="notification">
                <div class="header">
                    <h1>{title}</h1>
                </div>
                <div class="content">
                    <p>{message}</p>
                    {f'<a href="{action_url}" class="button">Ver Detalhes</a>' if action_url else ''}
                </div>
                <div class="footer">
                    <p>LITGO5 - Sistema de Matching Jurídico</p>
                </div>
            </div>
        </body>
        </html>
        """

        return await self.send_email(
            to=[to],
            subject=title,
            body=html_body,
            html=True
        )


# Instância singleton
email_service = EmailService()
