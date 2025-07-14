# 🎯 PLANO DE AÇÃO COMPLETO: Sistema de Busca Avançada
## Implementação de Presets Dinâmicos e Busca Inteligente B2B

### 📋 RESUMO EXECUTIVO

Este documento apresenta o plano completo para implementar um sistema de busca avançada que permite diferentes modos de busca (correspondente, especialista, B2B corporativo) através de presets dinâmicos. A beleza da abordagem é que ela aproveita 100% do poderoso algoritmo `MatchmakingAlgorithm` v2.8 já existente, sem necessidade de alterá-lo. A adaptação ocorre na forma como definimos o "caso" (a necessidade do usuário) e nos pesos que aplicamos.

**Objetivo Principal:** Transformar o algoritmo de matching de "uma marcha" para "múltiplas marchas", permitindo que diferentes tipos de usuários (clientes finais e advogados) obtenham resultados otimizados para suas necessidades específicas, transformando a plataforma de um marketplace B2C para uma **rede de colaboração profissional B2B**.

---

## 🔍 ANÁLISE PROFUNDA DO ESTADO ATUAL 

### 🎯 DESCOBERTAS CRÍTICAS DA ANÁLISE DE CÓDIGO

**⚠️ CORREÇÃO IMPORTANTE:** A análise inicial presumia um fluxo puramente assíncrono. A investigação profunda do código revelou um **fluxo híbrido** que muda completamente nossa estratégia de implementação.

#### 📊 FLUXO REAL DO SISTEMA (Descoberto)

1. **Triagem (Assíncrona):**
   - **Trigger:** Usuário descreve o caso no frontend
   - **Fluxo:** `triage_tasks.py` → `intelligent_triage_orchestrator.py` → `triage_service.py`
   - **Função:** Análise de texto com LLMs, extração de dados estruturados, geração de `summary_embedding`
   - **Resultado:** Caso completo salvo no banco de dados

2. **Matching (Síncrono):**
   - **Trigger:** Usuário clica "Encontrar Advogados" para um caso já triado
   - **Endpoint:** `POST /api/match` em `LITGO6/backend/api/main.py`
   - **Função:** Executa `MatchmakingAlgorithm` em tempo real
   - **Resultado:** Lista de advogados ranqueados retornada imediatamente

3. **Visualização (Cache):**
   - **Endpoint:** `GET /cases/{case_id}/matches` em `LITGO6/backend/routes/recommendations.py`
   - **Função:** Busca resultados pré-calculados da tabela `case_matches`
   - **Resultado:** Exibição rápida de matches já computados

### ✅ Backend (LITGO6) - Estado Atual REAL

**Pontos Fortes Confirmados:**

1. **Algoritmo Robusto:** 
   - `MatchmakingAlgorithm` v2.8 em `LITGO6/backend/algoritmo_match.py`
    - 11 features implementadas (A, S, T, G, Q, U, R, C, E, P, M)
   - Sistema de presets: `fast`, `expert`, `balanced`, `economic`, `b2b`
   - Validação automática de pesos via `_validate_preset_weights()`

2. **API Síncrona Funcional:**
   - **Endpoint Principal:** `POST /api/match` em `LITGO6/backend/api/main.py`
   - **Schema:** `MatchRequestSchema` já aceita parâmetro `preset`
   - **Execução:** Carrega dados → Instancia algoritmo → Executa `algorithm.rank()` → Retorna resultados
   - **Serviço:** `match_service.py` encapsula lógica de preparação

3. **Infraestrutura Completa:**
   - Cache Redis implementado
   - Métricas Prometheus configuradas
   - Logging estruturado
   - Validação de schemas

**Gaps Identificados:**
- ❌ Preset `'correspondent'` não existe no `PRESET_WEIGHTS`
- ❌ Campo `is_boutique` não existe na dataclass `LawFirm`
- ❌ Endpoint `/api/match` não aceita coordenadas geográficas customizadas
- ❌ Lógica de negócio para seleção automática de preset não implementada

### ⚠️ Frontend (Flutter) - Estado Atual REAL

**Pontos Fortes Confirmados:**

1. **Arquitetura Sólida:**
   - Clean Architecture com BLoC pattern
   - Injeção de dependência via `injection_container.dart`
   - Navegação contextual por perfil de usuário implementada

2. **Navegação Contextual Existente:**
   - **Cliente:** `/client-home`, `/client-cases`, `/find-lawyers`
   - **Advogado Associado:** `/dashboard`, `/cases`, `/agenda`
   - **Advogado Contratante:** `/home`, `/contractor-offers`, `/partners`

3. **Serviços Funcionais:**
   - `ApiService` em `apps/app_flutter/lib/src/core/services/api_service.dart`
   - Método `getMatches(String caseId)` funcional
   - Chamada correta para `POST /api/match`

**Gaps Críticos Confirmados:**
- ❌ **Preset Hardcoded:** `getMatches()` sempre envia `'preset': 'balanced'`
- ❌ **Sem Coordenadas:** Não há suporte para busca geográfica customizada
- ❌ **Interface Única:** Não há UI para diferentes tipos de busca
- ❌ **Sem Contexto:** Tipo de usuário não influencia parâmetros de busca

---

## 🧠 Como o Algoritmo se Adapta ao Cenário B2B

A genialidade do framework é que o `MatchmakingAlgorithm` em si não precisa de **nenhuma alteração**. A mágica acontece na definição do "caso" e na aplicação dos pesos corretos para cada cenário.

### 🎯 Casos de Uso B2B Identificados

#### 1. **Busca por Correspondente**
**Cenário:** Advogado de São Paulo precisa de colega em Belém para audiência
**Configuração:**
```python
case.coords = [-1.4558, -48.4902]  # Belém
case.radius_km = 10
preset = "correspondent"
```
**Pesos Otimizados:**
- **G (Geografia - 25%):** Proximidade física é crucial
- **U (Urgência - 20%):** Disponibilidade imediata
- **P (Preço - 15%):** Custo da diligência
- **A, Q, S, T (5-10%):** Qualidade secundária

#### 2. **Busca por Especialista**
**Cenário:** Advogado generalista precisa de expert em Direito Digital
**Configuração:**
```python
case.area = "Direito Digital"
case.complexity = "HIGH"
preset = "expert"
```
**Pesos Existentes:**
- **S (Similaridade - 25%):** Casos similares já resolvidos
- **Q (Qualificação - 15%):** Títulos e especializações
- **A (Área - 19%):** Match perfeito da expertise

#### 3. **Busca por Parecerista**
**Cenário:** Advogado quer segunda opinião de jurista renomado
**Configuração:**
```python
case.summary_embedding = embedding_parecer_tecnico
preset = "expert_opinion"  # NOVO
```
**Pesos Propostos:**
- **Q (Qualificação - 35%):** Doutores, publicações
- **S (Similaridade - 30%):** Pareceres similares
- **M (Maturidade - 20%):** Experiência comprovada

### 📊 Comparação de Prioridades

| Feature | Cliente Leigo | Advogado → Correspondente | Advogado → Especialista | Advogado → Parecerista |
|---------|---------------|---------------------------|-------------------------|------------------------|
| **Q** (Qualificação) | Alta | Baixa | **Muito Alta** | **Extrema** |
| **S** (Similaridade) | Média | Baixa | **Muito Alta** | **Muito Alta** |
| **G** (Geografia) | Média | **Extrema** | Baixa | Nula |
| **U** (Urgência) | Alta | **Muito Alta** | Média | Baixa |
| **P** (Preço) | **Muito Alta** | **Alta** | Média | Baixa |
| **C** (Soft Skills) | **Muito Alta** | Baixa | Média | Baixa |

---

## 🎯 ESTRATÉGIA DE INTEGRAÇÃO FINAL (Pós-Análise Detalhada)

Com base em uma análise aprofundada da base de código e da interface do usuário, a estratégia foi refinada para ser mais eficiente e alinhada com as funcionalidades existentes. Em vez de criar novas telas, vamos **evoluir as telas atuais**, conciliando as funcionalidades de busca existentes com as novas capacidades de busca avançada.

A implementação será direcionada para os perfis de usuário específicos da seguinte forma:

### 👤 Perfil: Cliente (`client`)

*   **Tela Alvo:** `LawyersScreen` (Aba "Advogados").
*   **Estado Atual:** Esta tela possui duas abas:
    1.  **"Recomendações":** Exibe uma lista de advogados e escritórios gerada pelo algoritmo de match com base no último caso do cliente.
    2.  **"Buscar":** Oferece um campo de texto para uma busca manual por palavra-chave.
*   **Estratégia de Integração:**
    *   **Aprimorar a Aba "Recomendações":** Vamos adicionar o seletor de "Estilo de Busca" (ex: `[⭐ Recomendado]`, `[💰 Melhor Custo]`, `[🏆 Mais Experientes]`) diretamente nesta aba. Isso dará ao cliente controle sobre o tipo de recomendação que ele deseja ver, sem sair do fluxo principal.
    *   **Manter a Aba "Buscar":** A funcionalidade de busca manual por palavra-chave na aba "Buscar" **será mantida como está**, servindo como uma ferramenta para quando o cliente sabe exatamente o nome do advogado ou escritório que procura.

### 👥 Perfis: Advogado Contratante (`lawyer_individual`, `lawyer_office`, `lawyer_platform_associate`)

*   **Tela Alvo:** `LawyerSearchScreen` (Aba "Parceiros").
*   **Estado Atual:** Esta tela já possui um campo de texto principal ("Descreva sua necessidade...") que alimenta uma busca semântica via IA no backend.
*   **Estratégia de Integração (Fluxo Híbrido):**
    *   **Manter o Campo de Texto como Protagonista:** A busca por texto livre continua sendo o ponto de partida.
    *   **Adicionar "Ferramentas de Precisão":** Vamos introduzir as novas ferramentas como opcionais para aprimorar a busca:
        *   **Seletor de Foco:** `[Correspondente]`, `[Especialista]`, `[Parecerista]`.
        *   **Botão de Localização:** Para buscar correspondentes em um local específico, ignorando a localização do caso.
    *   O advogado pode usar apenas o texto (fluxo atual) ou combinar o texto com as novas ferramentas para uma busca muito mais precisa e intencional.

### ✍️ Perfil: Advogado Associado (`lawyer_associated`)

*   **Estratégia de Integração:** **Nenhuma alteração.** O fluxo de trabalho deste perfil é focado na gestão de casos e tarefas atribuídas e não é impactado por esta funcionalidade de busca avançada.

---

## ✅ LISTA DE TAREFAS FINAL E COMPLETA (Versão Conciliada)

Esta lista de tarefas é o roteiro definitivo, projetado para implementar a funcionalidade de busca avançada de forma segura e eficiente, respeitando a arquitetura e os fluxos de UI existentes.

### FASE 1: Backend - Habilitando a Flexibilidade (4 tarefas)

*   **(P1) `backend_add_presets`:** No arquivo `LITGO6/backend/algoritmo_match.py`, adicionar os novos presets `correspondent` e `expert_opinion` ao dicionário `PRESET_WEIGHTS`.
*   **(P1) `backend_add_boutique_field`:** Na dataclass `LawFirm` em `LITGO6/backend/algoritmo_match.py`, adicionar o campo `is_boutique: bool = False`.
*   **(P2) `backend_validate_presets`:** Executar um script para rodar a função `_validate_preset_weights()` e garantir que a soma dos pesos dos novos presets é 1.0. *(Depende de: `backend_add_presets`)*
*   **(P3) `backend_expand_endpoint`:** No arquivo `LITGO6/backend/api/main.py`, modificar o endpoint `/api/match` e o schema `MatchRequestSchema` para aceitar um campo opcional de coordenadas geográficas (`custom_coords`) e um raio (`radius_km`). *(Depende de: `backend_add_presets`)*

### FASE 2: Flutter - Desacoplando a Lógica de Busca (4 tarefas)

*   **(P4) `flutter_api_service`:** Em `api_service.dart`, modificar a função de match para aceitar o `preset` e as coordenadas customizadas dinamicamente. *(Depende de: `backend_expand_endpoint`)*
*   **(P5) `flutter_search_architecture`:** Criar a arquitetura de busca (`Models`, `Repository`, `UseCases`, `BLoC`) na pasta `features/search`. *(Depende de: `flutter_api_service`)*
*   **(P6) `flutter_register_deps`:** Registrar as novas dependências da arquitetura de busca no `injection_container.dart`. *(Depende de: `flutter_search_architecture`)*
*   **(P7) `flutter_refactor_lawyer_screen`:** Refatorar a `LawyerSearchScreen` (tela do advogado) para usar o novo `SearchBloc`. *(Depende de: `flutter_register_deps`)*

### FASE 3: Flutter - Aprimorando as Interfaces (4 tarefas)

*   **(P8) `flutter_integrate_lawyer_tools`:** Adicionar as ferramentas de precisão (seletor de foco, botão de localização) à UI da `LawyerSearchScreen`. *(Depende de: `flutter_refactor_lawyer_screen`)*
*   **(P9) `flutter_connect_lawyer_logic`:** Conectar a UI da `LawyerSearchScreen` à lógica do `SearchBloc`, passando os novos parâmetros (preset, coordenadas). *(Depende de: `flutter_integrate_lawyer_tools`)*
*   **(P10) `flutter_build_client_selector`:** Na `LawyersScreen` (tela do cliente), dentro da aba "Recomendações", construir o seletor de presets amigáveis. *(Depende de: `flutter_api_service`)*
*   **(P11) `flutter_connect_client_logic`:** Conectar o seletor de presets do cliente para que ele acione uma nova busca com o preset correto via `HybridMatchBloc`. *(Depende de: `flutter_build_client_selector`)*

### FASE 4: Testes e Documentação (2 tarefas)

*   **(P12) `testing`:** Criar/adaptar os testes de integração para os novos fluxos de busca em ambas as telas. *(Depende de: `flutter_connect_lawyer_logic`, `flutter_connect_client_logic`)*
*   **(P13) `documentation`:** Atualizar a documentação (`ATUALIZACAO_STATUS.md`) para refletir a conclusão do projeto. *(Depende de: `testing`)*

---

## 📊 BENEFÍCIOS ESPERADOS (VERSÃO CONCILIADA)

### 🎯 Para o Negócio
- **Adoção Acelerada:** Usuários aproveitam novas funcionalidades sem uma curva de aprendizado íngreme.
- **Expansão B2B Orgânica:** A busca por parceiros se torna mais poderosa e precisa, incentivando o uso.
- **Maior Satisfação do Cliente:** Clientes se sentem no controle das recomendações que recebem.

### ⚡ Para a Tecnologia
- **Desenvolvimento Evolutivo:** Aprimorar em vez de substituir é mais rápido, seguro e menos propenso a bugs.
- **Reutilização Máxima:** Aproveita a tela e a lógica de filtros existentes.
- **Manutenibilidade:** A lógica continua centralizada no `SearchBloc`.

### 👥 Para os Usuários
- **Simplicidade Mantida, Poder Adicionado:** O fluxo simples continua disponível, mas ferramentas avançadas estão a um clique de distância.
- **Flexibilidade Total:** Permite combinar busca por texto, por localização e por intenção na mesma tela.
- **Resultados Mais Precisos:** Fornecer mais contexto ao algoritmo leva a matches de maior qualidade.

---

## 🧪 ESTRATÉGIA DE TESTES

### Backend
```bash
# Validar presets
python3 LITGO6/backend/algoritmo_match.py

# Testar endpoint
curl -X POST http://localhost:8000/api/match \
  -H "Content-Type: application/json" \
  -d '{"case_id": "test", "preset": "correspondent", "custom_coords": [-23.5505, -46.6333], "radius_km": 15}'
```

### Frontend
```bash
# Testes unitários
flutter test

# Testes de integração
flutter test integration_test/
```

---

## 📈 MÉTRICAS DE SUCESSO

### KPIs Técnicos
- **Tempo de resposta:** < 2s para todas as buscas
- **Taxa de sucesso:** > 95% nas chamadas de API
- **Cobertura de testes:** > 80%

### KPIs de Negócio
- **Uso por preset:** Distribuição entre tipos de busca
- **Conversão B2B:** Taxa de contratação entre advogados
- **Retenção:** Uso repetido das funcionalidades avançadas

---

## 🎯 CRONOGRAMA

**Sprint 1 (1 semana):** Backend Core (P1-P3)
**Sprint 2 (2 semanas):** Flutter Core (P4-P6)
**Sprint 3 (2 semanas):** Flutter UI (P7-P10)
**Sprint 4 (1 semana):** Testes e Finalização (P11-P12)

**Total: 6 semanas**

---

**🎯 OBJETIVO FINAL:** Transformar o LITGO de um sistema de "uma marcha" para um sistema de "múltiplas marchas", onde cada tipo de usuário tem uma experiência otimizada para suas necessidades específicas, consolidando a plataforma como uma **rede de colaboração profissional B2B** e mantendo a robustez e qualidade do algoritmo existente. 