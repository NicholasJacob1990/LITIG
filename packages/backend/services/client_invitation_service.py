"""
Client Invitation Service

Serviço responsável por enviar convites automáticos para advogados externos
quando clientes solicitam contato, com sistema de fallback multi-canal.
"""

import asyncio
import uuid
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List
from dataclasses import dataclass
import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Dependências internas
try:
    import aioredis
    from sqlalchemy.ext.asyncio import AsyncSession
    from sqlalchemy import select, insert, update
    HAS_DB = True
except ImportError:
    HAS_DB = False
    AsyncSession = None

logger = logging.getLogger(__name__)

@dataclass
class InvitationResult:
    """Resultado de uma tentativa de convite."""
    status: str  # 'success', 'fallback', 'failed'
    channel: str  # 'platform_email', 'linkedin_assisted', 'none'
    message: Optional[str] = None
    linkedin_url: Optional[str] = None
    linkedin_message: Optional[str] = None
    invitation_id: Optional[str] = None

@dataclass
class PendingInvitation:
    """Estrutura de convite pendente."""
    id: str
    client_id: str
    target_name: str
    target_email: Optional[str]
    case_summary: str
    token: str
    status: str
    created_at: datetime
    expires_at: datetime


class ClientInvitationService:
    """
    Serviço para enviar convites de clientes para advogados externos.
    
    Implementa hierarquia de fallback:
    1. E-mail da plataforma (primário)
    2. LinkedIn assistido (fallback)
    3. Orientação para verificados (último fallback)
    """
    
    def __init__(self, db_session: Optional[AsyncSession] = None):
        self.db_session = db_session
        self.smtp_host = os.getenv("SMTP_HOST", "smtp.gmail.com")
        self.smtp_port = int(os.getenv("SMTP_PORT", "587"))
        self.smtp_user = os.getenv("SMTP_USER", "oportunidades@litig.com")
        self.smtp_password = os.getenv("SMTP_PASSWORD", "")
        self.platform_domain = os.getenv("PLATFORM_DOMAIN", "https://app.litig.com")
        
        # Configurações de timing
        self.invitation_ttl_hours = int(os.getenv("INVITATION_TTL_HOURS", "168"))  # 7 dias
        
    async def send_client_lead_notification(self, 
                                          target_profile: Dict[str, Any], 
                                          case_info: Dict[str, Any], 
                                          client_info: Dict[str, Any]) -> InvitationResult:
        """
        Envia notificação para advogado não cadastrado usando hierarquia de canais.
        
        Args:
            target_profile: Dados do perfil externo do advogado
            case_info: Informações do caso do cliente
            client_info: Informações do cliente
            
        Returns:
            InvitationResult com detalhes da tentativa de contato
        """
        logger.info("Iniciando processo de convite", {
            "target_name": target_profile.get('name'),
            "client_id": client_info.get('id'),
            "case_area": case_info.get('area')
        })
        
        try:
            # 1. Gerar token único de convite
            invitation = await self._create_pending_invitation(
                target_name=target_profile['name'],
                client_id=client_info['id'],
                case_summary=case_info.get('summary', f"Caso de {case_info.get('area', 'Direito')}"),
                target_email=target_profile.get('email')
            )
            
            claim_url = f"{self.platform_domain}/claim-profile?token={invitation.token}"
            
            # 2. CANAL PRIMÁRIO: E-mail da plataforma
            if target_profile.get('email'):
                try:
                    email_result = await self._send_platform_email(
                        target_profile, case_info, client_info, claim_url, invitation.id
                    )
                    
                    if email_result:
                        await self._update_invitation_status(invitation.id, 'sent_platform_email')
                        logger.info("E-mail enviado com sucesso", {
                            "invitation_id": invitation.id,
                            "target_email": target_profile['email']
                        })
                        return InvitationResult(
                            status="success",
                            channel="platform_email",
                            message=f"E-mail enviado para {target_profile['name']}",
                            invitation_id=invitation.id
                        )
                        
                except Exception as e:
                    logger.warning(f"Falha no e-mail para {target_profile['name']}: {e}")
                    await self._update_invitation_status(invitation.id, 'failed_email')
            
            # 3. FALLBACK: LinkedIn Assistido
            if target_profile.get('linkedin_url'):
                linkedin_message = self._build_linkedin_client_message(
                    target_profile, case_info, client_info, claim_url
                )
                
                await self._update_invitation_status(invitation.id, 'linkedin_assisted')
                logger.info("Fallback LinkedIn ativado", {
                    "invitation_id": invitation.id,
                    "linkedin_url": target_profile['linkedin_url']
                })
                
                return InvitationResult(
                    status="fallback",
                    channel="linkedin_assisted",
                    linkedin_message=linkedin_message,
                    linkedin_url=target_profile['linkedin_url'],
                    invitation_id=invitation.id
                )
            
            # 4. ÚLTIMO FALLBACK: Nenhum método encontrado
            await self._update_invitation_status(invitation.id, 'no_contact_method')
            logger.warning("Nenhum método de contato encontrado", {
                "invitation_id": invitation.id,
                "target_name": target_profile['name']
            })
            
            return InvitationResult(
                status="failed", 
                channel="none", 
                message="Nenhum método de contato público encontrado",
                invitation_id=invitation.id
            )
            
        except Exception as e:
            logger.error(f"Erro crítico no processo de convite: {e}")
            return InvitationResult(
                status="failed",
                channel="error",
                message=f"Erro interno: {str(e)}"
            )
    
    async def _create_pending_invitation(self, 
                                       target_name: str,
                                       client_id: str, 
                                       case_summary: str,
                                       target_email: Optional[str] = None) -> PendingInvitation:
        """Cria um convite pendente no banco de dados."""
        invitation_id = str(uuid.uuid4())
        token = str(uuid.uuid4()).replace('-', '')  # Token sem hífens
        now = datetime.utcnow()
        expires_at = now + timedelta(hours=self.invitation_ttl_hours)
        
        invitation = PendingInvitation(
            id=invitation_id,
            client_id=client_id,
            target_name=target_name,
            target_email=target_email,
            case_summary=case_summary,
            token=token,
            status='pending',
            created_at=now,
            expires_at=expires_at
        )
        
        # Salvar no banco (se disponível)
        if self.db_session and HAS_DB:
            try:
                # TODO: Implementar inserção real na tabela client_invitations
                # query = insert(client_invitations_table).values(...)
                # await self.db_session.execute(query)
                # await self.db_session.commit()
                pass
            except Exception as e:
                logger.warning(f"Falha ao salvar convite no DB: {e}")
        
        logger.info("Convite criado", {
            "invitation_id": invitation_id,
            "expires_at": expires_at.isoformat()
        })
        
        return invitation
    
    async def _send_platform_email(self, 
                                 target_profile: Dict[str, Any],
                                 case_info: Dict[str, Any], 
                                 client_info: Dict[str, Any],
                                 claim_url: str,
                                 invitation_id: str) -> bool:
        """Envia e-mail profissional da plataforma."""
        try:
            subject, body = self._build_client_lead_email(
                target_profile, case_info, client_info, claim_url
            )
            
            # Configurar e-mail
            msg = MIMEMultipart('alternative')
            msg['Subject'] = subject
            msg['From'] = self.smtp_user
            msg['To'] = target_profile['email']
            msg['Reply-To'] = client_info.get('email', self.smtp_user)
            
            # Corpo do e-mail (texto plano)
            text_part = MIMEText(body, 'plain', 'utf-8')
            msg.attach(text_part)
            
            # Enviar via SMTP
            if self.smtp_password:  # Só tentar se tiver credenciais
                with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                    server.starttls()
                    server.login(self.smtp_user, self.smtp_password)
                    server.send_message(msg)
                
                return True
            else:
                logger.warning("SMTP não configurado, simulando envio")
                # Em desenvolvimento, simular sucesso
                return os.getenv("ENV") == "development"
                
        except Exception as e:
            logger.error(f"Erro ao enviar e-mail: {e}")
            return False
    
    def _build_client_lead_email(self, 
                               target_profile: Dict[str, Any],
                               case_info: Dict[str, Any], 
                               client_info: Dict[str, Any],
                               claim_url: str) -> tuple[str, str]:
        """Constrói subject e body do e-mail profissional."""
        
        subject = f"Nova oportunidade de caso jurídico - LITIG"
        
        # Dados do caso com fallbacks seguros
        case_area = case_info.get('area', 'Direito')
        case_location = case_info.get('location', 'Não especificado')
        case_complexity = case_info.get('complexity', 'Média')
        client_type = 'Empresa' if client_info.get('type') == 'PJ' else 'Cliente'
        
        body = f"""Prezado(a) Dr(a). {target_profile['name']},

Seu perfil foi identificado como altamente compatível para atender um cliente em nossa plataforma.

📋 Detalhes da Oportunidade:
• Área: {case_area}
• Localização: {case_location}
• Complexidade: {case_complexity}
• Cliente: {client_type}

Para ver os detalhes completos e demonstrar interesse, reivindique seu perfil gratuitamente:

🔗 Reivindicar Perfil e Ver Caso:
{claim_url}

Ao se juntar à LITIG, você acessa:
✓ Novos clientes qualificados
✓ Gestão completa de casos
✓ Pagamentos seguros
✓ Ferramentas jurídicas avançadas
✓ Rede de profissionais verificados

A LITIG é a plataforma líder em conectar advogados especializados com clientes que precisam de assistência jurídica de qualidade.

Esta oportunidade está disponível por tempo limitado. Reivindique seu perfil agora para não perder esta e outras oportunidades futuras.

Atenciosamente,
Equipe LITIG
oportunidades@litig.com

---
Este e-mail foi enviado porque seu perfil foi identificado como compatível com uma demanda específica. Se você não deseja receber estas comunicações, pode optar por não receber através do link de reivindicação."""

        return subject, body
    
    def _build_linkedin_client_message(self, 
                                     target_profile: Dict[str, Any],
                                     case_info: Dict[str, Any], 
                                     client_info: Dict[str, Any],
                                     claim_url: str) -> str:
        """Constrói mensagem para o cliente enviar no LinkedIn."""
        
        client_name = client_info.get('name', 'Cliente LITIG')
        case_area = case_info.get('area', 'sua área de expertise')
        
        return f"""Olá, Dr(a). {target_profile['name']},

Encontrei seu perfil através da plataforma LITIG e acredito que sua expertise em {case_area} seria ideal para meu caso.

A plataforma me recomendou você como altamente compatível. Se tiver interesse em saber mais detalhes, pode acessar através deste link:

{claim_url}

Fico no aguardo!

Atenciosamente,
{client_name}"""
    
    async def _update_invitation_status(self, invitation_id: str, status: str):
        """Atualiza status do convite no banco."""
        if self.db_session and HAS_DB:
            try:
                # TODO: Implementar update real na tabela client_invitations
                # query = update(client_invitations_table).where(...).values(status=status)
                # await self.db_session.execute(query)
                # await self.db_session.commit()
                pass
            except Exception as e:
                logger.warning(f"Falha ao atualizar status do convite: {e}")
        
        logger.info("Status do convite atualizado", {
            "invitation_id": invitation_id,
            "new_status": status
        })
    
    async def get_invitation_by_token(self, token: str) -> Optional[PendingInvitation]:
        """Busca convite pelo token."""
        # TODO: Implementar busca real no banco
        # Por enquanto, retornar None (será implementado com a tabela)
        return None
    
    async def accept_invitation(self, token: str, lawyer_data: Dict[str, Any]) -> bool:
        """Processa aceitação de convite e cria perfil de advogado."""
        invitation = await self.get_invitation_by_token(token)
        
        if not invitation:
            logger.warning(f"Token de convite não encontrado: {token}")
            return False
        
        if invitation.expires_at < datetime.utcnow():
            logger.warning(f"Token de convite expirado: {token}")
            return False
        
        try:
            # TODO: Implementar criação de perfil de advogado
            # 1. Criar usuário/advogado na tabela lawyers
            # 2. Associar com o caso original
            # 3. Notificar cliente sobre aceitação
            # 4. Marcar convite como aceito
            
            await self._update_invitation_status(invitation.id, 'accepted')
            
            logger.info("Convite aceito com sucesso", {
                "invitation_id": invitation.id,
                "lawyer_name": lawyer_data.get('name')
            })
            
            return True
            
        except Exception as e:
            logger.error(f"Erro ao processar aceitação de convite: {e}")
            return False
    
    async def get_invitation_analytics(self, 
                                     start_date: datetime, 
                                     end_date: datetime) -> Dict[str, Any]:
        """Retorna analytics de convites para o período."""
        # TODO: Implementar queries de analytics
        return {
            "total_invitations": 0,
            "success_rate_email": 0.0,
            "fallback_rate_linkedin": 0.0,
            "conversion_rate": 0.0,
            "top_areas": [],
            "response_time_avg_hours": 0.0
        } 