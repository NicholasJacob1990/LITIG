#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Teste do Job de Clusterização
==============================

Script para testar e validar o funcionamento do sistema de clusterização.
"""

import asyncio
import logging
import sys
from pathlib import Path

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

async def test_cluster_system():
    """Testa o sistema de clusterização completo."""
    
    print("🧪 Iniciando teste do sistema de clusterização...\n")
    
    try:
        # 1. Testar importações
        print("📦 Testando importações...")
        
        try:
            from jobs.cluster_generation_job import ClusterGenerationJob, ClusteringConfig
            from services.cluster_data_collection_service import ClusterDataCollectionService
            from services.cluster_labeling_service import ClusterLabelingService
            from services.embedding_service import generate_embedding_with_provider
            print("✅ Todas as importações principais disponíveis")
        except ImportError as e:
            print(f"❌ Erro de importação: {e}")
            return False
        
        # 2. Testar bibliotecas científicas
        print("\n🔬 Testando bibliotecas científicas...")
        
        try:
            import umap
            import hdbscan
            import numpy as np
            from sklearn.metrics import silhouette_score
            print("✅ Bibliotecas de clustering disponíveis")
        except ImportError as e:
            print(f"❌ Bibliotecas de clustering não instaladas: {e}")
            print("💡 Execute: pip install umap-learn hdbscan scikit-learn")
            return False
        
        # 3. Testar embedding service
        print("\n🧠 Testando serviço de embeddings...")
        
        try:
            test_text = "Advogado especializado em direito tributário para startups"
            embedding, provider = await generate_embedding_with_provider(test_text)
            print(f"✅ Embedding gerado via {provider}: dimensão {len(embedding)}")
        except Exception as e:
            print(f"❌ Erro no serviço de embedding: {e}")
            return False
        
        # 4. Testar coleta de dados
        print("\n📊 Testando coleta de dados...")
        
        try:
            data_collector = ClusterDataCollectionService()
            print("✅ Serviço de coleta de dados inicializado")
            
            # Teste com dados mock
            mock_lawyer_data = await data_collector._collect_internal_lawyer_data("test_lawyer_id")
            print("✅ Coleta de dados funcionando (modo teste)")
        except Exception as e:
            print(f"❌ Erro na coleta de dados: {e}")
            return False
        
        # 5. Testar configuração de clusterização
        print("\n⚙️ Testando configuração de clusterização...")
        
        try:
            config = ClusteringConfig(
                umap_n_neighbors=5,
                hdbscan_min_cluster_size=3
            )
            print(f"✅ Configuração criada: UMAP neighbors={config.umap_n_neighbors}")
        except Exception as e:
            print(f"❌ Erro na configuração: {e}")
            return False
        
        # 6. Testar algoritmo de clusterização com dados sintéticos
        print("\n🎯 Testando algoritmo de clusterização...")
        
        try:
            # Criar dados sintéticos para teste
            np.random.seed(42)
            n_samples = 50
            n_features = 768  # Dimensão dos embeddings
            
            # Gerar 3 clusters sintéticos
            cluster1 = np.random.normal(0, 0.5, (n_samples//3, n_features))
            cluster2 = np.random.normal(2, 0.5, (n_samples//3, n_features))  
            cluster3 = np.random.normal(-2, 0.5, (n_samples//3, n_features))
            
            synthetic_data = np.vstack([cluster1, cluster2, cluster3])
            
            # Aplicar UMAP
            umap_reducer = umap.UMAP(n_neighbors=5, min_dist=0.1, random_state=42)
            umap_result = umap_reducer.fit_transform(synthetic_data)
            
            # Aplicar HDBSCAN
            clusterer = hdbscan.HDBSCAN(min_cluster_size=5, min_samples=2)
            cluster_labels = clusterer.fit_predict(umap_result)
            
            n_clusters = len(set(cluster_labels)) - (1 if -1 in cluster_labels else 0)
            n_outliers = sum(1 for x in cluster_labels if x == -1)
            
            print(f"✅ Clusterização concluída: {n_clusters} clusters, {n_outliers} outliers")
            
            # Calcular silhouette score se há clusters válidos
            if n_clusters > 1:
                valid_mask = cluster_labels != -1
                if sum(valid_mask) > 1:
                    silhouette = silhouette_score(umap_result[valid_mask], cluster_labels[valid_mask])
                    print(f"📊 Silhouette Score: {silhouette:.3f}")
                    
        except Exception as e:
            print(f"❌ Erro no algoritmo de clusterização: {e}")
            return False
        
        # 7. Testar job principal (sem executar pipeline completo)
        print("\n🚀 Testando inicialização do job principal...")
        
        try:
            job = ClusterGenerationJob(config)
            print("✅ Job de clusterização inicializado com sucesso")
        except Exception as e:
            print(f"❌ Erro na inicialização do job: {e}")
            return False
        
        # 8. Verificar estrutura do banco (se disponível)
        print("\n🗄️ Verificando estrutura do banco...")
        
        try:
            from database import get_async_session
            
            async with get_async_session() as db:
                # Verificar se tabelas de cluster existem
                tables_to_check = [
                    'case_embeddings',
                    'lawyer_embeddings', 
                    'case_clusters',
                    'lawyer_clusters',
                    'cluster_metadata'
                ]
                
                for table in tables_to_check:
                    result = await db.execute(
                        f"SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = '{table}')"
                    )
                    exists = result.fetchone()[0]
                    status = "✅" if exists else "❌"
                    print(f"  {status} Tabela {table}")
                    
        except Exception as e:
            print(f"⚠️ Não foi possível verificar banco (normal em ambiente local): {e}")
        
        print("\n🎉 Teste do sistema de clusterização concluído com sucesso!")
        print("\n📋 Próximos passos:")
        print("  1. Configure as variáveis de ambiente (OPENAI_API_KEY, etc.)")
        print("  2. Execute a migration: python run_cluster_migration.py") 
        print("  3. Teste com dados reais: python -m jobs.cluster_generation_job")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro geral no teste: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_individual_components():
    """Testa componentes individuais do sistema."""
    
    print("🔧 Testando componentes individuais...\n")
    
    # Teste de embedding individual
    print("1. Teste de embedding individual:")
    try:
        test_texts = [
            "Advogado especializado em startups e direito tributário",
            "Caso de rescisão indireta de contrato de trabalho",
            "Disputa contratual entre empresa de tecnologia e fornecedor"
        ]
        
        for i, text in enumerate(test_texts, 1):
            embedding, provider = await generate_embedding_with_provider(text)
            print(f"   {i}. {provider}: {len(embedding)} dim - '{text[:50]}...'")
            
    except Exception as e:
        print(f"   ❌ Erro: {e}")
    
    # Teste de clusterização básica
    print("\n2. Teste de clusterização básica:")
    try:
        import numpy as np
        import umap
        import hdbscan
        
        # Dados sintéticos simples
        data = np.random.rand(20, 10)
        
        umap_reducer = umap.UMAP(n_neighbors=3, min_dist=0.1)
        umap_data = umap_reducer.fit_transform(data)
        
        clusterer = hdbscan.HDBSCAN(min_cluster_size=3)
        labels = clusterer.fit_predict(umap_data)
        
        unique_labels = set(labels)
        n_clusters = len(unique_labels) - (1 if -1 in unique_labels else 0)
        
        print(f"   ✅ {n_clusters} clusters encontrados em dados sintéticos")
        
    except Exception as e:
        print(f"   ❌ Erro: {e}")
    
    print("\n✅ Teste de componentes individuais concluído")


if __name__ == "__main__":
    print("🧪 TESTE DO SISTEMA DE CLUSTERIZAÇÃO")
    print("=" * 50)
    
    # Escolher tipo de teste
    if len(sys.argv) > 1 and sys.argv[1] == "components":
        result = asyncio.run(test_individual_components())
    else:
        result = asyncio.run(test_cluster_system())
    
    if result:
        print("\n🎯 Sistema pronto para uso!")
        sys.exit(0)
    else:
        print("\n❌ Sistema não está pronto - verifique os erros acima")
        sys.exit(1) 