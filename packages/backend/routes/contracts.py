"""
Rotas para gestão de contratos
"""
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, status, Query
from pydantic import BaseModel, Field

from auth import get_current_user
from models import Contract, ContractStatus, FeeModel
from services.contract_service import ContractService
from services.sign_service import SignService
from logger import AUDIT_LOGGER

router = APIRouter(prefix="/contracts", tags=["contracts"])

# ============================================================================
# DTOs
# ============================================================================


class FeeModelDTO(BaseModel):
    type: str = Field(..., description="Tipo: success, fixed, hourly")
    percent: Optional[float] = Field(None, description="Percentual para success fee")
    value: Optional[float] = Field(None, description="Valor fixo")
    rate: Optional[float] = Field(None, description="Valor por hora")

    class Config:
        schema_extra = {
            "examples": [
                {"type": "success", "percent": 20},
                {"type": "fixed", "value": 5000},
                {"type": "hourly", "rate": 300}
            ]
        }


class CreateContractDTO(BaseModel):
    case_id: str = Field(..., description="ID do caso")
    lawyer_id: str = Field(..., description="ID do advogado")
    fee_model: FeeModelDTO = Field(..., description="Modelo de honorários")


class SignContractDTO(BaseModel):
    role: str = Field(..., description="Papel: client ou lawyer")
    signature_data: Optional[Dict[str, Any]] = Field(
        None, description="Dados da assinatura")


class ContractResponse(BaseModel):
    id: str
    case_id: str
    lawyer_id: str
    client_id: str
    status: str
    fee_model: Dict[str, Any]
    created_at: datetime
    signed_client: Optional[datetime]
    signed_lawyer: Optional[datetime]
    doc_url: Optional[str]
    updated_at: datetime
    # Dados relacionados
    case_title: Optional[str]
    case_area: Optional[str]
    lawyer_name: Optional[str]
    client_name: Optional[str]

# ============================================================================
# Rotas
# ============================================================================


@router.post("/", response_model=ContractResponse)
async def create_contract(
    contract_data: CreateContractDTO,
    current_user: dict = Depends(get_current_user)
):
    """
    Criar novo contrato

    Apenas clientes podem criar contratos para seus próprios casos.
    Valida se existe oferta 'interested' do advogado para o caso.
    """
    try:
        # Validar se o usuário é dono do caso
        contract_service = ContractService()

        # Verificar se caso existe e pertence ao usuário
        case = await contract_service.get_case(contract_data.case_id)
        if not case or case.client_id != current_user["id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Caso não encontrado ou não pertence ao usuário"
            )

        # Verificar se existe oferta interessada do advogado
        offer = await contract_service.get_interested_offer(
            contract_data.case_id,
            contract_data.lawyer_id
        )
        if not offer:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Advogado não demonstrou interesse neste caso"
            )

        # Verificar se já existe contrato ativo para este caso
        existing = await contract_service.get_active_contract_for_case(contract_data.case_id)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Já existe um contrato ativo para este caso"
            )

        # Criar contrato
        contract = await contract_service.create_contract(
            case_id=contract_data.case_id,
            lawyer_id=contract_data.lawyer_id,
            client_id=current_user["id"],
            fee_model=contract_data.fee_model.dict()
        )

        # Gerar PDF do contrato
        sign_service = SignService()
        doc_url = await sign_service.generate_contract_pdf(contract)

        # Atualizar contrato com URL do documento
        await contract_service.update_contract_doc_url(contract.id, doc_url)
        contract.doc_url = doc_url

        return ContractResponse(**contract.dict())

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao criar contrato: {str(e)}"
        )


@router.get("/{contract_id}", response_model=ContractResponse)
async def get_contract(
    contract_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Buscar contrato por ID

    Apenas cliente ou advogado envolvido podem visualizar.
    """
    try:
        contract_service = ContractService()
        contract = await contract_service.get_contract_with_details(contract_id)

        if not contract:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Contrato não encontrado"
            )

        # Verificar permissão
        if contract.client_id != current_user["id"] and contract.lawyer_id != current_user["id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Sem permissão para visualizar este contrato"
            )

        return ContractResponse(**contract.dict())

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar contrato: {str(e)}"
        )


@router.get("/", response_model=List[ContractResponse])
async def list_user_contracts(
    current_user: dict = Depends(get_current_user),
    status_filter: Optional[str] = Query(None, enum=["pending-signature", "active", "closed", "canceled"]),
    limit: int = 20,
    offset: int = 0
):
    """
    Listar contratos do usuário

    Retorna contratos onde o usuário é cliente ou advogado.
    """
    try:
        contract_service = ContractService()
        contracts = await contract_service.get_user_contracts(
            user_id=current_user["id"],
            status_filter=status_filter,
            limit=limit,
            offset=offset
        )

        return [ContractResponse(**contract.dict()) for contract in contracts]

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao listar contratos: {str(e)}"
        )


@router.patch("/{contract_id}/sign", response_model=ContractResponse)
async def sign_contract(
    contract_id: str,
    sign_data: SignContractDTO,
    current_user: dict = Depends(get_current_user)
):
    """
    Assinar contrato

    Cliente ou advogado podem assinar. Quando ambos assinam, contrato fica ativo.
    """
    try:
        contract_service = ContractService()
        contract = await contract_service.get_contract(contract_id)

        if not contract:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Contrato não encontrado"
            )

        # Verificar permissão e papel
        user_role = None
        if contract.client_id == current_user["id"]:
            user_role = "client"
        elif contract.lawyer_id == current_user["id"]:
            user_role = "lawyer"
        else:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Sem permissão para assinar este contrato"
            )

        # Validar papel informado
        if sign_data.role != user_role:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Papel informado ({
                    sign_data.role}) não corresponde ao usuário ({user_role})"
            )

        # Verificar se já assinou
        if (user_role == "client" and contract.signed_client) or \
           (user_role == "lawyer" and contract.signed_lawyer):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Usuário já assinou este contrato"
            )

        # Assinar e verificar se o contrato ficou ativo
        updated_contract = await contract_service.sign_contract(
            contract_id=contract_id,
            user_id=current_user["id"],
            role=user_role
        )

        # Log de feedback para LTR se o contrato foi ativado
        if updated_contract.status == ContractStatus.ACTIVE:
            AUDIT_LOGGER.info("offer_feedback", {
                "action": "contract",
                "case_id": updated_contract.case_id,
                "lawyer_id": updated_contract.lawyer_id,
                "client_id": updated_contract.client_id,
                "contract_id": updated_contract.id,
            })

        # Chamar Docusign ou outro serviço de assinatura eletrônica, se aplicável
        # ...

        return ContractResponse(**updated_contract.dict())

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao assinar contrato: {str(e)}"
        )


@router.patch("/{contract_id}/cancel", response_model=ContractResponse)
async def cancel_contract(
    contract_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Cancelar contrato

    Apenas contratos pending-signature podem ser cancelados.
    Cliente ou advogado podem cancelar.
    """
    try:
        contract_service = ContractService()
        contract = await contract_service.get_contract(contract_id)

        if not contract:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Contrato não encontrado"
            )

        # Verificar permissão
        if contract.client_id != current_user["id"] and contract.lawyer_id != current_user["id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Sem permissão para cancelar este contrato"
            )

        # Verificar se pode ser cancelado
        if contract.status != ContractStatus.PENDING_SIGNATURE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Apenas contratos pendentes podem ser cancelados"
            )

        # Cancelar contrato
        updated_contract = await contract_service.cancel_contract(contract_id)

        return ContractResponse(**updated_contract.dict())

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao cancelar contrato: {str(e)}"
        )


@router.get("/{contract_id}/pdf")
async def download_contract_pdf(
    contract_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Download do PDF do contrato
    """
    try:
        contract_service = ContractService()
        contract = await contract_service.get_contract(contract_id)

        if not contract:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Contrato não encontrado"
            )

        # Verificar permissão
        if contract.client_id != current_user["id"] and contract.lawyer_id != current_user["id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Sem permissão para visualizar este contrato"
            )

        if not contract.doc_url:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Documento não encontrado"
            )

        # Retornar URL do documento
        return {"doc_url": contract.doc_url}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar documento: {str(e)}"
        )


@router.get("/{contract_id}/docusign-status")
async def get_docusign_status(
    contract_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Consulta status do envelope DocuSign
    """
    try:
        contract_service = ContractService()
        contract = await contract_service.get_contract(contract_id)

        if not contract:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Contrato não encontrado"
            )

        # Verificar permissão
        if contract.client_id != current_user["id"] and contract.lawyer_id != current_user["id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Sem permissão para visualizar este contrato"
            )

        # Verificar se é envelope DocuSign
        if not contract.doc_url or not contract.doc_url.startswith('envelope_'):
            return {"status": "not_docusign",
                    "message": "Contrato não foi criado via DocuSign"}

        # Consultar status no DocuSign
        sign_service = SignService()
        envelope_id = contract.doc_url
        status_info = await sign_service.get_envelope_status(envelope_id)

        return status_info

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao consultar status DocuSign: {str(e)}"
        )


@router.get("/{contract_id}/docusign-download")
async def download_docusign_document(
    contract_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Download do documento assinado do DocuSign
    """
    try:
        contract_service = ContractService()
        contract = await contract_service.get_contract(contract_id)

        if not contract:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Contrato não encontrado"
            )

        # Verificar permissão
        if contract.client_id != current_user["id"] and contract.lawyer_id != current_user["id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Sem permissão para visualizar este contrato"
            )

        # Verificar se é envelope DocuSign
        if not contract.doc_url or not contract.doc_url.startswith('envelope_'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Contrato não foi criado via DocuSign"
            )

        # Verificar se contrato está assinado
        if not contract.is_fully_signed:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Contrato ainda não foi totalmente assinado"
            )

        # Baixar documento do DocuSign
        sign_service = SignService()
        envelope_id = contract.doc_url
        document_bytes = await sign_service.download_signed_document(envelope_id)

        if not document_bytes:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Documento assinado não encontrado"
            )

        # Retornar documento como resposta de download
        from fastapi.responses import Response
        return Response(
            content=document_bytes,
            media_type="application/pdf",
            headers={
                "Content-Disposition": f"attachment; filename=contrato_{contract_id[:8]}_assinado.pdf"
            }
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao baixar documento DocuSign: {str(e)}"
        )


@router.post("/{contract_id}/sync-docusign")
async def sync_docusign_status(
    contract_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Sincroniza status do contrato com DocuSign
    """
    try:
        contract_service = ContractService()
        contract = await contract_service.get_contract(contract_id)

        if not contract:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Contrato não encontrado"
            )

        # Verificar permissão
        if contract.client_id != current_user["id"] and contract.lawyer_id != current_user["id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Sem permissão para sincronizar este contrato"
            )

        # Verificar se é envelope DocuSign
        if not contract.doc_url or not contract.doc_url.startswith('envelope_'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Contrato não foi criado via DocuSign"
            )

        # Consultar status no DocuSign
        sign_service = SignService()
        envelope_id = contract.doc_url
        status_info = await sign_service.get_envelope_status(envelope_id)

        # Atualizar status do contrato baseado no DocuSign
        if status_info.get("status") == "completed":
            # Verificar quais signatários assinaram
            recipients = status_info.get("recipients", [])

            for recipient in recipients:
                if recipient.get("status") == "completed" and recipient.get(
                        "signed_date"):
                    # Identificar se é cliente ou advogado pelo email
                    if recipient.get(
                            "email") == contract.client_id:  # Assumindo que client_id é email
                        if not contract.signed_client:
                            await contract_service.sign_contract(contract_id, "client")
                    # Assumindo que lawyer_id é email
                    elif recipient.get("email") == contract.lawyer_id:
                        if not contract.signed_lawyer:
                            await contract_service.sign_contract(contract_id, "lawyer")

        # Retornar contrato atualizado
        updated_contract = await contract_service.get_contract(contract_id)
        return ContractResponse(**updated_contract.dict())

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao sincronizar com DocuSign: {str(e)}"
        )

# ============================================================================
# Rotas administrativas (opcional)
# ============================================================================


@router.get("/admin/stats")
async def get_contract_stats(
    current_user: dict = Depends(get_current_user)
):
    """
    Estatísticas de contratos (apenas para admins)
    """
    # TODO: Implementar verificação de admin
    try:
        contract_service = ContractService()
        stats = await contract_service.get_contract_stats()
        return stats

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar estatísticas: {str(e)}"
        )
