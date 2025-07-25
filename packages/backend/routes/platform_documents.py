from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from uuid import UUID

from auth import get_current_user
from services.document_service import PlatformDocumentService, PlatformDocumentResponse

router = APIRouter(prefix="/platform-documents", tags=["Platform Documents"])

@router.get("/", response_model=List[PlatformDocumentResponse])
async def get_platform_documents_for_lawyer(
    current_user: dict = Depends(get_current_user)
):
    """Retorna a lista de documentos da plataforma relevantes para o advogado."""
    service = PlatformDocumentService()
    return await service.get_documents_for_lawyer(current_user['id'])

@router.post("/{document_id}/accept", status_code=status.HTTP_204_NO_CONTENT)
async def accept_platform_document(
    document_id: UUID,
    current_user: dict = Depends(get_current_user)
):
    """Registra o aceite de um documento da plataforma pelo advogado."""
    service = PlatformDocumentService()
    success = await service.accept_document(current_user['id'], document_id)
    if not success:
        raise HTTPException(status_code=400, detail="Não foi possível aceitar o documento.")
    return None

@router.get("/{document_id}/download-url", response_model=dict)
async def get_document_download_url(
    document_id: UUID,
    current_user: dict = Depends(get_current_user)
):
    """Obtém uma URL de download segura e temporária para um documento."""
    service = PlatformDocumentService()
    url_data = await service.get_document_download_url(current_user['id'], document_id)
    if not url_data:
        raise HTTPException(status_code=404, detail="Documento não encontrado ou acesso negado.")
    return {"url": url_data} 