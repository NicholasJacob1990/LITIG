# Análise da Arquitetura de Navegação - App Flutter

**Data:** $(date)
**Autor:** Sistema de Análise de Código IA
**Status:** Concluído

## 1. Objetivo da Análise

Esta análise foi conduzida para investigar e documentar a estrutura de navegação principal do aplicativo Flutter, com foco em entender como diferentes perfis de usuário (Cliente, Advogado Associado, Advogado Contratante) interagem com a interface e se um usuário pode atuar em múltiplos contextos (ex: um advogado criando um caso como cliente).

## 2. Resumo das Descobertas

A investigação confirmou que o aplicativo possui uma **arquitetura de navegação robusta e dinâmica**, baseada na biblioteca `go_router`. A interface principal se adapta ao perfil do usuário logado, apresentando menus e funcionalidades distintas para cada um.

- **✅ Navegação por "Casca" (Shell):** O app utiliza uma `StatefulShellRoute` para prover uma barra de navegação inferior (`BottomNavigationBar`) persistente.
- **✅ Menus Dinâmicos por Perfil:** Existem **três layouts de navegação distintos**, um para cada perfil principal de usuário. A lógica de qual menu exibir é centralizada no widget `MainTabsShell`.
- **✅ Contexto Duplo Confirmado:** A arquitetura permite que usuários do tipo "Advogado Contratante" iniciem um fluxo de criação de caso (atuando como clientes) diretamente de sua tela inicial. A mesma capacidade, embora intencionada para o "Advogado Associado", está com a implementação da UI incompleta.

## 3. Arquitetura Técnica Detalhada

A navegação é orquestrada por três arquivos principais:

1.  **`lib/main.dart`**: Ponto de entrada da aplicação, onde o `GoRouter` é inicializado.
2.  **`lib/src/router/app_router.dart`**: Arquivo central de configuração do `GoRouter`. Define todas as rotas da aplicação e a estrutura da `StatefulShellRoute` com seus três conjuntos de "branches" (abas).
3.  **`lib/src/shared/widgets/organisms/main_tabs_shell.dart`**: O widget que constrói a UI da "casca". Ele lê o `userRole` do `AuthBloc` e renderiza a `BottomNavigationBar` correta com base no perfil do usuário.

## 4. Estrutura de Navegação por Perfil de Usuário

A análise do `main_tabs_shell.dart` confirmou os seguintes menus de navegação:

---

### 👤 **Perfil: Cliente (Padrão)**
Usuário final que busca serviços jurídicos.

| Ícone | Rótulo | Rota de Destino | Tela |
| :--- | :--- | :--- | :--- |
| 🏠 | Início | `/client-home` | `HomeScreen` |
| 📋 | Meus Casos | `/client-cases`| `CasesScreen` |
| 🔍 | Advogados | `/find-lawyers`| `LawyersScreen` |
| 💬 | Mensagens | `/client-messages`|`MessagesScreen`|
| 🧩 | Serviços | `/services` | `ServicesScreen` |
| 👤 | Perfil | `/client-profile`| `ProfileScreen` |

**Fluxo Principal:** A aba "Início" leva à `HomeScreen`, que é um portal para iniciar uma nova consulta jurídica via `/triage`.

---

### 👨‍⚖️ **Perfil: Advogado Associado** (`lawyer_associated`)
Advogado que recebe e trabalha nos casos.

| Ícone | Rótulo | Rota de Destino | Tela |
| :--- | :--- | :--- | :--- |
| 📊 | Painel | `/dashboard` | `DashboardScreen` |
| 📂 | Casos | `/cases` | `CasesScreen` |
| 📅 | Agenda | `/agenda` | `AgendaScreen` |
| 📥 | Ofertas | `/offers` | `OffersScreen` |
| 💬 | Mensagens | `/messages` | `MessagesScreen` |
| 👤 | Perfil | `/profile` | `ProfileScreen` |

**Fluxo Principal:** Focado na gestão de sua carga de trabalho. A tela "Casos" (`CasesScreen`) atualmente **não possui** um `FloatingActionButton` para criar novos casos, representando uma implementação incompleta da funcionalidade de contexto duplo para este perfil.

---

### ⚖️ **Perfil: Advogado Contratante**
Engloba `lawyer_individual`, `lawyer_office`, e `lawyer_platform_associate`. Advogado ou escritório que cria e distribui casos.

| Ícone | Rótulo | Rota de Destino | Tela |
| :--- | :--- | :--- | :--- |
| 🏠 | Início | `/home` | `HomeScreen` |
| 📥 | Ofertas | `/contractor-offers`| `CaseOffersScreen`|
| 🔍 | Parceiros | `/partners` | `LawyerSearchScreen`|
| 👥 | Parcerias | `/partnerships` | `PartnershipsScreen`|
| 💬 | Mensagens | `/contractor-messages`|`MessagesScreen`|
| 👤 | Perfil | `/contractor-profile`|`ProfileScreen`|

**Fluxo Principal (Contexto Duplo):** A aba "Início" deste perfil leva à **mesma `HomeScreen` do cliente**, permitindo que este tipo de usuário inicie uma nova consulta e crie um caso diretamente, confirmando a capacidade do sistema de lidar com múltiplos contextos para um mesmo usuário. 