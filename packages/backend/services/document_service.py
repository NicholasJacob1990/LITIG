from datetime import datetime
from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from supabase.client import Client

from auth import get_current_user
from config import get_supabase_client, settings

router = APIRouter()


class DocumentService:
    def __init__(self, supabase_client: Client = Depends(get_supabase_client)):
        self.supabase = supabase_client

    async def upload_document(
        self, file_data: bytes, filename: str, case_id: str, document_type: str
    ) -> dict:
        """Upload de documento para um caso"""
        try:
            # Upload do arquivo para storage
            storage_path = f"documents/{case_id}/{filename}"

            result = self.supabase.storage.from_("documents").upload(storage_path, file_data)

            if result.error:
                raise Exception(f"Erro no upload: {result.error}")

            # Salvar metadados no banco
            document_data = {
                "case_id": case_id,
                "filename": filename,
                "storage_path": storage_path,
                "document_type": document_type,
                "file_size": len(file_data),
            }

            doc_result = self.supabase.table("documents").insert(document_data).execute()

            if doc_result.error:
                raise Exception(f"Erro ao salvar metadados: {doc_result.error}")

            return doc_result.data[0]

        except Exception as e:
            raise Exception(f"Erro ao fazer upload do documento: {str(e)}")

    async def get_document(self, document_id: str) -> dict:
        """Buscar documento por ID"""
        try:
            result = (
                self.supabase.table("documents")
                .select("*")
                .eq("id", document_id)
                .single()
                .execute()
            )

            if result.error or not result.data:
                raise Exception("Documento não encontrado")

            return result.data

        except Exception as e:
            raise Exception(f"Erro ao buscar documento: {str(e)}")

    async def download_document(self, document_id: str) -> bytes:
        """Download do conteúdo do documento"""
        try:
            # Buscar informações do documento
            document = await self.get_document(document_id)
            storage_path = document["storage_path"]

            # Download do storage
            result = self.supabase.storage.from_("documents").download(storage_path)

            if result.error:
                raise Exception(f"Erro no download: {result.error}")

            return result.data

        except Exception as e:
            raise Exception(f"Erro ao fazer download do documento: {str(e)}")

    async def delete_document(self, document_id: str) -> bool:
        """Deletar documento"""
        try:
            # Buscar informações do documento
            document = await self.get_document(document_id)
            storage_path = document["storage_path"]

            # Deletar do storage
            storage_result = self.supabase.storage.from_("documents").remove([storage_path])

            # Deletar do banco
            db_result = self.supabase.table("documents").delete().eq("id", document_id).execute()

            return not db_result.error

        except Exception as e:
            raise Exception(f"Erro ao deletar documento: {str(e)}")

    async def get_case_documents(self, case_id: str) -> list:
        """Listar documentos de um caso"""
        try:
            result = self.supabase.table("documents").select("*").eq("case_id", case_id).execute()

            if result.error:
                raise Exception(f"Erro ao buscar documentos: {result.error}")

            return result.data or []

        except Exception as e:
            raise Exception(f"Erro ao listar documentos do caso: {str(e)}")

    async def get_case_documents_preview(self, case_id: str, limit: int = 5) -> list:
        """Preview dos documentos de um caso"""
        try:
            result = (
                self.supabase.table("documents")
                .select("*")
                .eq("case_id", case_id)
                .limit(limit)
                .execute()
            )

            if result.error:
                raise Exception(f"Erro ao buscar preview: {result.error}")

            return result.data or []

        except Exception as e:
            raise Exception(f"Erro ao buscar preview dos documentos: {str(e)}")

    async def get_document_stats(self, case_id: str) -> dict:
        """Estatísticas dos documentos de um caso"""
        try:
            documents = await self.get_case_documents(case_id)

            total_documents = len(documents)
            total_size = sum(doc.get("file_size", 0) for doc in documents)

            types_count = {}
            for doc in documents:
                doc_type = doc.get("document_type", "unknown")
                types_count[doc_type] = types_count.get(doc_type, 0) + 1

            return {
                "total_documents": total_documents,
                "total_size_bytes": total_size,
                "types_count": types_count,
            }

        except Exception as e:
            raise Exception(f"Erro ao calcular estatísticas: {str(e)}")


class PlatformDocumentResponse(BaseModel):
    id: UUID
    title: str
    description: str | None = None
    type: str
    version: str
    document_url: str
    is_current: bool
    accepted_at: datetime | None = None


class PlatformDocumentService:
    def __init__(self, supabase_client: Client = Depends(get_supabase_client)):
        self.supabase = supabase_client

    async def get_documents_for_lawyer(self, lawyer_id: UUID) -> List[PlatformDocumentResponse]:
        """Busca documentos da plataforma para um advogado usando a função RPC."""
        try:
            result = await self.supabase.rpc(
                "get_platform_documents_for_lawyer", {"p_lawyer_id": str(lawyer_id)}
            ).execute()

            if result.data:
                return [PlatformDocumentResponse(**doc) for doc in result.data]
            return []
        except Exception as e:
            # logger.error(...)
            raise HTTPException(status_code=500, detail="Erro ao buscar documentos.")

    async def accept_document(
        self, lawyer_id: UUID, document_id: UUID, ip_address: str, user_agent: str
    ) -> bool:
        """Registra o aceite de um documento por um advogado."""
        try:
            # Prevenir aceite duplicado
            existing = (
                await self.supabase.table("lawyer_accepted_documents")
                .select("id")
                .eq("lawyer_id", str(lawyer_id))
                .eq("document_id", str(document_id))
                .execute()
            )
            if existing.data:
                return True  # Já aceito

            insert_data = {
                "lawyer_id": str(lawyer_id),
                "document_id": str(document_id),
                "ip_address": ip_address,
                "user_agent": user_agent,
            }
            await self.supabase.table("lawyer_accepted_documents").insert(insert_data).execute()
            return True
        except Exception as e:
            # logger.error(...)
            return False

    async def get_document_download_url(self, lawyer_id: UUID, document_id: UUID) -> Optional[str]:
        """Gera uma URL de download assinada para um documento."""
        try:
            # Verificar se o documento existe e se o advogado tem permissão (implícito pela RLS)
            doc_res = (
                await self.supabase.table("platform_documents")
                .select("document_url")
                .eq("id", str(document_id))
                .single()
                .execute()
            )

            if not doc_res.data:
                return None

            storage_path = doc_res.data["document_url"]

            # Gerar URL assinada com validade de 5 minutos
            response = await self.supabase.storage.from_("platform_documents").create_signed_url(
                storage_path, 300
            )
            return response.get("signedURL")
        except Exception as e:
            # logger.error(...)
            return None
