#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Partnership Invitation Service
==============================

Serviço para gerenciar convites de parceria para perfis externos.
Implementa o sistema de "Assisted Notification via LinkedIn".
"""

import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_
from sqlalchemy.orm import selectinload

from ..models.partnership_invitation import PartnershipInvitation

logger = logging.getLogger(__name__)


class PartnershipInvitationService:
    """Serviço para gerenciar convites de parceria."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.logger = logging.getLogger(__name__)
    
    async def create_invitation(
        self,
        inviter_lawyer_id: str,
        inviter_name: str,
        external_profile: Dict[str, Any],
        partnership_context: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Cria um convite de parceria para perfil externo.
        
        Args:
            inviter_lawyer_id: ID do advogado que está convidando
            inviter_name: Nome do advogado que está convidando
            external_profile: Dados do perfil externo
            partnership_context: Contexto da recomendação (score, motivo, etc.)
        
        Returns:
            Dict com dados do convite e mensagem preparada para LinkedIn
        """
        
        try:
            # Verificar se já existe convite pendente para este perfil
            existing_invite = await self._check_existing_invitation(
                inviter_lawyer_id, 
                external_profile.get('profile_url', '')
            )
            
            if existing_invite:
                self.logger.warning(f"Convite já existe para {external_profile.get('full_name')}")
                return {
                    "status": "already_exists",
                    "invitation_id": str(existing_invite.id),
                    "message": "Convite já foi enviado para este perfil",
                    "existing_invite": existing_invite.to_dict()
                }
            
            # Criar novo convite
            invitation = PartnershipInvitation(
                inviter_lawyer_id=inviter_lawyer_id,
                inviter_name=inviter_name,
                invitee_name=external_profile.get('full_name', 'Profissional'),
                invitee_profile_url=external_profile.get('profile_url'),
                invitee_context=external_profile,
                area_expertise=partnership_context.get('area_expertise'),
                compatibility_score=partnership_context.get('compatibility_score'),
                partnership_reason=partnership_context.get('partnership_reason'),
            )
            
            # Gerar mensagem personalizada para LinkedIn
            linkedin_message = self._generate_linkedin_message(
                inviter_name, invitation.invitee_name,
                partnership_context, invitation.claim_url
            )
            invitation.linkedin_message_template = linkedin_message
            
            # Salvar no banco
            self.db.add(invitation)
            await self.db.commit()
            await self.db.refresh(invitation)
            
            self.logger.info(f"Convite criado: {invitation.id} por {inviter_lawyer_id}")
            
            return {
                "status": "created",
                "invitation_id": str(invitation.id),
                "claim_url": invitation.claim_url,
                "linkedin_message": linkedin_message,
                "invitee_profile_url": external_profile.get('profile_url'),
                "expires_at": invitation.expires_at.isoformat(),
                "invitation_data": invitation.to_dict()
            }
            
        except Exception as e:
            await self.db.rollback()
            self.logger.error(f"Erro ao criar convite: {e}")
            raise Exception(f"Erro interno ao criar convite: {str(e)}")
    
    async def get_invitations_by_inviter(
        self, 
        inviter_lawyer_id: str,
        status_filter: Optional[str] = None,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """
        Busca convites enviados por um advogado.
        
        Args:
            inviter_lawyer_id: ID do advogado
            status_filter: Filtro por status (pending, accepted, expired, cancelled)
            limit: Limite de resultados
        
        Returns:
            Lista de convites
        """
        
        try:
            query = select(PartnershipInvitation).where(
                PartnershipInvitation.inviter_lawyer_id == inviter_lawyer_id
            ).order_by(PartnershipInvitation.created_at.desc()).limit(limit)
            
            if status_filter:
                query = query.where(PartnershipInvitation.status == status_filter)
            
            result = await self.db.execute(query)
            invitations = result.scalars().all()
            
            # Atualizar status de convites expirados
            await self._update_expired_invitations(invitations)
            
            return [inv.to_dict() for inv in invitations]
            
        except Exception as e:
            self.logger.error(f"Erro ao buscar convites: {e}")
            return []
    
    async def accept_invitation(
        self, 
        token: str, 
        new_lawyer_id: str
    ) -> Dict[str, Any]:
        """
        Aceita um convite usando o token.
        
        Args:
            token: Token único do convite
            new_lawyer_id: ID do novo advogado cadastrado
        
        Returns:
            Dict com dados do convite aceito
        """
        
        try:
            # Buscar convite pelo token
            query = select(PartnershipInvitation).where(
                PartnershipInvitation.token == token
            )
            result = await self.db.execute(query)
            invitation = result.scalar_one_or_none()
            
            if not invitation:
                return {
                    "status": "not_found",
                    "message": "Convite não encontrado"
                }
            
            if invitation.is_expired():
                invitation.expire()
                await self.db.commit()
                return {
                    "status": "expired",
                    "message": "Convite expirado"
                }
            
            if invitation.status != 'pending':
                return {
                    "status": "already_processed",
                    "message": f"Convite já foi {invitation.status}",
                    "invitation_data": invitation.to_dict()
                }
            
            # Aceitar convite
            invitation.accept(new_lawyer_id)
            await self.db.commit()
            
            self.logger.info(f"Convite aceito: {invitation.id} por {new_lawyer_id}")
            
            return {
                "status": "accepted",
                "message": "Convite aceito com sucesso",
                "invitation_data": invitation.to_dict(),
                "inviter_data": {
                    "lawyer_id": invitation.inviter_lawyer_id,
                    "name": invitation.inviter_name
                }
            }
            
        except Exception as e:
            await self.db.rollback()
            self.logger.error(f"Erro ao aceitar convite: {e}")
            raise Exception(f"Erro interno ao aceitar convite: {str(e)}")
    
    async def get_invitation_by_token(self, token: str) -> Optional[Dict[str, Any]]:
        """Busca convite pelo token."""
        
        try:
            query = select(PartnershipInvitation).where(
                PartnershipInvitation.token == token
            )
            result = await self.db.execute(query)
            invitation = result.scalar_one_or_none()
            
            if invitation:
                # Verificar se expirou
                if invitation.is_expired() and invitation.status == 'pending':
                    invitation.expire()
                    await self.db.commit()
                
                return invitation.to_dict()
            
            return None
            
        except Exception as e:
            self.logger.error(f"Erro ao buscar convite por token: {e}")
            return None
    
    async def cancel_invitation(self, invitation_id: str, inviter_lawyer_id: str) -> bool:
        """Cancela um convite."""
        
        try:
            query = select(PartnershipInvitation).where(
                and_(
                    PartnershipInvitation.id == invitation_id,
                    PartnershipInvitation.inviter_lawyer_id == inviter_lawyer_id,
                    PartnershipInvitation.status == 'pending'
                )
            )
            result = await self.db.execute(query)
            invitation = result.scalar_one_or_none()
            
            if invitation:
                invitation.cancel()
                await self.db.commit()
                self.logger.info(f"Convite cancelado: {invitation_id}")
                return True
            
            return False
            
        except Exception as e:
            await self.db.rollback()
            self.logger.error(f"Erro ao cancelar convite: {e}")
            return False
    
    async def _check_existing_invitation(
        self, 
        inviter_lawyer_id: str, 
        profile_url: str
    ) -> Optional[PartnershipInvitation]:
        """Verifica se já existe convite pendente para o mesmo perfil."""
        
        if not profile_url:
            return None
        
        query = select(PartnershipInvitation).where(
            and_(
                PartnershipInvitation.inviter_lawyer_id == inviter_lawyer_id,
                PartnershipInvitation.invitee_profile_url == profile_url,
                PartnershipInvitation.status == 'pending'
            )
        )
        result = await self.db.execute(query)
        return result.scalar_one_or_none()
    
    async def _update_expired_invitations(self, invitations: List[PartnershipInvitation]) -> None:
        """Atualiza status de convites expirados."""
        
        expired_invitations = [inv for inv in invitations if inv.is_expired() and inv.status == 'pending']
        
        if expired_invitations:
            for invitation in expired_invitations:
                invitation.expire()
            await self.db.commit()
            self.logger.info(f"Marcados {len(expired_invitations)} convites como expirados")
    
    def _generate_linkedin_message(
        self, 
        inviter_name: str,
        invitee_name: str,
        partnership_context: Dict[str, Any],
        claim_url: str
    ) -> str:
        """
        Gera mensagem personalizada para LinkedIn.
        
        Esta mensagem será copiada pelo usuário e enviada manualmente,
        protegendo a marca LinkedIn da empresa.
        """
        
        area_expertise = partnership_context.get('area_expertise', 'sua área de especialização')
        compatibility_score = partnership_context.get('compatibility_score', 'alta')
        
        # Template da mensagem
        message_template = f"""Olá {invitee_name}!

Sou {inviter_name} e descobri seu perfil através da plataforma LITIG. 

Nossos perfis profissionais têm uma compatibilidade de {compatibility_score} para parcerias estratégicas, especialmente em {area_expertise}.

A LITIG é uma plataforma que conecta advogados para colaborações e parcerias. Gostaria de convidá-lo(a) para conhecer a plataforma e explorarmos oportunidades de trabalho conjunto.

Para acessar seu convite personalizado:
{claim_url}

Aguardo seu contato!

Atenciosamente,
{inviter_name}"""
        
        return message_template.strip()
    
    async def get_invitation_stats(self, inviter_lawyer_id: str) -> Dict[str, Any]:
        """Retorna estatísticas de convites para um advogado."""
        
        try:
            from sqlalchemy import func
            
            # Query para contar convites por status
            query = select(
                PartnershipInvitation.status,
                func.count(PartnershipInvitation.id).label('count')
            ).where(
                PartnershipInvitation.inviter_lawyer_id == inviter_lawyer_id
            ).group_by(PartnershipInvitation.status)
            
            result = await self.db.execute(query)
            status_counts = {row.status: row.count for row in result.fetchall()}
            
            # Calcular métricas
            total_sent = sum(status_counts.values())
            accepted = status_counts.get('accepted', 0)
            pending = status_counts.get('pending', 0)
            expired = status_counts.get('expired', 0)
            
            acceptance_rate = (accepted / total_sent * 100) if total_sent > 0 else 0
            
            return {
                "total_sent": total_sent,
                "pending": pending,
                "accepted": accepted,
                "expired": expired,
                "cancelled": status_counts.get('cancelled', 0),
                "acceptance_rate": round(acceptance_rate, 1),
                "status_breakdown": status_counts
            }
            
        except Exception as e:
            self.logger.error(f"Erro ao buscar estatísticas: {e}")
            return {
                "total_sent": 0,
                "pending": 0,
                "accepted": 0,
                "expired": 0,
                "cancelled": 0,
                "acceptance_rate": 0.0,
                "status_breakdown": {}
            } 