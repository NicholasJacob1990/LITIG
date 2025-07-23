"""
Enhanced documents routes with new categorization system
Supports the expanded 42 document types and intelligent suggestions
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from pydantic import BaseModel
from supabase.client import Client

from auth import get_current_user
from config import get_supabase_client

router = APIRouter(prefix="/documents/enhanced", tags=["documents-enhanced"])

# ============================================================================
# DTOs for enhanced document system
# ============================================================================

class DocumentCategoryResponse(BaseModel):
    code: str
    name: str
    icon: str
    display_order: int
    document_count: Optional[int] = 0

class DocumentTypeResponse(BaseModel):
    type: str
    category_code: str
    category_name: str
    display_name: str
    description: str
    is_required_for_areas: List[str]
    suggested_for_areas: List[str]

class DocumentUploadRequest(BaseModel):
    case_id: str
    document_type: str
    description: Optional[str] = None

class DocumentSuggestionResponse(BaseModel):
    type: str
    display_name: str
    description: str
    is_required: bool
    category_name: str
    priority: str  # 'required', 'recommended', 'optional'
    reason: str

class EnhancedDocumentResponse(BaseModel):
    id: str
    case_id: str
    document_type: str
    type_display_name: str
    category_code: str
    category_name: str
    category_icon: str
    name: str
    original_name: str
    file_path: str
    file_size: int
    mime_type: str
    description: Optional[str]
    is_confidential: bool
    uploaded_by: str
    created_at: str
    updated_at: str

# ============================================================================
# Routes for document categories and types
# ============================================================================

@router.get("/categories", response_model=List[DocumentCategoryResponse])
async def get_document_categories(
    include_counts: bool = False,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """
    Get all document categories with optional document counts
    """
    try:
        if include_counts:
            # Query with counts - mais complexo
            result = supabase.rpc(
                "get_document_categories_with_counts",
                {"user_id": current_user["id"]}
            ).execute()
        else:
            # Query simples das categorias
            result = supabase.table("document_type_categories")\
                .select("*")\
                .order("display_order")\
                .execute()

        categories = []
        for row in result.data:
            categories.append(DocumentCategoryResponse(
                code=row["category_code"],
                name=row["category_name"],
                icon=row["category_icon"],
                display_order=row["display_order"],
                document_count=row.get("document_count", 0)
            ))

        return categories

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar categorias: {str(e)}"
        )

@router.get("/types", response_model=List[DocumentTypeResponse])
async def get_document_types(
    category_code: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """
    Get document types, optionally filtered by category
    """
    try:
        result = supabase.rpc(
            "get_document_types_by_category",
            {"p_category_code": category_code}
        ).execute()

        types = []
        for row in result.data:
            types.append(DocumentTypeResponse(
                type=row["document_type"],
                category_code=row["category_code"],
                category_name=row["category_name"],
                display_name=row["display_name"],
                description=row["description"],
                is_required_for_areas=row["is_required_for_areas"] or [],
                suggested_for_areas=row["suggested_for_areas"] or []
            ))

        return types

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar tipos: {str(e)}"
        )

# ============================================================================
# Intelligent suggestions
# ============================================================================

@router.get("/suggestions/{case_id}", response_model=List[DocumentSuggestionResponse])
async def get_document_suggestions_for_case(
    case_id: str,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """
    Get intelligent document suggestions for a specific case
    """
    try:
        # Buscar dados do caso
        case_result = supabase.table("cases")\
            .select("area, subarea")\
            .eq("id", case_id)\
            .single()\
            .execute()

        if not case_result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Caso não encontrado"
            )

        case_area = case_result.data["area"]
        
        # Buscar documentos já existentes no caso
        existing_docs = supabase.table("documents")\
            .select("document_type")\
            .eq("case_id", case_id)\
            .execute()

        existing_types = [doc["document_type"] for doc in existing_docs.data] if existing_docs.data else []

        # Usar função do banco para sugerir tipos
        suggestions_result = supabase.rpc(
            "suggest_document_types_for_case_area",
            {"p_case_area": case_area}
        ).execute()

        suggestions = []
        for row in suggestions_result.data:
            # Filtrar documentos já existentes
            if row["document_type"] not in existing_types:
                priority = "required" if row["is_required"] else "recommended"
                reason = f"Documento {priority.lower()} para casos de {case_area}"
                
                suggestions.append(DocumentSuggestionResponse(
                    type=row["document_type"],
                    display_name=row["display_name"],
                    description=row["description"],
                    is_required=row["is_required"],
                    category_name=row["category_name"],
                    priority=priority,
                    reason=reason
                ))

        return suggestions

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao gerar sugestões: {str(e)}"
        )

# ============================================================================
# Enhanced document upload and management
# ============================================================================

@router.post("/upload", response_model=EnhancedDocumentResponse)
async def upload_enhanced_document(
    file: UploadFile = File(...),
    case_id: str = Form(...),
    document_type: str = Form(...),
    description: Optional[str] = Form(None),
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """
    Upload document with enhanced type categorization
    """
    try:
        # Validar tamanho do arquivo
        file_content = await file.read()
        if len(file_content) > 10 * 1024 * 1024:  # 10MB
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="Arquivo muito grande. Máximo 10MB."
            )

        # Validar tipo de documento
        type_check = supabase.table("document_type_mappings")\
            .select("display_name, category_code")\
            .eq("document_type", document_type)\
            .single()\
            .execute()

        if not type_check.data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Tipo de documento inválido"
            )

        # Upload para storage
        storage_path = f"cases/{case_id}/{file.filename}"
        storage_result = supabase.storage.from_("case-documents")\
            .upload(storage_path, file_content)

        if hasattr(storage_result, 'error') and storage_result.error:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Erro no upload: {storage_result.error}"
            )

        # Salvar metadados no banco
        document_data = {
            "case_id": case_id,
            "uploaded_by": current_user["id"],
            "name": file.filename,
            "original_name": file.filename,
            "file_path": storage_path,
            "file_size": len(file_content),
            "mime_type": file.content_type or "application/octet-stream",
            "document_type": document_type,
            "description": description,
        }

        doc_result = supabase.table("documents")\
            .insert(document_data)\
            .execute()

        if not doc_result.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao salvar documento no banco"
            )

        # Retornar dados completos com informações de categoria
        doc_data = doc_result.data[0]
        type_info = type_check.data

        return EnhancedDocumentResponse(
            id=doc_data["id"],
            case_id=doc_data["case_id"],
            document_type=doc_data["document_type"],
            type_display_name=type_info["display_name"],
            category_code=type_info["category_code"],
            category_name="",  # Buscar depois se necessário
            category_icon="",  # Buscar depois se necessário
            name=doc_data["name"],
            original_name=doc_data["original_name"],
            file_path=doc_data["file_path"],
            file_size=doc_data["file_size"],
            mime_type=doc_data["mime_type"],
            description=doc_data["description"],
            is_confidential=doc_data["is_confidential"],
            uploaded_by=doc_data["uploaded_by"],
            created_at=doc_data["created_at"],
            updated_at=doc_data["updated_at"]
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro no upload: {str(e)}"
        )

@router.get("/case/{case_id}", response_model=List[EnhancedDocumentResponse])
async def get_case_documents_enhanced(
    case_id: str,
    category_code: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """
    Get case documents with enhanced categorization info
    """
    try:
        # Query complexa juntando documentos com tipos e categorias
        query = """
        SELECT 
            d.*,
            m.display_name as type_display_name,
            m.category_code,
            c.category_name,
            c.category_icon
        FROM documents d
        LEFT JOIN document_type_mappings m ON d.document_type = m.document_type
        LEFT JOIN document_type_categories c ON m.category_code = c.category_code
        WHERE d.case_id = %s
        """
        
        params = [case_id]
        
        if category_code:
            query += " AND m.category_code = %s"
            params.append(category_code)
            
        query += " ORDER BY d.created_at DESC"

        result = supabase.rpc("execute_raw_sql", {
            "query": query,
            "params": params
        }).execute()

        documents = []
        for row in result.data:
            documents.append(EnhancedDocumentResponse(
                id=row["id"],
                case_id=row["case_id"],
                document_type=row["document_type"],
                type_display_name=row.get("type_display_name", row["document_type"]),
                category_code=row.get("category_code", "outros"),
                category_name=row.get("category_name", "Outros"),
                category_icon=row.get("category_icon", "folder"),
                name=row["name"],
                original_name=row["original_name"],
                file_path=row["file_path"],
                file_size=row["file_size"],
                mime_type=row["mime_type"],
                description=row["description"],
                is_confidential=row["is_confidential"],
                uploaded_by=row["uploaded_by"],
                created_at=row["created_at"],
                updated_at=row["updated_at"]
            ))

        return documents

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar documentos: {str(e)}"
        )

# ============================================================================
# Statistics and analytics
# ============================================================================

@router.get("/stats/{case_id}")
async def get_case_document_stats(
    case_id: str,
    current_user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """
    Get document statistics for a case, organized by category
    """
    try:
        # Query para estatísticas por categoria
        result = supabase.rpc("get_case_document_stats", {
            "p_case_id": case_id
        }).execute()

        stats = {
            "total_documents": 0,
            "total_size_bytes": 0,
            "categories": {},
            "missing_required": [],
            "suggestions_count": 0
        }

        if result.data:
            for row in result.data:
                stats["categories"][row["category_code"]] = {
                    "name": row["category_name"],
                    "icon": row["category_icon"],
                    "count": row["document_count"],
                    "total_size": row["total_size"]
                }
                stats["total_documents"] += row["document_count"]
                stats["total_size_bytes"] += row["total_size"]

        return stats

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar estatísticas: {str(e)}"
        ) 