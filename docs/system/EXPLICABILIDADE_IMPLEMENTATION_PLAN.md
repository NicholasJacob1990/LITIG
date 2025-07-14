# Plano de Implementação de Explicabilidade do Sistema de Matching
**Versão:** 1.0  
**Data:** Janeiro 2025  
**Status:** Em Planejamento  

## Visão Geral

Este documento detalha o plano completo para implementar explicabilidade no sistema de matching jurídico, atendendo stakeholders técnicos, usuários finais e reguladores sem comprometer o segredo industrial. O plano se baseia na análise do estado atual do sistema e incorpora boas práticas de transparência em sistemas de recomendação.

## Contexto e Motivação

### Situação Atual
O algoritmo de matching v2.7-rc3 já produz logs estruturados completos com todas as informações necessárias para explicabilidade total. O sistema possui:
- **Backend:** Logs JSON detalhados com scores, features, delta e metadados de auditoria
- **Frontend Cliente:** UI parcialmente implementada com `LawyerMatchCard`, `RadarChart` e `ExplainabilityCard` (dados mocados)
- **Frontend Prestador:** Dashboard de performance funcional mas limitado a "extrato de notas"
- **Time Interno:** Logs estruturados disponíveis, mas sem ferramentas de consulta

### Objetivos
1. **Transparência Graduada:** Diferentes níveis de explicação para cada público
2. **Proteção de IP:** Nunca expor pesos, fórmulas ou scores brutos externamente
3. **Conformidade Regulatória:** Atender LGPD/GDPR com opt-in para explicações detalhadas
4. **Acionabilidade:** Fornecer insights que permitam melhorias práticas

## Arquitetura de Transparência

### Níveis de Acesso por Público

| Público | Transparência | Dados Expostos | Objetivo |
|---------|---------------|----------------|----------|
| **Cliente Final** | Intuitiva | Top 2-3 fatores, badges, resumo em linguagem natural | Gerar confiança na recomendação |
| **Prestador** | Orientada à Ação | Diagnóstico, benchmarks anônimos, sugestões práticas | Motivar melhorias no perfil |
| **Time Interno** | Total | Logs completos, scores brutos, pesos, metadados | Depuração e auditoria |
| **Regulador** | Sob Demanda | Dossiê técnico + amostra de logs | Conformidade legal |

## Fases de Implementação

### Fase 1: Explicabilidade para Cliente Final (MVP)
**Prazo:** 3-4 semanas  
**Objetivo:** Ativar explicabilidade detalhada e badges dinâmicos

#### Backend

##### Tarefa 1.1: Módulo de Explicabilidade
**Arquivo:** `packages/backend/services/explainability.py`

**Funcionalidades:**
- `generate_public_explanation(scores, case_context)`: Converte scores em explicação pública
- `extract_top_factors(delta, limit=2)`: Identifica principais fatores do ranking
- `generate_summary(top_factors)`: Cria resumo em linguagem natural
- Mapeamento de features para rótulos amigáveis

**Schema de Saída:**
```python
class PublicExplanation(BaseModel):
    lawyer_id: str
    case_id: str
    ranking_position: int
    top_factors: List[str]  # ["⭐ Excelente Avaliação", "📍 Próximo a Você"]
    summary: str           # "Selecionado por sua excelente avaliação..."
    confidence_level: str  # "Alta", "Média", "Baixa"
    version: str = "explanation_v1"
```

##### Tarefa 1.2: Endpoint Público
**Rota:** `GET /cases/{case_id}/matches/{lawyer_id}/explanation`

**Características:**
- Autenticação obrigatória (cliente proprietário do caso)
- Rate limiting (10 req/min por usuário)
- Cache de 1 hora para evitar reprocessamento
- Logs de acesso para auditoria
- Schema versionado (explanation_v1)

**Implementação:**
```python
@router.get("/cases/{case_id}/matches/{lawyer_id}/explanation")
async def get_match_explanation(
    case_id: str, 
    lawyer_id: str,
    user=Depends(authenticate_client)
):
    # Buscar log de auditoria do match
    audit_log = await fetch_audit_log(case_id, lawyer_id)
    
    # Gerar explicação pública
    explanation = generate_public_explanation(
        audit_log["scores"], 
        audit_log.get("case_context", {})
    )
    
    return explanation
```

#### Frontend (React Native)

##### Tarefa 1.3: Conectar ExplainabilityCard
**Arquivo:** `apps/app_react_native/components/organisms/ExplainabilityCard.tsx`

**Modificações:**
- Remover dados mocados
- Consumir dados reais do `matchData` passado da tela `lawyer-details`
- Implementar loading states e error handling
- Adicionar animações para melhor UX

##### Tarefa 1.4: Badges Dinâmicos
**Arquivo:** `apps/app_react_native/components/LawyerMatchCard.tsx`

**Funcionalidades:**
- Chamada à API `/explanation` para cada match
- Exibição de 1-2 badges baseados nos `top_factors`
- Cache local para evitar chamadas repetidas
- Fallback para badges genéricos em caso de erro

### Fase 2: Dashboard Acionável para Prestadores
**Prazo:** 4-5 semanas  
**Objetivo:** Transformar dashboard em ferramenta de melhoria

#### Backend

##### Tarefa 2.1: Endpoint de Insights
**Rota:** `GET /provider/performance-insights`

**Funcionalidades:**
- Análise das 3 features com menor performance
- Benchmarking anônimo (percentis 50, 75, 90)
- Sugestões práticas personalizadas
- Histórico de evolução (últimos 3 meses)
- Nota global do perfil (0-100)

**Schema de Saída:**
```python
class PerformanceInsights(BaseModel):
    overall_score: int  # 0-100
    grade: str         # "Excelente", "Bom", "Pode Melhorar"
    weak_points: List[WeakPoint]
    benchmarks: Dict[str, Benchmark]
    improvement_suggestions: List[Suggestion]
    trend: str         # "Melhorando", "Estável", "Declinando"
```

##### Tarefa 2.2: Algoritmo de Diagnóstico
**Funcionalidades:**
- Identificar features abaixo do percentil 50
- Gerar sugestões baseadas em templates
- Calcular benchmarks anônimos por área de atuação
- Detectar tendências de melhoria/piora

#### Frontend (React Native)

##### Tarefa 2.3: Redesign da Tela Performance
**Arquivo:** `apps/app_react_native/app/(tabs)/profile/performance.tsx`

**Novos Componentes:**
- `ProfileStrength.tsx`: Nota global com indicador visual
- `DiagnosticCard.tsx`: Card para cada ponto de melhoria
- `BenchmarkChart.tsx`: Comparação visual com mercado
- `ActionPlan.tsx`: Lista de próximas ações sugeridas

##### Tarefa 2.4: Sistema de Notificações
**Backend - Cron Job:**
- Análise semanal de mudanças significativas
- Envio de e-mails personalizados
- Template: "Sua taxa de resposta aumentou para 18h, impactando seu ranking"
- Link direto para dashboard de insights

### Fase 3: Ferramentas para Time Interno
**Prazo:** 2-3 semanas  
**Objetivo:** Facilitar auditoria e depuração

#### Tarefa 3.1: CLI de Explicabilidade
**Arquivo:** `packages/backend/scripts/explain_cli.py`

**Funcionalidades:**
```bash
# Explicar match específico
python explain_cli.py --case-id=xyz --lawyer-id=abc --pretty

# Analisar tendências de fairness
python explain_cli.py --fairness-report --date-range=2025-01-01:2025-01-31

# Validar consistency de pesos
python explain_cli.py --validate-weights --preset=balanced
```

**Saídas:**
- Breakdown completo de features e delta
- Análise de equidade por dimensões de diversidade
- Detecção de anomalias no ranking
- Relatórios de distribuição de scores

#### Tarefa 3.2: Dashboard de Fairness (Futuro)
**Objetivo:** Monitoramento contínuo de viés
- Distribuição de features por gênero, etnia, PCD
- Alertas automáticos para desvios estatísticos
- Métricas de equidade temporal
- Integração com Grafana/Datadog

### Fase 4: Planejamento para Escritórios
**Prazo:** Pesquisa - 4 semanas  
**Objetivo:** Levantar requisitos para dashboard de gestão

#### Tarefa 4.1: Pesquisa de Requisitos
**Metodologia:**
- Entrevistas com 5-10 escritórios parceiros
- Questionário sobre KPIs prioritários
- Análise de ferramentas concorrentes
- Workshop de co-criação

**Questões-Chave:**
- Quais métricas são mais importantes para gestão?
- Como preferem visualizar performance da equipe?
- Que ações de melhoria são mais factíveis?
- Qual frequência ideal de relatórios?

## Boas Práticas de Implementação

### 1. Contrato de Explicação Estável
- **Schema Versionado:** `explanation_v1`, `explanation_v2`, etc.
- **Backward Compatibility:** Manter versões antigas por 6 meses
- **Migration Path:** Documentar mudanças entre versões
- **Testing:** Suite de testes para cada versão do schema

### 2. Limite de Granularidade
**Público Externo:**
- Apenas rótulos ("Alta", "Média", "Baixa")
- Nunca expor pesos ou scores numéricos
- Percentuais arredondados (ex: 85% em vez de 84.7%)

**Time Interno:**
- Acesso total via logs seguros (S3/DataDog)
- Nunca no banco OLTP de produção
- Controle de acesso baseado em roles

### 3. Auditoria Reversível
**Implementação Atual (Aproveitada):**
- `algorithm_version` e `model_version` já salvos
- Hash dos pesos pode ser adicionado
- Logs com timestamp preciso
- Capacidade de reconstruir qualquer ranking

**Melhorias:**
```python
# Adicionar ao log_context existente
log_context.update({
    "weights_hash": hashlib.sha256(json.dumps(weights, sort_keys=True).encode()).hexdigest(),
    "feature_versions": get_feature_versions(),
    "reproducible_seed": case.id + lawyer.id  # Para determinismo
})
```

### 4. Conformidade LGPD/GDPR
**Opt-in de Explicação Detalhada:**
- ExplainabilityCard começa colapsado
- Clicar para expandir = consentimento implícito
- Log do consentimento para auditoria
- Botão "Não quero ver detalhes" para opt-out

**Implementação:**
```typescript
const handleExpandDetails = () => {
  if (!hasConsented) {
    // Log consent
    logUserConsent(userId, 'explanation_details', 'granted');
    setHasConsented(true);
  }
  setIsExpanded(true);
};
```

## Métricas de Sucesso

### Fase 1 (Cliente)
- **Engajamento:** % de clientes que expandem explicações detalhadas
- **Confiança:** NPS antes/depois da implementação
- **Compreensão:** Pesquisa qualitativa sobre clareza das explicações

### Fase 2 (Prestador)
- **Adoção:** % de advogados que acessam dashboard de insights
- **Ação:** % que implementam sugestões do sistema
- **Melhoria:** Evolução média dos KPIs após implementação

### Fase 3 (Interno)
- **Eficiência:** Tempo médio para resolver tickets de auditoria
- **Qualidade:** Redução de falsos positivos em detecção de viés
- **Adoption:** % da equipe que usa o CLI regularmente

## Cronograma Executivo

| Fase | Duração | Início | Entrega | Dependências |
|------|---------|--------|---------|--------------|
| **Fase 1** | 4 semanas | Sem 1 | Sem 4 | Aprovação do plano |
| **Fase 2** | 5 semanas | Sem 3 | Sem 8 | Fase 1 parcial |
| **Fase 3** | 3 semanas | Sem 6 | Sem 9 | - |
| **Fase 4** | 4 semanas | Sem 9 | Sem 13 | Aprovação stakeholders |

**Total:** 13 semanas para implementação completa

## Riscos e Mitigações

### Riscos Técnicos
1. **Performance:** Muitas chamadas à API de explicação
   - **Mitigação:** Cache agressivo, batch requests
2. **Consistência:** Explicações divergentes entre telas
   - **Mitigação:** Módulo centralizado de explicabilidade

### Riscos de Negócio
1. **Exposição de IP:** Engenharia reversa dos pesos
   - **Mitigação:** Limite rígido de granularidade
2. **Regulatório:** Não conformidade com LGPD/GDPR
   - **Mitigação:** Opt-in explícito, logs de consentimento

### Riscos de Produto
1. **Complexidade:** Interface muito técnica para usuários
   - **Mitigação:** Testes de usabilidade, linguagem natural
2. **Overload:** Excesso de informação
   - **Mitigação:** Progressive disclosure, interface adaptativa

## Próximos Passos

1. **Aprovação do Plano:** Revisão com stakeholders técnicos e de produto
2. **Setup do Projeto:** Criação de épicos no backlog, definição de sprints
3. **Kick-off Fase 1:** Início da implementação do módulo de explicabilidade
4. **Validação Contínua:** Testes de usabilidade a cada milestone

---

**Responsáveis:**
- **Tech Lead:** Arquitetura e revisão técnica
- **Backend:** Implementação de APIs e lógica de negócio  
- **Frontend:** Componentes de UI e integração
- **Product:** Validação de requisitos e testes de usabilidade
- **Legal:** Conformidade LGPD/GDPR

**Última Atualização:** Janeiro 2025 