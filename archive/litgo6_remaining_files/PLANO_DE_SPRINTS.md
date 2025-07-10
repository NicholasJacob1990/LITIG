# Plano de Sprints de Desenvolvimento - Litgo

Este documento detalha o plano de ação para a implementação de novas funcionalidades no aplicativo, dividido em três Sprints de desenvolvimento. O objetivo é priorizar as entregas de maior valor para o negócio e para os usuários (clientes e advogados), incorporando as melhores práticas de arquitetura e usabilidade.

---

## 🏗️ Estrutura de Navegação Recomendada

### Para Clientes:
```
Tabs Bottom Navigation:
├── 🏠 Início
├── 📁 Meus Casos  
├── 👥 Advogados      # ← Tela principal com sub-abas
├── 💰 Financeiro     # ← NOVA
└── 👤 Perfil
```
*Dentro da tela "Advogados", teremos uma navegação secundária (sub-abas):*
-   ***Busca Geral:*** Para explorar livremente todos os advogados.
-   ***Recomendações:*** Para ver os matches específicos para seus casos.

### Para Advogados:
```
Tabs Bottom Navigation:
├── 🏠 Início
├── 📁 Meus Casos
├── 📋 Ofertas        # ← NOVA  
├── 👥 Clientes
└── 👤 Perfil
```

---

## 🚀 Sprint 1: Fundações do Negócio & Qualidade

**Objetivo:** Implementar os fluxos essenciais de monetização, aquisição de casos e feedback, estabelecendo a base para a operação sustentável e a qualidade da plataforma.

| Epic ID | Feature | Perfil Alvo | Prioridade |
| :--- | :--- | :--- | :--- |
| **FIN-01** | 💰 Central de Pagamentos | Cliente | **Crítica** |
| **ADV-01** |  lawyer: **Crítica** |
| **OFR-01** | 📋 Sistema de Ofertas | Advogado | **Crítica** |
| **REV-01** | ⭐ Sistema de Avaliações | Cliente | **Crítica** |

### Detalhamento das Tarefas

#### **1. Central de Pagamentos (Cliente)**
-   **Justificativa:** Funcionalidade *core* do negócio. Merece uma aba própria por ser crítica e frequentemente acessada pelo cliente para gestão financeira.
-   **Estrutura de Arquivos (Frontend):**
    ```
    app/(tabs)/
    ├── financeiro/
    │   ├── index.tsx           # Dashboard financeiro
    │   ├── faturas.tsx         # Lista de faturas
    │   ├── pagamentos.tsx      # Histórico de pagamentos
    │   ├── metodos.tsx         # Métodos de pagamento
    │   └── fatura/[id].tsx     # Detalhes da fatura
    └── _layout.tsx             # Adicionar rota 'financeiro'
    ```
-   **Backend:**
    -   **Banco de Dados:** Criar tabelas `invoices` (faturas), `transactions` (transações) e `payment_methods`.
    -   **API:** Criar endpoints para `GET /invoices`, `GET /invoices/[id]`, `POST /invoices/[id]/pay` e `GET /transactions`.
-   **Frontend:**
    -   **Navegação:** Adicionar nova aba "Financeiro" na navegação principal do cliente.
    -   **Telas:** Desenvolver as telas conforme a estrutura de arquivos acima.
    -   **Hooks:** Criar `useInvoices` e `useTransactions` para encapsular a lógica de busca de dados.

#### **2. Hub de Advogados & Recomendações (Cliente)**
-   **Justificativa:** Unifica a descoberta de advogados em um único ponto, separando a busca exploratória das recomendações diretas, o que torna a interface mais limpa e focada.
-   **Estrutura de Arquivos (Frontend):**
    ```
    app/(tabs)/
    └── advogados/
        ├── _layout.tsx         # Layout com as sub-abas
        ├── index.tsx           # Tela de Busca Geral
        └── recomendacoes.tsx   # Tela de Recomendações (Matches)
    ```
-   **Backend:**
    -   As APIs para busca (`/lawyers/search`) e matches (`/cases/[id]/matches`) já existem e serão consumidas por cada sub-aba respectivamente.
-   **Frontend:**
    -   **Navegação:** Implementar a aba "Advogados" na navegação principal.
    -   **Componentes:** Criar um componente de "Segmented Control" ou "Top Tab Navigator" para alternar entre "Busca Geral" e "Recomendações".
    -   **Telas:** Desenvolver o conteúdo de cada uma das duas sub-abas.

#### **3. Sistema de Ofertas (Advogado)**
-   **Justificativa:** Funcionalidade crítica para o *supply-side* (advogados). É o principal canal de aquisição de novos casos, merecendo destaque na navegação.
-   **Estrutura de Arquivos (Frontend):**
    ```
    app/(tabs)/
    ├── ofertas/
    │   ├── index.tsx           # Lista de ofertas pendentes
    │   ├── [id].tsx            # Detalhes da oferta
    │   └── historico.tsx       # Ofertas anteriores (aceitas/recusadas)
    └── _layout.tsx             # Adicionar rota 'ofertas'
    ```
-   **Backend:**
    -   **Banco de Dados:** Utilizar e garantir o status na tabela `offers`.
    -   **API:** Criar endpoints `GET /lawyer/offers`, `GET /offers/[id]` e `POST /offers/[id]/update-status`.
-   **Frontend:**
    -   **Navegação:** Adicionar nova aba "Ofertas" na navegação principal do advogado.
    -   **Telas:** Desenvolver as telas conforme a estrutura.
    -   **Componentes:** Criar um `OfferCard` reutilizável.

#### **4. Sistema de Avaliações (Cliente)**
-   **Justificativa:** Essencial para o *marketplace*, pois gera confiança e dados para o algoritmo de matching. O fluxo é mais natural quando contextualizado com o caso recém-concluído.
-   **Estrutura de Arquivos (Frontend):**
    ```
    app/
    ├── (tabs)/
    │   ├── cases/CaseDetail.tsx   # Adicionar botão 'Avaliar'
    │   └── profile/
    │       └── minhas-avaliacoes.tsx # Nova tela
    └── (modals)/
        └── avaliar-advogado.tsx    # Nova tela ou modal
    ```
-   **Backend:**
    -   **API:** Criar endpoints `POST /cases/[id]/review` e `GET /lawyers/[id]/reviews`.
-   **Frontend:**
    -   **Fluxo:** Adicionar botão "Avaliar Atendimento" em `CaseDetail.tsx` (visível para casos concluídos).
    -   **UI:** Criar modal ou tela `avaliar-advogado.tsx` para submissão.
    -   **Visualização:** Integrar nota e comentários no perfil do advogado e criar a tela "Minhas Avaliações" no perfil do cliente.

### Critérios de Aceitação do Sprint 1
-   [ ] Clientes conseguem visualizar seu histórico financeiro e simular pagamentos.
-   [ ] A nova aba "Advogados" está funcional, permitindo alternar entre a busca geral e as recomendações de matches.
-   [ ] Advogados recebem ofertas de casos na nova aba e podem interagir com elas.
-   [ ] Clientes podem avaliar advogados em casos concluídos.
-   [ ] As novas abas de navegação estão funcionais e visíveis para os perfis corretos.

---

## 🚀 Sprint 2: Experiência e Transparência do Cliente

**Objetivo:** Melhorar a clareza, a confiança e o engajamento do cliente, fornecendo visibilidade sobre o andamento dos processos e a gestão dos acordos.

| Epic ID | Feature | Perfil Alvo | Prioridade |
| :--- | :--- | :--- | :--- |
| **TLN-01** | 📈 Timeline do Processo | Cliente | **Importante** |
| **CTR-01** | 📄 Gestão de Contratos | Cliente | **Importante** |

### Detalhamento das Tarefas

#### **1. Timeline do Processo (Cliente)**
-   **Justificativa:** Aumenta a transparência e reduz a ansiedade do cliente. Sendo uma informação contextual ao caso, deve estar diretamente acessível a partir de seus detalhes.
-   **Estrutura de Arquivos (Frontend):**
    ```
    app/(tabs)/cases/
    ├── CaseDetail.tsx      # Adicionar nova aba ou seção "Andamentos"
    └── (components)/
        └── CaseTimeline.tsx    # Novo componente para a timeline
    ```
-   **Backend:**
    -   **Banco de Dados:** Criar tabela `case_events` para registrar marcos importantes.
    -   **API:** Criar endpoint `GET /cases/[id]/timeline`.
-   **Frontend:**
    -   **Componentes:** Desenvolver um componente `CaseTimeline.tsx` para renderizar a linha do tempo.
    -   **Integração:** Adicionar nova seção "Andamentos" na tela `CaseDetail.tsx`.

#### **2. Gestão Completa de Contratos (Cliente)**
-   **Justificativa:** Centraliza um documento legal importante. Aproveitar a estrutura de rotas existente para contratos (`/contracts/[id]`) e expandi-la é a abordagem mais consistente.
-   **Estrutura de Arquivos (Frontend):**
    ```
    app/(tabs)/
    └── contract/
        ├── index.tsx           # (NOVO) Lista de todos os contratos
        ├── [id].tsx            # Detalhes (já existe)
        └── assinatura/[id].tsx # (NOVO) Fluxo de assinatura
    ```
-   **Backend:**
    -   **API:** Criar endpoints `GET /contracts` e `POST /contracts/[id]/request-signature`.
-   **Frontend:**
    -   **Telas:** Criar a tela de listagem `index.tsx` e a tela de assinatura.
    -   **Hooks:** Desenvolver `useContracts` para gerenciar o estado dos contratos.

### Critérios de Aceitação do Sprint 2
-   [ ] O cliente pode visualizar uma linha do tempo com os principais eventos do seu caso.
-   [ ] O cliente pode acessar uma tela que lista todos os seus contratos.
-   [ ] O cliente pode iniciar e concluir um fluxo de assinatura de contrato.

---

## 🚀 Sprint 3: Ferramentas Avançadas para Advogados

**Objetivo:** Empoderar os advogados com dados para análise de performance e ferramentas para gerenciar sua participação na plataforma de forma eficaz.

| Epic ID | Feature | Perfil Alvo | Prioridade |
| :--- | :--- | :--- | :--- |
| **PRF-01** | 📊 Métricas Financeiras | Advogado | Melhoria |
| **AVL-01** | 🔔 Gestão de Disponibilidade | Advogado | Melhoria |

### Detalhamento das Tarefas

#### **1. Métricas Financeiras Avançadas (Advogado)**
-   **Justificativa:** Oferece valor agregado ao advogado, ajudando-o a entender sua performance. Faz sentido expandir a tela de performance já existente para manter as análises centralizadas.
-   **Backend:**
    -   **API:** Criar endpoint `GET /lawyer/me/financials` que retorna dados estruturados.
-   **Frontend:**
    -   **Telas:** Redesenhar a tela `app/(tabs)/profile/performance.tsx` para usar abas.
    -   **Componentes:** Integrar biblioteca de gráficos para exibir as tendências.

#### **2. Gestão de Disponibilidade (Advogado)**
-   **Justificativa:** Funcionalidade essencial para a saúde do marketplace, garantindo que o matching só ofereça advogados que podem de fato aceitar o caso.
-   **Backend:**
    -   **Banco de Dados:** Adicionar colunas `is_available` e `availability_reason` na tabela `lawyers`.
    -   **Serviços:** Modificar `match_service` para filtrar advogados indisponíveis.
    -   **API:** Criar endpoint `PATCH /lawyer/me/availability`.
-   **Frontend:**
    -   **Telas:** Criar nova tela `app/(tabs)/profile/availability-settings.tsx`.
    -   **Componentes:** Adicionar um `Switch` para o advogado controlar sua disponibilidade.

### Critérios de Aceitação do Sprint 3
-   [ ] O advogado pode acessar um dashboard financeiro com gráficos sobre sua performance.
-   [ ] O advogado pode se marcar como "indisponível" e, como resultado, deixa de receber novas ofertas de casos.

---

## 💡 Dicas Gerais de Implementação

-   **Aproveitar Componentes Existentes:** Reutilizar `CaseCard`, `Badge`, `Avatar`, etc., para manter a consistência visual.
-   **Navegação Contextual:** Usar modais para ações rápidas (ex: avaliar, pagar) e telas completas para tarefas de gestão (ex: contratos, ofertas).
-   **Notificações Integradas:** Planejar o envio de notificações push para alertar sobre eventos importantes (faturas, novas ofertas, lembretes de avaliação).
-   **Gerenciamento de Estado:** Manter o padrão de `ActivityIndicator` para loading e `RefreshControl` para atualização de listas. 