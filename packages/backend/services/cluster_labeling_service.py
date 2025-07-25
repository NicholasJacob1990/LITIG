#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cluster Labeling Service
========================

Serviço para rotulagem automática de clusters via LLM (GPT-4o).
Gera rótulos humanos legíveis e profissionais para clusters de casos e advogados.

Features:
- Rotulagem automática via OpenAI ChatCompletion
- Prompts especializados por tipo de cluster
- Uso de função RPC get_cluster_texts para eficiência
- Cache de rótulos para evitar re-processamento
- Métricas de confiança dos rótulos gerados
"""

import asyncio
import logging
import json
from typing import Optional, List, Dict, Any
from datetime import datetime

# OpenAI para rotulagem
try:
    import openai
    from openai import AsyncOpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    logging.warning("⚠️ OpenAI não disponível: pip install openai")
    OPENAI_AVAILABLE = False

# SQLAlchemy
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text, select
from database import get_async_session

# Configuração
import os
from dotenv import load_dotenv

load_dotenv()


class ClusterLabelingService:
    """Serviço para rotulagem automática de clusters via LLM."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.logger = logging.getLogger(__name__)
        
        # Configurar cliente OpenAI
        openai_api_key = os.getenv("OPENAI_API_KEY")
        if OPENAI_AVAILABLE and openai_api_key:
            self.openai_client = AsyncOpenAI(api_key=openai_api_key)
            self.openai_enabled = True
        else:
            self.openai_client = None
            self.openai_enabled = False
            self.logger.warning("⚠️ OpenAI não configurado - rotulagem automática desabilitada")
        
        # Configurações de rotulagem
        self.max_retries = 3
        self.timeout_seconds = 30
        self.max_samples_per_cluster = 5
        
        # Templates de prompt por tipo
        self.prompt_templates = {
            'case': {
                'system': """Você é um especialista em Direito brasileiro. Sua tarefa é analisar grupos de casos jurídicos similares e criar rótulos profissionais concisos que identifiquem o nicho específico representado.""",
                'user': """Analise os seguintes casos jurídicos brasileiros e gere um rótulo preciso e profissional que represente a especialização jurídica específica.

DIRETRIZES:
- Máximo 4 palavras
- Uso de terminologia jurídica brasileira apropriada
- Foque na área jurídica, não em aspectos processuais
- Seja específico sobre o nicho (ex: "Startup Tributário", não apenas "Direito Tributário")

Exemplos do cluster:
{examples}

Rótulo jurídico profissional:"""
            },
            'lawyer': {
                'system': """Você é um especialista em análise profissional jurídica. Sua tarefa é identificar especializações e nichos de atuação de advogados baseado em seus perfis e histórico.""",
                'user': """Analise os seguintes perfis de advogados brasileiros e identifique a especialização principal que os caracteriza como grupo.

DIRETRIZES:
- Máximo 4 palavras
- Foque na especialização profissional
- Use terminologia do mercado jurídico
- Identifique o nicho específico de atuação

Perfis do cluster:
{examples}

Especialização profissional:"""
            }
        }
    
    async def label_all_clusters(self, entity_type: str = "case", model: str = "gpt-4o", n_samples: int = 5):
        """
        Rotula todos os clusters de um tipo específico que ainda não possuem rótulo.
        
        Args:
            entity_type: 'case' ou 'lawyer'
            model: Modelo OpenAI a usar (default: gpt-4o)
            n_samples: Número de amostras por cluster
        """
        
        if not self.openai_enabled:
            self.logger.error("❌ OpenAI não configurado - impossível gerar rótulos")
            return
        
        try:
            self.logger.info(f"🏷️ Iniciando rotulagem automática para clusters de {entity_type}")
            
            # Buscar clusters únicos sem rótulo
            clusters_to_label = await self._get_unlabeled_clusters(entity_type)
            
            if not clusters_to_label:
                self.logger.info(f"✅ Todos os clusters de {entity_type} já possuem rótulos")
                return
            
            self.logger.info(f"📝 Rotulando {len(clusters_to_label)} clusters de {entity_type}")
            
            # Processar clusters em batches para evitar rate limiting
            batch_size = 5
            for i in range(0, len(clusters_to_label), batch_size):
                batch = clusters_to_label[i:i + batch_size]
                
                # Processar batch
                batch_tasks = [
                    self._label_single_cluster(cluster_id, entity_type, model, n_samples)
                    for cluster_id in batch
                ]
                
                await asyncio.gather(*batch_tasks, return_exceptions=True)
                
                # Pequena pausa entre batches
                if i + batch_size < len(clusters_to_label):
                    await asyncio.sleep(1)
                    
                self.logger.debug(f"📊 Batch {i//batch_size + 1}/{(len(clusters_to_label) + batch_size - 1)//batch_size} concluído")
            
            self.logger.info(f"✅ Rotulagem automática de {entity_type} concluída")
            
        except Exception as e:
            self.logger.error(f"❌ Erro na rotulagem de clusters: {e}")
    
    async def _get_unlabeled_clusters(self, entity_type: str) -> List[str]:
        """Busca clusters que ainda não possuem rótulos."""
        
        try:
            # Query para buscar clusters sem rótulo
            query = text(f"""
                SELECT DISTINCT cm.cluster_id 
                FROM cluster_metadata cm
                LEFT JOIN {entity_type}_cluster_labels cl ON cm.cluster_id = cl.cluster_id
                WHERE cm.cluster_type = :entity_type 
                    AND cm.total_items >= 3
                    AND cm.cluster_id NOT LIKE '%_-1'
                    AND cl.cluster_id IS NULL
                ORDER BY cm.total_items DESC
                LIMIT 50
            """)
            
            result = await self.db.execute(query, {"entity_type": entity_type})
            cluster_ids = [row.cluster_id for row in result.fetchall()]
            
            self.logger.debug(f"🔍 Encontrados {len(cluster_ids)} clusters sem rótulo para {entity_type}")
            return cluster_ids
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao buscar clusters sem rótulo: {e}")
            return []
    
    async def _label_single_cluster(self, cluster_id: str, entity_type: str, model: str, n_samples: int):
        """Rotula um cluster específico."""
        
        try:
            self.logger.debug(f"🏷️ Gerando rótulo para cluster {cluster_id}")
            
            # Buscar textos representativos usando função RPC
            sample_texts = await self._get_cluster_sample_texts(cluster_id, entity_type, n_samples)
            
            if not sample_texts:
                self.logger.warning(f"⚠️ Nenhum texto encontrado para cluster {cluster_id}")
                return
            
            # Gerar rótulo via LLM
            label = await self._generate_label_via_llm(sample_texts, entity_type, model)
            
            if label:
                # Salvar rótulo no banco
                await self._save_cluster_label(cluster_id, label, entity_type, len(sample_texts))
                self.logger.info(f"✅ Cluster {cluster_id} rotulado: '{label}'")
            else:
                self.logger.warning(f"⚠️ Falha ao gerar rótulo para cluster {cluster_id}")
                
        except Exception as e:
            self.logger.error(f"❌ Erro ao rotular cluster {cluster_id}: {e}")
    
    async def _get_cluster_sample_texts(self, cluster_id: str, entity_type: str, n_samples: int) -> List[str]:
        """Busca textos representativos de um cluster usando função RPC."""
        
        try:
            # Usar função RPC otimizada do banco
            rpc_query = text("""
                SELECT entity_id, full_text, confidence_score
                FROM get_cluster_texts(:cluster_table, :source_table, :cluster_id, :limit_n)
            """)
            
            result = await self.db.execute(rpc_query, {
                "cluster_table": f"{entity_type}_clusters",
                "source_table": f"{entity_type}s",
                "cluster_id": cluster_id,
                "limit_n": n_samples
            })
            
            rows = result.fetchall()
            
            # Extrair textos e limitar tamanho
            sample_texts = []
            for row in rows:
                text = row.full_text or ""
                # Limitar texto para evitar tokens excessivos
                if len(text) > 500:
                    text = text[:497] + "..."
                sample_texts.append(text)
            
            self.logger.debug(f"📖 Coletados {len(sample_texts)} textos para cluster {cluster_id}")
            return sample_texts
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao buscar textos do cluster {cluster_id}: {e}")
            return []
    
    async def _generate_label_via_llm(self, sample_texts: List[str], entity_type: str, model: str) -> Optional[str]:
        """Gera rótulo via LLM usando prompts especializados."""
        
        if not sample_texts or not self.openai_enabled:
            return None
        
        try:
            # Construir prompt usando template
            template = self.prompt_templates.get(entity_type, self.prompt_templates['case'])
            
            examples_text = "\n".join([f"- {text}" for text in sample_texts])
            user_prompt = template['user'].format(examples=examples_text)
            
            # Chamar OpenAI com retry
            for attempt in range(self.max_retries):
                try:
                    response = await self.openai_client.chat.completions.create(
                        model=model,
                        messages=[
                            {"role": "system", "content": template['system']},
                            {"role": "user", "content": user_prompt}
                        ],
                        max_tokens=30,
                        temperature=0.2,  # Baixa temperatura para consistência
                        timeout=self.timeout_seconds
                    )
                    
                    label = response.choices[0].message.content.strip()
                    
                    # Validar rótulo
                    if self._validate_label(label):
                        self.logger.debug(f"🎯 Rótulo gerado: '{label}'")
                        return label
                    else:
                        self.logger.warning(f"⚠️ Rótulo inválido: '{label}'")
                        
                except openai.RateLimitError:
                    self.logger.warning(f"⏳ Rate limit - tentativa {attempt + 1}/{self.max_retries}")
                    await asyncio.sleep(2 ** attempt)  # Backoff exponencial
                
                except openai.APITimeoutError:
                    self.logger.warning(f"⏰ Timeout - tentativa {attempt + 1}/{self.max_retries}")
                    await asyncio.sleep(1)
                
                except Exception as e:
                    self.logger.error(f"❌ Erro na API OpenAI (tentativa {attempt + 1}): {e}")
                    await asyncio.sleep(1)
            
            self.logger.error("❌ Falha ao gerar rótulo após todas as tentativas")
            return None
            
        except Exception as e:
            self.logger.error(f"❌ Erro na geração de rótulo via LLM: {e}")
            return None
    
    def _validate_label(self, label: str) -> bool:
        """Valida se o rótulo gerado está dentro dos critérios."""
        
        if not label or len(label.strip()) == 0:
            return False
        
        label = label.strip()
        
        # Critérios de validação
        word_count = len(label.split())
        char_count = len(label)
        
        # Máximo 4 palavras, máximo 50 caracteres
        if word_count > 4 or char_count > 50:
            return False
        
        # Não deve conter caracteres especiais problemáticos
        invalid_chars = ['<', '>', '{', '}', '[', ']', '|', '\\']
        if any(char in label for char in invalid_chars):
            return False
        
        # Deve ter pelo menos uma palavra
        if word_count < 1:
            return False
        
        return True
    
    async def _save_cluster_label(self, cluster_id: str, label: str, entity_type: str, sample_count: int):
        """Salva o rótulo gerado no banco de dados."""
        
        try:
            # Salvar na tabela específica de rótulos
            labels_query = text(f"""
                INSERT INTO {entity_type}_cluster_labels (
                    cluster_id, label, description, confidence_score, 
                    generated_by, llm_model, created_at
                ) VALUES (
                    :cluster_id, :label, :description, :confidence_score,
                    'llm_auto', 'gpt-4o', NOW()
                )
                ON CONFLICT (cluster_id) 
                DO UPDATE SET 
                    label = :label,
                    description = :description,
                    confidence_score = :confidence_score,
                    generated_by = 'llm_auto',
                    llm_model = 'gpt-4o',
                    updated_at = NOW()
            """)
            
            # Calcular confidence score baseado no número de amostras
            confidence_score = min(0.95, 0.6 + (sample_count * 0.05))
            description = f"Rótulo gerado automaticamente via LLM baseado em {sample_count} amostras"
            
            await self.db.execute(labels_query, {
                "cluster_id": cluster_id,
                "label": label,
                "description": description,
                "confidence_score": confidence_score
            })
            
            # Atualizar também na tabela de metadados
            metadata_query = text("""
                UPDATE cluster_metadata 
                SET cluster_label = :label, last_updated = NOW()
                WHERE cluster_id = :cluster_id
            """)
            
            await self.db.execute(metadata_query, {
                "cluster_id": cluster_id,
                "label": label
            })
            
            await self.db.commit()
            
            self.logger.debug(f"💾 Rótulo salvo para cluster {cluster_id}: '{label}' (confidence: {confidence_score:.2f})")
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao salvar rótulo do cluster {cluster_id}: {e}")
            await self.db.rollback()
    
    async def relabel_cluster(self, cluster_id: str, entity_type: str, model: str = "gpt-4o") -> Optional[str]:
        """
        Re-rotula um cluster específico (força nova rotulagem).
        
        Args:
            cluster_id: ID do cluster
            entity_type: 'case' ou 'lawyer'
            model: Modelo a usar
            
        Returns:
            Novo rótulo gerado ou None
        """
        
        try:
            self.logger.info(f"🔄 Re-rotulando cluster {cluster_id}")
            
            await self._label_single_cluster(cluster_id, entity_type, model, self.max_samples_per_cluster)
            
            # Buscar rótulo gerado
            query = text(f"""
                SELECT label FROM {entity_type}_cluster_labels 
                WHERE cluster_id = :cluster_id
            """)
            
            result = await self.db.execute(query, {"cluster_id": cluster_id})
            row = result.fetchone()
            
            return row.label if row else None
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao re-rotular cluster {cluster_id}: {e}")
            return None
    
    async def get_cluster_labeling_stats(self) -> Dict[str, Any]:
        """Retorna estatísticas de rotulagem de clusters."""
        
        try:
            stats = {}
            
            for entity_type in ['case', 'lawyer']:
                # Contar clusters totais e rotulados
                total_query = text(f"""
                    SELECT COUNT(*) as total
                    FROM cluster_metadata 
                    WHERE cluster_type = :entity_type 
                        AND total_items >= 3
                        AND cluster_id NOT LIKE '%_-1'
                """)
                
                labeled_query = text(f"""
                    SELECT COUNT(*) as labeled
                    FROM {entity_type}_cluster_labels cl
                    JOIN cluster_metadata cm ON cl.cluster_id = cm.cluster_id
                    WHERE cm.cluster_type = :entity_type
                        AND cm.total_items >= 3
                """)
                
                total_result = await self.db.execute(total_query, {"entity_type": entity_type})
                labeled_result = await self.db.execute(labeled_query, {"entity_type": entity_type})
                
                total_count = total_result.fetchone().total
                labeled_count = labeled_result.fetchone().labeled
                
                stats[entity_type] = {
                    "total_clusters": total_count,
                    "labeled_clusters": labeled_count,
                    "labeling_percentage": (labeled_count / total_count * 100) if total_count > 0 else 0,
                    "unlabeled_clusters": total_count - labeled_count
                }
            
            self.logger.info(f"📊 Estatísticas de rotulagem: {stats}")
            return stats
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao obter estatísticas: {e}")
            return {}


# Função utilitária para uso standalone
async def label_clusters_standalone(entity_type: str = "case"):
    """Executa rotulagem standalone (útil para scripts)."""
    
    try:
        async with get_async_session() as db:
            service = ClusterLabelingService(db)
            await service.label_all_clusters(entity_type)
            
            # Mostrar estatísticas
            stats = await service.get_cluster_labeling_stats()
            print(f"Estatísticas de rotulagem: {json.dumps(stats, indent=2)}")
            
    except Exception as e:
        logging.error(f"❌ Erro na rotulagem standalone: {e}")


if __name__ == "__main__":
    # Teste direto
    import sys
    
    entity_type = sys.argv[1] if len(sys.argv) > 1 else "case"
    asyncio.run(label_clusters_standalone(entity_type)) 