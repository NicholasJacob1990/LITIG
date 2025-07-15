import logging
from typing import List, Optional
from pydantic import BaseModel
from ..database import get_db_connection
from ..api.schemas import MatchedLawyerSchema

logger = logging.getLogger(__name__)

class DirectorySearchRequest(BaseModel):
    query: Optional[str] = None
    min_rating: Optional[float] = None
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    is_available: Optional[bool] = None
    limit: int = 20

class DirectorySearchService:
    async def search(self, request: DirectorySearchRequest) -> List[MatchedLawyerSchema]:
        """
        Executa a busca no banco de dados com base nos filtros.
        """
        try:
            conn = get_db_connection()
            cursor = conn.cursor(cursor_factory=RealDictCursor)

            query_parts = ["SELECT * FROM lawyers WHERE ativo = true"]
            params = []

            if request.query:
                query_parts.append("AND (LOWER(nome) LIKE %s OR %s = ANY(LOWER(tags_expertise::text)::text[]))")
                search_term = f"%{request.query.lower()}%"
                params.extend([search_term, request.query.lower()])
            
            if request.min_rating is not None:
                query_parts.append("AND rating >= %s")
                params.append(request.min_rating)

            if request.is_available is not None:
                query_parts.append("AND is_available = %s")
                params.append(request.is_available)
            
            # Adicionar filtros de preço aqui quando os campos estiverem no DB

            query_parts.append("LIMIT %s")
            params.append(request.limit)

            final_query = " ".join(query_parts)
            cursor.execute(final_query, tuple(params))
            
            results = [MatchedLawyerSchema(**row) for row in cursor.fetchall()]
            
            cursor.close()
            conn.close()

            return results
        except Exception as e:
            logger.error(f"Erro no serviço de busca por diretório: {e}")
            # Em um cenário de produção, seria bom ter um tratamento de erro mais robusto
            return []

from psycopg2.extras import RealDictCursor 