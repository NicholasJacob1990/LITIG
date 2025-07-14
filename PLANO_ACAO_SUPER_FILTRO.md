# 🎯 PLANO DE AÇÃO: Implementação do Super-Filtro (Busca por Diretório)

---

## 1. Visão Geral e Objetivo Estratégico

Este documento detalha o plano de ação para a implementação de uma nova e poderosa funcionalidade de **busca por diretório**, que complementará o sistema de matchmaking por IA existente.

O objetivo estratégico é dar a todos os perfis de usuário (clientes e advogados) a capacidade de consultar diretamente toda a base de dados de profissionais através de um conjunto completo e granular de filtros, incluindo critérios inexistentes hoje como **faixa de preço** e **ordenação por relevância**.

Esta funcionalidade evolui a plataforma de um sistema puramente de "matchmaking" para um ecossistema de busca híbrido, que combina a inteligência da busca semântica com o poder e o controle da consulta direta a um diretório.

---

## 2. Estratégia de Integração e Experiência do Usuário (UX)

A funcionalidade será integrada de forma a aprimorar, e não fragmentar, a experiência do usuário.

*   **Não haverá novas telas de busca.** A funcionalidade será incorporada nas telas de busca existentes.
*   **Para Advogados (`LawyerSearchScreen`):** A tela ganhará um seletor de modo, permitindo ao usuário alternar entre:
    *   **`Busca por IA` (Padrão):** O fluxo atual, baseado em contexto, com presets e filtros pós-match.
    *   **`Busca por Filtros` (Novo):** Um modo que revelará a nova interface do "Super-Filtro" para consulta direta ao diretório.
*   **Para Clientes (`LawyersScreen`):** A separação será por abas.
    *   **Aba `Recomendações`:** Manterá o fluxo de matchmaking por IA, com os presets amigáveis e filtros pós-match.
    *   **Aba `Buscar`:** Será transformada para abrigar a nova interface do "Super-Filtro", permitindo ao cliente consultar todo o diretório com critérios exatos.

---

## 3. Plano de Implementação Faseado

O projeto será dividido em 5 fases lógicas para garantir uma implementação incremental, testável e segura.

### FASE 1: Backend - A Fundação dos Dados
*(Foco: Modificar o banco de dados e as entidades para suportar os novos filtros)*

*   **(SF-P1) `db_add_price_fields`:**
    *   **Ação:** Alterar o schema do banco de dados. Adicionar as colunas `price_range` (Enum: 'economic', 'standard', 'premium') e `average_hourly_rate` (Numeric, opcional) às tabelas `lawyers` e `law_firms`.
    *   **Dependências:** Nenhuma.

*   **(SF-P2) `profile_data_capture`:**
    *   **Ação:** No frontend, modificar as telas de "Editar Perfil" do advogado e do escritório para permitir que eles insiram e atualizem suas informações de `price_range` e `average_hourly_rate`.
    *   **Dependências:** `db_add_price_fields`.

*   **(SF-P3) `db_add_relevance_score`:**
    *   **Ação:** Definir uma fórmula para um score de "relevância geral", adicionar a coluna `relevance_score` às tabelas, criar um script de backfill para popular os dados existentes e integrar o cálculo na lógica de atualização de perfil.
    *   **Dependências:** Nenhuma.

*   **(SF-P4) `db_indexing`:**
    *   **Ação:** Analisar as futuras consultas e adicionar índices de banco de dados nas novas colunas (`price_range`, `relevance_score`) e em outras colunas que serão frequentemente filtradas (ex: `specialty`, `rating`).
    *   **Dependências:** `db_add_price_fields`, `db_add_relevance_score`.

### FASE 2: Backend - A Construção da API
*(Foco: Criar o serviço e o endpoint que servirão a busca)*

*   **(SF-P5) `backend_create_search_service`:**
    *   **Ação:** Criar um novo serviço, `DirectorySearchService`, em `backend/services/`, que conterá a lógica para construir e executar consultas de busca dinâmica no banco de dados.
    *   **Dependências:** `db_add_price_fields`.

*   **(SF-P6) `backend_build_search_endpoint`:**
    *   **Ação:** Criar um novo endpoint `GET /api/search/directory` que aceite múltiplos query parameters (`query`, `type`, `specialty`, `min_rating`, `max_distance`, `price_range`, `is_available`, `sort_by`).
    *   **Dependências:** `backend_create_search_service`.

*   **(SF-P7) `backend_implement_query_logic`:**
    *   **Ação:** Implementar a lógica no `DirectorySearchService` que recebe os parâmetros do endpoint e constrói a consulta SQL (ou via ORM) dinamicamente, aplicando os `WHERE` e `ORDER BY` correspondentes.
    *   **Dependências:** `backend_build_search_endpoint`.

### FASE 3: Frontend - A Interface do Super-Filtro
*(Foco: Construir os componentes visuais da nova funcionalidade)*

*   **(SF-P8) `flutter_build_super_filter_ui`:**
    *   **Ação:** Criar um novo widget reutilizável, `SuperFilterPanel`, que contém todos os novos controles de filtro: seletor de faixa de preço, dropdown de ordenação, etc., além dos filtros existentes.
    *   **Dependências:** Nenhuma.

*   **(SF-P9) `flutter_integrate_lawyer_mode_selector`:**
    *   **Ação:** Na `LawyerSearchScreen`, implementar o `SegmentedButton` para alternar entre os modos "Busca por IA" e "Busca por Filtros", alternando a visibilidade da UI correspondente.
    *   **Dependências:** `flutter_build_super_filter_ui`.

*   **(SF-P10) `flutter_evolve_client_search_tab`:**
    *   **Ação:** Na `LawyersScreen`, substituir o conteúdo atual da aba "Buscar" pelo novo widget `SuperFilterPanel`.
    *   **Dependências:** `flutter_build_super_filter_ui`.

### FASE 4: Frontend - Conectando a Lógica
*(Foco: Fazer a nova UI funcionar, conectando-a à nova API)*

*   **(SF-P11) `flutter_update_api_service`:**
    *   **Ação:** Adicionar uma nova função `searchDirectory(...)` ao `api_service.dart`, que fará a chamada ao novo endpoint `GET /api/search/directory`, passando todos os parâmetros de filtro.
    *   **Dependências:** `backend_implement_query_logic`.

*   **(SF-P12) `flutter_update_bloc`:**
    *   **Ação:** Modificar os BLoCs existentes (ou criar um novo, `DirectorySearchBloc`) para gerenciar o estado do `SuperFilterPanel`, com novos eventos (`ApplySuperFilters`) e estados (`DirectorySearchLoading`, `DirectorySearchLoaded`).
    *   **Dependências:** `flutter_update_api_service`.

*   **(SF-P13) `flutter_connect_ui_to_logic`:**
    *   **Ação:** Conectar as ações do usuário no `SuperFilterPanel` para que disparem os eventos corretos no BLoC e renderizem a lista de resultados com base no estado retornado.
    *   **Dependências:** `flutter_update_bloc`.

### FASE 5: Finalização e Rollout
*(Foco: Garantir a qualidade e fazer o lançamento de forma segura)*

*   **(SF-P14) `testing_e2e`:**
    *   **Ação:** Criar testes de integração (end-to-end) que validem todos os cenários do Super-Filtro para clientes e advogados, testando cada combinação de filtro.
    *   **Dependências:** `flutter_connect_ui_to_logic`.

*   **(SF-P15) `implement_feature_flag`:**
    *   **Ação:** Envolver toda a nova funcionalidade (backend e frontend) em um feature flag (ex: `super_filter_enabled`) para permitir um lançamento controlado e seguro.
    *   **Dependências:** `testing_e2e`.

*   **(SF-P16) `documentation_final`:**
    *   **Ação:** Atualizar toda a documentação do projeto (API, arquitetura, manuais de usuário) para refletir a adição da nova funcionalidade de busca por diretório.
    *   **Dependências:** `implement_feature_flag`.

--- 