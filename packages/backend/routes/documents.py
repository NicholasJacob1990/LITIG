#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
routes/documents.py

Endpoints para gerenciamento de documentos com OCR.
Integração com o sistema de extração de dados implementado.
"""

import logging
import os
from datetime import datetime
from typing import Dict, List, Optional
import uuid
import base64
import json

from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from supabase import create_client, Client

from ..auth import get_current_user
from ..services.ocr_validation_service import OCRValidationService

# Configuração Supabase
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")

def get_supabase_client() -> Client:
    """Retorna cliente Supabase"""
    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        raise ValueError("Credenciais do Supabase não configuradas")
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# Logging
logger = logging.getLogger(__name__)

# Router
router = APIRouter(prefix="/documents", tags=["documents"])

# Service instances
ocr_service = OCRValidationService()


# Pydantic Models
class DocumentProcessRequest(BaseModel):
    """Request para processar documento via OCR"""
    image_base64: str = Field(..., description="Imagem em base64")
    case_id: Optional[str] = Field(None, description="ID do caso relacionado")
    document_type_hint: Optional[str] = Field(None, description="Dica do tipo de documento")
    user_id: str = Field(..., description="ID do usuário")
    metadata: Optional[Dict] = Field(default_factory=dict, description="Metadados adicionais")


class DocumentSaveRequest(BaseModel):
    """Request para salvar documento processado"""
    case_id: str = Field(..., description="ID do caso")
    document_name: str = Field(..., description="Nome do documento")
    document_type: str = Field(..., description="Tipo do documento")
    extracted_data: Dict = Field(..., description="Dados extraídos")
    ocr_result: Dict = Field(..., description="Resultado completo do OCR")
    confidence_score: float = Field(..., description="Score de confiança")
    image_base64: Optional[str] = Field(None, description="Imagem original")


class DocumentValidateRequest(BaseModel):
    """Request para validar dados extraídos"""
    extracted_data: Dict = Field(..., description="Dados para validação")


class DocumentResponse(BaseModel):
    """Response padrão para documentos"""
    success: bool
    message: str
    data: Optional[Dict] = None
    document_id: Optional[str] = None


@router.post("/process-ocr", response_model=DocumentResponse)
async def process_document_ocr(
    request: DocumentProcessRequest,
    current_user: Dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """
    Processa documento via OCR e retorna dados extraídos.
    
    Este endpoint recebe uma imagem em base64, processa via OCR,
    extrai dados estruturados e retorna o resultado.
    """
    try:
        logger.info(f"Processando documento OCR para usuário {request.user_id}")
        
        # Validar se o usuário tem permissão
        if current_user["id"] != request.user_id:
            raise HTTPException(status_code=403, detail="Usuário não autorizado")
        
        # Processar documento via OCR
        ocr_result = await ocr_service.process_document_from_base64(
            image_base64=request.image_base64,
            document_type_hint=request.document_type_hint
        )
        
        if not ocr_result.get("success", False):
            raise HTTPException(
                status_code=400, 
                detail=f"Erro no processamento OCR: {ocr_result.get('error', 'Erro desconhecido')}"
            )
        
        # Salvar registro de processamento na base
        processing_record = {
            "id": str(uuid.uuid4()),
            "user_id": request.user_id,
            "case_id": request.case_id,
            "document_type": ocr_result.get("document_type"),
            "extracted_data": ocr_result.get("extracted_data", {}),
            "confidence_score": ocr_result.get("confidence_score", 0.0),
            "processing_method": ocr_result.get("ocr_method", "backend"),
            "created_at": datetime.now().isoformat(),
            "metadata": request.metadata,
            "status": "processed"
        }
        
        # Inserir no Supabase
        result = supabase.table("document_processing_logs").insert(processing_record).execute()
        
        logger.info(f"Documento processado com sucesso. ID: {processing_record['id']}")
        
        return DocumentResponse(
            success=True,
            message="Documento processado com sucesso",
            data={
                "processing_id": processing_record["id"],
                "extracted_data": ocr_result.get("extracted_data", {}),
                "document_type": ocr_result.get("document_type"),
                "confidence_score": ocr_result.get("confidence_score", 0.0),
                "validation": ocr_result.get("validation", {}),
                "ai_enhancement": ocr_result.get("ai_enhancement", {})
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro no processamento OCR: {e}")
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")


@router.post("/save-processed", response_model=DocumentResponse)
async def save_processed_document(
    request: DocumentSaveRequest,
    current_user: Dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """
    Salva documento processado na base de dados do caso.
    
    Este endpoint salva o documento processado e seus dados extraídos
    associando-o a um caso específico.
    """
    try:
        logger.info(f"Salvando documento processado para caso {request.case_id}")
        
        # Verificar se o usuário tem acesso ao caso
        case_result = supabase.table("cases").select("*").eq("id", request.case_id).execute()
        
        if not case_result.data:
            raise HTTPException(status_code=404, detail="Caso não encontrado")
        
        case = case_result.data[0]
        
        # Verificar permissões (owner do caso ou advogado atribuído)
        user_has_access = (
            case.get("client_id") == current_user["id"] or
            case.get("lawyer_id") == current_user["id"] or
            current_user.get("role") == "admin"
        )
        
        if not user_has_access:
            raise HTTPException(status_code=403, detail="Sem acesso ao caso")
        
        # Gerar ID único para o documento
        document_id = str(uuid.uuid4())
        
        # Preparar dados do documento
        document_data = {
            "id": document_id,
            "case_id": request.case_id,
            "name": request.document_name,
            "type": request.document_type,
            "category": "ocr_processed",
            "extracted_data": request.extracted_data,
            "ocr_result": request.ocr_result,
            "confidence_score": request.confidence_score,
            "uploaded_by": current_user["id"],
            "uploaded_at": datetime.now().isoformat(),
            "file_size": len(request.image_base64) if request.image_base64 else 0,
            "processing_metadata": {
                "processed_via_ocr": True,
                "processing_timestamp": datetime.now().isoformat(),
                "extracted_fields": list(request.extracted_data.keys())
            }
        }
        
        # Salvar imagem se fornecida (storage separado)
        image_url = None
        if request.image_base64:
            image_url = await _save_document_image(
                document_id, 
                request.image_base64, 
                supabase
            )
            document_data["image_url"] = image_url
        
        # Inserir documento na tabela
        result = supabase.table("case_documents").insert(document_data).execute()
        
        # Atualizar estatísticas do caso
        await _update_case_stats(request.case_id, supabase)
        
        logger.info(f"Documento salvo com sucesso. ID: {document_id}")
        
        return DocumentResponse(
            success=True,
            message="Documento salvo com sucesso",
            document_id=document_id,
            data={
                "document_id": document_id,
                "case_id": request.case_id,
                "name": request.document_name,
                "type": request.document_type,
                "extracted_data": request.extracted_data,
                "confidence_score": request.confidence_score,
                "image_url": image_url
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao salvar documento: {e}")
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")


@router.post("/validate-data", response_model=DocumentResponse)
async def validate_document_data(
    request: DocumentValidateRequest,
    current_user: Dict = Depends(get_current_user)
):
    """
    Valida dados extraídos de documentos.
    
    Realiza validações específicas para documentos brasileiros
    (CPF, CNPJ, OAB, emails, etc.)
    """
    try:
        logger.info("Validando dados extraídos de documento")
        
        # Validar dados via serviço OCR
        validation_result = await ocr_service.validate_document_data(request.extracted_data)
        
        return DocumentResponse(
            success=True,
            message="Validação concluída",
            data={
                "validation_result": validation_result,
                "validated_fields": validation_result.get("validated_fields", {}),
                "is_valid": validation_result.get("is_valid", False),
                "errors": validation_result.get("errors", []),
                "warnings": validation_result.get("warnings", [])
            }
        )
        
    except Exception as e:
        logger.error(f"Erro na validação de dados: {e}")
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")


@router.get("/case/{case_id}/ocr-documents")
async def get_case_ocr_documents(
    case_id: str,
    current_user: Dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """
    Lista documentos processados via OCR de um caso específico.
    """
    try:
        # Verificar acesso ao caso
        case_result = supabase.table("cases").select("*").eq("id", case_id).execute()
        
        if not case_result.data:
            raise HTTPException(status_code=404, detail="Caso não encontrado")
        
        case = case_result.data[0]
        
        # Verificar permissões
        user_has_access = (
            case.get("client_id") == current_user["id"] or
            case.get("lawyer_id") == current_user["id"] or
            current_user.get("role") == "admin"
        )
        
        if not user_has_access:
            raise HTTPException(status_code=403, detail="Sem acesso ao caso")
        
        # Buscar documentos OCR
        documents_result = supabase.table("case_documents")\
            .select("*")\
            .eq("case_id", case_id)\
            .eq("category", "ocr_processed")\
            .order("uploaded_at", desc=True)\
            .execute()
        
        documents = documents_result.data or []
        
        # Enriquecer com estatísticas
        for doc in documents:
            doc["extracted_field_count"] = len(doc.get("extracted_data", {}))
            doc["has_high_confidence"] = doc.get("confidence_score", 0) > 0.8
        
        return {
            "success": True,
            "case_id": case_id,
            "documents": documents,
            "total_count": len(documents),
            "high_confidence_count": sum(1 for d in documents if d.get("has_high_confidence"))
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar documentos OCR: {e}")
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")


@router.get("/document/{document_id}/details")
async def get_document_details(
    document_id: str,
    current_user: Dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """
    Obtém detalhes completos de um documento processado via OCR.
    """
    try:
        # Buscar documento
        doc_result = supabase.table("case_documents")\
            .select("*")\
            .eq("id", document_id)\
            .execute()
        
        if not doc_result.data:
            raise HTTPException(status_code=404, detail="Documento não encontrado")
        
        document = doc_result.data[0]
        
        # Verificar acesso ao caso relacionado
        case_result = supabase.table("cases").select("*").eq("id", document["case_id"]).execute()
        
        if case_result.data:
            case = case_result.data[0]
            user_has_access = (
                case.get("client_id") == current_user["id"] or
                case.get("lawyer_id") == current_user["id"] or
                current_user.get("role") == "admin"
            )
            
            if not user_has_access:
                raise HTTPException(status_code=403, detail="Sem acesso ao documento")
        
        # Enriquecer com informações do usuário que fez upload
        if document.get("uploaded_by"):
            user_result = supabase.table("users")\
                .select("id, name, email")\
                .eq("id", document["uploaded_by"])\
                .execute()
            
            if user_result.data:
                document["uploaded_by_user"] = user_result.data[0]
        
        return {
            "success": True,
            "document": document,
            "extracted_fields": list(document.get("extracted_data", {}).keys()),
            "processing_info": document.get("processing_metadata", {})
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar detalhes do documento: {e}")
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")


@router.post("/reprocess/{document_id}")
async def reprocess_document(
    document_id: str,
    current_user: Dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """
    Reprocessa um documento existente com versões mais recentes do OCR.
    """
    try:
        # Buscar documento original
        doc_result = supabase.table("case_documents")\
            .select("*")\
            .eq("id", document_id)\
            .execute()
        
        if not doc_result.data:
            raise HTTPException(status_code=404, detail="Documento não encontrado")
        
        document = doc_result.data[0]
        
        # Verificar permissões
        case_result = supabase.table("cases").select("*").eq("id", document["case_id"]).execute()
        
        if case_result.data:
            case = case_result.data[0]
            user_has_access = (
                case.get("lawyer_id") == current_user["id"] or
                current_user.get("role") == "admin"
            )
            
            if not user_has_access:
                raise HTTPException(status_code=403, detail="Sem permissão para reprocessar")
        
        # Verificar se tem imagem para reprocessar
        if not document.get("image_url"):
            raise HTTPException(status_code=400, detail="Documento não possui imagem para reprocessamento")
        
        # Baixar imagem do storage
        image_base64 = await _get_document_image(document["image_url"], supabase)
        
        # Reprocessar via OCR
        ocr_result = await ocr_service.process_document_from_base64(
            image_base64=image_base64,
            document_type_hint=document.get("type")
        )
        
        if not ocr_result.get("success", False):
            raise HTTPException(status_code=400, detail="Erro no reprocessamento")
        
        # Atualizar documento com novos dados
        updated_data = {
            "extracted_data": ocr_result.get("extracted_data", {}),
            "ocr_result": ocr_result,
            "confidence_score": ocr_result.get("confidence_score", 0.0),
            "reprocessed_at": datetime.now().isoformat(),
            "reprocessed_by": current_user["id"],
            "processing_metadata": {
                **document.get("processing_metadata", {}),
                "reprocessed": True,
                "reprocessing_count": document.get("processing_metadata", {}).get("reprocessing_count", 0) + 1
            }
        }
        
        supabase.table("case_documents")\
            .update(updated_data)\
            .eq("id", document_id)\
            .execute()
        
        logger.info(f"Documento reprocessado com sucesso. ID: {document_id}")
        
        return DocumentResponse(
            success=True,
            message="Documento reprocessado com sucesso",
            document_id=document_id,
            data={
                "new_extracted_data": ocr_result.get("extracted_data", {}),
                "new_confidence_score": ocr_result.get("confidence_score", 0.0),
                "reprocessed_at": updated_data["reprocessed_at"]
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro no reprocessamento: {e}")
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")


# Funções auxiliares
async def _save_document_image(document_id: str, image_base64: str, supabase: Client) -> Optional[str]:
    """Salva imagem do documento no storage do Supabase"""
    try:
        # Decodificar base64
        image_data = base64.b64decode(image_base64)
        
        # Nome do arquivo
        file_name = f"documents/{document_id}/original.jpg"
        
        # Upload para Supabase Storage
        result = supabase.storage.from_("document-images").upload(
            path=file_name,
            file=image_data,
            file_options={"content-type": "image/jpeg"}
        )
        
        # Gerar URL pública
        public_url = supabase.storage.from_("document-images").get_public_url(file_name)
        
        return public_url
        
    except Exception as e:
        logger.error(f"Erro ao salvar imagem: {e}")
        return None


async def _get_document_image(image_url: str, supabase: Client) -> str:
    """Recupera imagem do documento como base64"""
    try:
        # Extrair path da URL
        path = image_url.split("/")[-2:]  # documents/id/original.jpg
        file_path = "/".join(path)
        
        # Baixar do storage
        result = supabase.storage.from_("document-images").download(file_path)
        
        # Converter para base64
        image_base64 = base64.b64encode(result).decode('utf-8')
        
        return image_base64
        
    except Exception as e:
        logger.error(f"Erro ao recuperar imagem: {e}")
        return ""


async def _update_case_stats(case_id: str, supabase: Client):
    """Atualiza estatísticas do caso após adicionar documento"""
    try:
        # Contar documentos do caso
        docs_result = supabase.table("case_documents")\
            .select("id, category")\
            .eq("case_id", case_id)\
            .execute()
        
        total_docs = len(docs_result.data or [])
        ocr_docs = len([d for d in (docs_result.data or []) if d.get("category") == "ocr_processed"])
        
        # Atualizar caso
        supabase.table("cases")\
            .update({
                "document_count": total_docs,
                "ocr_document_count": ocr_docs,
                "updated_at": datetime.now().isoformat()
            })\
            .eq("id", case_id)\
            .execute()
            
    except Exception as e:
        logger.warning(f"Erro ao atualizar estatísticas do caso: {e}")


# Health check para o serviço OCR
@router.get("/ocr/health")
async def ocr_health_check():
    """Verifica status do serviço OCR"""
    return {
        "status": "healthy",
        "ocr_available": ocr_service.tesseract_available,
        "ai_enhancement_available": ocr_service.openai_available,
        "brazilian_validation_available": ocr_service.docbr_available,
        "timestamp": datetime.now().isoformat()
    }

@router.get("/ocr/engines")
async def get_ocr_engines(current_user: dict = Depends(get_current_user)):
    """
    Retorna informações sobre engines OCR disponíveis
    """
    try:
        ocr_service = OCRValidationService()
        engine_info = ocr_service.get_engine_info()
        
        return {
            "success": True,
            "data": engine_info,
            "message": f"Encontrados {engine_info['total_engines']} engines disponíveis"
        }
        
    except Exception as e:
        logger.error(f"Erro ao obter informações dos engines OCR: {e}")
        return {
            "success": False,
            "error": str(e),
            "data": None
        }

@router.post("/ocr/test-engine")
async def test_ocr_engine(
    request: dict,
    current_user: dict = Depends(get_current_user)
):
    """
    Testa um engine OCR específico com uma imagem
    """
    try:
        image_base64 = request.get("image_base64")
        engine = request.get("engine", "auto")
        
        if not image_base64:
            return {
                "success": False,
                "error": "Imagem base64 é obrigatória",
                "data": None
            }
        
        ocr_service = OCRValidationService()
        
        # Se engine específico foi solicitado, verificar se está disponível
        if engine != "auto" and engine not in ocr_service.available_engines:
            return {
                "success": False,
                "error": f"Engine '{engine}' não está disponível",
                "data": {
                    "available_engines": ocr_service.available_engines
                }
            }
        
        # Processar documento
        result = await ocr_service.process_document_from_base64(
            image_base64, 
            document_type_hint=request.get("document_type")
        )
        
        return {
            "success": True,
            "data": result,
            "message": "Teste de OCR concluído com sucesso"
        }
        
    except Exception as e:
        logger.error(f"Erro no teste de OCR: {e}")
        return {
            "success": False,
            "error": str(e),
            "data": None
        }
