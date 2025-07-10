"""
Rotas para gestão de documentos de casos
"""
from io import BytesIO
from typing import List, Optional

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from ..auth import get_current_user
from ..services.document_service import DocumentService

router = APIRouter(prefix="/documents", tags=["documents"])

# ============================================================================
# DTOs
# ============================================================================


class DocumentResponse(BaseModel):
    id: str
    case_id: str
    uploaded_by: str
    file_name: str
    file_size: int
    file_type: str
    file_url: str
    storage_path: str
    created_at: str
    updated_at: str


class DocumentStatsResponse(BaseModel):
    total_documents: int
    total_size_bytes: int
    total_size_mb: float
    types: dict
    last_upload: Optional[str]

# ============================================================================
# Rotas
# ============================================================================


@router.post("/upload/{case_id}", response_model=DocumentResponse)
async def upload_document(
    case_id: str,
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    """
    Fazer upload de documento para um caso
    """
    try:
        document_service = DocumentService()

        # Ler conteúdo do arquivo
        file_content = await file.read()

        document = await document_service.upload_document(
            case_id=case_id,
            uploaded_by=current_user["id"],
            file_name=file.filename,
            file_content=file_content,
            file_type=file.content_type
        )

        return DocumentResponse(**document)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao fazer upload: {str(e)}"
        )


@router.get("/{document_id}", response_model=DocumentResponse)
async def get_document(
    document_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Buscar documento por ID
    """
    try:
        document_service = DocumentService()
        document = await document_service.get_document(document_id)

        if not document:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Documento não encontrado"
            )

        return DocumentResponse(**document)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar documento: {str(e)}"
        )


@router.get("/{document_id}/download")
async def download_document(
    document_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Fazer download de um documento
    """
    try:
        document_service = DocumentService()

        # Buscar metadados
        document = await document_service.get_document(document_id)
        if not document:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Documento não encontrado"
            )

        # Download do arquivo
        file_content = await document_service.download_document(document_id)
        if not file_content:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Arquivo não encontrado"
            )

        # Retornar arquivo como stream
        return StreamingResponse(
            BytesIO(file_content),
            media_type=document['file_type'],
            headers={
                "Content-Disposition": f"attachment; filename={document['file_name']}"
            }
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao fazer download: {str(e)}"
        )


@router.delete("/{document_id}")
async def delete_document(
    document_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Remover documento
    """
    try:
        document_service = DocumentService()

        success = await document_service.delete_document(document_id, current_user["id"])

        if success:
            return {"message": "Documento removido com sucesso"}
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao remover documento"
            )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao remover documento: {str(e)}"
        )


@router.get("/case/{case_id}", response_model=List[DocumentResponse])
async def get_case_documents(
    case_id: str,
    limit: int = 50,
    current_user: dict = Depends(get_current_user)
):
    """
    Listar todos os documentos de um caso
    """
    try:
        document_service = DocumentService()
        documents = await document_service.get_case_documents(case_id, limit)

        return [DocumentResponse(**document) for document in documents]

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao listar documentos: {str(e)}"
        )


@router.get("/case/{case_id}/preview", response_model=List[DocumentResponse])
async def get_case_documents_preview(
    case_id: str,
    limit: int = 3,
    current_user: dict = Depends(get_current_user)
):
    """
    Buscar preview dos documentos de um caso (limitado)
    """
    try:
        document_service = DocumentService()
        documents = await document_service.get_case_documents_preview(case_id, limit)

        return [DocumentResponse(**document) for document in documents]

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar preview: {str(e)}"
        )


@router.get("/case/{case_id}/stats", response_model=DocumentStatsResponse)
async def get_document_stats(
    case_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Obter estatísticas dos documentos de um caso
    """
    try:
        document_service = DocumentService()
        stats = await document_service.get_document_stats(case_id)

        return DocumentStatsResponse(**stats)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao calcular estatísticas: {str(e)}"
        )
