import asyncio
import os
import sys
from typing import List, Tuple

# MUDANÇA: Usando um caminho absoluto para o diretório 'packages' para garantir
# que as importações funcionem independentemente do ambiente de execução.
packages_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, packages_dir)

import psycopg2
from dotenv import load_dotenv

from backend.services.embedding_orchestrator import generate_embedding, embedding_orchestrator, EmbeddingType
# A dependência do FirmProfileService foi removida para simplificar o script.
# A lógica de construção do perfil será feita com uma query direta.

# Carregar configuração da database
load_dotenv()
database_url = os.getenv('DATABASE_URL')


async def backfill_lawyers():
    """Gera e armazena embeddings V2 para advogados que ainda não os possuem."""
    print("🚀 Iniciando backfill para a tabela 'lawyers'...")
    
    try:
        conn = psycopg2.connect(database_url)
        cursor = conn.cursor()
        
        # Buscar advogados sem embedding V2 - usar campos disponíveis
        cursor.execute("""
            SELECT id, name, oab_number, primary_area, specialties
            FROM lawyers
            WHERE cv_embedding_v2 IS NULL
            LIMIT 50;
        """)
        
        lawyers = cursor.fetchall()
        print(f"📈 Encontrados {len(lawyers)} advogados para processar.")
        
        for lawyer_id, name, oab_number, primary_area, specialties in lawyers:
            try:
                # Criar texto do CV combinando campos disponíveis
                cv_parts = []
                if name:
                    cv_parts.append(f"Nome: {name}")
                if oab_number:
                    cv_parts.append(f"OAB: {oab_number}")
                if primary_area:
                    cv_parts.append(f"Área Principal: {primary_area}")
                if specialties:
                    cv_parts.append(f"Especialidades: {', '.join(specialties)}")
                
                cv_text = ". ".join(cv_parts) if cv_parts else f"Advogado: {name}"
                
                # Gerar embedding V2 (Padrão)
                print("   - Gerando embedding V2 (Padrão)...")
                embedding_v2_result = await generate_embedding(cv_text, "lawyer_cv")
                
                # TEMPORÁRIO: Comentando V3 até resolvermos a estrutura do banco
                # TODO: Descomentar quando cv_embedding_v2_enriched existir na tabela
                """
                # Gerar embedding V3 (Enriquecido)
                print("   - Gerando embedding V3 (Enriquecido)...")
                # Verificar se a tabela lawyer_kpis existe antes de fazer o JOIN
                cursor.execute(\"\"\"
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables 
                        WHERE table_schema = 'public' 
                        AND table_name = 'lawyer_kpis'
                    );
                \"\"\")
                kpis_table_exists = cursor.fetchone()[0]
                
                if kpis_table_exists:
                    # Usar query completa com KPIs
                    cursor.execute(\"\"\"
                        SELECT l.id as lawyer_id, l.name, l.oab_number, l.primary_area, l.specialties,
                               k.success_rate, k.cases_won, k.cases_lost, k.avg_case_duration_days, k.client_satisfaction_score
                        FROM lawyers l
                        LEFT JOIN lawyer_kpis k ON l.id = k.lawyer_id
                        WHERE l.id = %s
                    \"\"\", (lawyer_id,))
                else:
                    # Usar apenas dados básicos da tabela lawyers
                    print("     (Tabela lawyer_kpis não encontrada, usando dados básicos)")
                    cursor.execute(\"\"\"
                        SELECT id as lawyer_id, name, oab_number, primary_area, specialties,
                               NULL as success_rate, NULL as cases_won, NULL as cases_lost, 
                               NULL as avg_case_duration_days, NULL as client_satisfaction_score
                        FROM lawyers
                        WHERE id = %s
                    \"\"\", (lawyer_id,))
                
                lawyer_full_data = cursor.fetchone()
                lawyer_profile = dict(zip([desc[0] for desc in cursor.description], lawyer_full_data)) if lawyer_full_data else {}

                enriched_embedding_result = await embedding_orchestrator.generate_embedding(
                    text="",  # O texto é construído dentro do serviço
                    context_type="lawyer_cv_enriched",
                    embedding_type=EmbeddingType.ENRICHED,
                    lawyer_profile=lawyer_profile
                )
                """

                # Atualizar no banco apenas com embedding V2
                print("   - Atualizando banco de dados...")
                cursor.execute("""
                    UPDATE lawyers 
                    SET cv_embedding_v2 = %s
                    WHERE id = %s
                """, (embedding_v2_result, lawyer_id))
                
                conn.commit()
                print(f"✅ Advogado {name} processado com sucesso (V2).")
                
            except Exception as e:
                print(f"❌ Erro ao processar advogado {lawyer_id}: {e}")
                conn.rollback()
        
        cursor.close()
        conn.close()
        print("🎯 Backfill de advogados concluído.")
        
    except Exception as e:
        print(f"❌ Erro geral no backfill de advogados: {e}")


async def backfill_cases():
    """Gera e armazena embeddings V2 para casos que ainda não os possuem."""
    print("🚀 Iniciando backfill para a tabela 'cases'...")
    
    try:
        conn = psycopg2.connect(database_url)
        cursor = conn.cursor()
        
        # Buscar casos sem embedding V2 - usar campos disponíveis
        cursor.execute("""
            SELECT id, status, ai_analysis
            FROM cases
            WHERE embedding_v2 IS NULL
            LIMIT 50;
        """)
        
        cases = cursor.fetchall()
        print(f"📈 Encontrados {len(cases)} casos para processar.")
        
        for case_id, status, ai_analysis in cases:
            try:
                # Criar texto do caso combinando campos disponíveis
                case_parts = []
                if status:
                    case_parts.append(f"Status: {status}")
                if ai_analysis:
                    # Extrair informações relevantes do JSON de análise
                    if isinstance(ai_analysis, dict):
                        if 'description' in ai_analysis:
                            case_parts.append(f"Descrição: {ai_analysis['description']}")
                        if 'legal_area' in ai_analysis:
                            case_parts.append(f"Área Jurídica: {ai_analysis['legal_area']}")
                
                case_text = ". ".join(case_parts) if case_parts else f"Caso {case_id}"
                
                # Gerar embedding usando o orchestrator
                result = await generate_embedding(case_text, "case")
                embedding_vector = result.embedding
                
                # Atualizar no banco
                cursor.execute("""
                    UPDATE cases 
                    SET embedding_v2 = %s 
                    WHERE id = %s
                """, (embedding_vector, case_id))
                
                conn.commit()
                print(f"✅ Caso {case_id} processado com sucesso.")
                
            except Exception as e:
                print(f"❌ Erro ao processar caso {case_id}: {e}")
                conn.rollback()
        
        cursor.close()
        conn.close()
        print("🎯 Backfill de casos concluído.")
        
    except Exception as e:
        print(f"❌ Erro geral no backfill de casos: {e}")


async def backfill_law_firms():
    """Gera e armazena embeddings V2 para escritórios que ainda não os possuem."""
    print("🚀 Iniciando backfill para a tabela 'law_firms'...")
    
    try:
        conn = psycopg2.connect(database_url)
        cursor = conn.cursor()
        
        # Buscar escritórios sem embedding V2 - usar campos disponíveis e relacionados
        cursor.execute("""
            SELECT f.id, f.name, f.team_size, 
                   COUNT(l.id) as lawyer_count,
                   ARRAY_AGG(DISTINCT l.primary_area) FILTER (WHERE l.primary_area IS NOT NULL) as areas
            FROM law_firms f
            LEFT JOIN lawyers l ON l.firm_id = f.id
            WHERE f.embedding_v2 IS NULL
            GROUP BY f.id, f.name, f.team_size
            LIMIT 50;
        """)
        
        firms = cursor.fetchall()
        print(f"📈 Encontrados {len(firms)} escritórios para processar.")
        
        for firm_id, name, team_size, lawyer_count, areas in firms:
            try:
                # Criar texto do escritório combinando campos disponíveis
                firm_parts = []
                if name:
                    firm_parts.append(f"Escritório: {name}")
                if team_size:
                    firm_parts.append(f"Tamanho da equipe: {team_size} pessoas")
                if lawyer_count and lawyer_count > 0:
                    firm_parts.append(f"Advogados ativos: {lawyer_count}")
                if areas and len(areas) > 0:
                    firm_parts.append(f"Áreas de atuação: {', '.join(areas)}")
                
                firm_text = ". ".join(firm_parts) if firm_parts else f"Escritório: {name}"
                
                # Gerar embedding usando o orchestrator
                result = await generate_embedding(firm_text, "law_firm")
                embedding_vector = result.embedding
                
                # Atualizar no banco
                cursor.execute("""
                    UPDATE law_firms 
                    SET embedding_v2 = %s 
                    WHERE id = %s
                """, (embedding_vector, firm_id))
                
                conn.commit()
                print(f"✅ Escritório {name} processado com sucesso.")
                
            except Exception as e:
                print(f"❌ Erro ao processar escritório {firm_id}: {e}")
                conn.rollback()
        
        cursor.close()
        conn.close()
        print("🎯 Backfill de escritórios concluído.")
        
    except Exception as e:
        print(f"❌ Erro geral no backfill de escritórios: {e}")


async def main():
    """Função principal para orquestrar o processo de backfill."""
    load_dotenv()
    
    print("--- INICIANDO PROCESSO DE BACKFILL DE EMBEDDINGS V2 ---")
    
    await backfill_lawyers()
    await backfill_cases()
    await backfill_law_firms()
    
    print("\n--- PROCESSO DE BACKFILL CONCLUÍDO ---")


if __name__ == "__main__":
    asyncio.run(main())