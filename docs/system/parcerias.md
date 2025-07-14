

* O **contrato com advogado associado** é firmado no **ato do cadastro** (vínculo direto com o escritório).
* As demais **parcerias** (entre advogados/autônomos/escritórios) terão **contratos gerados após o match**, como parte do processo de parceria.

---

# ✅ PLANO DE AÇÃO REVISADO — FUNCIONALIDADE DE PARCERIAS NA ADVOCACIA

> Parte 1: Registro por perfil, com contratos vinculados apenas para advogado associado.
> As demais relações contratuais surgem **posteriormente**, a partir das **parcerias firmadas dentro do app**.

---

## 🧩 PARTE 1 — REGISTRO E ESTRUTURA DE PERFIS COM BASE CONTRATUAL

---

## 🔐 1. TELA DE LOGIN

### Ao final da tela, exibir:

```plaintext
É advogado? Cadastre-se como:
[ Autônomo ]   [ Associado ]   [ Escritório ]
```

---

## 📝 2. FLUXO DE CADASTRO POR PERFIL

### 🔹 2.1 ADVOGADO AUTÔNOMO

| Campo                 | Obrigatório |
| --------------------- | ----------- |
| Nome completo         | ✅           |
| E-mail / senha        | ✅           |
| CPF                   | ✅           |
| Nº OAB                | ✅           |
| Áreas de atuação      | ✅           |
| Endereço profissional | ✅           |
| Termo de uso e LGPD   | ✅           |

📄 **Contrato de parceria NÃO é exibido agora.**

> `user_type = 'lawyer_individual'`

---

### 🔹 2.2 ADVOGADO ASSOCIADO

| Campo                                                         | Obrigatório     |
| ------------------------------------------------------------- | --------------- |
| Nome completo                                                 | ✅               |
| E-mail / senha                                                | ✅               |
| Nº OAB                                                        | ✅               |
| Áreas de atuação                                              | ✅               |
| Experiência / Bio                                             | ✅               |
| Escritório ao qual se associa (pré-selecionado ou com código) | ✅               |
| Termo de uso e LGPD                                           | ✅               |
| ✅ **Aceite do contrato de associação**                        | **OBRIGATÓRIO** |

📄 **Contrato de associação firmado neste ato.**

* Exibido e aceito digitalmente
* Gravado com versão e data

> `user_type = 'lawyer_associated'`
> Vinculado a um `lawyer_office_id` no banco

---

### 🔹 2.3 ESCRITÓRIO DE ADVOCACIA

| Campo                    | Obrigatório |
| ------------------------ | ----------- |
| Nome fantasia            | ✅           |
| CNPJ                     | ✅           |
| Responsável (nome + OAB) | ✅           |
| E-mail / senha           | ✅           |
| Endereço                 | ✅           |
| Áreas de atuação         | ✅           |
| Termo de uso e LGPD      | ✅           |

📄 **Contrato de parceria será gerado apenas após match/parceria**.

> `user_type = 'lawyer_office'`

---

## 🧠 3. BACKEND – MODELAGEM DE DADOS

### 🔸 Tabela `users`

| Campo       | Tipo                                                                              |
| ----------- | --------------------------------------------------------------------------------- |
| id          | UUID                                                                              |
| email       | TEXT                                                                              |
| password    | TEXT                                                                              |
| user\_type  | ENUM: `'client'`, `'lawyer_individual'`, `'lawyer_associated'`, `'lawyer_office'` |
| created\_at | TIMESTAMP                                                                         |

---

### 🔸 Tabela `lawyer_profiles`

| Campo                  | Tipo                                              |
| ---------------------- | ------------------------------------------------- |
| user\_id (FK)          | UUID                                              |
| oab\_number            | TEXT                                              |
| cpf                    | TEXT (individual only)                            |
| cnpj                   | TEXT (office only)                                |
| is\_office             | BOOLEAN                                           |
| is\_associated         | BOOLEAN                                           |
| expertise              | TEXT\[]                                           |
| office\_id (FK)        | UUID (referência ao escritório, se for associado) |
| accepted\_contract\_at | TIMESTAMP (somente associado)                     |
| contract\_url          | TEXT (somente associado)                          |

---

📌 **Todos os outros tipos (autônomo e escritório)** receberão contratos posteriormente, durante o fluxo de parceria (a ser tratado na Parte 2).

---

Se desejar, posso agora:

* Gerar o código completo do formulário Flutter para cada tipo de advogado;
* Criar os campos dinâmicos para contrato apenas no fluxo de associado;
* Fornecer o endpoint de aceite do contrato digital com versão controlada.

Deseja que eu siga para a Parte 2 (match e parceria entre advogados/escritórios)?

**PARTE 2** do plano de ação, focando no coração da funcionalidade: **match inteligente e formalização da parceria entre advogados (ou escritórios)**. Este fluxo é posterior ao cadastro e contempla:

* Busca ativa ou triagem por IA
* Proposta de parceria
* Aceite e início da colaboração
* Geração e aceite do contrato jurídico
* Acompanhamento da execução

---

# ✅ PARTE 2 – FLUXO DE PARCERIA ENTRE ADVOGADOS E ESCRITÓRIOS

---

## 🎯 OBJETIVO

Permitir que **qualquer advogado (autônomo, associado ou escritório)** contrate **outro advogado ou escritório**, para atuar em um caso específico ou colaboração recorrente, com contrato digital e gestão integrada via app.

---

## 🔄 1. FORMAS DE ENCONTRAR PARCEIROS

### 🔹 A) Match por Triagem Inteligente

* Usuário descreve o caso (área, urgência, tipo de atuação)
* O sistema consulta o algoritmo de match (IA semântica ou filtro estruturado)
* Retorna lista de advogados/escritórios compatíveis

> Ex: “Preciso de apoio em Direito Ambiental com urgência no Pará”
> → Match com 5 profissionais aptos e disponíveis

---

### 🔹 B) Busca Manual

* Navegação por filtros: área, localização, disponibilidade, preço médio
* Pode ser feita por qualquer tipo de advogado ou escritório
* Resultados mostram tipo do parceiro (autônomo, escritório)

---

## 📝 2. PROPOSTA DE PARCERIA (ENVIO DE OFERTA)

### ⚙️ Tela: `/propose-partnership`

**Campos**:

* Profissional destino (ID)
* Caso vinculado (se houver)
* Tipo de colaboração:

  * `consultoria`, `redação técnica`, `audiência`, `suporte total`, `parceria recorrente`
* Honorários sugeridos (ou marcar “a combinar”)
* Mensagem opcional

➡️ **Gatilho: POST /api/partnerships**

---

## 📥 3. ACEITE DA PARCERIA

### Tela: `/partnerships`

* Lista de **propostas recebidas** e **propostas enviadas**
* Ações:

  * ✅ Aceitar
  * ❌ Recusar
  * 🔍 Ver detalhes e histórico do contratante

➡️ **PATCH /api/partnerships/\:id/accept**
➡️ **PATCH /api/partnerships/\:id/reject**

---

## 📄 4. GERAÇÃO DO CONTRATO (após aceite)

### Automatizado:

* Modelo jurídico baseado no tipo de parceria
* Cláusulas:

  * Descrição do serviço
  * Valor e forma de pagamento
  * Responsabilidade profissional
  * Sigilo e confidencialidade
  * Condições de rescisão
  * Divisão de honorários (se aplicável)

### Exibição:

* Tela: `/partnerships/:id/contract`
* Botão: `Aceitar e Assinar Digitalmente`

➡️ `POST /api/partnerships/:id/accept-contract`

---

## 📂 5. STATUS DA PARCERIA

Cada parceria terá os seguintes **status de progresso**:

| Status              | Condição                       |
| ------------------- | ------------------------------ |
| `pendente`          | proposta enviada, aguardando   |
| `aceita`            | aceite formal da proposta      |
| `contrato_pendente` | aguardando aceite do contrato  |
| `ativa`             | contrato aceito e em andamento |
| `finalizada`        | encerrada pelas partes         |
| `cancelada`         | recusada ou interrompida       |

---

## 🧱 BACKEND – MODELO DA TABELA `legal_partnerships`

| Campo                | Tipo            |
| -------------------- | --------------- |
| id                   | UUID            |
| ofertante\_id        | UUID (FK user)  |
| parceiro\_id         | UUID (FK user)  |
| caso\_id             | UUID (opcional) |
| tipo\_colaboracao    | ENUM            |
| status               | ENUM            |
| honorarios           | DECIMAL / TEXT  |
| contrato\_url        | TEXT            |
| contrato\_aceito\_em | TIMESTAMP       |
| created\_at          | TIMESTAMP       |

---

## ✅ Resultado da Parte 2:

✔️ Profissionais se encontram por IA ou busca
✔️ Propostas e aceitações são rastreáveis
✔️ Contrato é gerado dinamicamente
✔️ Tudo com respaldo jurídico e controle de status

---

# ✅ PARTE 3.1 — NAVEGAÇÃO FINAL POR PERFIL DE ADVOGADO

---

## 👨‍⚖️ ADVOGADO ASSOCIADO (`lawyer_associated`)

> Focado em atuar nos casos do escritório ao qual está vinculado.
> **Não** contrata parceiros.

| Aba          | Rota         | Ícone              | Função                                                       |
| ------------ | ------------ | ------------------ | ------------------------------------------------------------ |
| 🧭 Painel    | `/dashboard` | `Icons.dashboard`  | Visão geral: próximos compromissos, alertas e casos recentes |
| 📁 Casos     | `/cases`     | `Icons.folder`     | Casos em que está atuando                                    |
| 📅 Agenda    | `/agenda`    | `Icons.event_note` | Compromissos e audiências agendadas                          |
| 📥 Ofertas   | `/offers`    | `Icons.inbox`      | Propostas de atuação recebidas do escritório                 |
| 💬 Mensagens | `/messages`  | `Icons.chat`       | Conversas com escritório e clientes                          |
| 👤 Perfil    | `/profile`   | `Icons.person`     | Dados do advogado                                            |

---

## 🧑‍💼 ADVOGADO CONTRATANTE / ESCRITÓRIO (`lawyer_office` ou `lawyer_individual` com poder de contratação)

> Responsável por **buscar**, **contratar parceiros**, **acompanhar parcerias** e **gerenciar casos delegados**.

| Aba                 | Rota            | Ícone             | Função                                                                  |
| ------------------- | --------------- | ----------------- | ----------------------------------------------------------------------- |
| 🏠 Início           | `/home`         | `Icons.home`      | Tela principal com KPIs, notificações e ações rápidas                   |
| 👨‍⚖️ Parceiros     | `/lawyers`      | `Icons.search`    | Buscar advogados ou escritórios disponíveis para contratação            |
| 🤝 Minhas Parcerias | `/partnerships` | `Icons.handshake` | Parcerias em andamento, pendentes, finalizadas (com contratos digitais) |
| 💬 Mensagens        | `/messages`     | `Icons.chat`      | Conversas com parceiros ou associados                                   |
| 👤 Perfil           | `/profile`      | `Icons.person`    | Dados da organização ou advogado autônomo                               |

---

## 🧠 Lógica no Flutter

```dart
final userType = authRepository.currentUser.userType;

final tabs = switch (userType) {
  'lawyer_associated' => associatedTabs,
  'lawyer_office' || 'lawyer_individual' => hiringTabs,
  _ => clientTabs, // já existentes
};
```

---

## ✅ Próximos passos possíveis:

Se desejar, posso agora:

1. **Gerar o código Flutter completo** das `tabs` conforme essa navegação;
2. Criar os arquivos de `Screen` vazios ou com `mock` dos dados reais;
3. Fornecer o esquema REST para alimentar as telas de parceiros, parcerias e painel.

à **Parte 4**, onde definiremos toda a **infraestrutura backend RESTful** necessária para suportar o sistema de **parcerias inteligentes**, desde a triagem até o aceite de contratos, incluindo permissões, fluxos e relacionamentos.

---

# ✅ PARTE 4 — BACKEND: ENDPOINTS REST E LÓGICA DE PARCERIAS

---

## 📦 1. ENTIDADE `partnerships`

### 🔹 Campos principais:

| Campo                  | Tipo              | Descrição                                                                     |
| ---------------------- | ----------------- | ----------------------------------------------------------------------------- |
| `id`                   | UUID              | ID único                                                                      |
| `creator_id`           | UUID (FK `users`) | Quem enviou a proposta (autônomo ou escritório)                               |
| `partner_id`           | UUID (FK `users`) | Quem vai receber e atuar na parceria                                          |
| `case_id`              | UUID (opcional)   | Caso vinculado, se aplicável                                                  |
| `type`                 | ENUM              | `consultoria`, `redação`, `audiência`, `atuação total`, etc                   |
| `status`               | ENUM              | `pendente`, `aceita`, `rejeitada`, `contrato_pendente`, `ativa`, `finalizada` |
| `proposal_message`     | TEXT              | Texto opcional enviado na proposta                                            |
| `honorarios`           | DECIMAL / TEXT    | Valor negociado (se informado)                                                |
| `contract_url`         | TEXT              | URL do contrato gerado para aceite                                            |
| `contract_accepted_at` | TIMESTAMP         | Quando foi assinado digitalmente                                              |
| `created_at`           | TIMESTAMP         | Criada em                                                                     |
| `updated_at`           | TIMESTAMP         | Última atualização                                                            |

---

## 🌐 2. ENDPOINTS REST COMPLETOS

### 🔹 2.1 Criar proposta de parceria

```http
POST /api/partnerships
```

**Body:**

```json
{
  "partner_id": "uuid", 
  "case_id": "uuid (opcional)",
  "type": "consultoria",
  "proposal_message": "Precisamos de apoio neste caso...",
  "honorarios": "a combinar"
}
```

---

### 🔹 2.2 Listar parcerias do usuário

```http
GET /api/partnerships?filter=ativa|pendente|todas
```

Retorna todas as parcerias onde o usuário:

* é o `creator_id` (quem contratou) ou
* é o `partner_id` (quem foi contratado)

---

### 🔹 2.3 Aceitar ou recusar proposta

```http
PATCH /api/partnerships/{id}/accept
PATCH /api/partnerships/{id}/reject
```

### 🔹 2.4 Gerar contrato e aguardar aceite

```http
POST /api/partnerships/{id}/generate-contract
```

Retorna:

```json
{ "contract_url": "https://..." }
```

### 🔹 2.5 Aceitar contrato digitalmente

```http
PATCH /api/partnerships/{id}/accept-contract
```

---

## 🧠 3. LÓGICA DE FLUXO (STATUS MACHINE)

```plaintext
[pendente] --(aceite)--> [contrato_pendente] --(aceite do contrato)--> [ativa] --(encerramento)--> [finalizada]
                     \--(recusa)--------------------------------------> [rejeitada]
```

---

## 🔐 4. PERMISSÕES POR PAPEL

| Ação                      | Quem pode fazer                 |
| ------------------------- | ------------------------------- |
| Criar proposta            | Autônomo ou escritório          |
| Aceitar/recusar proposta  | Advogado autônomo ou escritório |
| Gerar contrato            | Apenas quem aceitou a proposta  |
| Aceitar contrato          | O contratado (partner\_id)      |
| Listar todas as parcerias | Ambos os envolvidos             |

---

## 📁 5. MODELO DE CONTRATO GERADO (Markdown ou HTML)

* Geração automática no backend (pode usar Jinja, Markdown-to-PDF, etc.)
* Exibição formatada no app Flutter
* Salvamento com versionamento no Supabase Storage / Firebase

---

## ✅ Resultado da Parte 4

✔️ API completa e segura para:

* Propor, aceitar e rastrear parcerias
* Gerar e aceitar contratos
* Diferenciar fluxos por papel (advogado/escritório)
* Integrar de forma transparente com a UI

---
Excelente pergunta, Nicolas. Abaixo está o **fluxo completo das parcerias jurídicas no app**, **desde a busca até a formação e ativação contratual**, com cada etapa bem definida em termos de lógica de negócio, interfaces e backend.

---

# 🔄 FLUXO COMPLETO DAS PARCERIAS – PASSO A PASSO

> Válido para **advogados contratantes** (autônomos ou escritórios) que desejam formar uma parceria com **outros advogados ou escritórios**.



## ✅ ETAPA 1 – INÍCIO DA BUSCA POR PARCEIRO

**Onde:** Aba `Parceiros` → `/lawyers`

**Ações:**

* Filtro por:

  * Área de atuação
  * Jurisdição/UF
  * Disponibilidade
  * Tipo de serviço desejado (consultoria, audiência, petição etc.)

**Origem da necessidade:**

* Pode ser livre (busca ativa)
* Ou vinculada a um **caso já criado**

---

## ✅ ETAPA 2 – VISUALIZAÇÃO DO PERFIL DO PARCEIRO

**Onde:** Card do advogado na listagem

**Ações:**

* Ver currículo resumido
* Avaliações anteriores (se houver)
* Áreas de expertise
* Honorários médios (se configurado)
* Botão: **"Propor parceria"**

---

## ✅ ETAPA 3 – ENVIO DA PROPOSTA DE PARCERIA

**Onde:** `/propose-partnership`

**Ações do contratante:**

* Escolhe tipo de colaboração:

  * Consultoria
  * Petição técnica
  * Audiência local
  * Atuação total
  * Parceria recorrente
* (Opcional) Vincula a um caso existente
* Escreve mensagem breve (escopo)
* Informa valor sugerido, ou seleciona "a combinar"

➡️ Criação no backend: `POST /api/partnerships`

---

## ✅ ETAPA 4 – RECEBIMENTO E RESPOSTA DO PARCEIRO

**Onde:** Aba `Ofertas` → `/offers`

**Ações do advogado convidado:**

* Visualiza proposta
* Aceita ou recusa

➡️ Se **recusar**: fim do fluxo (status `rejeitada`)
➡️ Se **aceitar**: segue para geração do contrato (status `contrato_pendente`)

---

## ✅ ETAPA 5 – GERAÇÃO DO CONTRATO AUTOMÁTICO

**Backend:**

* Sistema gera contrato jurídico dinâmico (Markdown/HTML)
* Preenche com:

  * Dados do contratante
  * Dados do parceiro
  * Tipo da parceria
  * Honorários
  * Data

**Onde:** `/partnerships/:id/contract`

---

## ✅ ETAPA 6 – ACEITE DIGITAL DO CONTRATO

**Ações do parceiro (convidado):**

* Lê contrato completo
* Confirma: **“Aceitar e Assinar”**

**Registro no backend:**

* Grava URL e versão do contrato aceito
* Timestamp do aceite
* Atualiza status para `ativa`

---

## ✅ ETAPA 7 – EXECUÇÃO DA PARCERIA

**Onde:** Aba `Parcerias` → `/partnerships`

**Ambas as partes podem:**

* Acompanhar andamento do serviço
* Enviar mensagens
* Encerrar quando finalizado

---

## 🔁 FLUXO COMPLETO (VISUAL SIMPLIFICADO)

```plaintext
BUSCA → PERFIL → PROPOSTA → ACEITE → CONTRATO → ASSINATURA → PARCERIA ATIVA
```

---

## 🛡️ SEGURANÇA E RASTREABILIDADE

Cada passo gera:

* Um status persistente (auditoria)
* Um registro com timestamps
* Uma relação clara entre `creator_id`, `partner_id`, `case_id` (se aplicável)



