#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
jobs/economic_optimization_job.py

Job de otimização contínua da economia de API.
Analisa padrões de uso, ajusta TTLs dinamicamente e gera relatórios de economia.
"""

import asyncio
import json
import logging
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple

from config.database import get_database
from config.economic_optimization import (
    ProcessPhaseClassifier, 
    PHASE_BASED_TTL,
    AREA_SPECIFIC_TTL,
    USER_ACCESS_PRIORITY,
    PREDICTIVE_PATTERNS
)
from services.economy_calculator_service import economy_calculator
from services.process_cache_service import process_cache_service

logger = logging.getLogger(__name__)

class EconomicOptimizationJob:
    """
    Job que roda diariamente para otimizar configurações baseado em:
    - Padrões de uso real
    - Fases processuais detectadas  
    - Histórico de movimentações
    - Custos de API
    """
    
    def __init__(self):
        self.optimization_interval_hours = 24  # Otimiza diariamente
        self.analysis_window_days = 7  # Analisa últimos 7 dias
        self.min_access_count = 3  # Mínimo de acessos para considerar padrão
        
    async def run_continuous(self):
        """Executa otimização contínua em background."""
        logger.info("🎯 Iniciando job de otimização econômica contínua")
        
        while True:
            try:
                await self.run_daily_optimization()
                
                # Aguardar próximo ciclo (24 horas)
                await asyncio.sleep(self.optimization_interval_hours * 3600)
                
            except Exception as e:
                logger.error(f"Erro no ciclo de otimização econômica: {e}")
                # Em caso de erro, tentar novamente em 1 hora
                await asyncio.sleep(3600)
    
    async def run_daily_optimization(self):
        """Executa ciclo completo de otimização diária."""
        start_time = datetime.now()
        logger.info(f"🎯 Iniciando otimização econômica diária: {start_time}")
        
        try:
            # 1. Analisar padrões de uso dos últimos 7 dias
            usage_patterns = await self.analyze_usage_patterns()
            
            # 2. Detectar fases processuais atualizadas
            process_phases = await self.classify_all_process_phases()
            
            # 3. Calcular TTLs otimizados
            optimized_configs = await self.calculate_optimal_configs(
                usage_patterns, process_phases
            )
            
            # 4. Ajustar configurações automaticamente
            applied_optimizations = await self.apply_optimizations(optimized_configs)
            
            # 5. Analisar padrões predictivos
            predictive_insights = await self.analyze_predictive_patterns()
            
            # 6. Gerar relatório de economia
            economy_report = await self.generate_economy_report(
                usage_patterns, applied_optimizations, predictive_insights
            )
            
            # 7. Salvar métricas de otimização
            await self.save_optimization_metrics(economy_report)
            
            duration = (datetime.now() - start_time).total_seconds()
            logger.info(f"✅ Otimização concluída em {duration:.2f}s")
            
        except Exception as e:
            logger.error(f"Erro na otimização diária: {e}")
            raise
    
    async def analyze_usage_patterns(self) -> Dict[str, Any]:
        """Analisa padrões de uso dos últimos 7 dias."""
        logger.info("📊 Analisando padrões de uso dos últimos 7 dias")
        
        async with get_database() as conn:
            # Buscar acessos por processo
            access_query = """
                SELECT 
                    cnj,
                    COUNT(*) as access_count,
                    MAX(last_accessed_at) as last_access,
                    AVG(EXTRACT(EPOCH FROM (NOW() - last_accessed_at))/3600) as avg_hours_since_access,
                    process_area,
                    detected_phase
                FROM process_optimization_config 
                WHERE last_accessed_at > NOW() - INTERVAL '7 days'
                GROUP BY cnj, process_area, detected_phase
                ORDER BY access_count DESC
            """
            
            access_results = await conn.fetch(access_query)
            
            # Buscar métricas de cache
            cache_query = """
                SELECT 
                    date_recorded,
                    cache_hit_rate,
                    api_calls_saved,
                    economy_percentage,
                    daily_savings
                FROM api_economy_metrics 
                WHERE date_recorded > NOW() - INTERVAL '7 days'
                ORDER BY date_recorded
            """
            
            cache_results = await conn.fetch(cache_query)
            
            # Analisar padrões
            patterns = {
                "total_processes_analyzed": len(access_results),
                "access_patterns": {},
                "phase_distribution": {},
                "area_distribution": {},
                "cache_performance": {
                    "avg_hit_rate": 0,
                    "avg_economy": 0,
                    "trend": "stable"
                }
            }
            
            # Classificar padrões de acesso
            for row in access_results:
                access_count = row['access_count']
                
                if access_count >= 20:  # Diário
                    pattern = "daily"
                elif access_count >= 5:  # Semanal
                    pattern = "weekly"
                elif access_count >= 2:  # Mensal
                    pattern = "monthly"
                else:
                    pattern = "rarely"
                
                if pattern not in patterns["access_patterns"]:
                    patterns["access_patterns"][pattern] = []
                
                patterns["access_patterns"][pattern].append({
                    "cnj": row['cnj'],
                    "access_count": access_count,
                    "area": row['process_area'],
                    "phase": row['detected_phase']
                })
                
                # Distribuição por fase
                phase = row['detected_phase'] or 'unknown'
                patterns["phase_distribution"][phase] = patterns["phase_distribution"].get(phase, 0) + 1
                
                # Distribuição por área
                area = row['process_area'] or 'unknown'
                patterns["area_distribution"][area] = patterns["area_distribution"].get(area, 0) + 1
            
            # Analisar performance do cache
            if cache_results:
                hit_rates = [float(r['cache_hit_rate']) for r in cache_results if r['cache_hit_rate']]
                economies = [float(r['economy_percentage']) for r in cache_results if r['economy_percentage']]
                
                if hit_rates:
                    patterns["cache_performance"]["avg_hit_rate"] = sum(hit_rates) / len(hit_rates)
                
                if economies:
                    patterns["cache_performance"]["avg_economy"] = sum(economies) / len(economies)
                    
                    # Detectar tendência
                    if len(economies) >= 3:
                        recent_avg = sum(economies[-3:]) / 3
                        older_avg = sum(economies[:-3]) / len(economies[:-3]) if len(economies) > 3 else recent_avg
                        
                        if recent_avg > older_avg + 1:
                            patterns["cache_performance"]["trend"] = "improving"
                        elif recent_avg < older_avg - 1:
                            patterns["cache_performance"]["trend"] = "declining"
            
            logger.info(f"📊 Padrões analisados: {patterns['total_processes_analyzed']} processos")
            return patterns
    
    async def classify_all_process_phases(self) -> Dict[str, str]:
        """Detecta e atualiza fases processuais de todos os processos."""
        logger.info("🔍 Classificando fases processuais")
        
        async with get_database() as conn:
            # Buscar processos com movimentações recentes
            query = """
                SELECT DISTINCT cnj
                FROM process_movements 
                WHERE fetched_from_api_at > NOW() - INTERVAL '30 days'
            """
            
            processes = await conn.fetch(query)
            phase_updates = {}
            
            for process_row in processes:
                cnj = process_row['cnj']
                
                # Buscar movimentações mais recentes
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
                    
                    # Extrair texto das movimentações
                    movement_texts = []
                    if isinstance(movements_data, list):
                        for mov in movements_data[:5]:  # 5 mais recentes
                            if isinstance(mov, dict):
                                content = mov.get('full_content') or mov.get('description', '')
                                if content:
                                    movement_texts.append(content)
                    
                    if movement_texts:
                        # Classificar fase
                        detected_phase = ProcessPhaseClassifier.classify_phase(movement_texts)
                        phase_updates[cnj] = detected_phase
                        
                        # Atualizar configuração
                        update_query = """
                            INSERT INTO process_optimization_config (cnj, detected_phase, updated_at)
                            VALUES ($1, $2, NOW())
                            ON CONFLICT (cnj) 
                            DO UPDATE SET 
                                detected_phase = $2,
                                updated_at = NOW()
                        """
                        
                        await conn.execute(update_query, cnj, detected_phase)
            
            logger.info(f"🔍 Classificadas {len(phase_updates)} fases processuais")
            return phase_updates
    
    async def calculate_optimal_configs(
        self, 
        usage_patterns: Dict[str, Any], 
        process_phases: Dict[str, str]
    ) -> Dict[str, Dict[str, Any]]:
        """Calcula configurações otimizadas de TTL."""
        logger.info("⚙️ Calculando configurações otimizadas")
        
        optimized_configs = {}
        
        # Para cada padrão de acesso, calcular TTL ótimo
        for access_pattern, processes in usage_patterns["access_patterns"].items():
            for process_info in processes:
                cnj = process_info["cnj"]
                area = process_info["area"]
                phase = process_phases.get(cnj, process_info["phase"])
                
                # Calcular TTL otimizado
                optimal_config = ProcessPhaseClassifier.get_optimal_ttl(
                    phase=phase,
                    last_movement_days=30,  # Placeholder - seria calculado do histórico
                    area=area,
                    access_pattern=access_pattern
                )
                
                optimized_configs[cnj] = {
                    "redis_ttl": optimal_config["redis_ttl"],
                    "db_ttl": optimal_config["db_ttl"], 
                    "sync_interval": optimal_config["sync_interval"],
                    "phase": phase,
                    "area": area,
                    "access_pattern": access_pattern,
                    "multipliers": optimal_config["multipliers"]
                }
        
        logger.info(f"⚙️ Configurações otimizadas para {len(optimized_configs)} processos")
        return optimized_configs
    
    async def apply_optimizations(
        self, 
        optimized_configs: Dict[str, Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Aplica otimizações calculadas."""
        logger.info("🔧 Aplicando otimizações")
        
        applied_count = 0
        async with get_database() as conn:
            for cnj, config in optimized_configs.items():
                try:
                    update_query = """
                        UPDATE process_optimization_config 
                        SET 
                            redis_ttl_seconds = $1,
                            db_ttl_seconds = $2,
                            sync_interval_seconds = $3,
                            detected_phase = $4,
                            process_area = $5,
                            access_pattern = $6,
                            updated_at = NOW()
                        WHERE cnj = $7
                    """
                    
                    await conn.execute(
                        update_query,
                        config["redis_ttl"],
                        config["db_ttl"],
                        config["sync_interval"],
                        config["phase"],
                        config["area"],
                        config["access_pattern"],
                        cnj
                    )
                    
                    applied_count += 1
                    
                except Exception as e:
                    logger.warning(f"Erro ao aplicar otimização para {cnj}: {e}")
        
        result = {
            "applied_optimizations": applied_count,
            "total_configs": len(optimized_configs),
            "success_rate": (applied_count / len(optimized_configs)) * 100 if optimized_configs else 0
        }
        
        logger.info(f"🔧 Aplicadas {applied_count}/{len(optimized_configs)} otimizações")
        return result
    
    async def analyze_predictive_patterns(self) -> Dict[str, Any]:
        """Analisa padrões predictivos para cache proativo."""
        logger.info("🔮 Analisando padrões predictivos")
        
        async with get_database() as conn:
            # Buscar movimentações com padrões conhecidos
            pattern_query = """
                SELECT 
                    cnj,
                    movement_data,
                    fetched_from_api_at
                FROM process_movements 
                WHERE fetched_from_api_at > NOW() - INTERVAL '30 days'
                ORDER BY fetched_from_api_at DESC
            """
            
            results = await conn.fetch(pattern_query)
            
            predictive_insights = {
                "total_analyzed": len(results),
                "patterns_detected": {},
                "predictions_made": 0,
                "confidence_scores": []
            }
            
            for row in results:
                if not row['movement_data']:
                    continue
                    
                movements_data = row['movement_data']
                if isinstance(movements_data, dict) and 'movements' in movements_data:
                    movements = movements_data['movements']
                    
                    if isinstance(movements, list) and movements:
                        # Verificar padrões predictivos nas movimentações mais recentes
                        recent_text = " ".join([
                            m.get('full_content', '') for m in movements[:3] 
                            if isinstance(m, dict)
                        ]).lower()
                        
                        for pattern_name, pattern_config in PREDICTIVE_PATTERNS.items():
                            if hasattr(pattern_config, 'get'):
                                pattern_regex = pattern_config.get('pattern', '')
                                import re
                                if re.search(pattern_regex, recent_text, re.IGNORECASE):
                                    if pattern_name not in predictive_insights["patterns_detected"]:
                                        predictive_insights["patterns_detected"][pattern_name] = []
                                    
                                    prediction = ProcessPhaseClassifier.predict_next_movement([recent_text])
                                    if prediction.get("prediction"):
                                        predictive_insights["patterns_detected"][pattern_name].append({
                                            "cnj": row['cnj'],
                                            "prediction": prediction,
                                            "detected_at": row['fetched_from_api_at'].isoformat()
                                        })
                                        
                                        predictive_insights["predictions_made"] += 1
                                        confidence = prediction.get("confidence", 0)
                                        predictive_insights["confidence_scores"].append(confidence)
            
            # Calcular confiança média
            if predictive_insights["confidence_scores"]:
                avg_confidence = sum(predictive_insights["confidence_scores"]) / len(predictive_insights["confidence_scores"])
                predictive_insights["average_confidence"] = avg_confidence
            
            logger.info(f"🔮 Detectados {len(predictive_insights['patterns_detected'])} padrões predictivos")
            return predictive_insights
    
    async def generate_economy_report(
        self,
        usage_patterns: Dict[str, Any],
        optimizations: Dict[str, Any], 
        predictive_insights: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Gera relatório completo de economia."""
        logger.info("📊 Gerando relatório de economia")
        
        # Calcular economia atual para diferentes cenários
        small_economy = economy_calculator.calculate_monthly_cost_with_cache("small")
        medium_economy = economy_calculator.calculate_monthly_cost_with_cache("medium")
        large_economy = economy_calculator.calculate_monthly_cost_with_cache("large")
        
        # Métricas de cache dos últimos 7 dias
        async with get_database() as conn:
            metrics_query = """
                SELECT 
                    AVG(cache_hit_rate) as avg_hit_rate,
                    AVG(economy_percentage) as avg_economy,
                    SUM(daily_savings) as total_weekly_savings,
                    COUNT(*) as days_tracked
                FROM api_economy_metrics 
                WHERE date_recorded > NOW() - INTERVAL '7 days'
            """
            
            metrics_result = await conn.fetchrow(metrics_query)
        
        report = {
            "generated_at": datetime.now().isoformat(),
            "period": "7_days_analysis", 
            "usage_analysis": usage_patterns,
            "optimization_results": optimizations,
            "predictive_analysis": predictive_insights,
            "economy_scenarios": {
                "small_office": small_economy,
                "medium_office": medium_economy,
                "large_office": large_economy
            },
            "performance_metrics": {
                "cache_hit_rate": float(metrics_result['avg_hit_rate'] or 0),
                "economy_percentage": float(metrics_result['avg_economy'] or 0),
                "weekly_savings": float(metrics_result['total_weekly_savings'] or 0),
                "days_tracked": int(metrics_result['days_tracked'] or 0)
            },
            "recommendations": await self._generate_recommendations(
                usage_patterns, optimizations, predictive_insights
            )
        }
        
        logger.info("📊 Relatório de economia gerado")
        return report
    
    async def save_optimization_metrics(self, report: Dict[str, Any]):
        """Salva métricas de otimização no banco."""
        logger.info("💾 Salvando métricas de otimização")
        
        async with get_database() as conn:
            insert_query = """
                INSERT INTO api_economy_metrics (
                    date_recorded,
                    cache_hit_rate,
                    economy_percentage,
                    daily_savings,
                    total_data_size_mb,
                    archived_data_size_mb
                ) VALUES (
                    CURRENT_DATE,
                    $1, $2, $3, $4, $5
                ) ON CONFLICT (date_recorded) 
                DO UPDATE SET
                    cache_hit_rate = $1,
                    economy_percentage = $2,
                    daily_savings = $3,
                    total_data_size_mb = $4,
                    archived_data_size_mb = $5
            """
            
            metrics = report["performance_metrics"]
            await conn.execute(
                insert_query,
                metrics["cache_hit_rate"],
                metrics["economy_percentage"], 
                metrics.get("daily_savings", metrics["weekly_savings"] / 7),
                1000,  # Placeholder para tamanho total
                500    # Placeholder para dados arquivados
            )
        
        # Salvar relatório completo como JSON
        report_query = """
            INSERT INTO optimization_reports (
                generated_at,
                report_data,
                report_type
            ) VALUES ($1, $2, 'daily_optimization')
        """
        
        try:
            await conn.execute(
                report_query,
                datetime.now(),
                json.dumps(report),
            )
        except:
            # Tabela pode não existir ainda, criar se necessário
            create_table_query = """
                CREATE TABLE IF NOT EXISTS optimization_reports (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    report_data JSONB,
                    report_type TEXT,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                )
            """
            await conn.execute(create_table_query)
            await conn.execute(report_query, datetime.now(), json.dumps(report))
        
        logger.info("💾 Métricas salvas com sucesso")
    
    async def _generate_recommendations(
        self,
        usage_patterns: Dict[str, Any],
        optimizations: Dict[str, Any],
        predictive_insights: Dict[str, Any]
    ) -> List[str]:
        """Gera recomendações baseadas na análise."""
        recommendations = []
        
        # Analisar performance do cache
        cache_perf = usage_patterns.get("cache_performance", {})
        hit_rate = cache_perf.get("avg_hit_rate", 0)
        
        if hit_rate < 90:
            recommendations.append("🔧 Aumentar TTL para melhorar cache hit rate")
        elif hit_rate > 97:
            recommendations.append("⚡ Sistema altamente otimizado - manter configurações")
        
        # Analisar sucesso das otimizações
        success_rate = optimizations.get("success_rate", 0)
        if success_rate < 95:
            recommendations.append("⚠️ Revisar processo de aplicação de otimizações")
        
        # Analisar insights predictivos
        predictions = predictive_insights.get("predictions_made", 0)
        if predictions > 0:
            avg_confidence = predictive_insights.get("average_confidence", 0)
            if avg_confidence > 0.8:
                recommendations.append("🔮 Implementar cache predictivo mais agressivo")
        
        # Recomendar baseado em tendência
        trend = cache_perf.get("trend", "stable")
        if trend == "declining":
            recommendations.append("📉 Investigar causa da queda de performance")
        elif trend == "improving":
            recommendations.append("📈 Performance melhorando - continuar otimizações")
        
        return recommendations

# ============================================================================
# FUNÇÃO DE INICIALIZAÇÃO
# ============================================================================

async def start_optimization_job():
    """Inicia o job de otimização em background."""
    job = EconomicOptimizationJob()
    await job.run_continuous()

if __name__ == "__main__":
    asyncio.run(start_optimization_job()) 