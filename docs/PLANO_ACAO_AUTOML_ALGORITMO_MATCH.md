# Plano de Ação: Evolução do Algoritmo de Match (v3.0-automl)

## 📋 Resumo Executivo

**Objetivo Primário:** Transformar o `algoritmo_match.py` em um sistema de AutoML completamente funcional, capaz de aprender com dados reais e melhorar continuamente sua precisão e relevância.

**Status Atual:** Base de AutoML implementada (UnifiedCacheService, CaseMatchMLService, MultiDimensionalScoring, AdvancedDiversification) - **PRONTO PARA OPERACIONALIZAÇÃO**

**Próximo Marco:** Fechar o ciclo de aprendizado automático (feedback → retreinamento → melhoria)

---

## 🎯 Visão Geral das Fases

| Fase | Foco | Status | Prioridade |
|------|------|--------|------------|
| **Fase 1** | Operacionalização (Fechar Ciclo) | 🔄 Em Andamento | **CRÍTICA** |
| **Fase 2** | UX/Transparência (XAI) | ⏳ Aguardando | ALTA |
| **Fase 3** | IA Avançada (LLM Reranking) | 📋 Planejada | MÉDIA |

---

## 🚀 Fase 1: Fechar o Ciclo de Aprendizado

### **Por que esta fase é crítica?**
- **Data Drift**: Modelos que não se retro-alimentam entram rapidamente em data-drift e perdem acurácia ([LinkedIn MLOps](https://www.linkedin.com/pulse/day-22-model-retraining-feedback-loops-mlops-srinivasan-ramanujam-n8gmc))
- **Evidência Industrial**: Nubank relata que reciclar pesos só vale a pena quando o log de feedback está integrado ao pipeline ([Building Nubank](https://building.nubank.com/automatic-retraining-for-machine-learning-models/))
- **Padrão AWS**: Amazon Personalize só ativa retrain automático se encontra dados novos na tabela de interações ([AWS Documentation](https://docs.aws.amazon.com/personalize/latest/dg/maintaining-relevance.html))
- Sem ela, o AutoML é apenas teórico - o ciclo `feedback → retreinamento → melhoria` está quebrado

### Tarefa 1.1: Criar Tabela `case_feedback` no Banco de Dados

**📁 Arquivo:** `packages/backend/alembic/versions/[timestamp]_create_case_feedback_table.py`

**🎯 Objetivo:** Criar infraestrutura de persistência para feedback de matching

**📋 Checklist:**
- [ ] Gerar nova migração Alembic ([Tutorial Oficial](https://alembic.sqlalchemy.org/en/latest/tutorial.html))
- [ ] Criar tabela baseada na dataclass `CaseFeedback` do `case_match_ml_service.py`
- [ ] Adicionar índices em `case_id` e `lawyer_id` ([Naming Constraints](https://alembic.sqlalchemy.org/en/latest/naming.html))
- [ ] Testar migração em ambiente de desenvolvimento
- [ ] **Buffer mínimo**: Implementar gatilho de 50 eventos OU 24h para evitar treinos vazios
- [ ] **Audit Trail**: Configurar backup completo no S3 antes de deletar dados quentes
- [ ] **Feature Flag**: Fallback para `DEFAULT_WEIGHTS` se job falhar

**🔧 Schema da Tabela:**
```sql
CREATE TABLE case_feedback (
    id SERIAL PRIMARY KEY,
    case_id VARCHAR NOT NULL,
    lawyer_id VARCHAR NOT NULL,
    client_id VARCHAR NOT NULL,
    hired BOOLEAN NOT NULL,
    client_satisfaction DECIMAL(2,1) CHECK (client_satisfaction >= 0 AND client_satisfaction <= 5),
    case_success BOOLEAN NOT NULL DEFAULT FALSE,
    case_outcome_value DECIMAL(12,2),
    response_time_hours DECIMAL(5,2),
    negotiation_rounds INTEGER,
    case_duration_days INTEGER,
    case_area VARCHAR NOT NULL,
    case_complexity VARCHAR DEFAULT 'MEDIUM',
    case_urgency_hours INTEGER DEFAULT 48,
    case_value_range VARCHAR DEFAULT 'unknown',
    lawyer_rank_position INTEGER NOT NULL DEFAULT 1,
    total_candidates INTEGER NOT NULL DEFAULT 5,
    match_score DECIMAL(4,3) CHECK (match_score >= 0 AND match_score <= 1),
    features_used JSONB,
    preset_used VARCHAR DEFAULT 'balanced',
    feedback_source VARCHAR DEFAULT 'client',
    feedback_notes TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_case_feedback_case_id ON case_feedback(case_id);
CREATE INDEX idx_case_feedback_lawyer_id ON case_feedback(lawyer_id);
CREATE INDEX idx_case_feedback_timestamp ON case_feedback(timestamp);
```

---

### Tarefa 1.2: Desenvolver API de Coleta de Feedback

**📁 Arquivo:** `packages/backend/routes/feedback_routes.py`

**🎯 Objetivo:** Criar endpoints para coletar outcomes de matching

**📋 Checklist:**
- [ ] Criar arquivo de rotas `feedback_routes.py` ([REST Pattern Reference](https://abellogin.github.io/2018/recsys-demo.pdf))
- [ ] Implementar endpoint `POST /feedback/case`
- [ ] Implementar endpoint `POST /feedback/case/batch`
- [ ] Criar schemas Pydantic para validação robusta
- [ ] Conectar com `MatchmakingAlgorithm.record_case_outcome()`
- [ ] Adicionar tratamento de erros e logs de auditoria
- [ ] Testes unitários dos endpoints
- [ ] **Validação**: Garantir que dados inválidos não corrompam o modelo
- [ ] **Rate Limiting**: Prevenir spam de feedback que poderia enviesar o algoritmo

**🔗 Endpoints:**

#### `POST /feedback/case`
```python
{
    "case_id": "string",
    "lawyer_id": "string", 
    "client_id": "string",
    "hired": boolean,
    "client_satisfaction": float, # 0.0-5.0
    "case_success": boolean,
    "case_outcome_value": float, # opcional
    "response_time_hours": float, # opcional
    "case_duration_days": int, # opcional
    "lawyer_rank_position": int,
    "total_candidates": int,
    "match_score": float,
    "features_used": object, # opcional
    "preset_used": string,
    "feedback_notes": string # opcional
}
```

#### `POST /feedback/case/batch`
```python
{
    "case_id": "string",
    "client_id": "string",
    "outcomes": [
        {
            "lawyer_id": "string",
            "hired": boolean,
            "client_rating": float,
            "rank_position": int,
            "match_score": float,
            "features": object
        }
    ],
    "case_context": {
        "case_success": boolean,
        "case_value": float,
        "duration_days": int,
        "preset_used": string
    }
}
```

---

### Tarefa 1.3: Criar Job de Retreinamento Automático

**📁 Arquivo:** `packages/backend/jobs/case_match_retrain.py`

**🎯 Objetivo:** Automatizar processo de retreinamento do modelo

**📋 Checklist:**
- [ ] Criar script de job baseado no padrão `partnership_retrain.py`
- [ ] Conectar com `CaseMatchMLService`
- [ ] Implementar lógica de verificação de feedback suficiente
- [ ] Configurar agendamento (cron/Celery Beat)
- [ ] Logs detalhados de execução
- [ ] Métricas de performance pós-otimização

**⏰ Agendamento Sugerido:**
- **Frequência:** Diário (às 2:00 AM)
- **Gatilhos:** Mínimo 50 novos feedbacks OU degradação de performance
- **Timeout:** 30 minutos máximo
- **Retry:** 3 tentativas com backoff exponencial

**📊 Métricas Monitoradas:**
- Taxa de contratação (hire rate)
- Satisfação média do cliente
- Taxa de sucesso dos casos
- Tempo médio de resposta
- Convergência do modelo

---

## 🎨 Fase 2: Melhoria da Experiência e Transparência

### **Por que esta fase é crítica?**
- **Evidência Científica**: Estudos mostram que expor fatores-chave de decisão aumenta confiança e adesão a recomendações ([ScienceDirect XAI](https://www.sciencedirect.com/science/article/pii/S0040162522006412))
- **Feedback de Qualidade**: Interfaces que deixam o usuário ajustar prioridades reduzem percepções de injustiça e ampliam diversidade de cliques ([ACM Digital Library](https://dl.acm.org/doi/fullHtml/10.1145/3450613.3456835))
- **Valor de Negócio**: Transparência gera feedback implícito valioso para o AutoML - mudanças de slider são sinais de preferência

### Tarefa 2.1: Implementar Explicações Inteligentes (XAI) na API

**📁 Arquivo:** `packages/backend/algoritmo_match.py` (expansão)

**🎯 Objetivo:** Retornar explicações detalhadas das recomendações

**✅ Vantagem:** UI já tem componentes (`explanation_modal.dart`, `match_explanation_section.dart`)

**📋 Checklist:**
- [ ] Expandir classe `IntelligentExplanations`
- [ ] Gerar `Dict` estruturado com motivos
- [ ] Integrar ao método `rank()` do `MatchmakingAlgorithm`
- [ ] Atualizar schema de resposta da API

**📤 Formato de Saída:**
```python
{
    "lawyer_id": "ADV123",
    "name": "Dr. João Silva",
    "fair_score": 0.85,
    "explanation": {
        "score_geral": 0.85,
        "destaques": [
            "Especialista em Direito Trabalhista",
            "Taxa de sucesso de 92%", 
            "Qualificação excepcional",
            "Resposta em 4h"
        ],
        "breakdown": {
            "expertise_match": 0.95,
            "track_record": 0.92,
            "qualification": 0.88,
            "responsiveness": 0.85
        },
        "context_factors": [
            "Adequado para casos complexos",
            "Experiência em casos similares",
            "Disponibilidade imediata"
        ]
    }
}
```

---

### Tarefa 2.2: Conectar UI aos Dados de XAI

**📁 Arquivos:** 
- `apps/app_flutter/lib/src/features/recommendations/presentation/screens/recomendacoes_screen.dart`
- `apps/app_flutter/lib/src/features/lawyers/presentation/widgets/explanation_modal.dart`

**🎯 Objetivo:** Substituir placeholders por explicações reais

**📋 Checklist:**
- [ ] Modificar `onExplain` no `recomendacoes_screen.dart` (remover TODO)
- [ ] Atualizar `LawyerMatchCard` para receber dados de explicação
- [ ] Implementar renderização real no `explanation_modal`
- [ ] **Sliders de Preferência**: Adicionar controles "Experiência | Preço | Agilidade"
- [ ] **Feedback Implícito**: Capturar mudanças de slider como novo tipo de feedback
- [ ] **Dynamic Weights**: Integrar sliders com `apply_dynamic_weights()` na API
- [ ] Testes de UI completos

---

## 🧠 Fase 3: Refinamento com IA Avançada

### **Por que deixar por último?**
- **Custo vs Benefício**: LLM reranking traz ganhos médios de 3-7pp em NDCG, mas custa tokens e latência ([DEV Community](https://dev.to/simplr_sh/llm-re-ranking-enhancing-search-and-retrieval-with-ai-28b7))
- **Pré-requisito**: A etapa só vale a pena quando já existe top-k forte e cache afinado
- **ROI**: Investimento só se justifica com base robusta de dados e feedback rodando

### Tarefa 3.1: Implementar Reranking Semântico com LLM

**📁 Arquivo:** `packages/backend/services/llm_enhancement_service.py` (novo)

**🎯 Objetivo:** Ajuste fino de rankings usando compreensão semântica

**📋 Checklist:**
- [ ] Criar `LLMEnhancementService` ([OpenAI Cookbook](https://cookbook.openai.com/examples/search_reranking_with_cross-encoders))
- [ ] Integrar com APIs existentes (Perplexity/OpenAI)
- [ ] **Otimização**: Passar apenas top 5-7 candidatos (reduz custo)
- [ ] **Prompt Engineering**: JSON schema com `boost_factor` e `justification`
- [ ] **Cache**: Hash de `(case, lawyer_set)` para evitar recálculos
- [ ] **Async**: Chamar LLM assíncrono, exibir lista provisória primeiro
- [ ] Implementar validação Pydantic para prevenir alucinações
- [ ] Adicionar ao pipeline do `MatchmakingAlgorithm`
- [ ] A/B testing para validar melhoria (meta: +4pp NDCG, P95 < 400ms)

---

## 📊 Métricas de Sucesso

### Fase 1 (Operacionalização)
- [ ] **Coleta de Feedback:** 100+ feedbacks coletados por semana
- [ ] **Retreinamento:** Modelo otimizado automaticamente a cada 24-48h
- [ ] **Performance:** Algoritmo melhora hire rate em 10-15% em 30 dias

### Fase 2 (Transparência)  
- [ ] **Engajamento:** 80% dos usuários usam explicações
- [ ] **Confiança:** Aumento de 25% na satisfação com recomendações
- [ ] **Feedback:** Coleta de preferências melhora precisão

### Fase 3 (IA Avançada)
- [ ] **Precisão:** LLM reranking melhora relevância em 15-20%
- [ ] **Diferenciação:** Capacidade semântica única no mercado

---

## 🔄 Cronograma Consolidado

| Sprint | Entrega | Métrica-Chave | Referência |
|--------|---------|---------------|------------|
| **S1** | Feedback DB + API | 100% feedback persistido; job cron roda sem erro | [AWS Personalize Pattern](https://docs.aws.amazon.com/personalize/latest/dg/maintaining-relevance.html) |
| **S2** | Painel XAI + sliders | CTR ↑, tempo na tela ↑, novo tipo de feedback coletado | [ACM Fairness](https://dl.acm.org/doi/fullHtml/10.1145/3450613.3456835) |
| **S3** | LLM reranking piloto em 10% tráfego | ΔNDCG ≥ +4pp, P95 latência < 400ms | [OpenAI Reranking](https://cookbook.openai.com/examples/search_reranking_with_cross-encoders) |

### **Roadmap Detalhado**

| Semana | Fase | Tarefa | Entregável |
|--------|------|--------|------------|
| **S1** | 1 | 1.1 | Migração `case_feedback` + boas práticas |
| **S2** | 1 | 1.2 | API `/feedback/case` + validação robusta |
| **S3** | 1 | 1.3 | Job de retreinamento + feature flags |
| **S4** | 1 | Validação | Ciclo completo funcionando + métricas |
| **S5-S6** | 2 | 2.1-2.2 | XAI completo + sliders de preferência |
| **S7+** | 3 | 3.1 | LLM reranking + A/B testing |

---

## ⚠️ Riscos e Mitigações (Baseado em Literatura)

| Risco | Impacto | Mitigação | Referência |
|-------|---------|-----------|------------|
| **Data Drift** | Crítico | Buffer 50 eventos + janela 24h | [LinkedIn MLOps](https://www.linkedin.com/pulse/day-22-model-retraining-feedback-loops-mlops-srinivasan-ramanujam-n8gmc) |
| **Feedback Spam** | Alto | Rate limiting + validação Pydantic | [REST Patterns](https://abellogin.github.io/2018/recsys-demo.pdf) |
| **Overfitting** | Alto | Validação cruzada + regularização | [Nubank ML](https://building.nubank.com/automatic-retraining-for-machine-learning-models/) |
| **Latência LLM** | Médio | Cache hash + chamada assíncrona | [OpenAI Cookbook](https://cookbook.openai.com/examples/search_reranking_with_cross-encoders) |
| **Alucinações LLM** | Médio | JSON schema + validação Pydantic | [DEV Community](https://dev.to/simplr_sh/llm-re-ranking-enhancing-search-and-retrieval-with-ai-28b7) |
| **Custo Tokens** | Baixo | Top-k limitado + cache por 6h | [Caylent GenAI](https://caylent.com/blog/building-recommendation-systems-using-genai-and-amazon-personalize) |

---

## 📝 Notas de Implementação

### Princípios Seguidos
- ✅ **Verificação Ativa:** Estado atual verificado antes da implementação
- ✅ **Implementação Holística:** Backend + Frontend + Navegação
- ✅ **ZERO Simplificações:** Problemas corrigidos na raiz
- ✅ **Documentação:** TO-DOs e rastreabilidade mantidos

### Dependências Técnicas
- ✅ `CaseMatchMLService` implementado
- ✅ `UnifiedCacheService` funcionando  
- ✅ `MultiDimensionalScoring` ativo
- ✅ `AdvancedDiversification` implementada

### Próximos Passos Imediatos
1. **Iniciar Tarefa 1.1** - Criar migração `case_feedback` com buffer mínimo
2. **Coordenar com Frontend** - Preparar integração de feedback com rate limiting
3. **Configurar Monitoramento** - Métricas de acompanhamento baseadas em AWS Personalize
4. **Setup Feature Flags** - Garantir fallback para `DEFAULT_WEIGHTS`

---

## 📚 **VALIDAÇÃO TÉCNICA E FUNDAMENTAÇÃO ACADÊMICA**

### **Sequência Estratégica Validada: 1 → 2 → 3**

**A ordem de prioridade foi validada por evidências da indústria e literatura acadêmica:**

1. **🔄 Fase 1 (Operacionalização)**: "Sem dados nenhum modelo aprende" 
   - **Nubank**: Retrain só vale com feedback integrado ao pipeline
   - **AWS Personalize**: Auto-retrain condicionado a dados novos na tabela
   - **LinkedIn MLOps**: Data drift é inevitável sem feedback loop

2. **🎨 Fase 2 (Transparência)**: "Transparência gera feedback de qualidade"
   - **ScienceDirect**: XAI aumenta confiança e adesão
   - **ACM**: Controles de usuário reduzem percepção de injustiça
   - **Benefício Extra**: Sliders capturam feedback implícito valioso

3. **🧠 Fase 3 (LLM Enhancement)**: "ROI só se justifica com base robusta"
   - **DEV Community**: Ganhos de 3-7pp custam tokens e latência
   - **OpenAI**: Reranking eficiente requer top-k forte
   - **Caylent**: Cache inteligente essencial para viabilidade

### **Armadilhas Identificadas e Mitigadas**

| Armadilha | Como Evitar | Fonte |
|:---|:---|:---|
| **Treinos vazios** | Buffer 50 eventos + janela 24h | LinkedIn MLOps |
| **Feedback spam** | Rate limiting + validação Pydantic | REST Patterns |
| **Latência LLM** | Async + cache hash | OpenAI Cookbook |
| **Data drift silencioso** | Métricas contínuas + feature flags | AWS Personalize |
| **Overfitting** | Validação cruzada rigorosa | Nubank ML |

### **Padrões da Indústria Aplicados**

- ✅ **Amazon Personalize**: Retrain automático baseado em dados novos
- ✅ **Nubank**: Pipeline de feedback integrado ao retreinamento
- ✅ **LinkedIn**: MLOps com métricas de data drift
- ✅ **OpenAI**: Reranking com cache otimizado
- ✅ **ScienceDirect/ACM**: XAI para confiança e feedback

### **ROI Esperado por Fase**

| Fase | Investimento | ROI | Timeline |
|:---|:---|:---|:---|
| **Fase 1** | Alto (infraestrutura) | **Crítico** (base de tudo) | 4 semanas |
| **Fase 2** | Médio (UI/UX) | **Alto** (+25% engajamento) | 2 semanas |
| **Fase 3** | Alto (tokens LLM) | **Médio** (+4pp NDCG) | 2+ semanas |

**Conclusão**: A sequência é estratégica, fundamentada e otimizada para máximo ROI com mínimo risco técnico.

---

**📅 Data de Criação:** 2025-01-26  
**👤 Responsável:** Equipe de Desenvolvimento  
**🔄 Última Atualização:** 2025-01-26 (Validação Técnica Completa)  
**📈 Status Geral:** 🟡 Em Progresso (Fase 1) - **VALIDADO TECNICAMENTE** 