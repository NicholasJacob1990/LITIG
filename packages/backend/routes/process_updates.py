"""
Endpoints para Atualização de Processos via Escavador
"""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from auth import get_current_user
from models.user import User
from services.escavador_integration import EscavadorClient

# Configuração
ESCAVADOR_API_KEY = "dummy"  # Será substituído pela injeção de dependência
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/process-updates", tags=["Process Updates"])

# Pydantic Schemas
class UpdateRequestResponse(BaseModel):
    id: int
    status: str
    numero_cnj: str
    criado_em: str
    concluido_em: Optional[str] = None

class UpdateStatusResponse(BaseModel):
    numero_cnj: str
    data_ultima_verificacao: Optional[str]
    tempo_desde_ultima_verificacao: Optional[str]
    ultima_verificacao: Optional[UpdateRequestResponse] = None

class CaseFilesRequestResponse(BaseModel):
    async_id: str
    numero_cnj: str
    status: str
    mensagem: str
    certificado_utilizado: Optional[int] = None

class CaseFilesStatusResponse(BaseModel):
    async_id: str
    numero_cnj: str
    status: str  # PENDENTE, SUCESSO, ERRO
    dados_disponíveis: bool
    instancias: Optional[int] = None
    documentos_encontrados: Optional[int] = None

class CaseFilesDownloadResponse(BaseModel):
    numero_cnj: str
    async_id: str
    total_arquivos: int
    arquivos_baixados: list
    diretorio_saida: str

# Dependency
def get_escavador_client() -> EscavadorClient:
    """Injeta o cliente do Escavador com a API key."""
    import os
    api_key = os.getenv("ESCAVADOR_API_KEY")
    if not api_key:
        raise HTTPException(
            status_code=500, 
            detail="Configuração da API do Escavador não encontrada"
        )
    return EscavadorClient(api_key=api_key)

@router.post("/{cnj}/request", response_model=UpdateRequestResponse)
async def request_process_update(
    cnj: str,
    download_docs: bool = Query(False, description="Se deve baixar documentos públicos"),
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client)
):
    """
    Solicita a atualização de um processo nos sistemas dos Tribunais.
    
    Esta funcionalidade força o Escavador a buscar informações atualizadas
    diretamente nos sistemas dos tribunais.
    """
    try:
        result = await escavador_client.request_process_update(cnj, download_docs)
        
        return UpdateRequestResponse(
            id=result.get("id", 0),
            status=result.get("status", "PENDENTE"),
            numero_cnj=cnj,
            criado_em=result.get("criado_em", ""),
            concluido_em=result.get("concluido_em")
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Erro ao solicitar atualização do processo {cnj}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.get("/{cnj}/status", response_model=UpdateStatusResponse)
async def get_process_update_status(
    cnj: str,
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client)
):
    """
    Consulta o status de uma solicitação de atualização de processo.
    """
    try:
        result = await escavador_client.get_process_update_status(cnj)
        
        return UpdateStatusResponse(
            numero_cnj=cnj,
            data_ultima_verificacao=result.get("data_ultima_verificacao"),
            tempo_desde_ultima_verificacao=result.get("tempo_desde_ultima_verificacao"),
            ultima_verificacao=UpdateRequestResponse(
                id=result.get("ultima_verificacao", {}).get("id", 0),
                status=result.get("ultima_verificacao", {}).get("status", ""),
                numero_cnj=cnj,
                criado_em=result.get("ultima_verificacao", {}).get("criado_em", ""),
                concluido_em=result.get("ultima_verificacao", {}).get("concluido_em")
            ) if result.get("ultima_verificacao") else None
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Erro ao consultar status do processo {cnj}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.post("/{cnj}/request-case-files", response_model=CaseFilesRequestResponse)
async def request_case_files_with_certificate(
    cnj: str,
    certificate_id: Optional[int] = Query(None, description="ID do certificado específico (opcional)"),
    send_callback: bool = Query(True, description="Se deve enviar callback quando concluído"),
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client)
):
    """
    Solicita acesso aos autos de um processo utilizando certificado digital.
    
    IMPORTANTE: Requer certificado digital válido cadastrado no painel do Escavador.
    """
    try:
        result = await escavador_client.request_case_files_with_certificate(
            cnj=cnj,
            certificate_id=certificate_id,
            send_callback=send_callback
        )
        
        resposta = result.get("resposta", {})
        
        return CaseFilesRequestResponse(
            async_id=resposta.get("id", ""),
            numero_cnj=cnj,
            status=resposta.get("status", "PENDENTE"),
            mensagem=resposta.get("mensagem", "Solicitação enviada com sucesso"),
            certificado_utilizado=certificate_id
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Erro ao solicitar autos do processo {cnj}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.get("/case-files/{async_id}/status", response_model=CaseFilesStatusResponse)
async def get_case_files_status(
    async_id: str,
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client)
):
    """
    Consulta o status de uma solicitação de autos com certificado digital.
    """
    try:
        result = await escavador_client.get_case_files_status(async_id)
        
        resposta = result.get("resposta", {})
        resposta_data = resposta.get("resposta", {})
        
        # Contar instâncias e documentos se disponível
        instancias_count = len(resposta_data.get("instancias", []))
        documentos_count = 0
        for instancia in resposta_data.get("instancias", []):
            documentos_count += len(instancia.get("documentos", []))
        
        return CaseFilesStatusResponse(
            async_id=async_id,
            numero_cnj=resposta_data.get("numero_cnj", ""),
            status=resposta.get("status", "DESCONHECIDO"),
            dados_disponíveis=resposta.get("status") == "SUCESSO",
            instancias=instancias_count if instancias_count > 0 else None,
            documentos_encontrados=documentos_count if documentos_count > 0 else None
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Erro ao consultar status da solicitação {async_id}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.post("/case-files/{async_id}/download", response_model=CaseFilesDownloadResponse)
async def download_case_files(
    async_id: str,
    cnj: str = Query(..., description="Número CNJ do processo"),
    output_directory: str = Query("./downloads", description="Diretório para salvar os arquivos"),
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client)
):
    """
    Baixa os arquivos dos autos após a conclusão da solicitação.
    
    ATENÇÃO: Esta operação pode demorar dependendo do tamanho dos arquivos.
    """
    try:
        result = await escavador_client.download_case_files(
            cnj=cnj,
            async_id=async_id,
            output_directory=output_directory
        )
        
        return CaseFilesDownloadResponse(
            numero_cnj=result["cnj"],
            async_id=result["async_id"],
            total_arquivos=result["total_files"],
            arquivos_baixados=result["downloaded_files"],
            diretorio_saida=result["output_directory"]
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Erro ao baixar arquivos da solicitação {async_id}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor") 
Endpoints para Atualização de Processos via Escavador
"""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from auth import get_current_user
from models.user import User
from services.escavador_integration import EscavadorClient

# Configuração
ESCAVADOR_API_KEY = "dummy"  # Será substituído pela injeção de dependência
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/process-updates", tags=["Process Updates"])

# Pydantic Schemas
class UpdateRequestResponse(BaseModel):
    id: int
    status: str
    numero_cnj: str
    criado_em: str
    concluido_em: Optional[str] = None

class UpdateStatusResponse(BaseModel):
    numero_cnj: str
    data_ultima_verificacao: Optional[str]
    tempo_desde_ultima_verificacao: Optional[str]
    ultima_verificacao: Optional[UpdateRequestResponse] = None

class CaseFilesRequestResponse(BaseModel):
    async_id: str
    numero_cnj: str
    status: str
    mensagem: str
    certificado_utilizado: Optional[int] = None

class CaseFilesStatusResponse(BaseModel):
    async_id: str
    numero_cnj: str
    status: str  # PENDENTE, SUCESSO, ERRO
    dados_disponíveis: bool
    instancias: Optional[int] = None
    documentos_encontrados: Optional[int] = None

class CaseFilesDownloadResponse(BaseModel):
    numero_cnj: str
    async_id: str
    total_arquivos: int
    arquivos_baixados: list
    diretorio_saida: str

# Dependency
def get_escavador_client() -> EscavadorClient:
    """Injeta o cliente do Escavador com a API key."""
    import os
    api_key = os.getenv("ESCAVADOR_API_KEY")
    if not api_key:
        raise HTTPException(
            status_code=500, 
            detail="Configuração da API do Escavador não encontrada"
        )
    return EscavadorClient(api_key=api_key)

@router.post("/{cnj}/request", response_model=UpdateRequestResponse)
async def request_process_update(
    cnj: str,
    download_docs: bool = Query(False, description="Se deve baixar documentos públicos"),
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client)
):
    """
    Solicita a atualização de um processo nos sistemas dos Tribunais.
    
    Esta funcionalidade força o Escavador a buscar informações atualizadas
    diretamente nos sistemas dos tribunais.
    """
    try:
        result = await escavador_client.request_process_update(cnj, download_docs)
        
        return UpdateRequestResponse(
            id=result.get("id", 0),
            status=result.get("status", "PENDENTE"),
            numero_cnj=cnj,
            criado_em=result.get("criado_em", ""),
            concluido_em=result.get("concluido_em")
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Erro ao solicitar atualização do processo {cnj}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.get("/{cnj}/status", response_model=UpdateStatusResponse)
async def get_process_update_status(
    cnj: str,
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client)
):
    """
    Consulta o status de uma solicitação de atualização de processo.
    """
    try:
        result = await escavador_client.get_process_update_status(cnj)
        
        return UpdateStatusResponse(
            numero_cnj=cnj,
            data_ultima_verificacao=result.get("data_ultima_verificacao"),
            tempo_desde_ultima_verificacao=result.get("tempo_desde_ultima_verificacao"),
            ultima_verificacao=UpdateRequestResponse(
                id=result.get("ultima_verificacao", {}).get("id", 0),
                status=result.get("ultima_verificacao", {}).get("status", ""),
                numero_cnj=cnj,
                criado_em=result.get("ultima_verificacao", {}).get("criado_em", ""),
                concluido_em=result.get("ultima_verificacao", {}).get("concluido_em")
            ) if result.get("ultima_verificacao") else None
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Erro ao consultar status do processo {cnj}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.post("/{cnj}/request-case-files", response_model=CaseFilesRequestResponse)
async def request_case_files_with_certificate(
    cnj: str,
    certificate_id: Optional[int] = Query(None, description="ID do certificado específico (opcional)"),
    send_callback: bool = Query(True, description="Se deve enviar callback quando concluído"),
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client)
):
    """
    Solicita acesso aos autos de um processo utilizando certificado digital.
    
    IMPORTANTE: Requer certificado digital válido cadastrado no painel do Escavador.
    """
    try:
        result = await escavador_client.request_case_files_with_certificate(
            cnj=cnj,
            certificate_id=certificate_id,
            send_callback=send_callback
        )
        
        resposta = result.get("resposta", {})
        
        return CaseFilesRequestResponse(
            async_id=resposta.get("id", ""),
            numero_cnj=cnj,
            status=resposta.get("status", "PENDENTE"),
            mensagem=resposta.get("mensagem", "Solicitação enviada com sucesso"),
            certificado_utilizado=certificate_id
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Erro ao solicitar autos do processo {cnj}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.get("/case-files/{async_id}/status", response_model=CaseFilesStatusResponse)
async def get_case_files_status(
    async_id: str,
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client)
):
    """
    Consulta o status de uma solicitação de autos com certificado digital.
    """
    try:
        result = await escavador_client.get_case_files_status(async_id)
        
        resposta = result.get("resposta", {})
        resposta_data = resposta.get("resposta", {})
        
        # Contar instâncias e documentos se disponível
        instancias_count = len(resposta_data.get("instancias", []))
        documentos_count = 0
        for instancia in resposta_data.get("instancias", []):
            documentos_count += len(instancia.get("documentos", []))
        
        return CaseFilesStatusResponse(
            async_id=async_id,
            numero_cnj=resposta_data.get("numero_cnj", ""),
            status=resposta.get("status", "DESCONHECIDO"),
            dados_disponíveis=resposta.get("status") == "SUCESSO",
            instancias=instancias_count if instancias_count > 0 else None,
            documentos_encontrados=documentos_count if documentos_count > 0 else None
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Erro ao consultar status da solicitação {async_id}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.post("/case-files/{async_id}/download", response_model=CaseFilesDownloadResponse)
async def download_case_files(
    async_id: str,
    cnj: str = Query(..., description="Número CNJ do processo"),
    output_directory: str = Query("./downloads", description="Diretório para salvar os arquivos"),
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client)
):
    """
    Baixa os arquivos dos autos após a conclusão da solicitação.
    
    ATENÇÃO: Esta operação pode demorar dependendo do tamanho dos arquivos.
    """
    try:
        result = await escavador_client.download_case_files(
            cnj=cnj,
            async_id=async_id,
            output_directory=output_directory
        )
        
        return CaseFilesDownloadResponse(
            numero_cnj=result["cnj"],
            async_id=result["async_id"],
            total_arquivos=result["total_files"],
            arquivos_baixados=result["downloaded_files"],
            diretorio_saida=result["output_directory"]
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Erro ao baixar arquivos da solicitação {async_id}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor") 
Endpoints para Atualização de Processos via Escavador
"""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from auth import get_current_user
from models.user import User
from services.escavador_integration import EscavadorClient

# Configuração
ESCAVADOR_API_KEY = "dummy"  # Será substituído pela injeção de dependência
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/process-updates", tags=["Process Updates"])

# Pydantic Schemas
class UpdateRequestResponse(BaseModel):
    id: int
    status: str
    numero_cnj: str
    criado_em: str
    concluido_em: Optional[str] = None

class UpdateStatusResponse(BaseModel):
    numero_cnj: str
    data_ultima_verificacao: Optional[str]
    tempo_desde_ultima_verificacao: Optional[str]
    ultima_verificacao: Optional[UpdateRequestResponse] = None

class CaseFilesRequestResponse(BaseModel):
    async_id: str
    numero_cnj: str
    status: str
    mensagem: str
    certificado_utilizado: Optional[int] = None

class CaseFilesStatusResponse(BaseModel):
    async_id: str
    numero_cnj: str
    status: str  # PENDENTE, SUCESSO, ERRO
    dados_disponíveis: bool
    instancias: Optional[int] = None
    documentos_encontrados: Optional[int] = None

class CaseFilesDownloadResponse(BaseModel):
    numero_cnj: str
    async_id: str
    total_arquivos: int
    arquivos_baixados: list
    diretorio_saida: str

# Dependency
def get_escavador_client() -> EscavadorClient:
    """Injeta o cliente do Escavador com a API key."""
    import os
    api_key = os.getenv("ESCAVADOR_API_KEY")
    if not api_key:
        raise HTTPException(
            status_code=500, 
            detail="Configuração da API do Escavador não encontrada"
        )
    return EscavadorClient(api_key=api_key)

@router.post("/{cnj}/request", response_model=UpdateRequestResponse)
async def request_process_update(
    cnj: str,
    download_docs: bool = Query(False, description="Se deve baixar documentos públicos"),
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client)
):
    """
    Solicita a atualização de um processo nos sistemas dos Tribunais.
    
    Esta funcionalidade força o Escavador a buscar informações atualizadas
    diretamente nos sistemas dos tribunais.
    """
    try:
        result = await escavador_client.request_process_update(cnj, download_docs)
        
        return UpdateRequestResponse(
            id=result.get("id", 0),
            status=result.get("status", "PENDENTE"),
            numero_cnj=cnj,
            criado_em=result.get("criado_em", ""),
            concluido_em=result.get("concluido_em")
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Erro ao solicitar atualização do processo {cnj}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.get("/{cnj}/status", response_model=UpdateStatusResponse)
async def get_process_update_status(
    cnj: str,
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client)
):
    """
    Consulta o status de uma solicitação de atualização de processo.
    """
    try:
        result = await escavador_client.get_process_update_status(cnj)
        
        return UpdateStatusResponse(
            numero_cnj=cnj,
            data_ultima_verificacao=result.get("data_ultima_verificacao"),
            tempo_desde_ultima_verificacao=result.get("tempo_desde_ultima_verificacao"),
            ultima_verificacao=UpdateRequestResponse(
                id=result.get("ultima_verificacao", {}).get("id", 0),
                status=result.get("ultima_verificacao", {}).get("status", ""),
                numero_cnj=cnj,
                criado_em=result.get("ultima_verificacao", {}).get("criado_em", ""),
                concluido_em=result.get("ultima_verificacao", {}).get("concluido_em")
            ) if result.get("ultima_verificacao") else None
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Erro ao consultar status do processo {cnj}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.post("/{cnj}/request-case-files", response_model=CaseFilesRequestResponse)
async def request_case_files_with_certificate(
    cnj: str,
    certificate_id: Optional[int] = Query(None, description="ID do certificado específico (opcional)"),
    send_callback: bool = Query(True, description="Se deve enviar callback quando concluído"),
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client)
):
    """
    Solicita acesso aos autos de um processo utilizando certificado digital.
    
    IMPORTANTE: Requer certificado digital válido cadastrado no painel do Escavador.
    """
    try:
        result = await escavador_client.request_case_files_with_certificate(
            cnj=cnj,
            certificate_id=certificate_id,
            send_callback=send_callback
        )
        
        resposta = result.get("resposta", {})
        
        return CaseFilesRequestResponse(
            async_id=resposta.get("id", ""),
            numero_cnj=cnj,
            status=resposta.get("status", "PENDENTE"),
            mensagem=resposta.get("mensagem", "Solicitação enviada com sucesso"),
            certificado_utilizado=certificate_id
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Erro ao solicitar autos do processo {cnj}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.get("/case-files/{async_id}/status", response_model=CaseFilesStatusResponse)
async def get_case_files_status(
    async_id: str,
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client)
):
    """
    Consulta o status de uma solicitação de autos com certificado digital.
    """
    try:
        result = await escavador_client.get_case_files_status(async_id)
        
        resposta = result.get("resposta", {})
        resposta_data = resposta.get("resposta", {})
        
        # Contar instâncias e documentos se disponível
        instancias_count = len(resposta_data.get("instancias", []))
        documentos_count = 0
        for instancia in resposta_data.get("instancias", []):
            documentos_count += len(instancia.get("documentos", []))
        
        return CaseFilesStatusResponse(
            async_id=async_id,
            numero_cnj=resposta_data.get("numero_cnj", ""),
            status=resposta.get("status", "DESCONHECIDO"),
            dados_disponíveis=resposta.get("status") == "SUCESSO",
            instancias=instancias_count if instancias_count > 0 else None,
            documentos_encontrados=documentos_count if documentos_count > 0 else None
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Erro ao consultar status da solicitação {async_id}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.post("/case-files/{async_id}/download", response_model=CaseFilesDownloadResponse)
async def download_case_files(
    async_id: str,
    cnj: str = Query(..., description="Número CNJ do processo"),
    output_directory: str = Query("./downloads", description="Diretório para salvar os arquivos"),
    current_user: User = Depends(get_current_user),
    escavador_client: EscavadorClient = Depends(get_escavador_client)
):
    """
    Baixa os arquivos dos autos após a conclusão da solicitação.
    
    ATENÇÃO: Esta operação pode demorar dependendo do tamanho dos arquivos.
    """
    try:
        result = await escavador_client.download_case_files(
            cnj=cnj,
            async_id=async_id,
            output_directory=output_directory
        )
        
        return CaseFilesDownloadResponse(
            numero_cnj=result["cnj"],
            async_id=result["async_id"],
            total_arquivos=result["total_files"],
            arquivos_baixados=result["downloaded_files"],
            diretorio_saida=result["output_directory"]
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Erro ao baixar arquivos da solicitação {async_id}: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor") 