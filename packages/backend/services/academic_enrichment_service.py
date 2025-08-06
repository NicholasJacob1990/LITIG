#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
services/academic_enrichment_service.py

Serviço para enriquecimento de perfis profissionais com dados acadêmicos da API do Escavador.
Este serviço busca, processa e estrutura informações do Currículo Lattes.
"""
import asyncio
import logging
from typing import Any, Dict, List, Optional

from fastapi import HTTPException, status
from pydantic import BaseModel, Field

from services.escavador_integration import EscavadorClient
from config.base import ESCAVADOR_API_KEY

logger = logging.getLogger(__name__)


# ============================================================================
# 1. MODELOS PYDANTIC PARA DADOS ACADÊMICOS
# ============================================================================

class FormacaoAcademica(BaseModel):
    """Modelo para formação acadêmica e títulos."""
    ano_inicio: Optional[int] = None
    ano_fim: Optional[int] = None
    tipo: Optional[str] = None
    titulo: Optional[str] = None
    nome_instituicao: Optional[str] = None

class AtuacaoProfissional(BaseModel):
    """Modelo para experiência profissional."""
    ano_inicio: Optional[int] = None
    ano_fim: Optional[int] = None
    descricao: Optional[str] = None
    nome_instituicao: Optional[str] = None

class ProducaoBibliografica(BaseModel):
    """Modelo para produções bibliográficas."""
    ano: Optional[int] = None
    descricao: Optional[str] = None

class ProjetoPesquisa(BaseModel):
    """Modelo para projetos de pesquisa."""
    ano_inicio: Optional[int] = None
    ano_fim: Optional[int] = None
    nome: Optional[str] = None
    descricao: Optional[str] = None

class CurriculoLattes(BaseModel):
    """Modelo estruturado do Currículo Lattes."""
    lattes_id: Optional[str] = None
    resumo: Optional[str] = None
    ultima_atualizacao: Optional[str] = Field(None, alias="ultima_atualizacao")
    areas_de_atuacao: Optional[str] = Field(None, alias="areas_de_atuacao")
    nome_em_citacoes: Optional[str] = Field(None, alias="nome_em_citacoes")
    formacoes: List[FormacaoAcademica] = []
    atuacoes_profissionais: List[AtuacaoProfissional] = Field([], alias="atuacoes_profissionais")
    producoes_bibliograficas: List[ProducaoBibliografica] = Field([], alias="producoes_bibliograficas")
    projetos_pesquisa: List[ProjetoPesquisa] = Field([], alias="projetos")

class PerfilAcademico(BaseModel):
    """Modelo completo do perfil acadêmico enriquecido."""
    id_pessoa: int
    nome: str
    curriculo_lattes: Optional[CurriculoLattes] = None
    tem_curriculo: bool = False
    enriquecido_em: datetime = Field(default_factory=datetime.now)


# ============================================================================
# 2. SERVIÇO DE ENRIQUECIMENTO ACADÊMICO
# ============================================================================

class AcademicEnrichmentService:
    """
    Serviço para buscar e processar dados do Currículo Lattes via API do Escavador.
    """
    def __init__(self):
        if not ESCAVADOR_API_KEY:
            raise ValueError("API Key do Escavador não configurada.")
        
        self.escavador_client = EscavadorClient(api_key=ESCAVADOR_API_KEY)
        logger.info("Serviço de Enriquecimento Acadêmico inicializado.")

    async def get_academic_profile(self, person_id: int) -> PerfilAcademico:
        """
        Busca o perfil acadêmico de uma pessoa pelo seu ID no Escavador.

        Args:
            person_id: ID da pessoa no Escavador.

        Returns:
            Um objeto PerfilAcademico com os dados do currículo.
        """
        logger.info(f"Buscando perfil acadêmico para a pessoa ID: {person_id}")

        try:
            # Chamar o método do cliente Escavador para obter dados da pessoa
            pessoa_data = await self.escavador_client.get_person_details(person_id)

            if not pessoa_data:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Pessoa com ID {person_id} não encontrada."
                )

            # Processar e estruturar os dados do currículo
            return self._process_curriculo_data(pessoa_data)

        except HTTPException as e:
            # Repassar exceções HTTP
            raise e
        except Exception as e:
            logger.error(f"Erro ao buscar perfil acadêmico para ID {person_id}: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Erro interno ao processar dados do Escavador: {e}"
            )

    def _process_curriculo_data(self, pessoa_data: Dict[str, Any]) -> PerfilAcademico:
        """
        Processa os dados brutos da API e os converte em um modelo PerfilAcademico.
        """
        curriculo_data = pessoa_data.get("curriculo_lattes")

        if not curriculo_data:
            return PerfilAcademico(
                id_pessoa=pessoa_data["id"],
                nome=pessoa_data["nome"],
                tem_curriculo=False
            )

        # Mapear e validar os dados usando os modelos Pydantic
        curriculo_lattes = CurriculoLattes(
            lattes_id=curriculo_data.get("lattes_id"),
            resumo=curriculo_data.get("resumo"),
            ultima_atualizacao=curriculo_data.get("ultima_atualizacao"),
            areas_de_atuacao=curriculo_data.get("areas_de_atuacao"),
            nome_em_citacoes=curriculo_data.get("nome_em_citacoes"),
            formacoes=[FormacaoAcademica(**f) for f in curriculo_data.get("formacoes", [])],
            atuacoes_profissionais=[AtuacaoProfissional(**a) for a in curriculo_data.get("atuacoes_profissionais", [])],
            producoes_bibliograficas=[ProducaoBibliografica(**p) for p in curriculo_data.get("producoes_bibliograficas", [])],
            projetos_pesquisa=[ProjetoPesquisa(**p) for p in curriculo_data.get("projetos", [])]
        )

        return PerfilAcademico(
            id_pessoa=pessoa_data["id"],
            nome=pessoa_data["nome"],
            curriculo_lattes=curriculo_lattes,
            tem_curriculo=True
        )

# ============================================================================
# INSTÂNCIA GLOBAL DO SERVIÇO
# ============================================================================

academic_enrichment_service = AcademicEnrichmentService() 