import os
import psycopg2
import json
from dotenv import load_dotenv

def backfill_embeddings():
    """
    Script para migrar embeddings de um campo JSONB para uma coluna pgvector.
    
    Lê `cv_analysis -> embedding` e o insere em `cv_embedding`.
    """
    load_dotenv()
    db_url = os.getenv("DATABASE_URL")
    
    if not db_url:
        print("Erro: DATABASE_URL não está configurada no .env")
        return

    conn = None
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()

        # Seleciona advogados que têm o embedding no campo JSONB e a nova coluna ainda é nula
        cur.execute("""
            SELECT id, cv_analysis->'embedding' as embedding
            FROM lawyers
            WHERE cv_analysis->'embedding' IS NOT NULL
              AND cv_embedding IS NULL
        """)
        
        lawyers_to_update = cur.fetchall()
        
        if not lawyers_to_update:
            print("Nenhum advogado para atualizar. Os embeddings já podem estar migrados.")
            return

        print(f"Encontrados {len(lawyers_to_update)} advogados para migrar embeddings...")
        
        updated_count = 0
        for lawyer_id, embedding_json in lawyers_to_update:
            if not embedding_json:
                continue
            
            # pgvector espera um formato de string como '[1.2,3.4, ...]'
            embedding_str = str(embedding_json)

            try:
                cur.execute(
                    "UPDATE lawyers SET cv_embedding = %s WHERE id = %s",
                    (embedding_str, lawyer_id)
                )
                updated_count += 1
            except psycopg2.Error as e:
                print(f"Erro ao atualizar advogado {lawyer_id}: {e}")
                conn.rollback() # Desfaz a transação para este advogado

        conn.commit()
        print(f"Migração concluída! {updated_count} advogados atualizados.")

    except psycopg2.Error as e:
        print(f"Erro de banco de dados: {e}")
    finally:
        if conn:
            cur.close()
            conn.close()
            print("Conexão com o banco de dados fechada.")

if __name__ == "__main__":
    backfill_embeddings() 