"""
Exemplo Prático: Como Usar BERTimbau para Embeddings Jurídicos

Este arquivo demonstra como integrar BERTimbau (BERT Brasileiro) ao seu sistema
de embeddings existente como fallback local especializado em português.

Modelo oficial: https://huggingface.co/neuralmind/bert-large-portuguese-cased
Paper: https://link.springer.com/chapter/10.1007/978-3-030-61377-8_28
"""

import logging
import time
import asyncio
from typing import List, Optional, Tuple
import numpy as np

logger = logging.getLogger(__name__)

class BertimbauEmbeddingService:
    """
    Serviço de embeddings usando BERTimbau Large para português brasileiro.
    
    Características:
    - 1024D nativos (compatível com sua estratégia V2)
    - Especializado em português brasileiro
    - Funciona offline (após download inicial)
    - Ideal como fallback local
    """
    
    def __init__(self):
        self.model = None
        self.embedding_dim = 1024
        self._load_model()
    
    def _load_model(self):
        """Carrega o modelo BERTimbau Large (1024D)."""
        try:
            from sentence_transformers import SentenceTransformer
            
            logger.info("🇧🇷 Carregando BERTimbau Large (primeira vez pode demorar 2-4 minutos)...")
            start_time = time.time()
            
            # Modelo oficial do paper BERTimbau
            self.model = SentenceTransformer('neuralmind/bert-large-portuguese-cased')
            
            load_time = time.time() - start_time
            logger.info(f"✅ BERTimbau carregado em {load_time:.1f}s")
            
        except ImportError:
            logger.error("❌ sentence-transformers não instalado. Execute: pip install sentence-transformers")
            self.model = None
        except Exception as e:
            logger.error(f"❌ Erro ao carregar BERTimbau: {e}")
            self.model = None
    
    async def generate_embedding(self, text: str) -> Tuple[List[float], str]:
        """
        Gera embedding usando BERTimbau.
        
        Args:
            text: Texto em português para gerar embedding
            
        Returns:
            Tuple com (embedding_vector, provider_name)
        """
        if not self.model:
            raise RuntimeError("BERTimbau não disponível")
        
        try:
            # Executar de forma assíncrona para não bloquear
            loop = asyncio.get_event_loop()
            
            def _encode():
                return self.model.encode(text)
            
            embedding = await loop.run_in_executor(None, _encode)
            embedding_list = embedding.tolist()
            
            # Ajustar dimensões se necessário
            if len(embedding_list) != self.embedding_dim:
                logger.warning(f"BERTimbau retornou {len(embedding_list)}D, ajustando para {self.embedding_dim}D")
                
                if len(embedding_list) > self.embedding_dim:
                    # Truncar
                    embedding_list = embedding_list[:self.embedding_dim]
                else:
                    # Padding com zeros
                    padding = [0.0] * (self.embedding_dim - len(embedding_list))
                    embedding_list.extend(padding)
            
            return embedding_list, "bertimbau_large"
            
        except Exception as e:
            logger.error(f"Erro ao gerar embedding BERTimbau: {e}")
            raise
    
    def get_similarity(self, embedding1: List[float], embedding2: List[float]) -> float:
        """Calcula similaridade coseno entre dois embeddings."""
        vec1 = np.array(embedding1[:self.embedding_dim])
        vec2 = np.array(embedding2[:self.embedding_dim])
        
        dot_product = np.dot(vec1, vec2)
        norm1 = np.linalg.norm(vec1)
        norm2 = np.linalg.norm(vec2)
        
        if norm1 == 0 or norm2 == 0:
            return 0.0
        
        return float(dot_product / (norm1 * norm2))
    
    def is_available(self) -> bool:
        """Verifica se BERTimbau está disponível."""
        return self.model is not None


# Instância global para reutilização
bertimbau_service = BertimbauEmbeddingService()


async def demo_bertimbau():
    """
    Demonstração prática de uso do BERTimbau.
    """
    print("🇧🇷 DEMO: BERTimbau para Embeddings Jurídicos Brasileiros")
    print("=" * 60)
    
    if not bertimbau_service.is_available():
        print("❌ BERTimbau não disponível. Verifique as dependências.")
        return
    
    # Textos jurídicos de exemplo
    textos_juridicos = [
        "Advogado especialista em Direito Trabalhista com 15 anos de experiência",
        "Caso de indenização por danos morais e materiais",
        "Escritório de advocacia com expertise em Direito Civil e Família",
        "Processo de divórcio consensual com partilha de bens"
    ]
    
    print("📝 Gerando embeddings para textos jurídicos...")
    embeddings = []
    
    for i, texto in enumerate(textos_juridicos, 1):
        print(f"\n{i}. {texto}")
        
        start_time = time.time()
        embedding, provider = await bertimbau_service.generate_embedding(texto)
        duration = time.time() - start_time
        
        embeddings.append(embedding)
        print(f"   ✅ Embedding gerado em {duration:.2f}s ({len(embedding)}D)")
    
    # Calcular similaridades
    print(f"\n📊 Análise de Similaridades:")
    print("-" * 40)
    
    for i in range(len(embeddings)):
        for j in range(i + 1, len(embeddings)):
            similarity = bertimbau_service.get_similarity(embeddings[i], embeddings[j])
            print(f"Texto {i+1} ↔ Texto {j+1}: {similarity:.3f}")
    
    print(f"\n🎯 BERTimbau Performance:")
    print(f"   • Dimensões: {bertimbau_service.embedding_dim}D")
    print(f"   • Especialização: Português Brasileiro")
    print(f"   • Offline: ✅ (após download inicial)")
    print(f"   • Ideal para: Fallback local confiável")


# Exemplo de integração com sua arquitetura existente
async def exemplo_integracao_v2():
    """
    Mostra como integrar BERTimbau como 4º fallback em sua cascata V2.
    """
    texto = "Advogado especialista em Direito Tributário e Empresarial"
    
    print("🔄 Simulando Cascata V2 + BERTimbau:")
    print("-" * 40)
    
    # Simular falha dos primeiros provedores
    provedores = [
        ("OpenAI", False, "API key inválida"),
        ("Voyage", False, "Timeout de conexão"),
        ("Arctic", False, "Modelo não carregado"),
        ("BERTimbau", True, "Sucesso")
    ]
    
    for nome, disponivel, status in provedores:
        print(f"{nome}: {status}")
        
        if disponivel and nome == "BERTimbau":
            embedding, provider = await bertimbau_service.generate_embedding(texto)
            print(f"✅ Embedding gerado com {provider} ({len(embedding)}D)")
            break
    
    print("\n💡 BERTimbau como fallback garante 100% de disponibilidade!")


if __name__ == "__main__":
    # Executar demo
    asyncio.run(demo_bertimbau())
    print("\n" + "=" * 60)
    asyncio.run(exemplo_integracao_v2())