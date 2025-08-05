# packages/backend/services/firm_profile_service.py

import asyncio
from typing import Dict, Any, List, Optional
from ..dependencies import get_db
# MUDANÇA: Apontando para o novo serviço orquestrador
from .embedding_orchestrator import generate_embedding
from psycopg2.extras import Json

class FirmProfileService:
    """
    Serviço responsável por construir, gerar e armazenar perfis semânticos
    e embeddings para escritórios de advocacia (law_firms).
    """

    async def generate_and_update_firm_embedding(self, firm_id: str) -> bool:
        """
        Orquestra a geração do perfil semântico e do embedding para um escritório específico.

        Args:
            firm_id: O UUID do escritório a ser processado.

        Returns:
            True se a atualização foi bem-sucedida, False caso contrário.
        """
        print(f"Iniciando a geração de embedding para o escritório: {firm_id}")

        # 1. Buscar dados brutos do escritório
        firm_data = await self._get_firm_data(firm_id)
        if not firm_data:
            print(f"Escritório com ID {firm_id} não encontrado.")
            return False

        # 2. Construir o perfil semântico
        semantic_profile = self._build_semantic_profile(firm_data)

        # 3. Gerar o embedding via orquestrador
        result = await generate_embedding(semantic_profile, context_type="lawyer_cv")
        embedding = result.embedding

        # 4. Atualizar o banco de dados
        success = await self._update_firm_profile_and_embedding(firm_id, semantic_profile, embedding)

        if success:
            print(f"Embedding para o escritório {firm_id} atualizado com sucesso.")
        else:
            print(f"Falha ao atualizar o embedding para o escritório {firm_id}.")

        return success

    async def _get_firm_data(self, firm_id: str) -> Optional[Dict[str, Any]]:
        """Busca os dados necessários de um escritório e seus advogados associados."""
        db = next(get_db())
        # Esta query agregada é mais eficiente do que múltiplas chamadas ao banco.
        query = """
            SELECT
                f.id,
                f.name,
                f.description,
                f.website,
                f.is_boutique,
                fk.reputation_score,
                fk.success_rate,
                (SELECT array_agg(DISTINCT la.area)
                 FROM lawyers l
                 JOIN lawyer_areas la ON l.id = la.lawyer_id
                 WHERE l.firm_id = f.id) as areas_of_law,
                (SELECT array_agg(l.name || ' - ' || l.position)
                 FROM lawyers l
                 WHERE l.firm_id = f.id AND l.is_partner = TRUE) as partners,
                (
                    SELECT array_agg(kpi_subarea)
                    FROM (
                        SELECT l.kpi_subarea
                        FROM lawyers l
                        WHERE l.firm_id = f.id AND l.kpi_subarea IS NOT NULL
                        GROUP BY l.kpi_subarea
                        ORDER BY count(l.kpi_subarea) DESC
                        LIMIT 5
                    ) as top_subareas
                ) as collective_expertise
            FROM public.law_firms f
            LEFT JOIN public.firm_kpis fk ON f.id = fk.firm_id
            WHERE f.id = %s
            GROUP BY f.id, fk.id;
        """
        with db.cursor() as cursor:
            cursor.execute(query, (firm_id,))
            result = cursor.fetchone()
            if result:
                columns = [desc[0] for desc in cursor.description]
                return dict(zip(columns, result))
        return None

    def _build_semantic_profile(self, firm_data: Dict[str, Any]) -> str:
        """
        Constrói um perfil textual coeso a partir dos dados do escritório.
        Este perfil será a fonte para a geração do embedding.
        """
        profile_parts = []

        # Nome e descrição
        if firm_data.get("name"):
            profile_parts.append(f"Escritório de Advocacia: {firm_data['name']}.")
        if firm_data.get("description"):
            profile_parts.append(f"Descrição: {firm_data['description']}.")
        
        # Tipo de escritório
        if firm_data.get("is_boutique"):
            profile_parts.append("Este é um escritório de advocacia do tipo boutique, altamente especializado.")

        # Áreas de atuação
        if firm_data.get("areas_of_law"):
            areas = ", ".join(firm_data["areas_of_law"])
            profile_parts.append(f"Especialidades e áreas de atuação principais: {areas}.")

        # Expertise Coletiva
        if firm_data.get("collective_expertise"):
            expertise = ", ".join(firm_data["collective_expertise"])
            profile_parts.append(f"A equipe do escritório possui expertise coletiva e consolidada nas seguintes subáreas: {expertise}.")

        # Sócios
        if firm_data.get("partners"):
            partners = "; ".join(firm_data["partners"])
            profile_parts.append(f"Sócios principais: {partners}.")
            
        # KPIs de Reputação
        if firm_data.get("reputation_score") is not None:
            profile_parts.append(f"Com um score de reputação de {firm_data['reputation_score']:.2f}.")
        if firm_data.get("success_rate") is not None:
            profile_parts.append(f"E uma taxa de sucesso em casos de {firm_data['success_rate'] * 100:.0f}%.")

        # Website
        if firm_data.get("website"):
            profile_parts.append(f"Website para mais informações: {firm_data['website']}.")
            
        return "\n".join(profile_parts)

    async def _update_firm_profile_and_embedding(self, firm_id: str, profile: str, embedding: List[float]) -> bool:
        """Atualiza o perfil semântico e o embedding no banco de dados."""
        db = next(get_db())
        query = """
            UPDATE public.law_firms
            SET
                semantic_profile = %s,
                embedding = %s,
                updated_at = NOW()
            WHERE id = %s;
        """
        try:
            with db.cursor() as cursor:
                # O embedding precisa ser formatado como uma string para o psycopg2
                embedding_str = str(embedding)
                cursor.execute(query, (profile, embedding_str, firm_id))
            db.commit()
            return cursor.rowcount > 0
        except Exception as e:
            db.rollback()
            print(f"Erro de banco de dados ao atualizar escritório {firm_id}: {e}")
            return False

    async def find_similar_firms(self, text_query: str, top_k: int = 10) -> List[Dict[str, Any]]:
        """
        Encontra os escritórios mais semanticamente similares a uma consulta de texto.

        Args:
            text_query: A descrição em linguagem natural para a busca.
            top_k: O número de escritórios a serem retornados.

        Returns:
            Uma lista de dicionários, cada um representando um escritório similar
            e seu score de similaridade.
        """
        if not text_query:
            return []

        # 1. Gerar o embedding para a consulta do usuário via orquestrador
        try:
            result = await generate_embedding(text_query, context_type="case")
            query_embedding = result.embedding
        except Exception as e:
            print(f"Falha ao gerar embedding para a consulta: {e}")
            return []

        # 2. Executar a busca por similaridade de cosseno no banco de dados
        db = next(get_db())
        query = """
            SELECT
                id,
                name,
                description,
                website,
                is_boutique,
                1 - (embedding <=> %s) as similarity_score
            FROM public.law_firms
            WHERE embedding IS NOT NULL
            ORDER BY similarity_score DESC
            LIMIT %s;
        """
        try:
            with db.cursor() as cursor:
                embedding_str = str(query_embedding)
                cursor.execute(query, (embedding_str, top_k))
                
                results = []
                columns = [desc[0] for desc in cursor.description]
                for row in cursor.fetchall():
                    results.append(dict(zip(columns, row)))
                return results
        except Exception as e:
            print(f"Erro na busca por similaridade de escritórios: {e}")
            return []


# Instância do serviço para ser usada em outras partes da aplicação
firm_profile_service = FirmProfileService() 
 