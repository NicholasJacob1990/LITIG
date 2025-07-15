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

## 🎯 ESTRATÉGIA DE INTEGRAÇÃO CONCILIADA (VERSÃO FINAL)

Após uma análise profunda da UI e das funcionalidades existentes, a estratégia de integração foi **aprimorada** para ser mais eficiente e menos disruptiva para o usuário. Em vez de criar telas novas, vamos **evoluir as telas existentes**, conciliando as funcionalidades atuais com as novas capacidades de busca avançada.

### 🔄 Fluxo Híbrido: O Melhor de Dois Mundos

A nova abordagem mantém os fluxos atuais como base e adiciona as ferramentas de precisão como "superpoderes" opcionais, criando uma experiência mais rica e flexível.

#### 1. Para Advogados (Aba "Parceiros" - `LawyerSearchScreen`)
- **O que é Mantido:** A busca principal por meio de um campo de texto, onde o advogado descreve sua necessidade e a IA faz a triagem. O sistema de filtros manuais (pós-busca) também é 100% preservado.
- **O que é Adicionado (Aprimoramento):**
  - **📍 Ferramenta de Localização:** Um botão opcional `Adicionar Localização` que abre um mapa (`LocationPicker`). Se um local for selecionado, a busca usará o preset `'correspondent'` automaticamente.
  - **⚙️ Seletor de Foco:** Um dropdown opcional para forçar um `preset` específico (`expert`, `expert_opinion`), dando ao usuário controle total sobre a intenção da busca.
- **Resultado:** Uma única tela que permite desde uma busca rápida por texto até uma busca multi-condicional (texto + localização + foco), com o refinamento manual dos filtros no final.

#### 2. Para Clientes (Aba "Advogados" - `LawyersScreen`)
- **O que é Mantido:** A busca manual por texto/filtro direto continua funcionando de forma independente.
- **O que é Adicionado (Aprimoramento):**
  - **⭐ Seletor de Estilo de Busca:** Abaixo da busca manual, um seletor de "estilo" será adicionado para guiar o algoritmo de match. As opções serão amigáveis:
    - `[Recomendado]` (preset: `balanced`)
    - `[Melhor Custo]` (preset: `economic`)
    - `[Mais Experientes]` (preset: `expert`)
- **Resultado:** O cliente ganha controle sobre o tipo de recomendação que deseja receber, podendo alternar entre diferentes perfis de advogados com um único toque.

---

### 🧭 Arquitetura de Navegação e Perfis

A navegação e a interação dos diferentes perfis de usuário com o sistema de busca avançada estão detalhadas no documento central de arquitetura do sistema.

**[➡️ Consulte aqui a Arquitetura Geral do Sistema para detalhes sobre Perfis e Navegação](ARQUITETURA_GERAL_DO_SISTEMA.md)**

---

## 🚀 LISTA DE TAREFAS ATUALIZADA (PÓS-ANÁLISE)

Esta lista de tarefas foi **adaptada** para refletir a estratégia de aprimoramento das telas existentes.

### 📋 FASE 1: Backend - Habilitando a Flexibilidade (Inalterado)

**P1. backend_add_presets**
- **Arquivos:** `LITGO6/backend/algoritmo_match.py`, `LITGO6/backend/api/schemas.py`
- **Ação:** Adicionar presets 'correspondent' e 'expert_opinion' aos `PRESET_WEIGHTS` e ao enum `PresetPesos`.
- **Dependências:** Nenhuma

**P1. backend_add_boutique_field**
- **Arquivo:** `LITGO6/backend/algoritmo_match.py`
- **Ação:** Adicionar `is_boutique: bool = False` à dataclass `LawFirm`.
- **Dependências:** Nenhuma

**P2. backend_validate_new_presets**
- **Ação:** Executar `_validate_preset_weights()` para validar a soma dos pesos dos novos presets.
- **Dependências:** `backend_add_presets`

**P3. backend_expand_match_endpoint**
- **Arquivo:** `LITGO6/backend/api/main.py`
- **Ação:** Modificar o schema `MatchRequestSchema` para aceitar `custom_coords` e `radius_km`. O `match_service` deverá ser atualizado para usar essas coordenadas quando presentes.
- **Dependências:** `backend_add_presets`

### 📱 FASE 2: Flutter - Desacoplando a Lógica de Busca (Inalterado)

**P4. flutter_api_service_dynamic_preset**
- **Arquivo:** `apps/app_flutter/lib/src/core/services/api_service.dart` (ou serviço relevante)
- **Ação:** Modificar a função de match para aceitar `preset`, `customCoords` e `radiusKm` dinamicamente.
- **Dependências:** `backend_expand_match_endpoint`

**P5. flutter_create_search_architecture**
- **Ação:** Implementar a arquitetura de busca com Models, Repository, UseCases e BLoC para encapsular toda a lógica da busca avançada.
- **Dependências:** `flutter_api_service_dynamic_preset`

**P6. flutter_register_dependencies**
- **Ação:** Registrar todas as novas classes (Repository, UseCases, BLoC) no `injection_container.dart`.
- **Dependências:** `flutter_create_search_architecture`

### 🎨 FASE 3: Flutter - Aprimorando as Interfaces Existentes (Adaptado)

**P7. flutter_refactor_lawyer_search_screen**
- **Arquivo:** `.../lawyer_search_screen.dart`
- **Ação:** Refatorar a tela para usar o novo `SearchBloc` como fonte de estado, desacoplando a UI da lógica de chamada direta ao serviço.
- **Dependências:** `flutter_register_dependencies`

**P8. flutter_integrate_lawyer_tools**
- **Arquivo:** `.../lawyer_search_screen.dart`
- **Ação:** Adicionar os novos widgets de ferramentas de precisão: o botão `Adicionar Localização` (que abre um mapa) e o `Dropdown` de Foco da Busca.
- **Dependências:** `flutter_refactor_lawyer_search_screen`

**P9. flutter_connect_lawyer_search_logic**
- **Arquivo:** `.../lawyer_search_screen.dart`
- **Ação:** Conectar os inputs (texto, localização, foco) para que o botão "Buscar" dispare o evento correto do `SearchBloc` com todos os dados.
- **Dependências:** `flutter_integrate_lawyer_tools`

**P10. flutter_build_client_preset_selector**
- **Arquivo:** `.../lawyers_screen.dart`
- **Ação:** Construir e integrar o widget `PresetSelector` com opções amigáveis ("Recomendado", "Melhor Custo", etc.).
- **Dependências:** `flutter_api_service_dynamic_preset`

**P11. flutter_connect_client_search_logic**
- **Arquivo:** `.../lawyers_screen.dart`
- **Ação:** Conectar o `PresetSelector` para que ele dispare uma nova busca via `SearchBloc` (ou um BLoC similar) com o `preset` escolhido pelo cliente.
- **Dependências:** `flutter_build_client_preset_selector`

### 🧪 FASE 4: Finalização (Adaptado)

**P12. testing_end_to_end**
- **Ação:** Criar e/ou adaptar testes de integração para validar os novos fluxos de busca do advogado e do cliente.
- **Dependências:** `flutter_connect_lawyer_search_logic`, `flutter_connect_client_search_logic`

**P13. documentation_update**
- **Ação:** Atualizar este documento (`PLANO_SISTEMA_BUSCA_AVANCADA.md`) e o `status.md` para refletir as implementações concluídas.
- **Dependências:** `testing_end_to_end`

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

### 🚪 Ponto de Entrada do Cliente: A Aba "Advogados"

Para garantir que o cliente tenha um acesso claro e intuitivo ao sistema de busca, a navegação principal manterá a aba **"Advogados"**, em vez de uma aba genérica "Buscar". Esta decisão, embora pareça simples, é fundamental para a experiência do usuário e se alinha com a estratégia de aprimoramento.

#### Justificativa da Nomenclatura
- **Clareza de Propósito:** O termo "Advogados" é mais específico e direto sobre o que o cliente encontrará.
- **Consistência e Intuitividade:** Respeita a implementação atual e o modelo mental do usuário, que busca por profissionais, não por uma "ferramenta de busca".
- **Diferenciação de Contexto:** Evita confusão com outras funcionalidades de busca (casos, documentos, etc.) que podem ser implementadas no futuro.

#### Fluxo de Usuário e Integração
A aba "Advogados" não é apenas um link, mas sim o **início do funil do sistema de busca avançada** para o cliente.

1.  **Ponto de Partida:** O cliente clica na aba "Advogados" no menu principal.
2.  **Tela de Ação:** É direcionado para a `LawyersScreen`, que já integra a interface do sistema de busca (campo de texto, filtros e o seletor de estilo de busca).
3.  **Engajamento:** O cliente interage com os componentes da busca para encontrar os profissionais mais adequados.

```
Cliente → Menu Principal → Aba "Advogados" → LawyersScreen → [Busca/Filtros] → Resultados
```

#### Estrutura do Menu do Cliente
A estrutura de navegação que suporta este fluxo é a seguinte:

```dart
// Implementação em main_tabs_shell.dart
case 'client':
  return [
    NavigationItem(label: 'Início', icon: Icons.home, branchIndex: 0),
    NavigationItem(label: 'Advogados', icon: Icons.people, branchIndex: 1), // Ponto de entrada para a busca
    NavigationItem(label: 'Meus Casos', icon: Icons.folder, branchIndex: 2),
    NavigationItem(label: 'Mensagens', icon: Icons.message, branchIndex: 3),
    NavigationItem(label: 'Perfil', icon: Icons.person, branchIndex: 4),
  ];
```
Esta abordagem garante que o sistema de busca avançada, poderoso e complexo em sua lógica interna, seja apresentado ao cliente da forma mais simples e direta possível.

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