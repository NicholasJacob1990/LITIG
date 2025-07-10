# Sprint 3: Observabilidade e A/B Testing

## 📋 **Checklist de Implementação**

### **Dia 1-4: Monitoramento de Custos e Latência**

#### **1. Serviço de Monitoramento de IA**
```python
# backend/services/ai_monitoring_service.py
import time
import asyncio
from typing import Dict, Any, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass
from prometheus_client import Counter, Histogram, Gauge
import logging

logger = logging.getLogger(__name__)

@dataclass
class AICallMetrics:
    """Métricas de uma chamada de IA."""
    provider: str  # "openai" | "anthropic"
    model: str
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int
    cost_usd: float
    latency_ms: float
    timestamp: datetime
    success: bool
    error: Optional[str] = None

# Métricas Prometheus
ai_calls_total = Counter(
    'ai_calls_total',
    'Total de chamadas para APIs de IA',
    ['provider', 'model', 'status']
)

ai_latency_histogram = Histogram(
    'ai_latency_seconds',
    'Latência das chamadas de IA',
    ['provider', 'model'],
    buckets=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 30.0, 60.0]
)

ai_cost_gauge = Gauge(
    'ai_cost_usd_total',
    'Custo total acumulado de IA em USD',
    ['provider', 'model']
)

ai_tokens_total = Counter(
    'ai_tokens_total',
    'Total de tokens processados',
    ['provider', 'model', 'type']  # type: prompt|completion
)

class AIMonitoringService:
    """Serviço para monitorar custos e performance de APIs de IA."""
    
    def __init__(self):
        self.redis_service = None  # Será injetado
        self.daily_costs_key = "ai_costs:daily"
        self.monthly_costs_key = "ai_costs:monthly"
        self.calls_history_key = "ai_calls:history"
        
        # Configuração de preços (USD por 1K tokens)
        self.pricing = {
            "openai": {
                "gpt-4o": {"prompt": 0.005, "completion": 0.015},
                "gpt-4o-mini": {"prompt": 0.00015, "completion": 0.0006},
                "gpt-3.5-turbo": {"prompt": 0.0015, "completion": 0.002}
            },
            "anthropic": {
                "claude-3-opus": {"prompt": 0.015, "completion": 0.075},
                "claude-3-sonnet": {"prompt": 0.003, "completion": 0.015},
                "claude-3-haiku": {"prompt": 0.00025, "completion": 0.00125}
            }
        }
    
    async def track_openai_call(
        self,
        model: str,
        prompt_tokens: int,
        completion_tokens: int,
        latency_ms: float,
        success: bool = True,
        error: Optional[str] = None
    ) -> AICallMetrics:
        """Rastreia chamada OpenAI."""
        
        # Calcular custo
        cost = self._calculate_cost("openai", model, prompt_tokens, completion_tokens)
        
        # Criar métricas
        metrics = AICallMetrics(
            provider="openai",
            model=model,
            prompt_tokens=prompt_tokens,
            completion_tokens=completion_tokens,
            total_tokens=prompt_tokens + completion_tokens,
            cost_usd=cost,
            latency_ms=latency_ms,
            timestamp=datetime.now(),
            success=success,
            error=error
        )
        
        # Atualizar métricas Prometheus
        await self._update_prometheus_metrics(metrics)
        
        # Salvar no Redis
        await self._save_metrics_to_redis(metrics)
        
        return metrics
    
    async def track_anthropic_call(
        self,
        model: str,
        prompt_tokens: int,
        completion_tokens: int,
        latency_ms: float,
        success: bool = True,
        error: Optional[str] = None
    ) -> AICallMetrics:
        """Rastreia chamada Anthropic."""
        
        # Calcular custo
        cost = self._calculate_cost("anthropic", model, prompt_tokens, completion_tokens)
        
        # Criar métricas
        metrics = AICallMetrics(
            provider="anthropic",
            model=model,
            prompt_tokens=prompt_tokens,
            completion_tokens=completion_tokens,
            total_tokens=prompt_tokens + completion_tokens,
            cost_usd=cost,
            latency_ms=latency_ms,
            timestamp=datetime.now(),
            success=success,
            error=error
        )
        
        # Atualizar métricas Prometheus
        await self._update_prometheus_metrics(metrics)
        
        # Salvar no Redis
        await self._save_metrics_to_redis(metrics)
        
        return metrics
    
    def _calculate_cost(self, provider: str, model: str, prompt_tokens: int, completion_tokens: int) -> float:
        """Calcula custo da chamada."""
        try:
            pricing = self.pricing.get(provider, {}).get(model, {})
            if not pricing:
                logger.warning(f"Preço não encontrado para {provider}/{model}")
                return 0.0
            
            prompt_cost = (prompt_tokens / 1000) * pricing.get("prompt", 0)
            completion_cost = (completion_tokens / 1000) * pricing.get("completion", 0)
            
            return prompt_cost + completion_cost
            
        except Exception as e:
            logger.error(f"Erro ao calcular custo: {e}")
            return 0.0
    
    async def _update_prometheus_metrics(self, metrics: AICallMetrics):
        """Atualiza métricas Prometheus."""
        try:
            status = "success" if metrics.success else "error"
            
            # Contador de chamadas
            ai_calls_total.labels(
                provider=metrics.provider,
                model=metrics.model,
                status=status
            ).inc()
            
            # Latência
            ai_latency_histogram.labels(
                provider=metrics.provider,
                model=metrics.model
            ).observe(metrics.latency_ms / 1000)
            
            # Custo (incrementar)
            ai_cost_gauge.labels(
                provider=metrics.provider,
                model=metrics.model
            ).inc(metrics.cost_usd)
            
            # Tokens
            ai_tokens_total.labels(
                provider=metrics.provider,
                model=metrics.model,
                type="prompt"
            ).inc(metrics.prompt_tokens)
            
            ai_tokens_total.labels(
                provider=metrics.provider,
                model=metrics.model,
                type="completion"
            ).inc(metrics.completion_tokens)
            
        except Exception as e:
            logger.error(f"Erro ao atualizar métricas Prometheus: {e}")
    
    async def _save_metrics_to_redis(self, metrics: AICallMetrics):
        """Salva métricas no Redis."""
        try:
            if not self.redis_service:
                return
            
            # Chave para hoje
            today = datetime.now().strftime("%Y-%m-%d")
            daily_key = f"{self.daily_costs_key}:{today}"
            
            # Chave para este mês
            month = datetime.now().strftime("%Y-%m")
            monthly_key = f"{self.monthly_costs_key}:{month}"
            
            # Atualizar custos diários
            await self.redis_service.increment_float(daily_key, metrics.cost_usd)
            await self.redis_service.set_ttl(daily_key, 86400 * 7)  # 7 dias
            
            # Atualizar custos mensais
            await self.redis_service.increment_float(monthly_key, metrics.cost_usd)
            await self.redis_service.set_ttl(monthly_key, 86400 * 90)  # 90 dias
            
            # Salvar histórico da chamada
            call_data = {
                "provider": metrics.provider,
                "model": metrics.model,
                "tokens": metrics.total_tokens,
                "cost": metrics.cost_usd,
                "latency": metrics.latency_ms,
                "success": metrics.success,
                "timestamp": metrics.timestamp.isoformat()
            }
            
            history_key = f"{self.calls_history_key}:{today}"
            await self.redis_service.list_append(history_key, call_data)
            await self.redis_service.set_ttl(history_key, 86400 * 30)  # 30 dias
            
        except Exception as e:
            logger.error(f"Erro ao salvar métricas no Redis: {e}")
    
    async def get_daily_costs(self, date: Optional[str] = None) -> Dict[str, float]:
        """Obtém custos do dia."""
        try:
            if not self.redis_service:
                return {}
            
            target_date = date or datetime.now().strftime("%Y-%m-%d")
            daily_key = f"{self.daily_costs_key}:{target_date}"
            
            cost = await self.redis_service.get_float(daily_key)
            
            return {
                "date": target_date,
                "total_cost_usd": cost or 0.0
            }
            
        except Exception as e:
            logger.error(f"Erro ao obter custos diários: {e}")
            return {}
    
    async def get_monthly_costs(self, month: Optional[str] = None) -> Dict[str, float]:
        """Obtém custos do mês."""
        try:
            if not self.redis_service:
                return {}
            
            target_month = month or datetime.now().strftime("%Y-%m")
            monthly_key = f"{self.monthly_costs_key}:{target_month}"
            
            cost = await self.redis_service.get_float(monthly_key)
            
            return {
                "month": target_month,
                "total_cost_usd": cost or 0.0
            }
            
        except Exception as e:
            logger.error(f"Erro ao obter custos mensais: {e}")
            return {}
    
    async def get_cost_summary(self) -> Dict[str, Any]:
        """Obtém resumo de custos."""
        try:
            today = await self.get_daily_costs()
            this_month = await self.get_monthly_costs()
            
            # Custo dos últimos 7 dias
            week_cost = 0.0
            for i in range(7):
                date = (datetime.now() - timedelta(days=i)).strftime("%Y-%m-%d")
                day_cost = await self.get_daily_costs(date)
                week_cost += day_cost.get("total_cost_usd", 0.0)
            
            return {
                "today": today,
                "this_week": {"total_cost_usd": week_cost},
                "this_month": this_month,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Erro ao obter resumo de custos: {e}")
            return {}
    
    async def get_performance_metrics(self) -> Dict[str, Any]:
        """Obtém métricas de performance."""
        try:
            # Buscar histórico de hoje
            today = datetime.now().strftime("%Y-%m-%d")
            history_key = f"{self.calls_history_key}:{today}"
            
            calls = await self.redis_service.list_get_all(history_key)
            
            if not calls:
                return {
                    "total_calls": 0,
                    "average_latency_ms": 0,
                    "success_rate": 0,
                    "providers": {}
                }
            
            # Calcular estatísticas
            total_calls = len(calls)
            successful_calls = sum(1 for call in calls if call.get("success", False))
            success_rate = successful_calls / total_calls if total_calls > 0 else 0
            
            latencies = [call.get("latency", 0) for call in calls if call.get("latency")]
            avg_latency = sum(latencies) / len(latencies) if latencies else 0
            
            # Agrupar por provider
            providers = {}
            for call in calls:
                provider = call.get("provider", "unknown")
                if provider not in providers:
                    providers[provider] = {
                        "calls": 0,
                        "total_cost": 0,
                        "avg_latency": 0,
                        "success_rate": 0
                    }
                
                providers[provider]["calls"] += 1
                providers[provider]["total_cost"] += call.get("cost", 0)
            
            # Calcular médias por provider
            for provider_data in providers.values():
                provider_calls = [c for c in calls if c.get("provider") == provider]
                if provider_calls:
                    provider_latencies = [c.get("latency", 0) for c in provider_calls]
                    provider_data["avg_latency"] = sum(provider_latencies) / len(provider_latencies)
                    
                    successful = sum(1 for c in provider_calls if c.get("success", False))
                    provider_data["success_rate"] = successful / len(provider_calls)
            
            return {
                "total_calls": total_calls,
                "average_latency_ms": avg_latency,
                "success_rate": success_rate,
                "providers": providers,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Erro ao obter métricas de performance: {e}")
            return {}

# Instância global
ai_monitoring_service = AIMonitoringService()
```

#### **2. Instrumentação dos Serviços de IA**
```python
# backend/services/intelligent_interviewer_service.py
# Adicionar monitoramento às chamadas de IA

class IntelligentInterviewerService:
    
    async def _call_openai_with_monitoring(self, messages: List[Dict], model: str = "gpt-4o") -> str:
        """Chama OpenAI com monitoramento."""
        start_time = time.time()
        
        try:
            response = await self.openai_client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=0.7,
                max_tokens=1000
            )
            
            # Calcular latência
            latency_ms = (time.time() - start_time) * 1000
            
            # Extrair métricas
            usage = response.usage
            content = response.choices[0].message.content
            
            # Rastrear chamada
            await ai_monitoring_service.track_openai_call(
                model=model,
                prompt_tokens=usage.prompt_tokens,
                completion_tokens=usage.completion_tokens,
                latency_ms=latency_ms,
                success=True
            )
            
            return content
            
        except Exception as e:
            # Rastrear erro
            latency_ms = (time.time() - start_time) * 1000
            
            await ai_monitoring_service.track_openai_call(
                model=model,
                prompt_tokens=0,
                completion_tokens=0,
                latency_ms=latency_ms,
                success=False,
                error=str(e)
            )
            
            raise
    
    async def _call_openai_stream_with_monitoring(self, messages: List[Dict], model: str = "gpt-4o") -> AsyncGenerator[str, None]:
        """Chama OpenAI com streaming e monitoramento."""
        start_time = time.time()
        prompt_tokens = 0
        completion_tokens = 0
        
        try:
            # Estimar tokens do prompt (aproximado)
            prompt_text = " ".join([msg["content"] for msg in messages])
            prompt_tokens = len(prompt_text.split()) * 1.3  # Aproximação
            
            stream = await self.openai_client.chat.completions.create(
                model=model,
                messages=messages,
                temperature=0.7,
                max_tokens=1000,
                stream=True
            )
            
            full_response = ""
            async for chunk in stream:
                if chunk.choices[0].delta.content:
                    content = chunk.choices[0].delta.content
                    full_response += content
                    completion_tokens += len(content.split()) * 1.3  # Aproximação
                    yield content
            
            # Calcular latência
            latency_ms = (time.time() - start_time) * 1000
            
            # Rastrear chamada
            await ai_monitoring_service.track_openai_call(
                model=model,
                prompt_tokens=int(prompt_tokens),
                completion_tokens=int(completion_tokens),
                latency_ms=latency_ms,
                success=True
            )
            
        except Exception as e:
            # Rastrear erro
            latency_ms = (time.time() - start_time) * 1000
            
            await ai_monitoring_service.track_openai_call(
                model=model,
                prompt_tokens=int(prompt_tokens),
                completion_tokens=int(completion_tokens),
                latency_ms=latency_ms,
                success=False,
                error=str(e)
            )
            
            raise
```

#### **3. Dashboards Grafana**
```json
// grafana/dashboards/ai-monitoring.json
{
  "dashboard": {
    "title": "AI Monitoring - LITGO5",
    "panels": [
      {
        "title": "Custo Diário de IA",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(ai_cost_usd_total)",
            "legendFormat": "Custo Total USD"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "currencyUSD",
            "color": {
              "mode": "palette-classic"
            }
          }
        }
      },
      {
        "title": "Latência por Provider",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, ai_latency_seconds_bucket)",
            "legendFormat": "P95 - {{provider}}/{{model}}"
          },
          {
            "expr": "histogram_quantile(0.50, ai_latency_seconds_bucket)",
            "legendFormat": "P50 - {{provider}}/{{model}}"
          }
        ]
      },
      {
        "title": "Chamadas por Minuto",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(ai_calls_total[1m])",
            "legendFormat": "{{provider}}/{{model}} - {{status}}"
          }
        ]
      },
      {
        "title": "Taxa de Sucesso",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate(ai_calls_total{status=\"success\"}[5m])) / sum(rate(ai_calls_total[5m])) * 100",
            "legendFormat": "Taxa de Sucesso"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100
          }
        }
      },
      {
        "title": "Tokens por Segundo",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(ai_tokens_total[1m])",
            "legendFormat": "{{provider}}/{{model}} - {{type}}"
          }
        ]
      },
      {
        "title": "Custo por Provider",
        "type": "piechart",
        "targets": [
          {
            "expr": "sum by (provider) (ai_cost_usd_total)",
            "legendFormat": "{{provider}}"
          }
        ]
      }
    ]
  }
}
```

#### **4. Alertas Prometheus**
```yaml
# prometheus/alerts/ai-monitoring.yml
groups:
  - name: ai-monitoring
    rules:
      - alert: AIHighCost
        expr: increase(ai_cost_usd_total[1h]) > 10
        for: 0m
        labels:
          severity: warning
        annotations:
          summary: "Custo de IA alto na última hora"
          description: "Custo de IA de ${{ $value }} na última hora excedeu o limite de $10"
      
      - alert: AIHighLatency
        expr: histogram_quantile(0.95, ai_latency_seconds_bucket) > 10
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Latência alta nas APIs de IA"
          description: "P95 da latência de IA é {{ $value }}s, acima do limite de 10s"
      
      - alert: AILowSuccessRate
        expr: sum(rate(ai_calls_total{status="success"}[5m])) / sum(rate(ai_calls_total[5m])) < 0.95
        for: 3m
        labels:
          severity: critical
        annotations:
          summary: "Taxa de sucesso baixa nas APIs de IA"
          description: "Taxa de sucesso de {{ $value | humanizePercentage }} está abaixo de 95%"
      
      - alert: AIDailyCostLimit
        expr: sum(ai_cost_usd_total) > 100
        for: 0m
        labels:
          severity: critical
        annotations:
          summary: "Limite diário de custo de IA excedido"
          description: "Custo diário de IA de ${{ $value }} excedeu o limite de $100"
```

### **Dia 5-8: A/B Testing da Nova Arquitetura**

#### **1. Configuração do Experimento**
```python
# backend/services/ab_testing_service.py
from typing import Dict, Any, Optional
import hashlib
import random
from datetime import datetime, timedelta

class ABTestingService:
    """Serviço para A/B testing da triagem inteligente."""
    
    def __init__(self):
        self.experiments = {
            "intelligent_triage_v2": {
                "name": "Triagem Inteligente V2",
                "description": "Comparação entre triagem tradicional e conversacional",
                "start_date": "2024-01-01",
                "end_date": "2024-02-01",
                "variants": {
                    "control": {
                        "name": "Triagem Tradicional (V1)",
                        "weight": 50,
                        "version": "v1",
                        "description": "Formulário estruturado tradicional"
                    },
                    "treatment": {
                        "name": "Triagem Conversacional (V2)",
                        "weight": 50,
                        "version": "v2",
                        "description": "Conversa inteligente com IA"
                    }
                },
                "metrics": [
                    "completion_rate",
                    "time_to_complete",
                    "user_satisfaction",
                    "classification_accuracy",
                    "conversion_rate"
                ]
            }
        }
    
    def get_variant_for_user(self, user_id: str, experiment_name: str) -> Optional[Dict[str, Any]]:
        """Determina variante para o usuário."""
        experiment = self.experiments.get(experiment_name)
        if not experiment:
            return None
        
        # Verificar se experimento está ativo
        start_date = datetime.strptime(experiment["start_date"], "%Y-%m-%d")
        end_date = datetime.strptime(experiment["end_date"], "%Y-%m-%d")
        now = datetime.now()
        
        if now < start_date or now > end_date:
            return None
        
        # Hash consistente baseado no user_id
        hash_input = f"{user_id}:{experiment_name}"
        hash_value = int(hashlib.md5(hash_input.encode()).hexdigest(), 16)
        
        # Determinar variante baseado no peso
        variants = experiment["variants"]
        total_weight = sum(variant["weight"] for variant in variants.values())
        
        position = hash_value % total_weight
        current_weight = 0
        
        for variant_key, variant_config in variants.items():
            current_weight += variant_config["weight"]
            if position < current_weight:
                return {
                    "experiment": experiment_name,
                    "variant": variant_key,
                    "version": variant_config["version"],
                    "config": variant_config
                }
        
        # Fallback para controle
        return {
            "experiment": experiment_name,
            "variant": "control",
            "version": variants["control"]["version"],
            "config": variants["control"]
        }
    
    async def track_event(
        self,
        user_id: str,
        experiment_name: str,
        variant: str,
        event_type: str,
        event_data: Dict[str, Any]
    ):
        """Rastreia evento do A/B test."""
        try:
            event = {
                "user_id": user_id,
                "experiment": experiment_name,
                "variant": variant,
                "event_type": event_type,
                "event_data": event_data,
                "timestamp": datetime.now().isoformat()
            }
            
            # Salvar no Redis/banco
            await self._save_ab_event(event)
            
            # Atualizar métricas Prometheus
            await self._update_ab_metrics(event)
            
        except Exception as e:
            logger.error(f"Erro ao rastrear evento A/B: {e}")
    
    async def _save_ab_event(self, event: Dict[str, Any]):
        """Salva evento no storage."""
        # Implementar salvamento no Redis ou banco
        pass
    
    async def _update_ab_metrics(self, event: Dict[str, Any]):
        """Atualiza métricas Prometheus."""
        # Implementar métricas específicas
        pass
    
    async def get_experiment_results(self, experiment_name: str) -> Dict[str, Any]:
        """Obtém resultados do experimento."""
        # Implementar análise estatística
        pass

# Instância global
ab_testing_service = ABTestingService()
```

#### **2. Integração no Frontend**
```typescript
// lib/services/abTesting.ts
export class ABTestingService {
  private cache: Map<string, ABTestVariant> = new Map();
  
  async getVariant(experimentName: string): Promise<ABTestVariant | null> {
    // Verificar cache
    const cached = this.cache.get(experimentName);
    if (cached) {
      return cached;
    }
    
    try {
      const response = await fetch(`/api/ab-testing/variant/${experimentName}`, {
        headers: {
          'Authorization': `Bearer ${await this.getToken()}`
        }
      });
      
      if (!response.ok) {
        return null;
      }
      
      const variant = await response.json();
      this.cache.set(experimentName, variant);
      
      return variant;
    } catch (error) {
      console.error('Erro ao obter variante A/B:', error);
      return null;
    }
  }
  
  async trackEvent(
    experimentName: string,
    variant: string,
    eventType: string,
    eventData: any
  ): Promise<void> {
    try {
      await fetch('/api/ab-testing/track', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${await this.getToken()}`
        },
        body: JSON.stringify({
          experiment: experimentName,
          variant,
          event_type: eventType,
          event_data: eventData
        })
      });
    } catch (error) {
      console.error('Erro ao rastrear evento A/B:', error);
    }
  }
}

export interface ABTestVariant {
  experiment: string;
  variant: string;
  version: string;
  config: any;
}
```

#### **3. Roteamento Baseado em Variante**
```tsx
// app/(tabs)/triagem/index.tsx
import { useState, useEffect } from 'react';
import { ABTestingService } from '@/lib/services/abTesting';
import { TriagemTradicional } from '@/components/TriagemTradicional';
import { TriagemConversacional } from '@/components/TriagemConversacional';

export default function TriagemScreen() {
  const [variant, setVariant] = useState<ABTestVariant | null>(null);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    const loadVariant = async () => {
      const abService = new ABTestingService();
      const testVariant = await abService.getVariant('intelligent_triage_v2');
      
      setVariant(testVariant);
      setLoading(false);
      
      // Rastrear exposição ao experimento
      if (testVariant) {
        await abService.trackEvent(
          'intelligent_triage_v2',
          testVariant.variant,
          'experiment_exposure',
          {
            screen: 'triagem_index',
            timestamp: new Date().toISOString()
          }
        );
      }
    };
    
    loadVariant();
  }, []);
  
  if (loading) {
    return <LoadingScreen />;
  }
  
  // Renderizar baseado na variante
  if (variant?.version === 'v2') {
    return (
      <TriagemConversacional 
        variant={variant}
        onEvent={(eventType, eventData) => {
          const abService = new ABTestingService();
          abService.trackEvent(
            variant.experiment,
            variant.variant,
            eventType,
            eventData
          );
        }}
      />
    );
  } else {
    return (
      <TriagemTradicional 
        variant={variant}
        onEvent={(eventType, eventData) => {
          if (variant) {
            const abService = new ABTestingService();
            abService.trackEvent(
              variant.experiment,
              variant.variant,
              eventType,
              eventData
            );
          }
        }}
      />
    );
  }
}
```

#### **4. Métricas de Comparação**
```python
# backend/services/ab_metrics_service.py
from typing import Dict, Any, List
from datetime import datetime, timedelta
import numpy as np
from scipy import stats

class ABMetricsService:
    """Serviço para análise de métricas A/B."""
    
    async def calculate_completion_rate(self, experiment: str, variant: str) -> float:
        """Calcula taxa de conclusão."""
        # Buscar eventos de início e conclusão
        started_events = await self._get_events(experiment, variant, "triage_started")
        completed_events = await self._get_events(experiment, variant, "triage_completed")
        
        if not started_events:
            return 0.0
        
        return len(completed_events) / len(started_events)
    
    async def calculate_time_to_complete(self, experiment: str, variant: str) -> Dict[str, float]:
        """Calcula tempo médio para conclusão."""
        completed_events = await self._get_events(experiment, variant, "triage_completed")
        
        times = []
        for event in completed_events:
            start_time = event.get("event_data", {}).get("start_time")
            end_time = event.get("event_data", {}).get("end_time")
            
            if start_time and end_time:
                start_dt = datetime.fromisoformat(start_time)
                end_dt = datetime.fromisoformat(end_time)
                duration = (end_dt - start_dt).total_seconds()
                times.append(duration)
        
        if not times:
            return {"mean": 0, "median": 0, "std": 0}
        
        return {
            "mean": np.mean(times),
            "median": np.median(times),
            "std": np.std(times),
            "count": len(times)
        }
    
    async def calculate_user_satisfaction(self, experiment: str, variant: str) -> Dict[str, float]:
        """Calcula satisfação do usuário."""
        satisfaction_events = await self._get_events(experiment, variant, "user_satisfaction")
        
        ratings = []
        for event in satisfaction_events:
            rating = event.get("event_data", {}).get("rating")
            if rating is not None:
                ratings.append(rating)
        
        if not ratings:
            return {"mean": 0, "count": 0}
        
        return {
            "mean": np.mean(ratings),
            "count": len(ratings),
            "nps": self._calculate_nps(ratings)
        }
    
    def _calculate_nps(self, ratings: List[float]) -> float:
        """Calcula Net Promoter Score."""
        if not ratings:
            return 0
        
        # Assumindo escala 1-10
        promoters = len([r for r in ratings if r >= 9])
        detractors = len([r for r in ratings if r <= 6])
        
        return ((promoters - detractors) / len(ratings)) * 100
    
    async def run_statistical_test(
        self, 
        experiment: str, 
        metric: str
    ) -> Dict[str, Any]:
        """Executa teste estatístico entre variantes."""
        
        # Obter dados das variantes
        control_data = await self._get_metric_data(experiment, "control", metric)
        treatment_data = await self._get_metric_data(experiment, "treatment", metric)
        
        if not control_data or not treatment_data:
            return {"error": "Dados insuficientes para teste estatístico"}
        
        # Executar teste t
        t_stat, p_value = stats.ttest_ind(control_data, treatment_data)
        
        # Calcular tamanho do efeito (Cohen's d)
        pooled_std = np.sqrt(((len(control_data) - 1) * np.var(control_data) + 
                             (len(treatment_data) - 1) * np.var(treatment_data)) / 
                            (len(control_data) + len(treatment_data) - 2))
        
        cohens_d = (np.mean(treatment_data) - np.mean(control_data)) / pooled_std
        
        # Determinar significância
        is_significant = p_value < 0.05
        
        return {
            "metric": metric,
            "control": {
                "mean": np.mean(control_data),
                "std": np.std(control_data),
                "count": len(control_data)
            },
            "treatment": {
                "mean": np.mean(treatment_data),
                "std": np.std(treatment_data),
                "count": len(treatment_data)
            },
            "test_results": {
                "t_statistic": t_stat,
                "p_value": p_value,
                "cohens_d": cohens_d,
                "is_significant": is_significant,
                "confidence_level": 0.95
            },
            "interpretation": self._interpret_results(p_value, cohens_d, is_significant)
        }
    
    def _interpret_results(self, p_value: float, cohens_d: float, is_significant: bool) -> str:
        """Interpreta resultados do teste."""
        if not is_significant:
            return "Não há diferença estatisticamente significativa entre as variantes."
        
        direction = "superior" if cohens_d > 0 else "inferior"
        
        if abs(cohens_d) < 0.2:
            effect_size = "pequeno"
        elif abs(cohens_d) < 0.5:
            effect_size = "médio"
        else:
            effect_size = "grande"
        
        return f"A variante treatment é {direction} à control com efeito {effect_size} (p={p_value:.4f})."

# Instância global
ab_metrics_service = ABMetricsService()
```

### **Dia 9-10: Dashboards e Relatórios**

#### **1. Dashboard A/B Testing**
```json
// grafana/dashboards/ab-testing.json
{
  "dashboard": {
    "title": "A/B Testing - Triagem Inteligente",
    "panels": [
      {
        "title": "Taxa de Conclusão por Variante",
        "type": "stat",
        "targets": [
          {
            "expr": "ab_completion_rate{experiment=\"intelligent_triage_v2\"}",
            "legendFormat": "{{variant}}"
          }
        ]
      },
      {
        "title": "Tempo Médio de Conclusão",
        "type": "graph",
        "targets": [
          {
            "expr": "ab_completion_time_seconds{experiment=\"intelligent_triage_v2\"}",
            "legendFormat": "{{variant}}"
          }
        ]
      },
      {
        "title": "Satisfação do Usuário (NPS)",
        "type": "gauge",
        "targets": [
          {
            "expr": "ab_user_satisfaction_nps{experiment=\"intelligent_triage_v2\"}",
            "legendFormat": "{{variant}}"
          }
        ]
      },
      {
        "title": "Distribuição de Usuários",
        "type": "piechart",
        "targets": [
          {
            "expr": "sum by (variant) (ab_user_count{experiment=\"intelligent_triage_v2\"})",
            "legendFormat": "{{variant}}"
          }
        ]
      }
    ]
  }
}
```

#### **2. Relatório Automatizado**
```python
# backend/jobs/ab_testing_reports.py
from backend.celery_config import celery_app
from backend.services.ab_metrics_service import ab_metrics_service
import asyncio

@celery_app.task(name="generate_ab_report")
def generate_ab_report_task(experiment_name: str):
    """Gera relatório A/B automatizado."""
    
    async def generate_report():
        # Calcular métricas
        metrics = {}
        
        for variant in ["control", "treatment"]:
            metrics[variant] = {
                "completion_rate": await ab_metrics_service.calculate_completion_rate(
                    experiment_name, variant
                ),
                "time_to_complete": await ab_metrics_service.calculate_time_to_complete(
                    experiment_name, variant
                ),
                "user_satisfaction": await ab_metrics_service.calculate_user_satisfaction(
                    experiment_name, variant
                )
            }
        
        # Executar testes estatísticos
        statistical_tests = {}
        for metric in ["completion_rate", "time_to_complete", "user_satisfaction"]:
            statistical_tests[metric] = await ab_metrics_service.run_statistical_test(
                experiment_name, metric
            )
        
        # Gerar relatório
        report = {
            "experiment": experiment_name,
            "generated_at": datetime.now().isoformat(),
            "metrics": metrics,
            "statistical_tests": statistical_tests,
            "summary": generate_summary(metrics, statistical_tests)
        }
        
        return report
    
    return asyncio.run(generate_report())

def generate_summary(metrics: Dict, tests: Dict) -> Dict[str, str]:
    """Gera resumo executivo do A/B test."""
    summary = {
        "winner": "inconclusive",
        "key_findings": [],
        "recommendations": []
    }
    
    # Analisar resultados
    significant_improvements = []
    
    for metric, test_result in tests.items():
        if test_result.get("test_results", {}).get("is_significant"):
            cohens_d = test_result["test_results"]["cohens_d"]
            if cohens_d > 0:
                significant_improvements.append(metric)
    
    if len(significant_improvements) >= 2:
        summary["winner"] = "treatment"
        summary["key_findings"].append(
            f"Variante treatment mostrou melhoria significativa em {len(significant_improvements)} métricas"
        )
        summary["recommendations"].append(
            "Recomenda-se implementar a triagem conversacional para todos os usuários"
        )
    elif len(significant_improvements) == 1:
        summary["winner"] = "mixed"
        summary["key_findings"].append(
            f"Variante treatment mostrou melhoria apenas em {significant_improvements[0]}"
        )
        summary["recommendations"].append(
            "Considerar implementação parcial ou continuar testando"
        )
    else:
        summary["winner"] = "control"
        summary["key_findings"].append(
            "Não houve melhoria significativa na variante treatment"
        )
        summary["recommendations"].append(
            "Manter triagem tradicional ou revisar implementação da v2"
        )
    
    return summary
```

## 🎯 **Critérios de Sucesso Sprint 3**

- [ ] ✅ Custos de IA monitorados em tempo real
- [ ] ✅ Alertas funcionando corretamente
- [ ] ✅ Dashboards Grafana atualizados
- [ ] ✅ A/B testing implementado e funcionando
- [ ] ✅ Resultados estatísticos significativos
- [ ] ✅ Relatórios automatizados gerados
- [ ] ✅ Métricas de negócio melhoradas
- [ ] ✅ Decisão baseada em dados tomada

**Resultado esperado**: Validação científica da nova arquitetura com dados concretos de melhoria na experiência do usuário e eficiência operacional.

## 📊 **Resumo Final dos 3 Sprints**

### **Sprint 1**: Persistência e Resiliência ✅
- Redis implementado
- Conversas persistem após restart
- Escalabilidade horizontal habilitada

### **Sprint 2**: Performance e UX ✅
- Streaming de respostas implementado
- Processamento em background funcionando
- Experiência do usuário otimizada

### **Sprint 3**: Observabilidade e Validação ✅
- Monitoramento completo de custos e performance
- A/B testing validando melhorias
- Decisões baseadas em dados

**Resultado Global**: Sistema de triagem inteligente robusto, escalável, monitorado e cientificamente validado para produção em larga escala. 