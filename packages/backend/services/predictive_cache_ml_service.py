#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
services/predictive_cache_ml_service.py

Serviço de cache predictivo avançado usando Machine Learning.
Prediz quando ocorrerão movimentações processuais para fazer cache proativo.
"""

import asyncio
import logging
import pickle
import json
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
from sklearn.ensemble import RandomForestClassifier, GradientBoostingRegressor
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, mean_absolute_error

from config.database import get_database
from config.economic_optimization import PREDICTIVE_PATTERNS, ProcessPhaseClassifier
from services.process_cache_service import process_cache_service

logger = logging.getLogger(__name__)

class PredictiveCacheMLService:
    """
    Serviço de cache predictivo usando machine learning.
    
    Recursos:
    1. Predição de próximas movimentações baseado em histórico
    2. Classificação de padrões temporais de processos
    3. Recomendação de TTL dinâmico baseado em ML
    4. Cache proativo para otimizar hit rate
    """
    
    def __init__(self):
        self.movement_classifier = None
        self.timing_predictor = None
        self.ttl_optimizer = None
        self.text_vectorizer = None
        self.label_encoder = None
        self.feature_scaler = None
        
        # Configurações de ML
        self.min_samples_for_training = 100
        self.retrain_interval_days = 7
        self.confidence_threshold = 0.75
        
    async def initialize_models(self):
        """Inicializa ou carrega modelos ML treinados."""
        logger.info("🧠 Inicializando modelos de ML para cache predictivo")
        
        try:
            # Tentar carregar modelos existentes
            await self._load_trained_models()
            logger.info("✅ Modelos ML carregados do cache")
            
        except:
            # Se não existirem, treinar novos modelos
            logger.info("🔄 Treinando novos modelos ML")
            await self.train_predictive_models()
    
    async def train_predictive_models(self):
        """Treina modelos ML com dados históricos."""
        logger.info("🎯 Iniciando treinamento de modelos predictivos")
        
        # Buscar dados de treinamento
        training_data = await self._collect_training_data()
        
        if len(training_data) < self.min_samples_for_training:
            logger.warning(f"Poucos dados para treinamento: {len(training_data)} < {self.min_samples_for_training}")
            return False
        
        # 1. Treinar classificador de movimentações
        await self._train_movement_classifier(training_data)
        
        # 2. Treinar preditor de timing
        await self._train_timing_predictor(training_data)
        
        # 3. Treinar otimizador de TTL
        await self._train_ttl_optimizer(training_data)
        
        # Salvar modelos treinados
        await self._save_trained_models()
        
        logger.info("✅ Modelos ML treinados e salvos")
        return True
    
    async def predict_next_movements(
        self, 
        cnj: str, 
        recent_movements: List[str]
    ) -> Dict[str, Any]:
        """Prediz próximas movimentações de um processo."""
        
        if not self.movement_classifier or not recent_movements:
            return {"prediction": None, "confidence": 0.0}
        
        try:
            # Extrair features do texto
            movement_text = " ".join(recent_movements[-3:])  # 3 mais recentes
            text_features = self.text_vectorizer.transform([movement_text])
            
            # Extrair features temporais e processuais
            temporal_features = await self._extract_temporal_features(cnj)
            processual_features = await self._extract_processual_features(cnj, recent_movements)
            
            # Combinar features
            combined_features = np.hstack([
                text_features.toarray(),
                temporal_features.reshape(1, -1),
                processual_features.reshape(1, -1)
            ])
            
            # Fazer predição
            prediction_proba = self.movement_classifier.predict_proba(combined_features)[0]
            predicted_class = self.movement_classifier.predict(combined_features)[0]
            confidence = max(prediction_proba)
            
            # Predizer timing se confiança for alta
            timing_prediction = None
            if confidence > self.confidence_threshold:
                timing_features = combined_features[:, :50]  # Usar subset para timing
                predicted_days = self.timing_predictor.predict(timing_features)[0]
                
                timing_prediction = {
                    "estimated_days": max(1, int(predicted_days)),
                    "estimated_date": (datetime.now() + timedelta(days=predicted_days)).isoformat()
                }
            
            # Decodificar classe predita
            predicted_movement = self.label_encoder.inverse_transform([predicted_class])[0]
            
            return {
                "prediction": predicted_movement,
                "confidence": float(confidence),
                "timing": timing_prediction,
                "should_preload": confidence > self.confidence_threshold,
                "ml_features_used": {
                    "text_features": text_features.shape[1],
                    "temporal_features": temporal_features.shape[0],
                    "processual_features": processual_features.shape[0]
                }
            }
            
        except Exception as e:
            logger.error(f"Erro na predição ML para CNJ {cnj}: {e}")
            return {"prediction": None, "confidence": 0.0, "error": str(e)}
    
    async def optimize_ttl_with_ml(
        self, 
        cnj: str, 
        current_access_pattern: str,
        process_phase: str
    ) -> Dict[str, int]:
        """Otimiza TTL usando ML baseado em padrões de acesso."""
        
        if not self.ttl_optimizer:
            # Fallback para método baseado em regras
            return ProcessPhaseClassifier.get_optimal_ttl(
                phase=process_phase,
                last_movement_days=30,
                access_pattern=current_access_pattern
            )
        
        try:
            # Extrair features para otimização de TTL
            access_features = await self._extract_access_features(cnj, current_access_pattern)
            phase_features = self._encode_phase_features(process_phase)
            historical_features = await self._extract_historical_features(cnj)
            
            # Combinar features
            ttl_features = np.hstack([access_features, phase_features, historical_features]).reshape(1, -1)
            ttl_features_scaled = self.feature_scaler.transform(ttl_features)
            
            # Predizer TTLs otimizados
            predicted_redis_ttl = self.ttl_optimizer.predict(ttl_features_scaled)[0]
            
            # Calcular TTLs relacionados baseado no Redis TTL
            optimal_config = {
                "redis_ttl": max(900, int(predicted_redis_ttl)),  # Mínimo 15 min
                "db_ttl": max(3600, int(predicted_redis_ttl * 3)),  # 3x o Redis
                "sync_interval": max(1800, int(predicted_redis_ttl * 2)),  # 2x o Redis
                "ml_optimized": True,
                "confidence": 0.8  # Placeholder - seria calculado da validação
            }
            
            logger.info(f"TTL otimizado por ML para {cnj}: Redis={optimal_config['redis_ttl']}s")
            return optimal_config
            
        except Exception as e:
            logger.error(f"Erro na otimização ML de TTL para {cnj}: {e}")
            # Fallback para método baseado em regras
            return ProcessPhaseClassifier.get_optimal_ttl(
                phase=process_phase,
                last_movement_days=30,
                access_pattern=current_access_pattern
            )
    
    async def run_proactive_caching(self):
        """Executa cache proativo baseado em predições ML."""
        logger.info("🔮 Iniciando cache proativo baseado em ML")
        
        if not self.movement_classifier:
            logger.warning("Modelos ML não inicializados - pulando cache proativo")
            return
        
        async with get_database() as conn:
            # Buscar processos ativos com movimentações recentes
            query = """
                SELECT DISTINCT pm.cnj
                FROM process_movements pm
                JOIN process_optimization_config poc ON pm.cnj = poc.cnj
                WHERE pm.fetched_from_api_at > NOW() - INTERVAL '7 days'
                AND poc.last_accessed_at > NOW() - INTERVAL '3 days'
                ORDER BY poc.access_count DESC
                LIMIT 50
            """
            
            active_processes = await conn.fetch(query)
            
            proactive_cache_count = 0
            
            for process_row in active_processes:
                cnj = process_row['cnj']
                
                try:
                    # Buscar movimentações recentes
                    movements_query = """
                        SELECT movement_data->'movements' as movements
                        FROM process_movements 
                        WHERE cnj = $1 
                        ORDER BY fetched_from_api_at DESC 
                        LIMIT 1
                    """
                    
                    movement_result = await conn.fetchrow(movements_query, cnj)
                    
                    if movement_result and movement_result['movements']:
                        movements_data = movement_result['movements']
                        
                        # Extrair textos das movimentações
                        movement_texts = []
                        if isinstance(movements_data, list):
                            for mov in movements_data[:5]:
                                if isinstance(mov, dict):
                                    content = mov.get('full_content') or mov.get('description', '')
                                    if content:
                                        movement_texts.append(content)
                        
                        if movement_texts:
                            # Fazer predição
                            prediction = await self.predict_next_movements(cnj, movement_texts)
                            
                            # Se predição for confiável e timing for próximo
                            if (prediction.get("should_preload") and 
                                prediction.get("timing") and
                                prediction["timing"].get("estimated_days", 999) <= 3):
                                
                                # Fazer cache proativo
                                await self._proactive_cache_update(cnj)
                                proactive_cache_count += 1
                                
                                logger.info(f"Cache proativo aplicado para {cnj} - predição: {prediction['prediction']}")
                
                except Exception as e:
                    logger.warning(f"Erro no cache proativo para {cnj}: {e}")
            
            logger.info(f"🔮 Cache proativo concluído: {proactive_cache_count} processos atualizados")
    
    async def _collect_training_data(self) -> List[Dict[str, Any]]:
        """Coleta dados históricos para treinamento."""
        async with get_database() as conn:
            # Buscar histórico de movimentações com timing
            training_query = """
                SELECT 
                    pm.cnj,
                    pm.movement_data,
                    pm.fetched_from_api_at,
                    poc.detected_phase,
                    poc.process_area,
                    poc.access_count,
                    poc.access_pattern,
                    poc.redis_ttl_seconds,
                    poc.last_accessed_at,
                    LAG(pm.fetched_from_api_at) OVER (
                        PARTITION BY pm.cnj 
                        ORDER BY pm.fetched_from_api_at
                    ) as previous_fetch
                FROM process_movements pm
                LEFT JOIN process_optimization_config poc ON pm.cnj = poc.cnj
                WHERE pm.fetched_from_api_at > NOW() - INTERVAL '60 days'
                ORDER BY pm.cnj, pm.fetched_from_api_at
            """
            
            results = await conn.fetch(training_query)
            
            training_data = []
            for row in results:
                if row['previous_fetch']:  # Só incluir se tiver movimento anterior
                    # Calcular intervalo entre movimentações
                    time_diff = (row['fetched_from_api_at'] - row['previous_fetch']).total_seconds() / 86400  # em dias
                    
                    if 0.1 <= time_diff <= 90:  # Filtrar intervalos razoáveis
                        training_data.append({
                            'cnj': row['cnj'],
                            'movement_data': row['movement_data'],
                            'time_to_next_movement': time_diff,
                            'phase': row['detected_phase'] or 'unknown',
                            'area': row['process_area'] or 'unknown',
                            'access_count': row['access_count'] or 0,
                            'access_pattern': row['access_pattern'] or 'weekly',
                            'current_ttl': row['redis_ttl_seconds'] or 3600
                        })
            
            logger.info(f"📊 Coletados {len(training_data)} amostras para treinamento")
            return training_data
    
    async def _train_movement_classifier(self, training_data: List[Dict[str, Any]]):
        """Treina classificador de tipos de movimentação."""
        texts = []
        labels = []
        
        for sample in training_data:
            if sample['movement_data'] and isinstance(sample['movement_data'], dict):
                movements = sample['movement_data'].get('movements', [])
                if movements and isinstance(movements, list):
                    # Extrair texto da última movimentação
                    last_movement = movements[0] if movements else {}
                    if isinstance(last_movement, dict):
                        text = last_movement.get('full_content') or last_movement.get('description', '')
                        if text:
                            texts.append(text)
                            
                            # Classificar tipo de movimentação baseado em padrões
                            movement_type = self._classify_movement_type(text)
                            labels.append(movement_type)
        
        if len(texts) < 50:
            logger.warning("Poucos textos para treinar classificador de movimentações")
            return
        
        # Vetorizar textos
        self.text_vectorizer = TfidfVectorizer(
            max_features=1000,
            stop_words=['de', 'da', 'do', 'para', 'com', 'em', 'por'],  # Stop words PT
            ngram_range=(1, 2)
        )
        text_features = self.text_vectorizer.fit_transform(texts)
        
        # Codificar labels
        self.label_encoder = LabelEncoder()
        encoded_labels = self.label_encoder.fit_transform(labels)
        
        # Treinar classificador
        self.movement_classifier = RandomForestClassifier(
            n_estimators=100,
            random_state=42,
            max_depth=10
        )
        
        # Split para validação
        X_train, X_test, y_train, y_test = train_test_split(
            text_features, encoded_labels, test_size=0.2, random_state=42
        )
        
        self.movement_classifier.fit(X_train, y_train)
        
        # Avaliar performance
        y_pred = self.movement_classifier.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        
        logger.info(f"🎯 Classificador de movimentações treinado - Acurácia: {accuracy:.3f}")
    
    async def _train_timing_predictor(self, training_data: List[Dict[str, Any]]):
        """Treina preditor de timing de próximas movimentações."""
        features = []
        targets = []
        
        for sample in training_data:
            # Extrair features numéricas
            feature_vector = [
                sample['access_count'],
                len(sample['phase']),  # Proxy para complexidade da fase
                1 if sample['area'] == 'trabalhista' else 0,  # Área mais rápida
                1 if sample['area'] == 'tributario' else 0,   # Área mais lenta
                sample['current_ttl'] / 3600,  # TTL em horas
            ]
            
            features.append(feature_vector)
            targets.append(sample['time_to_next_movement'])
        
        if len(features) < 50:
            logger.warning("Poucos dados para treinar preditor de timing")
            return
        
        features_array = np.array(features)
        targets_array = np.array(targets)
        
        # Treinar regressor
        self.timing_predictor = GradientBoostingRegressor(
            n_estimators=100,
            random_state=42,
            max_depth=6
        )
        
        # Split para validação
        X_train, X_test, y_train, y_test = train_test_split(
            features_array, targets_array, test_size=0.2, random_state=42
        )
        
        self.timing_predictor.fit(X_train, y_train)
        
        # Avaliar performance
        y_pred = self.timing_predictor.predict(X_test)
        mae = mean_absolute_error(y_test, y_pred)
        
        logger.info(f"⏰ Preditor de timing treinado - MAE: {mae:.2f} dias")
    
    async def _train_ttl_optimizer(self, training_data: List[Dict[str, Any]]):
        """Treina otimizador de TTL baseado em padrões de acesso."""
        features = []
        targets = []
        
        for sample in training_data:
            # Features para otimização de TTL
            feature_vector = [
                sample['access_count'],
                sample['time_to_next_movement'],
                1 if sample['access_pattern'] == 'daily' else 0,
                1 if sample['access_pattern'] == 'weekly' else 0,
                1 if sample['access_pattern'] == 'monthly' else 0,
                len(sample['phase']),  # Complexidade da fase
                1 if sample['area'] == 'penal' else 0,  # Necessita TTL menor
            ]
            
            features.append(feature_vector)
            # Target é o TTL atual (assumindo que está otimizado)
            targets.append(sample['current_ttl'])
        
        if len(features) < 50:
            logger.warning("Poucos dados para treinar otimizador de TTL")
            return
        
        features_array = np.array(features)
        targets_array = np.array(targets)
        
        # Normalizar features
        self.feature_scaler = StandardScaler()
        features_scaled = self.feature_scaler.fit_transform(features_array)
        
        # Treinar otimizador
        self.ttl_optimizer = GradientBoostingRegressor(
            n_estimators=100,
            random_state=42,
            max_depth=4
        )
        
        self.ttl_optimizer.fit(features_scaled, targets_array)
        
        logger.info("🔧 Otimizador de TTL treinado")
    
    def _classify_movement_type(self, text: str) -> str:
        """Classifica tipo de movimentação baseado no texto."""
        text_lower = text.lower()
        
        if any(word in text_lower for word in ['sentença', 'sentenca', 'julgado']):
            return 'sentenca'
        elif any(word in text_lower for word in ['audiência', 'audiencia', 'designada']):
            return 'audiencia'
        elif any(word in text_lower for word in ['petição', 'peticao', 'juntada']):
            return 'peticao'
        elif any(word in text_lower for word in ['recurso', 'apelação', 'apelacao']):
            return 'recurso'
        elif any(word in text_lower for word in ['despacho', 'decisão', 'decisao']):
            return 'despacho'
        else:
            return 'outros'
    
    async def _extract_temporal_features(self, cnj: str) -> np.ndarray:
        """Extrai features temporais do processo."""
        # Features básicas temporais (seria expandido com dados reais)
        current_hour = datetime.now().hour
        current_day = datetime.now().weekday()
        
        return np.array([
            current_hour / 24.0,  # Normalizado
            current_day / 7.0,    # Normalizado
            1.0 if 9 <= current_hour <= 17 else 0.0,  # Horário comercial
            1.0 if current_day < 5 else 0.0,  # Dia útil
        ])
    
    async def _extract_processual_features(self, cnj: str, movements: List[str]) -> np.ndarray:
        """Extrai features específicas do processo."""
        # Features básicas processuais
        return np.array([
            len(movements),  # Número de movimentações
            len(" ".join(movements)) / 1000.0,  # Tamanho normalizado do texto
            1.0 if any('urgente' in m.lower() for m in movements) else 0.0,  # Urgência
            1.0 if any('liminar' in m.lower() for m in movements) else 0.0,  # Liminar
        ])
    
    async def _extract_access_features(self, cnj: str, access_pattern: str) -> np.ndarray:
        """Extrai features de padrão de acesso."""
        pattern_encoding = {
            'daily': [1, 0, 0, 0],
            'weekly': [0, 1, 0, 0], 
            'monthly': [0, 0, 1, 0],
            'rarely': [0, 0, 0, 1]
        }
        
        return np.array(pattern_encoding.get(access_pattern, [0, 1, 0, 0]))
    
    def _encode_phase_features(self, phase: str) -> np.ndarray:
        """Codifica features da fase processual."""
        phase_encoding = {
            'inicial': [1, 0, 0, 0, 0, 0],
            'instrutoria': [0, 1, 0, 0, 0, 0],
            'decisoria': [0, 0, 1, 0, 0, 0],
            'recursal': [0, 0, 0, 1, 0, 0],
            'final': [0, 0, 0, 0, 1, 0],
            'arquivado': [0, 0, 0, 0, 0, 1]
        }
        
        return np.array(phase_encoding.get(phase, [0, 1, 0, 0, 0, 0]))
    
    async def _extract_historical_features(self, cnj: str) -> np.ndarray:
        """Extrai features do histórico do processo."""
        # Features históricas básicas (seria expandido com dados reais)
        return np.array([
            0.5,  # Taxa histórica de cache hit
            30.0, # Dias médios entre movimentações
            5.0   # Número médio de acessos por semana
        ])
    
    async def _proactive_cache_update(self, cnj: str):
        """Executa atualização proativa do cache."""
        try:
            # Usar o serviço de cache para atualizar dados
            if process_cache_service:
                await process_cache_service.get_process_movements_cached(
                    cnj=cnj,
                    limit=50,
                    force_refresh=True  # Forçar atualização
                )
                logger.debug(f"Cache proativo atualizado para {cnj}")
        except Exception as e:
            logger.warning(f"Erro no cache proativo para {cnj}: {e}")
    
    async def _save_trained_models(self):
        """Salva modelos treinados no banco de dados."""
        try:
            models_data = {
                'movement_classifier': pickle.dumps(self.movement_classifier) if self.movement_classifier else None,
                'timing_predictor': pickle.dumps(self.timing_predictor) if self.timing_predictor else None,
                'ttl_optimizer': pickle.dumps(self.ttl_optimizer) if self.ttl_optimizer else None,
                'text_vectorizer': pickle.dumps(self.text_vectorizer) if self.text_vectorizer else None,
                'label_encoder': pickle.dumps(self.label_encoder) if self.label_encoder else None,
                'feature_scaler': pickle.dumps(self.feature_scaler) if self.feature_scaler else None,
                'trained_at': datetime.now().isoformat()
            }
            
            async with get_database() as conn:
                # Criar tabela se não existir
                create_table = """
                    CREATE TABLE IF NOT EXISTS ml_models_cache (
                        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                        model_type TEXT NOT NULL,
                        model_data BYTEA,
                        trained_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                    )
                """
                await conn.execute(create_table)
                
                # Salvar cada modelo
                for model_name, model_data in models_data.items():
                    if model_data and model_name != 'trained_at':
                        await conn.execute(
                            """
                            INSERT INTO ml_models_cache (model_type, model_data)
                            VALUES ($1, $2)
                            ON CONFLICT (model_type) DO UPDATE SET
                                model_data = $2,
                                trained_at = NOW()
                            """,
                            model_name, model_data
                        )
            
            logger.info("💾 Modelos ML salvos no banco de dados")
            
        except Exception as e:
            logger.error(f"Erro ao salvar modelos ML: {e}")
    
    async def _load_trained_models(self):
        """Carrega modelos treinados do banco de dados."""
        async with get_database() as conn:
            # Buscar modelos salvos
            results = await conn.fetch(
                "SELECT model_type, model_data FROM ml_models_cache"
            )
            
            for row in results:
                model_type = row['model_type']
                model_data = row['model_data']
                
                if model_data:
                    if model_type == 'movement_classifier':
                        self.movement_classifier = pickle.loads(model_data)
                    elif model_type == 'timing_predictor':
                        self.timing_predictor = pickle.loads(model_data)
                    elif model_type == 'ttl_optimizer':
                        self.ttl_optimizer = pickle.loads(model_data)
                    elif model_type == 'text_vectorizer':
                        self.text_vectorizer = pickle.loads(model_data)
                    elif model_type == 'label_encoder':
                        self.label_encoder = pickle.loads(model_data)
                    elif model_type == 'feature_scaler':
                        self.feature_scaler = pickle.loads(model_data)

# ============================================================================
# INSTÂNCIA GLOBAL DO SERVIÇO
# ============================================================================

predictive_cache_ml = PredictiveCacheMLService() 
# -*- coding: utf-8 -*-
"""
services/predictive_cache_ml_service.py

Serviço de cache predictivo avançado usando Machine Learning.
Prediz quando ocorrerão movimentações processuais para fazer cache proativo.
"""

import asyncio
import logging
import pickle
import json
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
from sklearn.ensemble import RandomForestClassifier, GradientBoostingRegressor
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, mean_absolute_error

from config.database import get_database
from config.economic_optimization import PREDICTIVE_PATTERNS, ProcessPhaseClassifier
from services.process_cache_service import process_cache_service

logger = logging.getLogger(__name__)

class PredictiveCacheMLService:
    """
    Serviço de cache predictivo usando machine learning.
    
    Recursos:
    1. Predição de próximas movimentações baseado em histórico
    2. Classificação de padrões temporais de processos
    3. Recomendação de TTL dinâmico baseado em ML
    4. Cache proativo para otimizar hit rate
    """
    
    def __init__(self):
        self.movement_classifier = None
        self.timing_predictor = None
        self.ttl_optimizer = None
        self.text_vectorizer = None
        self.label_encoder = None
        self.feature_scaler = None
        
        # Configurações de ML
        self.min_samples_for_training = 100
        self.retrain_interval_days = 7
        self.confidence_threshold = 0.75
        
    async def initialize_models(self):
        """Inicializa ou carrega modelos ML treinados."""
        logger.info("🧠 Inicializando modelos de ML para cache predictivo")
        
        try:
            # Tentar carregar modelos existentes
            await self._load_trained_models()
            logger.info("✅ Modelos ML carregados do cache")
            
        except:
            # Se não existirem, treinar novos modelos
            logger.info("🔄 Treinando novos modelos ML")
            await self.train_predictive_models()
    
    async def train_predictive_models(self):
        """Treina modelos ML com dados históricos."""
        logger.info("🎯 Iniciando treinamento de modelos predictivos")
        
        # Buscar dados de treinamento
        training_data = await self._collect_training_data()
        
        if len(training_data) < self.min_samples_for_training:
            logger.warning(f"Poucos dados para treinamento: {len(training_data)} < {self.min_samples_for_training}")
            return False
        
        # 1. Treinar classificador de movimentações
        await self._train_movement_classifier(training_data)
        
        # 2. Treinar preditor de timing
        await self._train_timing_predictor(training_data)
        
        # 3. Treinar otimizador de TTL
        await self._train_ttl_optimizer(training_data)
        
        # Salvar modelos treinados
        await self._save_trained_models()
        
        logger.info("✅ Modelos ML treinados e salvos")
        return True
    
    async def predict_next_movements(
        self, 
        cnj: str, 
        recent_movements: List[str]
    ) -> Dict[str, Any]:
        """Prediz próximas movimentações de um processo."""
        
        if not self.movement_classifier or not recent_movements:
            return {"prediction": None, "confidence": 0.0}
        
        try:
            # Extrair features do texto
            movement_text = " ".join(recent_movements[-3:])  # 3 mais recentes
            text_features = self.text_vectorizer.transform([movement_text])
            
            # Extrair features temporais e processuais
            temporal_features = await self._extract_temporal_features(cnj)
            processual_features = await self._extract_processual_features(cnj, recent_movements)
            
            # Combinar features
            combined_features = np.hstack([
                text_features.toarray(),
                temporal_features.reshape(1, -1),
                processual_features.reshape(1, -1)
            ])
            
            # Fazer predição
            prediction_proba = self.movement_classifier.predict_proba(combined_features)[0]
            predicted_class = self.movement_classifier.predict(combined_features)[0]
            confidence = max(prediction_proba)
            
            # Predizer timing se confiança for alta
            timing_prediction = None
            if confidence > self.confidence_threshold:
                timing_features = combined_features[:, :50]  # Usar subset para timing
                predicted_days = self.timing_predictor.predict(timing_features)[0]
                
                timing_prediction = {
                    "estimated_days": max(1, int(predicted_days)),
                    "estimated_date": (datetime.now() + timedelta(days=predicted_days)).isoformat()
                }
            
            # Decodificar classe predita
            predicted_movement = self.label_encoder.inverse_transform([predicted_class])[0]
            
            return {
                "prediction": predicted_movement,
                "confidence": float(confidence),
                "timing": timing_prediction,
                "should_preload": confidence > self.confidence_threshold,
                "ml_features_used": {
                    "text_features": text_features.shape[1],
                    "temporal_features": temporal_features.shape[0],
                    "processual_features": processual_features.shape[0]
                }
            }
            
        except Exception as e:
            logger.error(f"Erro na predição ML para CNJ {cnj}: {e}")
            return {"prediction": None, "confidence": 0.0, "error": str(e)}
    
    async def optimize_ttl_with_ml(
        self, 
        cnj: str, 
        current_access_pattern: str,
        process_phase: str
    ) -> Dict[str, int]:
        """Otimiza TTL usando ML baseado em padrões de acesso."""
        
        if not self.ttl_optimizer:
            # Fallback para método baseado em regras
            return ProcessPhaseClassifier.get_optimal_ttl(
                phase=process_phase,
                last_movement_days=30,
                access_pattern=current_access_pattern
            )
        
        try:
            # Extrair features para otimização de TTL
            access_features = await self._extract_access_features(cnj, current_access_pattern)
            phase_features = self._encode_phase_features(process_phase)
            historical_features = await self._extract_historical_features(cnj)
            
            # Combinar features
            ttl_features = np.hstack([access_features, phase_features, historical_features]).reshape(1, -1)
            ttl_features_scaled = self.feature_scaler.transform(ttl_features)
            
            # Predizer TTLs otimizados
            predicted_redis_ttl = self.ttl_optimizer.predict(ttl_features_scaled)[0]
            
            # Calcular TTLs relacionados baseado no Redis TTL
            optimal_config = {
                "redis_ttl": max(900, int(predicted_redis_ttl)),  # Mínimo 15 min
                "db_ttl": max(3600, int(predicted_redis_ttl * 3)),  # 3x o Redis
                "sync_interval": max(1800, int(predicted_redis_ttl * 2)),  # 2x o Redis
                "ml_optimized": True,
                "confidence": 0.8  # Placeholder - seria calculado da validação
            }
            
            logger.info(f"TTL otimizado por ML para {cnj}: Redis={optimal_config['redis_ttl']}s")
            return optimal_config
            
        except Exception as e:
            logger.error(f"Erro na otimização ML de TTL para {cnj}: {e}")
            # Fallback para método baseado em regras
            return ProcessPhaseClassifier.get_optimal_ttl(
                phase=process_phase,
                last_movement_days=30,
                access_pattern=current_access_pattern
            )
    
    async def run_proactive_caching(self):
        """Executa cache proativo baseado em predições ML."""
        logger.info("🔮 Iniciando cache proativo baseado em ML")
        
        if not self.movement_classifier:
            logger.warning("Modelos ML não inicializados - pulando cache proativo")
            return
        
        async with get_database() as conn:
            # Buscar processos ativos com movimentações recentes
            query = """
                SELECT DISTINCT pm.cnj
                FROM process_movements pm
                JOIN process_optimization_config poc ON pm.cnj = poc.cnj
                WHERE pm.fetched_from_api_at > NOW() - INTERVAL '7 days'
                AND poc.last_accessed_at > NOW() - INTERVAL '3 days'
                ORDER BY poc.access_count DESC
                LIMIT 50
            """
            
            active_processes = await conn.fetch(query)
            
            proactive_cache_count = 0
            
            for process_row in active_processes:
                cnj = process_row['cnj']
                
                try:
                    # Buscar movimentações recentes
                    movements_query = """
                        SELECT movement_data->'movements' as movements
                        FROM process_movements 
                        WHERE cnj = $1 
                        ORDER BY fetched_from_api_at DESC 
                        LIMIT 1
                    """
                    
                    movement_result = await conn.fetchrow(movements_query, cnj)
                    
                    if movement_result and movement_result['movements']:
                        movements_data = movement_result['movements']
                        
                        # Extrair textos das movimentações
                        movement_texts = []
                        if isinstance(movements_data, list):
                            for mov in movements_data[:5]:
                                if isinstance(mov, dict):
                                    content = mov.get('full_content') or mov.get('description', '')
                                    if content:
                                        movement_texts.append(content)
                        
                        if movement_texts:
                            # Fazer predição
                            prediction = await self.predict_next_movements(cnj, movement_texts)
                            
                            # Se predição for confiável e timing for próximo
                            if (prediction.get("should_preload") and 
                                prediction.get("timing") and
                                prediction["timing"].get("estimated_days", 999) <= 3):
                                
                                # Fazer cache proativo
                                await self._proactive_cache_update(cnj)
                                proactive_cache_count += 1
                                
                                logger.info(f"Cache proativo aplicado para {cnj} - predição: {prediction['prediction']}")
                
                except Exception as e:
                    logger.warning(f"Erro no cache proativo para {cnj}: {e}")
            
            logger.info(f"🔮 Cache proativo concluído: {proactive_cache_count} processos atualizados")
    
    async def _collect_training_data(self) -> List[Dict[str, Any]]:
        """Coleta dados históricos para treinamento."""
        async with get_database() as conn:
            # Buscar histórico de movimentações com timing
            training_query = """
                SELECT 
                    pm.cnj,
                    pm.movement_data,
                    pm.fetched_from_api_at,
                    poc.detected_phase,
                    poc.process_area,
                    poc.access_count,
                    poc.access_pattern,
                    poc.redis_ttl_seconds,
                    poc.last_accessed_at,
                    LAG(pm.fetched_from_api_at) OVER (
                        PARTITION BY pm.cnj 
                        ORDER BY pm.fetched_from_api_at
                    ) as previous_fetch
                FROM process_movements pm
                LEFT JOIN process_optimization_config poc ON pm.cnj = poc.cnj
                WHERE pm.fetched_from_api_at > NOW() - INTERVAL '60 days'
                ORDER BY pm.cnj, pm.fetched_from_api_at
            """
            
            results = await conn.fetch(training_query)
            
            training_data = []
            for row in results:
                if row['previous_fetch']:  # Só incluir se tiver movimento anterior
                    # Calcular intervalo entre movimentações
                    time_diff = (row['fetched_from_api_at'] - row['previous_fetch']).total_seconds() / 86400  # em dias
                    
                    if 0.1 <= time_diff <= 90:  # Filtrar intervalos razoáveis
                        training_data.append({
                            'cnj': row['cnj'],
                            'movement_data': row['movement_data'],
                            'time_to_next_movement': time_diff,
                            'phase': row['detected_phase'] or 'unknown',
                            'area': row['process_area'] or 'unknown',
                            'access_count': row['access_count'] or 0,
                            'access_pattern': row['access_pattern'] or 'weekly',
                            'current_ttl': row['redis_ttl_seconds'] or 3600
                        })
            
            logger.info(f"📊 Coletados {len(training_data)} amostras para treinamento")
            return training_data
    
    async def _train_movement_classifier(self, training_data: List[Dict[str, Any]]):
        """Treina classificador de tipos de movimentação."""
        texts = []
        labels = []
        
        for sample in training_data:
            if sample['movement_data'] and isinstance(sample['movement_data'], dict):
                movements = sample['movement_data'].get('movements', [])
                if movements and isinstance(movements, list):
                    # Extrair texto da última movimentação
                    last_movement = movements[0] if movements else {}
                    if isinstance(last_movement, dict):
                        text = last_movement.get('full_content') or last_movement.get('description', '')
                        if text:
                            texts.append(text)
                            
                            # Classificar tipo de movimentação baseado em padrões
                            movement_type = self._classify_movement_type(text)
                            labels.append(movement_type)
        
        if len(texts) < 50:
            logger.warning("Poucos textos para treinar classificador de movimentações")
            return
        
        # Vetorizar textos
        self.text_vectorizer = TfidfVectorizer(
            max_features=1000,
            stop_words=['de', 'da', 'do', 'para', 'com', 'em', 'por'],  # Stop words PT
            ngram_range=(1, 2)
        )
        text_features = self.text_vectorizer.fit_transform(texts)
        
        # Codificar labels
        self.label_encoder = LabelEncoder()
        encoded_labels = self.label_encoder.fit_transform(labels)
        
        # Treinar classificador
        self.movement_classifier = RandomForestClassifier(
            n_estimators=100,
            random_state=42,
            max_depth=10
        )
        
        # Split para validação
        X_train, X_test, y_train, y_test = train_test_split(
            text_features, encoded_labels, test_size=0.2, random_state=42
        )
        
        self.movement_classifier.fit(X_train, y_train)
        
        # Avaliar performance
        y_pred = self.movement_classifier.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        
        logger.info(f"🎯 Classificador de movimentações treinado - Acurácia: {accuracy:.3f}")
    
    async def _train_timing_predictor(self, training_data: List[Dict[str, Any]]):
        """Treina preditor de timing de próximas movimentações."""
        features = []
        targets = []
        
        for sample in training_data:
            # Extrair features numéricas
            feature_vector = [
                sample['access_count'],
                len(sample['phase']),  # Proxy para complexidade da fase
                1 if sample['area'] == 'trabalhista' else 0,  # Área mais rápida
                1 if sample['area'] == 'tributario' else 0,   # Área mais lenta
                sample['current_ttl'] / 3600,  # TTL em horas
            ]
            
            features.append(feature_vector)
            targets.append(sample['time_to_next_movement'])
        
        if len(features) < 50:
            logger.warning("Poucos dados para treinar preditor de timing")
            return
        
        features_array = np.array(features)
        targets_array = np.array(targets)
        
        # Treinar regressor
        self.timing_predictor = GradientBoostingRegressor(
            n_estimators=100,
            random_state=42,
            max_depth=6
        )
        
        # Split para validação
        X_train, X_test, y_train, y_test = train_test_split(
            features_array, targets_array, test_size=0.2, random_state=42
        )
        
        self.timing_predictor.fit(X_train, y_train)
        
        # Avaliar performance
        y_pred = self.timing_predictor.predict(X_test)
        mae = mean_absolute_error(y_test, y_pred)
        
        logger.info(f"⏰ Preditor de timing treinado - MAE: {mae:.2f} dias")
    
    async def _train_ttl_optimizer(self, training_data: List[Dict[str, Any]]):
        """Treina otimizador de TTL baseado em padrões de acesso."""
        features = []
        targets = []
        
        for sample in training_data:
            # Features para otimização de TTL
            feature_vector = [
                sample['access_count'],
                sample['time_to_next_movement'],
                1 if sample['access_pattern'] == 'daily' else 0,
                1 if sample['access_pattern'] == 'weekly' else 0,
                1 if sample['access_pattern'] == 'monthly' else 0,
                len(sample['phase']),  # Complexidade da fase
                1 if sample['area'] == 'penal' else 0,  # Necessita TTL menor
            ]
            
            features.append(feature_vector)
            # Target é o TTL atual (assumindo que está otimizado)
            targets.append(sample['current_ttl'])
        
        if len(features) < 50:
            logger.warning("Poucos dados para treinar otimizador de TTL")
            return
        
        features_array = np.array(features)
        targets_array = np.array(targets)
        
        # Normalizar features
        self.feature_scaler = StandardScaler()
        features_scaled = self.feature_scaler.fit_transform(features_array)
        
        # Treinar otimizador
        self.ttl_optimizer = GradientBoostingRegressor(
            n_estimators=100,
            random_state=42,
            max_depth=4
        )
        
        self.ttl_optimizer.fit(features_scaled, targets_array)
        
        logger.info("🔧 Otimizador de TTL treinado")
    
    def _classify_movement_type(self, text: str) -> str:
        """Classifica tipo de movimentação baseado no texto."""
        text_lower = text.lower()
        
        if any(word in text_lower for word in ['sentença', 'sentenca', 'julgado']):
            return 'sentenca'
        elif any(word in text_lower for word in ['audiência', 'audiencia', 'designada']):
            return 'audiencia'
        elif any(word in text_lower for word in ['petição', 'peticao', 'juntada']):
            return 'peticao'
        elif any(word in text_lower for word in ['recurso', 'apelação', 'apelacao']):
            return 'recurso'
        elif any(word in text_lower for word in ['despacho', 'decisão', 'decisao']):
            return 'despacho'
        else:
            return 'outros'
    
    async def _extract_temporal_features(self, cnj: str) -> np.ndarray:
        """Extrai features temporais do processo."""
        # Features básicas temporais (seria expandido com dados reais)
        current_hour = datetime.now().hour
        current_day = datetime.now().weekday()
        
        return np.array([
            current_hour / 24.0,  # Normalizado
            current_day / 7.0,    # Normalizado
            1.0 if 9 <= current_hour <= 17 else 0.0,  # Horário comercial
            1.0 if current_day < 5 else 0.0,  # Dia útil
        ])
    
    async def _extract_processual_features(self, cnj: str, movements: List[str]) -> np.ndarray:
        """Extrai features específicas do processo."""
        # Features básicas processuais
        return np.array([
            len(movements),  # Número de movimentações
            len(" ".join(movements)) / 1000.0,  # Tamanho normalizado do texto
            1.0 if any('urgente' in m.lower() for m in movements) else 0.0,  # Urgência
            1.0 if any('liminar' in m.lower() for m in movements) else 0.0,  # Liminar
        ])
    
    async def _extract_access_features(self, cnj: str, access_pattern: str) -> np.ndarray:
        """Extrai features de padrão de acesso."""
        pattern_encoding = {
            'daily': [1, 0, 0, 0],
            'weekly': [0, 1, 0, 0], 
            'monthly': [0, 0, 1, 0],
            'rarely': [0, 0, 0, 1]
        }
        
        return np.array(pattern_encoding.get(access_pattern, [0, 1, 0, 0]))
    
    def _encode_phase_features(self, phase: str) -> np.ndarray:
        """Codifica features da fase processual."""
        phase_encoding = {
            'inicial': [1, 0, 0, 0, 0, 0],
            'instrutoria': [0, 1, 0, 0, 0, 0],
            'decisoria': [0, 0, 1, 0, 0, 0],
            'recursal': [0, 0, 0, 1, 0, 0],
            'final': [0, 0, 0, 0, 1, 0],
            'arquivado': [0, 0, 0, 0, 0, 1]
        }
        
        return np.array(phase_encoding.get(phase, [0, 1, 0, 0, 0, 0]))
    
    async def _extract_historical_features(self, cnj: str) -> np.ndarray:
        """Extrai features do histórico do processo."""
        # Features históricas básicas (seria expandido com dados reais)
        return np.array([
            0.5,  # Taxa histórica de cache hit
            30.0, # Dias médios entre movimentações
            5.0   # Número médio de acessos por semana
        ])
    
    async def _proactive_cache_update(self, cnj: str):
        """Executa atualização proativa do cache."""
        try:
            # Usar o serviço de cache para atualizar dados
            if process_cache_service:
                await process_cache_service.get_process_movements_cached(
                    cnj=cnj,
                    limit=50,
                    force_refresh=True  # Forçar atualização
                )
                logger.debug(f"Cache proativo atualizado para {cnj}")
        except Exception as e:
            logger.warning(f"Erro no cache proativo para {cnj}: {e}")
    
    async def _save_trained_models(self):
        """Salva modelos treinados no banco de dados."""
        try:
            models_data = {
                'movement_classifier': pickle.dumps(self.movement_classifier) if self.movement_classifier else None,
                'timing_predictor': pickle.dumps(self.timing_predictor) if self.timing_predictor else None,
                'ttl_optimizer': pickle.dumps(self.ttl_optimizer) if self.ttl_optimizer else None,
                'text_vectorizer': pickle.dumps(self.text_vectorizer) if self.text_vectorizer else None,
                'label_encoder': pickle.dumps(self.label_encoder) if self.label_encoder else None,
                'feature_scaler': pickle.dumps(self.feature_scaler) if self.feature_scaler else None,
                'trained_at': datetime.now().isoformat()
            }
            
            async with get_database() as conn:
                # Criar tabela se não existir
                create_table = """
                    CREATE TABLE IF NOT EXISTS ml_models_cache (
                        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                        model_type TEXT NOT NULL,
                        model_data BYTEA,
                        trained_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                    )
                """
                await conn.execute(create_table)
                
                # Salvar cada modelo
                for model_name, model_data in models_data.items():
                    if model_data and model_name != 'trained_at':
                        await conn.execute(
                            """
                            INSERT INTO ml_models_cache (model_type, model_data)
                            VALUES ($1, $2)
                            ON CONFLICT (model_type) DO UPDATE SET
                                model_data = $2,
                                trained_at = NOW()
                            """,
                            model_name, model_data
                        )
            
            logger.info("💾 Modelos ML salvos no banco de dados")
            
        except Exception as e:
            logger.error(f"Erro ao salvar modelos ML: {e}")
    
    async def _load_trained_models(self):
        """Carrega modelos treinados do banco de dados."""
        async with get_database() as conn:
            # Buscar modelos salvos
            results = await conn.fetch(
                "SELECT model_type, model_data FROM ml_models_cache"
            )
            
            for row in results:
                model_type = row['model_type']
                model_data = row['model_data']
                
                if model_data:
                    if model_type == 'movement_classifier':
                        self.movement_classifier = pickle.loads(model_data)
                    elif model_type == 'timing_predictor':
                        self.timing_predictor = pickle.loads(model_data)
                    elif model_type == 'ttl_optimizer':
                        self.ttl_optimizer = pickle.loads(model_data)
                    elif model_type == 'text_vectorizer':
                        self.text_vectorizer = pickle.loads(model_data)
                    elif model_type == 'label_encoder':
                        self.label_encoder = pickle.loads(model_data)
                    elif model_type == 'feature_scaler':
                        self.feature_scaler = pickle.loads(model_data)

# ============================================================================
# INSTÂNCIA GLOBAL DO SERVIÇO
# ============================================================================

predictive_cache_ml = PredictiveCacheMLService() 
# -*- coding: utf-8 -*-
"""
services/predictive_cache_ml_service.py

Serviço de cache predictivo avançado usando Machine Learning.
Prediz quando ocorrerão movimentações processuais para fazer cache proativo.
"""

import asyncio
import logging
import pickle
import json
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
from sklearn.ensemble import RandomForestClassifier, GradientBoostingRegressor
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, mean_absolute_error

from config.database import get_database
from config.economic_optimization import PREDICTIVE_PATTERNS, ProcessPhaseClassifier
from services.process_cache_service import process_cache_service

logger = logging.getLogger(__name__)

class PredictiveCacheMLService:
    """
    Serviço de cache predictivo usando machine learning.
    
    Recursos:
    1. Predição de próximas movimentações baseado em histórico
    2. Classificação de padrões temporais de processos
    3. Recomendação de TTL dinâmico baseado em ML
    4. Cache proativo para otimizar hit rate
    """
    
    def __init__(self):
        self.movement_classifier = None
        self.timing_predictor = None
        self.ttl_optimizer = None
        self.text_vectorizer = None
        self.label_encoder = None
        self.feature_scaler = None
        
        # Configurações de ML
        self.min_samples_for_training = 100
        self.retrain_interval_days = 7
        self.confidence_threshold = 0.75
        
    async def initialize_models(self):
        """Inicializa ou carrega modelos ML treinados."""
        logger.info("🧠 Inicializando modelos de ML para cache predictivo")
        
        try:
            # Tentar carregar modelos existentes
            await self._load_trained_models()
            logger.info("✅ Modelos ML carregados do cache")
            
        except:
            # Se não existirem, treinar novos modelos
            logger.info("🔄 Treinando novos modelos ML")
            await self.train_predictive_models()
    
    async def train_predictive_models(self):
        """Treina modelos ML com dados históricos."""
        logger.info("🎯 Iniciando treinamento de modelos predictivos")
        
        # Buscar dados de treinamento
        training_data = await self._collect_training_data()
        
        if len(training_data) < self.min_samples_for_training:
            logger.warning(f"Poucos dados para treinamento: {len(training_data)} < {self.min_samples_for_training}")
            return False
        
        # 1. Treinar classificador de movimentações
        await self._train_movement_classifier(training_data)
        
        # 2. Treinar preditor de timing
        await self._train_timing_predictor(training_data)
        
        # 3. Treinar otimizador de TTL
        await self._train_ttl_optimizer(training_data)
        
        # Salvar modelos treinados
        await self._save_trained_models()
        
        logger.info("✅ Modelos ML treinados e salvos")
        return True
    
    async def predict_next_movements(
        self, 
        cnj: str, 
        recent_movements: List[str]
    ) -> Dict[str, Any]:
        """Prediz próximas movimentações de um processo."""
        
        if not self.movement_classifier or not recent_movements:
            return {"prediction": None, "confidence": 0.0}
        
        try:
            # Extrair features do texto
            movement_text = " ".join(recent_movements[-3:])  # 3 mais recentes
            text_features = self.text_vectorizer.transform([movement_text])
            
            # Extrair features temporais e processuais
            temporal_features = await self._extract_temporal_features(cnj)
            processual_features = await self._extract_processual_features(cnj, recent_movements)
            
            # Combinar features
            combined_features = np.hstack([
                text_features.toarray(),
                temporal_features.reshape(1, -1),
                processual_features.reshape(1, -1)
            ])
            
            # Fazer predição
            prediction_proba = self.movement_classifier.predict_proba(combined_features)[0]
            predicted_class = self.movement_classifier.predict(combined_features)[0]
            confidence = max(prediction_proba)
            
            # Predizer timing se confiança for alta
            timing_prediction = None
            if confidence > self.confidence_threshold:
                timing_features = combined_features[:, :50]  # Usar subset para timing
                predicted_days = self.timing_predictor.predict(timing_features)[0]
                
                timing_prediction = {
                    "estimated_days": max(1, int(predicted_days)),
                    "estimated_date": (datetime.now() + timedelta(days=predicted_days)).isoformat()
                }
            
            # Decodificar classe predita
            predicted_movement = self.label_encoder.inverse_transform([predicted_class])[0]
            
            return {
                "prediction": predicted_movement,
                "confidence": float(confidence),
                "timing": timing_prediction,
                "should_preload": confidence > self.confidence_threshold,
                "ml_features_used": {
                    "text_features": text_features.shape[1],
                    "temporal_features": temporal_features.shape[0],
                    "processual_features": processual_features.shape[0]
                }
            }
            
        except Exception as e:
            logger.error(f"Erro na predição ML para CNJ {cnj}: {e}")
            return {"prediction": None, "confidence": 0.0, "error": str(e)}
    
    async def optimize_ttl_with_ml(
        self, 
        cnj: str, 
        current_access_pattern: str,
        process_phase: str
    ) -> Dict[str, int]:
        """Otimiza TTL usando ML baseado em padrões de acesso."""
        
        if not self.ttl_optimizer:
            # Fallback para método baseado em regras
            return ProcessPhaseClassifier.get_optimal_ttl(
                phase=process_phase,
                last_movement_days=30,
                access_pattern=current_access_pattern
            )
        
        try:
            # Extrair features para otimização de TTL
            access_features = await self._extract_access_features(cnj, current_access_pattern)
            phase_features = self._encode_phase_features(process_phase)
            historical_features = await self._extract_historical_features(cnj)
            
            # Combinar features
            ttl_features = np.hstack([access_features, phase_features, historical_features]).reshape(1, -1)
            ttl_features_scaled = self.feature_scaler.transform(ttl_features)
            
            # Predizer TTLs otimizados
            predicted_redis_ttl = self.ttl_optimizer.predict(ttl_features_scaled)[0]
            
            # Calcular TTLs relacionados baseado no Redis TTL
            optimal_config = {
                "redis_ttl": max(900, int(predicted_redis_ttl)),  # Mínimo 15 min
                "db_ttl": max(3600, int(predicted_redis_ttl * 3)),  # 3x o Redis
                "sync_interval": max(1800, int(predicted_redis_ttl * 2)),  # 2x o Redis
                "ml_optimized": True,
                "confidence": 0.8  # Placeholder - seria calculado da validação
            }
            
            logger.info(f"TTL otimizado por ML para {cnj}: Redis={optimal_config['redis_ttl']}s")
            return optimal_config
            
        except Exception as e:
            logger.error(f"Erro na otimização ML de TTL para {cnj}: {e}")
            # Fallback para método baseado em regras
            return ProcessPhaseClassifier.get_optimal_ttl(
                phase=process_phase,
                last_movement_days=30,
                access_pattern=current_access_pattern
            )
    
    async def run_proactive_caching(self):
        """Executa cache proativo baseado em predições ML."""
        logger.info("🔮 Iniciando cache proativo baseado em ML")
        
        if not self.movement_classifier:
            logger.warning("Modelos ML não inicializados - pulando cache proativo")
            return
        
        async with get_database() as conn:
            # Buscar processos ativos com movimentações recentes
            query = """
                SELECT DISTINCT pm.cnj
                FROM process_movements pm
                JOIN process_optimization_config poc ON pm.cnj = poc.cnj
                WHERE pm.fetched_from_api_at > NOW() - INTERVAL '7 days'
                AND poc.last_accessed_at > NOW() - INTERVAL '3 days'
                ORDER BY poc.access_count DESC
                LIMIT 50
            """
            
            active_processes = await conn.fetch(query)
            
            proactive_cache_count = 0
            
            for process_row in active_processes:
                cnj = process_row['cnj']
                
                try:
                    # Buscar movimentações recentes
                    movements_query = """
                        SELECT movement_data->'movements' as movements
                        FROM process_movements 
                        WHERE cnj = $1 
                        ORDER BY fetched_from_api_at DESC 
                        LIMIT 1
                    """
                    
                    movement_result = await conn.fetchrow(movements_query, cnj)
                    
                    if movement_result and movement_result['movements']:
                        movements_data = movement_result['movements']
                        
                        # Extrair textos das movimentações
                        movement_texts = []
                        if isinstance(movements_data, list):
                            for mov in movements_data[:5]:
                                if isinstance(mov, dict):
                                    content = mov.get('full_content') or mov.get('description', '')
                                    if content:
                                        movement_texts.append(content)
                        
                        if movement_texts:
                            # Fazer predição
                            prediction = await self.predict_next_movements(cnj, movement_texts)
                            
                            # Se predição for confiável e timing for próximo
                            if (prediction.get("should_preload") and 
                                prediction.get("timing") and
                                prediction["timing"].get("estimated_days", 999) <= 3):
                                
                                # Fazer cache proativo
                                await self._proactive_cache_update(cnj)
                                proactive_cache_count += 1
                                
                                logger.info(f"Cache proativo aplicado para {cnj} - predição: {prediction['prediction']}")
                
                except Exception as e:
                    logger.warning(f"Erro no cache proativo para {cnj}: {e}")
            
            logger.info(f"🔮 Cache proativo concluído: {proactive_cache_count} processos atualizados")
    
    async def _collect_training_data(self) -> List[Dict[str, Any]]:
        """Coleta dados históricos para treinamento."""
        async with get_database() as conn:
            # Buscar histórico de movimentações com timing
            training_query = """
                SELECT 
                    pm.cnj,
                    pm.movement_data,
                    pm.fetched_from_api_at,
                    poc.detected_phase,
                    poc.process_area,
                    poc.access_count,
                    poc.access_pattern,
                    poc.redis_ttl_seconds,
                    poc.last_accessed_at,
                    LAG(pm.fetched_from_api_at) OVER (
                        PARTITION BY pm.cnj 
                        ORDER BY pm.fetched_from_api_at
                    ) as previous_fetch
                FROM process_movements pm
                LEFT JOIN process_optimization_config poc ON pm.cnj = poc.cnj
                WHERE pm.fetched_from_api_at > NOW() - INTERVAL '60 days'
                ORDER BY pm.cnj, pm.fetched_from_api_at
            """
            
            results = await conn.fetch(training_query)
            
            training_data = []
            for row in results:
                if row['previous_fetch']:  # Só incluir se tiver movimento anterior
                    # Calcular intervalo entre movimentações
                    time_diff = (row['fetched_from_api_at'] - row['previous_fetch']).total_seconds() / 86400  # em dias
                    
                    if 0.1 <= time_diff <= 90:  # Filtrar intervalos razoáveis
                        training_data.append({
                            'cnj': row['cnj'],
                            'movement_data': row['movement_data'],
                            'time_to_next_movement': time_diff,
                            'phase': row['detected_phase'] or 'unknown',
                            'area': row['process_area'] or 'unknown',
                            'access_count': row['access_count'] or 0,
                            'access_pattern': row['access_pattern'] or 'weekly',
                            'current_ttl': row['redis_ttl_seconds'] or 3600
                        })
            
            logger.info(f"📊 Coletados {len(training_data)} amostras para treinamento")
            return training_data
    
    async def _train_movement_classifier(self, training_data: List[Dict[str, Any]]):
        """Treina classificador de tipos de movimentação."""
        texts = []
        labels = []
        
        for sample in training_data:
            if sample['movement_data'] and isinstance(sample['movement_data'], dict):
                movements = sample['movement_data'].get('movements', [])
                if movements and isinstance(movements, list):
                    # Extrair texto da última movimentação
                    last_movement = movements[0] if movements else {}
                    if isinstance(last_movement, dict):
                        text = last_movement.get('full_content') or last_movement.get('description', '')
                        if text:
                            texts.append(text)
                            
                            # Classificar tipo de movimentação baseado em padrões
                            movement_type = self._classify_movement_type(text)
                            labels.append(movement_type)
        
        if len(texts) < 50:
            logger.warning("Poucos textos para treinar classificador de movimentações")
            return
        
        # Vetorizar textos
        self.text_vectorizer = TfidfVectorizer(
            max_features=1000,
            stop_words=['de', 'da', 'do', 'para', 'com', 'em', 'por'],  # Stop words PT
            ngram_range=(1, 2)
        )
        text_features = self.text_vectorizer.fit_transform(texts)
        
        # Codificar labels
        self.label_encoder = LabelEncoder()
        encoded_labels = self.label_encoder.fit_transform(labels)
        
        # Treinar classificador
        self.movement_classifier = RandomForestClassifier(
            n_estimators=100,
            random_state=42,
            max_depth=10
        )
        
        # Split para validação
        X_train, X_test, y_train, y_test = train_test_split(
            text_features, encoded_labels, test_size=0.2, random_state=42
        )
        
        self.movement_classifier.fit(X_train, y_train)
        
        # Avaliar performance
        y_pred = self.movement_classifier.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        
        logger.info(f"🎯 Classificador de movimentações treinado - Acurácia: {accuracy:.3f}")
    
    async def _train_timing_predictor(self, training_data: List[Dict[str, Any]]):
        """Treina preditor de timing de próximas movimentações."""
        features = []
        targets = []
        
        for sample in training_data:
            # Extrair features numéricas
            feature_vector = [
                sample['access_count'],
                len(sample['phase']),  # Proxy para complexidade da fase
                1 if sample['area'] == 'trabalhista' else 0,  # Área mais rápida
                1 if sample['area'] == 'tributario' else 0,   # Área mais lenta
                sample['current_ttl'] / 3600,  # TTL em horas
            ]
            
            features.append(feature_vector)
            targets.append(sample['time_to_next_movement'])
        
        if len(features) < 50:
            logger.warning("Poucos dados para treinar preditor de timing")
            return
        
        features_array = np.array(features)
        targets_array = np.array(targets)
        
        # Treinar regressor
        self.timing_predictor = GradientBoostingRegressor(
            n_estimators=100,
            random_state=42,
            max_depth=6
        )
        
        # Split para validação
        X_train, X_test, y_train, y_test = train_test_split(
            features_array, targets_array, test_size=0.2, random_state=42
        )
        
        self.timing_predictor.fit(X_train, y_train)
        
        # Avaliar performance
        y_pred = self.timing_predictor.predict(X_test)
        mae = mean_absolute_error(y_test, y_pred)
        
        logger.info(f"⏰ Preditor de timing treinado - MAE: {mae:.2f} dias")
    
    async def _train_ttl_optimizer(self, training_data: List[Dict[str, Any]]):
        """Treina otimizador de TTL baseado em padrões de acesso."""
        features = []
        targets = []
        
        for sample in training_data:
            # Features para otimização de TTL
            feature_vector = [
                sample['access_count'],
                sample['time_to_next_movement'],
                1 if sample['access_pattern'] == 'daily' else 0,
                1 if sample['access_pattern'] == 'weekly' else 0,
                1 if sample['access_pattern'] == 'monthly' else 0,
                len(sample['phase']),  # Complexidade da fase
                1 if sample['area'] == 'penal' else 0,  # Necessita TTL menor
            ]
            
            features.append(feature_vector)
            # Target é o TTL atual (assumindo que está otimizado)
            targets.append(sample['current_ttl'])
        
        if len(features) < 50:
            logger.warning("Poucos dados para treinar otimizador de TTL")
            return
        
        features_array = np.array(features)
        targets_array = np.array(targets)
        
        # Normalizar features
        self.feature_scaler = StandardScaler()
        features_scaled = self.feature_scaler.fit_transform(features_array)
        
        # Treinar otimizador
        self.ttl_optimizer = GradientBoostingRegressor(
            n_estimators=100,
            random_state=42,
            max_depth=4
        )
        
        self.ttl_optimizer.fit(features_scaled, targets_array)
        
        logger.info("🔧 Otimizador de TTL treinado")
    
    def _classify_movement_type(self, text: str) -> str:
        """Classifica tipo de movimentação baseado no texto."""
        text_lower = text.lower()
        
        if any(word in text_lower for word in ['sentença', 'sentenca', 'julgado']):
            return 'sentenca'
        elif any(word in text_lower for word in ['audiência', 'audiencia', 'designada']):
            return 'audiencia'
        elif any(word in text_lower for word in ['petição', 'peticao', 'juntada']):
            return 'peticao'
        elif any(word in text_lower for word in ['recurso', 'apelação', 'apelacao']):
            return 'recurso'
        elif any(word in text_lower for word in ['despacho', 'decisão', 'decisao']):
            return 'despacho'
        else:
            return 'outros'
    
    async def _extract_temporal_features(self, cnj: str) -> np.ndarray:
        """Extrai features temporais do processo."""
        # Features básicas temporais (seria expandido com dados reais)
        current_hour = datetime.now().hour
        current_day = datetime.now().weekday()
        
        return np.array([
            current_hour / 24.0,  # Normalizado
            current_day / 7.0,    # Normalizado
            1.0 if 9 <= current_hour <= 17 else 0.0,  # Horário comercial
            1.0 if current_day < 5 else 0.0,  # Dia útil
        ])
    
    async def _extract_processual_features(self, cnj: str, movements: List[str]) -> np.ndarray:
        """Extrai features específicas do processo."""
        # Features básicas processuais
        return np.array([
            len(movements),  # Número de movimentações
            len(" ".join(movements)) / 1000.0,  # Tamanho normalizado do texto
            1.0 if any('urgente' in m.lower() for m in movements) else 0.0,  # Urgência
            1.0 if any('liminar' in m.lower() for m in movements) else 0.0,  # Liminar
        ])
    
    async def _extract_access_features(self, cnj: str, access_pattern: str) -> np.ndarray:
        """Extrai features de padrão de acesso."""
        pattern_encoding = {
            'daily': [1, 0, 0, 0],
            'weekly': [0, 1, 0, 0], 
            'monthly': [0, 0, 1, 0],
            'rarely': [0, 0, 0, 1]
        }
        
        return np.array(pattern_encoding.get(access_pattern, [0, 1, 0, 0]))
    
    def _encode_phase_features(self, phase: str) -> np.ndarray:
        """Codifica features da fase processual."""
        phase_encoding = {
            'inicial': [1, 0, 0, 0, 0, 0],
            'instrutoria': [0, 1, 0, 0, 0, 0],
            'decisoria': [0, 0, 1, 0, 0, 0],
            'recursal': [0, 0, 0, 1, 0, 0],
            'final': [0, 0, 0, 0, 1, 0],
            'arquivado': [0, 0, 0, 0, 0, 1]
        }
        
        return np.array(phase_encoding.get(phase, [0, 1, 0, 0, 0, 0]))
    
    async def _extract_historical_features(self, cnj: str) -> np.ndarray:
        """Extrai features do histórico do processo."""
        # Features históricas básicas (seria expandido com dados reais)
        return np.array([
            0.5,  # Taxa histórica de cache hit
            30.0, # Dias médios entre movimentações
            5.0   # Número médio de acessos por semana
        ])
    
    async def _proactive_cache_update(self, cnj: str):
        """Executa atualização proativa do cache."""
        try:
            # Usar o serviço de cache para atualizar dados
            if process_cache_service:
                await process_cache_service.get_process_movements_cached(
                    cnj=cnj,
                    limit=50,
                    force_refresh=True  # Forçar atualização
                )
                logger.debug(f"Cache proativo atualizado para {cnj}")
        except Exception as e:
            logger.warning(f"Erro no cache proativo para {cnj}: {e}")
    
    async def _save_trained_models(self):
        """Salva modelos treinados no banco de dados."""
        try:
            models_data = {
                'movement_classifier': pickle.dumps(self.movement_classifier) if self.movement_classifier else None,
                'timing_predictor': pickle.dumps(self.timing_predictor) if self.timing_predictor else None,
                'ttl_optimizer': pickle.dumps(self.ttl_optimizer) if self.ttl_optimizer else None,
                'text_vectorizer': pickle.dumps(self.text_vectorizer) if self.text_vectorizer else None,
                'label_encoder': pickle.dumps(self.label_encoder) if self.label_encoder else None,
                'feature_scaler': pickle.dumps(self.feature_scaler) if self.feature_scaler else None,
                'trained_at': datetime.now().isoformat()
            }
            
            async with get_database() as conn:
                # Criar tabela se não existir
                create_table = """
                    CREATE TABLE IF NOT EXISTS ml_models_cache (
                        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                        model_type TEXT NOT NULL,
                        model_data BYTEA,
                        trained_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                    )
                """
                await conn.execute(create_table)
                
                # Salvar cada modelo
                for model_name, model_data in models_data.items():
                    if model_data and model_name != 'trained_at':
                        await conn.execute(
                            """
                            INSERT INTO ml_models_cache (model_type, model_data)
                            VALUES ($1, $2)
                            ON CONFLICT (model_type) DO UPDATE SET
                                model_data = $2,
                                trained_at = NOW()
                            """,
                            model_name, model_data
                        )
            
            logger.info("💾 Modelos ML salvos no banco de dados")
            
        except Exception as e:
            logger.error(f"Erro ao salvar modelos ML: {e}")
    
    async def _load_trained_models(self):
        """Carrega modelos treinados do banco de dados."""
        async with get_database() as conn:
            # Buscar modelos salvos
            results = await conn.fetch(
                "SELECT model_type, model_data FROM ml_models_cache"
            )
            
            for row in results:
                model_type = row['model_type']
                model_data = row['model_data']
                
                if model_data:
                    if model_type == 'movement_classifier':
                        self.movement_classifier = pickle.loads(model_data)
                    elif model_type == 'timing_predictor':
                        self.timing_predictor = pickle.loads(model_data)
                    elif model_type == 'ttl_optimizer':
                        self.ttl_optimizer = pickle.loads(model_data)
                    elif model_type == 'text_vectorizer':
                        self.text_vectorizer = pickle.loads(model_data)
                    elif model_type == 'label_encoder':
                        self.label_encoder = pickle.loads(model_data)
                    elif model_type == 'feature_scaler':
                        self.feature_scaler = pickle.loads(model_data)

# ============================================================================
# INSTÂNCIA GLOBAL DO SERVIÇO
# ============================================================================

predictive_cache_ml = PredictiveCacheMLService() 