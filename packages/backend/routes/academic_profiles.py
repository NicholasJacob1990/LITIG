#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
routes/academic_profiles.py

API endpoints para acessar perfis acadêmicos enriquecidos.
"""

from fastapi import APIRouter, Depends, HTTPException, Path
from typing import Optional

from services.academic_enrichment_service import (
    academic_enrichment_service,
    PerfilAcademico
)
# Supondo que você tenha um sistema de autenticação
# from dependencies.auth import get_current_user

router = APIRouter(
    prefix="/persons",
    tags=["Academic Profiles"],
    # dependencies=[Depends(get_current_user)] # Ativar em produção
)


@router.get(
    "/{person_id}/academic-profile",
    response_model=PerfilAcademico,
    summary="Obter Perfil Acadêmico Enriquecido",
    description="Busca e retorna o perfil acadêmico de uma pessoa, incluindo dados do Currículo Lattes, a partir da API do Escavador."
)
async def get_enriched_academic_profile(
    person_id: int = Path(..., title="ID da Pessoa no Escavador", ge=1)
):
    """
    Endpoint para obter o perfil acadêmico de uma pessoa.

    - **person_id**: O identificador numérico da pessoa no Escavador.
    """
    try:
        profile = await academic_enrichment_service.get_academic_profile(person_id)
        return profile
    except HTTPException as e:
        # Repassa exceções HTTP já tratadas pelo serviço
        raise e
    except Exception as e:
        # Captura exceções genéricas
        raise HTTPException(status_code=500, detail=f"Ocorreu um erro inesperado: {str(e)}") 
# -*- coding: utf-8 -*-
"""
routes/academic_profiles.py

API endpoints para acessar perfis acadêmicos enriquecidos.
"""

from fastapi import APIRouter, Depends, HTTPException, Path
from typing import Optional

from services.academic_enrichment_service import (
    academic_enrichment_service,
    PerfilAcademico
)
# Supondo que você tenha um sistema de autenticação
# from dependencies.auth import get_current_user

router = APIRouter(
    prefix="/persons",
    tags=["Academic Profiles"],
    # dependencies=[Depends(get_current_user)] # Ativar em produção
)


@router.get(
    "/{person_id}/academic-profile",
    response_model=PerfilAcademico,
    summary="Obter Perfil Acadêmico Enriquecido",
    description="Busca e retorna o perfil acadêmico de uma pessoa, incluindo dados do Currículo Lattes, a partir da API do Escavador."
)
async def get_enriched_academic_profile(
    person_id: int = Path(..., title="ID da Pessoa no Escavador", ge=1)
):
    """
    Endpoint para obter o perfil acadêmico de uma pessoa.

    - **person_id**: O identificador numérico da pessoa no Escavador.
    """
    try:
        profile = await academic_enrichment_service.get_academic_profile(person_id)
        return profile
    except HTTPException as e:
        # Repassa exceções HTTP já tratadas pelo serviço
        raise e
    except Exception as e:
        # Captura exceções genéricas
        raise HTTPException(status_code=500, detail=f"Ocorreu um erro inesperado: {str(e)}") 
# -*- coding: utf-8 -*-
"""
routes/academic_profiles.py

API endpoints para acessar perfis acadêmicos enriquecidos.
"""

from fastapi import APIRouter, Depends, HTTPException, Path
from typing import Optional

from services.academic_enrichment_service import (
    academic_enrichment_service,
    PerfilAcademico
)
# Supondo que você tenha um sistema de autenticação
# from dependencies.auth import get_current_user

router = APIRouter(
    prefix="/persons",
    tags=["Academic Profiles"],
    # dependencies=[Depends(get_current_user)] # Ativar em produção
)


@router.get(
    "/{person_id}/academic-profile",
    response_model=PerfilAcademico,
    summary="Obter Perfil Acadêmico Enriquecido",
    description="Busca e retorna o perfil acadêmico de uma pessoa, incluindo dados do Currículo Lattes, a partir da API do Escavador."
)
async def get_enriched_academic_profile(
    person_id: int = Path(..., title="ID da Pessoa no Escavador", ge=1)
):
    """
    Endpoint para obter o perfil acadêmico de uma pessoa.

    - **person_id**: O identificador numérico da pessoa no Escavador.
    """
    try:
        profile = await academic_enrichment_service.get_academic_profile(person_id)
        return profile
    except HTTPException as e:
        # Repassa exceções HTTP já tratadas pelo serviço
        raise e
    except Exception as e:
        # Captura exceções genéricas
        raise HTTPException(status_code=500, detail=f"Ocorreu um erro inesperado: {str(e)}") 