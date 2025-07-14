"""
backend/services/provider_insights_service.py

Serviço para gerar insights de performance para prestadores de serviços.
Inclui análise de pontos fracos, benchmarks de mercado e sugestões de melhoria.
"""
import logging
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta
import json
import numpy as np
from statistics import median

from supabase import Client

logger = logging.getLogger(__name__)

class ProviderInsightsService:
    """Serviço para gerar insights de performance para prestadores"""
    
    def __init__(self, supabase_client: Client):
        self.supabase = supabase_client
        
        # Mapeamento de features para rótulos amigáveis
        self.feature_labels = {
            'response_time': 'Tempo de Resposta',
            'success_rate': 'Taxa de Sucesso',
            'rating': 'Avaliação Média',
            'availability': 'Disponibilidade',
            'specialization': 'Especialização',
            'experience': 'Experiência',
            'communication': 'Comunicação',
            'case_completion': 'Conclusão de Casos',
            'client_satisfaction': 'Satisfação do Cliente',
            'price_competitiveness': 'Competitividade de Preços'
        }
        
        # Templates de sugestões por categoria
        self.suggestion_templates = {
            'response_time': {
                'title': 'Melhorar Tempo de Resposta',
                'category': 'Comunicação',
                'description': 'Reduzir o tempo de resposta inicial aos clientes',
                'action_items': [
                    'Configurar notificações push para novos casos',
                    'Estabelecer horários específicos para verificar mensagens',
                    'Criar respostas automáticas para reconhecimento inicial'
                ]
            },
            'success_rate': {
                'title': 'Aumentar Taxa de Sucesso',
                'category': 'Resultados',
                'description': 'Melhorar os resultados obtidos nos casos',
                'action_items': [
                    'Focar em casos da sua área de especialização',
                    'Investir em capacitação jurídica contínua',
                    'Desenvolver parcerias estratégicas'
                ]
            },
            'rating': {
                'title': 'Melhorar Avaliação dos Clientes',
                'category': 'Satisfação',
                'description': 'Aumentar a satisfação e avaliação dos clientes',
                'action_items': [
                    'Solicitar feedback regular dos clientes',
                    'Melhorar comunicação durante o processo',
                    'Entregar resultados acima das expectativas'
                ]
            }
        }

    async def generate_performance_insights(
        self,
        provider_id: str,
        period_days: int = 90,
        include_benchmarks: bool = True,
        include_suggestions: bool = True
    ) -> Dict[str, Any]:
        """
        Gera insights completos de performance para um prestador
        """
        try:
            # Buscar dados do prestador
            provider_data = await self._get_provider_data(provider_id)
            
            # Calcular métricas de performance
            performance_metrics = await self._calculate_performance_metrics(
                provider_id, period_days
            )
            
            # Identificar pontos fracos
            weak_points = await self._identify_weak_points(
                provider_id, performance_metrics
            )
            
            # Gerar benchmarks se solicitado
            benchmarks = []
            if include_benchmarks:
                benchmarks = await self.generate_market_benchmarks(
                    provider_id, 
                    area=provider_data.get('primary_area')
                )
            
            # Gerar sugestões se solicitado
            suggestions = []
            if include_suggestions:
                suggestions = await self._generate_improvement_suggestions(
                    weak_points, performance_metrics
                )
            
            # Calcular nota geral
            overall_score = self._calculate_overall_score(performance_metrics)
            
            # Determinar tendência
            trend = await self._calculate_trend(provider_id, period_days)
            
            # Métricas de evolução
            evolution_metrics = await self._get_evolution_metrics(
                provider_id, period_days
            )
            
            return {
                'provider_id': provider_id,
                'overall_score': overall_score,
                'grade': self._score_to_grade(overall_score),
                'trend': trend,
                'last_updated': datetime.now(),
                'weak_points': weak_points,
                'benchmarks': benchmarks,
                'improvement_suggestions': suggestions,
                'evolution_metrics': evolution_metrics,
                'analysis_period': f'{period_days} dias',
                'market_segment': provider_data.get('primary_area', 'Geral')
            }
            
        except Exception as e:
            logger.error(f"Erro ao gerar insights de performance: {e}")
            raise

    async def generate_performance_summary(self, provider_id: str) -> Dict[str, Any]:
        """
        Gera resumo rápido de performance para dashboard
        """
        try:
            # Buscar métricas básicas
            performance_metrics = await self._calculate_performance_metrics(
                provider_id, period_days=30
            )
            
            overall_score = self._calculate_overall_score(performance_metrics)
            
            # Identificar principal ponto fraco
            weak_points = await self._identify_weak_points(
                provider_id, performance_metrics
            )
            main_weakness = weak_points[0] if weak_points else None
            
            # Calcular tendência
            trend = await self._calculate_trend(provider_id, 30)
            
            return {
                'overall_score': overall_score,
                'grade': self._score_to_grade(overall_score),
                'trend': trend,
                'main_weakness': main_weakness,
                'last_updated': datetime.now(),
                'metrics_count': len(performance_metrics)
            }
            
        except Exception as e:
            logger.error(f"Erro ao gerar resumo de performance: {e}")
            raise

    async def generate_market_benchmarks(
        self,
        provider_id: str,
        area: Optional[str] = None,
        features: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """
        Gera benchmarks de mercado anônimos
        """
        try:
            # Buscar dados do prestador
            provider_metrics = await self._calculate_performance_metrics(provider_id)
            
            # Definir features a serem comparadas
            if features is None:
                features = list(self.feature_labels.keys())
            
            benchmarks = []
            
            for feature in features:
                if feature in provider_metrics:
                    benchmark = await self._calculate_feature_benchmark(
                        feature, provider_metrics[feature], area
                    )
                    if benchmark:
                        benchmarks.append(benchmark)
            
            return benchmarks
            
        except Exception as e:
            logger.error(f"Erro ao gerar benchmarks de mercado: {e}")
            raise

    # ============================================================================
    # Métodos Privados
    # ============================================================================

    async def _get_provider_data(self, provider_id: str) -> Dict[str, Any]:
        """Busca dados básicos do prestador"""
        try:
            response = self.supabase.table('lawyers').select('*').eq('id', provider_id).single().execute()
            return response.data or {}
        except Exception as e:
            logger.error(f"Erro ao buscar dados do prestador: {e}")
            return {}

    async def _calculate_performance_metrics(
        self, 
        provider_id: str, 
        period_days: int = 90
    ) -> Dict[str, float]:
        """Calcula métricas de performance do prestador"""
        try:
            # Data de início do período
            start_date = datetime.now() - timedelta(days=period_days)
            
            # Buscar dados de cases e contratos
            cases_response = self.supabase.table('cases')\
                .select('*')\
                .eq('lawyer_id', provider_id)\
                .gte('created_at', start_date.isoformat())\
                .execute()
            
            cases = cases_response.data or []
            
            # Buscar avaliações
            reviews_response = self.supabase.table('reviews')\
                .select('*')\
                .eq('lawyer_id', provider_id)\
                .gte('created_at', start_date.isoformat())\
                .execute()
            
            reviews = reviews_response.data or []
            
            # Calcular métricas
            metrics = {}
            
            # Taxa de sucesso
            successful_cases = len([c for c in cases if c.get('status') == 'completed'])
            total_cases = len(cases)
            metrics['success_rate'] = (successful_cases / total_cases * 100) if total_cases > 0 else 0
            
            # Avaliação média
            if reviews:
                ratings = [r.get('rating', 0) for r in reviews if r.get('rating')]
                metrics['rating'] = sum(ratings) / len(ratings) if ratings else 0
            else:
                metrics['rating'] = 0
            
            # Tempo de resposta (simulado - seria calculado com base em mensagens)
            metrics['response_time'] = np.random.normal(8, 2)  # Média 8h, desvio 2h
            
            # Disponibilidade (simulado)
            metrics['availability'] = np.random.normal(85, 10)  # 85% disponível
            
            # Outras métricas simuladas
            metrics['specialization'] = np.random.normal(75, 15)
            metrics['experience'] = np.random.normal(70, 20)
            metrics['communication'] = np.random.normal(80, 10)
            metrics['case_completion'] = np.random.normal(90, 5)
            metrics['client_satisfaction'] = np.random.normal(85, 8)
            metrics['price_competitiveness'] = np.random.normal(70, 15)
            
            return metrics
            
        except Exception as e:
            logger.error(f"Erro ao calcular métricas de performance: {e}")
            return {}

    async def _identify_weak_points(
        self,
        provider_id: str,
        performance_metrics: Dict[str, float]
    ) -> List[Dict[str, Any]]:
        """Identifica os 3 pontos mais fracos do prestador"""
        try:
            weak_points = []
            
            # Buscar benchmarks de mercado para comparação
            market_benchmarks = await self._get_market_benchmarks_data()
            
            # Calcular gaps para cada métrica
            gaps = []
            for feature, value in performance_metrics.items():
                if feature in market_benchmarks:
                    market_data = market_benchmarks[feature]
                    gap = market_data['p50'] - value
                    if gap > 0:  # Prestador está abaixo da mediana
                        gaps.append({
                            'feature': feature,
                            'gap': gap,
                            'impact': gap / market_data['p50']  # Impacto relativo
                        })
            
            # Ordenar por impacto e pegar os 3 maiores gaps
            gaps.sort(key=lambda x: x['impact'], reverse=True)
            
            for gap in gaps[:3]:
                feature = gap['feature']
                market_data = market_benchmarks[feature]
                
                weak_point = {
                    'feature': feature,
                    'feature_label': self.feature_labels.get(feature, feature),
                    'current_value': performance_metrics[feature],
                    'benchmark_p50': market_data['p50'],
                    'benchmark_p75': market_data['p75'],
                    'benchmark_p90': market_data['p90'],
                    'impact_score': gap['impact'],
                    'improvement_potential': self._calculate_improvement_potential(gap['impact'])
                }
                
                weak_points.append(weak_point)
            
            return weak_points
            
        except Exception as e:
            logger.error(f"Erro ao identificar pontos fracos: {e}")
            return []

    async def _get_market_benchmarks_data(self) -> Dict[str, Dict[str, float]]:
        """Busca dados de benchmark de mercado (simulado)"""
        # Em produção, isso viria de análise real dos dados
        return {
            'response_time': {'p50': 6.0, 'p75': 4.0, 'p90': 2.0},
            'success_rate': {'p50': 85.0, 'p75': 90.0, 'p90': 95.0},
            'rating': {'p50': 4.2, 'p75': 4.5, 'p90': 4.8},
            'availability': {'p50': 80.0, 'p75': 85.0, 'p90': 90.0},
            'specialization': {'p50': 70.0, 'p75': 80.0, 'p90': 90.0},
            'experience': {'p50': 65.0, 'p75': 75.0, 'p90': 85.0},
            'communication': {'p50': 75.0, 'p75': 85.0, 'p90': 90.0},
            'case_completion': {'p50': 85.0, 'p75': 90.0, 'p90': 95.0},
            'client_satisfaction': {'p50': 80.0, 'p75': 85.0, 'p90': 90.0},
            'price_competitiveness': {'p50': 65.0, 'p75': 75.0, 'p90': 85.0}
        }

    async def _calculate_feature_benchmark(
        self,
        feature: str,
        provider_value: float,
        area: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """Calcula benchmark para uma feature específica"""
        try:
            market_data = await self._get_market_benchmarks_data()
            
            if feature not in market_data:
                return None
            
            benchmark_data = market_data[feature]
            
            # Calcular percentil do prestador
            percentile = self._calculate_percentile(provider_value, benchmark_data)
            
            # Determinar comparação
            if provider_value >= benchmark_data['p75']:
                comparison = 'above'
            elif provider_value <= benchmark_data['p50']:
                comparison = 'below'
            else:
                comparison = 'at'
            
            return {
                'feature': feature,
                'feature_label': self.feature_labels.get(feature, feature),
                'your_value': provider_value,
                'your_percentile': percentile,
                'market_p50': benchmark_data['p50'],
                'market_p75': benchmark_data['p75'],
                'market_p90': benchmark_data['p90'],
                'comparison': comparison
            }
            
        except Exception as e:
            logger.error(f"Erro ao calcular benchmark para {feature}: {e}")
            return None

    def _calculate_percentile(self, value: float, benchmark_data: Dict[str, float]) -> int:
        """Calcula o percentil aproximado de um valor"""
        if value >= benchmark_data['p90']:
            return 90
        elif value >= benchmark_data['p75']:
            return 75
        elif value >= benchmark_data['p50']:
            return 50
        else:
            return 25

    def _calculate_improvement_potential(self, impact_score: float) -> str:
        """Calcula o potencial de melhoria baseado no impacto"""
        if impact_score > 0.3:
            return 'Alto'
        elif impact_score > 0.15:
            return 'Médio'
        else:
            return 'Baixo'

    async def _generate_improvement_suggestions(
        self,
        weak_points: List[Dict[str, Any]],
        performance_metrics: Dict[str, float]
    ) -> List[Dict[str, Any]]:
        """Gera sugestões de melhoria baseadas nos pontos fracos"""
        suggestions = []
        
        for weak_point in weak_points:
            feature = weak_point['feature']
            
            if feature in self.suggestion_templates:
                template = self.suggestion_templates[feature]
                
                # Personalizar sugestão baseada no nível de impacto
                priority = 'high' if weak_point['impact_score'] > 0.3 else 'medium'
                timeframe = '2-4 semanas' if priority == 'high' else '1-2 meses'
                
                suggestion = {
                    'category': template['category'],
                    'title': template['title'],
                    'description': template['description'],
                    'priority': priority,
                    'estimated_impact': weak_point['improvement_potential'],
                    'timeframe': timeframe,
                    'action_items': template['action_items']
                }
                
                suggestions.append(suggestion)
        
        return suggestions

    def _calculate_overall_score(self, performance_metrics: Dict[str, float]) -> int:
        """Calcula nota geral do perfil (0-100)"""
        if not performance_metrics:
            return 0
        
        # Pesos por métrica
        weights = {
            'success_rate': 0.25,
            'rating': 0.20,
            'response_time': 0.15,
            'availability': 0.10,
            'specialization': 0.10,
            'experience': 0.05,
            'communication': 0.05,
            'case_completion': 0.05,
            'client_satisfaction': 0.05
        }
        
        weighted_score = 0
        total_weight = 0
        
        for metric, value in performance_metrics.items():
            if metric in weights:
                # Normalizar valores para 0-100
                normalized_value = min(100, max(0, value))
                weighted_score += normalized_value * weights[metric]
                total_weight += weights[metric]
        
        if total_weight > 0:
            return int(weighted_score / total_weight)
        else:
            return 0

    def _score_to_grade(self, score: int) -> str:
        """Converte nota numérica em classificação textual"""
        if score >= 90:
            return 'Excelente'
        elif score >= 80:
            return 'Muito Bom'
        elif score >= 70:
            return 'Bom'
        elif score >= 60:
            return 'Regular'
        else:
            return 'Precisa Melhorar'

    async def _calculate_trend(self, provider_id: str, period_days: int) -> str:
        """Calcula tendência de evolução"""
        try:
            # Comparar período atual com período anterior
            current_metrics = await self._calculate_performance_metrics(
                provider_id, period_days
            )
            previous_metrics = await self._calculate_performance_metrics(
                provider_id, period_days * 2
            )
            
            current_score = self._calculate_overall_score(current_metrics)
            previous_score = self._calculate_overall_score(previous_metrics)
            
            if current_score > previous_score + 5:
                return 'Melhorando'
            elif current_score < previous_score - 5:
                return 'Declinando'
            else:
                return 'Estável'
                
        except Exception as e:
            logger.error(f"Erro ao calcular tendência: {e}")
            return 'Estável'

    async def _get_evolution_metrics(
        self,
        provider_id: str,
        period_days: int
    ) -> Dict[str, Any]:
        """Obtém métricas de evolução temporal"""
        try:
            # Dividir período em 3 partes para análise temporal
            periods = [
                period_days // 3,
                (period_days // 3) * 2,
                period_days
            ]
            
            evolution_data = {}
            
            for i, days in enumerate(periods):
                metrics = await self._calculate_performance_metrics(provider_id, days)
                score = self._calculate_overall_score(metrics)
                
                evolution_data[f'period_{i+1}'] = {
                    'score': score,
                    'days_back': days,
                    'key_metrics': {
                        'success_rate': metrics.get('success_rate', 0),
                        'rating': metrics.get('rating', 0),
                        'response_time': metrics.get('response_time', 0)
                    }
                }
            
            return evolution_data
            
        except Exception as e:
            logger.error(f"Erro ao obter métricas de evolução: {e}")
            return {} 