# 📁 Estrutura do Projeto - LITGO5

## 🏗️ Visão Geral da Arquitetura

```
LITGO5/
├── 📱 Frontend (React Native + Expo)
├── ⚙️ Backend (Python + FastAPI)
├── 🗄️ Banco de Dados (Supabase/PostgreSQL)
├── �� Documentação
└── 🔧 Configuração e Scripts
```

## 📂 Estrutura Detalhada

### 🎨 Frontend - React Native/Expo

```
app/                          # Telas principais (Expo Router)
├── (auth)/                   # Fluxo de autenticação
│   ├── index.tsx            # Login
│   ├── register-client.tsx  # Cadastro cliente
│   ├── register-lawyer.tsx  # Cadastro advogado
│   └── role-selection.tsx   # Seleção de perfil
│
├── (tabs)/                   # Navegação principal
│   ├── _layout.tsx          # Layout das tabs
│   ├── index.tsx            # Home/Dashboard
│   ├── cases.tsx            # Lista de casos
│   ├── advogados.tsx        # Lista de advogados
│   ├── agenda.tsx           # Calendário
│   ├── chat.tsx             # Conversas
│   ├── contracts.tsx        # Contratos
│   └── profile.tsx          # Perfil do usuário
│
├── cases/                    # Funcionalidades de casos
│   ├── CaseDetail.tsx       # Detalhes do caso
│   ├── CaseDocuments.tsx    # Documentos
│   ├── CaseTasks.tsx        # Tarefas
│   └── AISummary.tsx        # Resumo IA
│
├── triagem.tsx              # Triagem inteligente
├── chat-triagem.tsx         # Chat com IA
├── MatchesPage.tsx          # Resultados do match
├── NewCase.tsx              # Novo caso
└── _layout.tsx              # Layout principal
```

### 🧩 Componentes

```
components/
├── atoms/                    # Componentes básicos
│   ├── Avatar.tsx           # Avatar de usuário
│   ├── Badge.tsx            # Badges e tags
│   ├── ProgressBar.tsx      # Barra de progresso
│   └── StatusDot.tsx        # Indicador de status
│
├── molecules/               # Componentes compostos
│   ├── CaseHeader.tsx       # Cabeçalho de caso
│   ├── DocumentItem.tsx     # Item de documento
│   ├── AttachmentItem.tsx   # Item de anexo
│   └── StepItem.tsx         # Item de etapa
│
├── organisms/               # Componentes complexos
│   ├── CaseCard.tsx         # Card de caso
│   ├── ContractCard.tsx     # Card de contrato
│   ├── DocuSignStatus.tsx   # Status DocuSign
│   └── PreAnalysisCard.tsx  # Card de pré-análise
│
├── layout/                  # Componentes de layout
│   ├── TopBar.tsx           # Barra superior
│   └── FabNewCase.tsx       # Botão flutuante
│
└── LawyerMatchCard.tsx      # Card de match principal
```

### ⚙️ Backend - Python/FastAPI

```
backend/
├── main.py                  # Entry point da API
├── config.py                # Configurações (Settings)
├── models.py                # Schemas Pydantic
├── auth.py                  # Autenticação JWT
├── routes.py                # Definição de rotas
├── services.py              # Lógica de negócio
│
├── services/                # Serviços específicos
│   ├── match_service.py     # Serviço de match
│   ├── contract_service.py  # Serviço de contratos
│   ├── sign_service.py      # Integração DocuSign
│   ├── notify_service.py    # Notificações
│   └── offer_service.py     # Gerenciamento de ofertas
│
├── routes/                  # Rotas específicas
│   ├── contracts.py         # Endpoints de contratos
│   └── offers.py            # Endpoints de ofertas
│
├── algoritmo_match.py       # Algoritmo v2.1
├── triage_service.py        # Serviço de triagem IA
├── embedding_service.py     # Geração de embeddings
├── explanation_service.py   # Explicações IA
│
├── celery_app.py           # Configuração Celery
├── tasks.py                # Tarefas assíncronas
│
├── jobs/                   # Jobs agendados
│   ├── jusbrasil_sync.py   # Sync dados Jusbrasil
│   └── expire_offers.py    # Expiração de ofertas
│
└── tests/                  # Testes automatizados
    ├── test_match.py       # Testes do algoritmo
    ├── test_triage.py      # Testes de triagem
    └── test_docusign_integration.py
```

### 🗄️ Banco de Dados - Supabase

```
supabase/
├── migrations/             # Migrações SQL
│   ├── 20250103000000_create_profiles_table.sql
│   ├── 20250704000000_setup_cases_table.sql
│   ├── 20250718000000_add_match_algorithm_fields.sql
│   ├── 20250719000000_enable_pgvector.sql
│   └── 20250720000000_create_offers_table.sql
│
├── functions/              # Edge Functions
│   ├── support-ticket-notifier/
│   └── task-deadline-notifier/
│
└── config.toml            # Configuração Supabase
```

### 📚 Documentação

```
docs/
├── README.md                        # Visão geral
├── DOCUMENTACAO_COMPLETA.md         # Referência técnica
├── ARQUITETURA_SISTEMA.md           # Arquitetura
├── GUIA_DESENVOLVIMENTO.md          # Guia de dev
├── API_DOCUMENTATION.md             # Documentação API
├── FLUXO_NEGOCIO.md                # Fluxo de negócio
├── README_TECNICO.md                # README técnico
│
├── Algoritmo/                       # Documentação do algoritmo
│   ├── Algoritmo.md                 # Especificação v2.1
│   ├── algoritmo_match_v2_1_stable_readable.py
│   ├── API_contract_v2.md           # Contrato da API
│   ├── LLM-triage.md               # Triagem com LLM
│   └── LLM-explanation.md          # Explicações IA
│
├── Integrações/                     # Documentação de integrações
│   ├── INTEGRACAO_DOCUSIGN_COMPLETA.md
│   ├── GOOGLE_CALENDAR_SETUP_MANUAL.md
│   └── INTEGRACAO_VIDEOCHAMADA_DAILY.md
│
└── Correções/                       # Status e correções
    ├── CORRECOES_CRITICAS.md
    ├── STATUS_CORRECOES.md
    └── CHANGELOG.md
```

### 🔧 Configuração e Scripts

```
configuracao/
├── .env.example             # Variáveis de ambiente exemplo
├── docker-compose.yml       # Orquestração Docker
├── Dockerfile              # Imagem backend
├── package.json            # Dependências frontend
├── requirements.txt        # Dependências backend
├── app.config.ts           # Configuração Expo
├── tsconfig.json           # Configuração TypeScript
├── eslint.config.js        # Configuração ESLint
├── pytest.ini              # Configuração pytest
│
└── scripts/                # Scripts utilitários
    ├── setup_google_calendar.sh
    ├── configure_credentials.sh
    └── docusign_example.py
```

## 🔑 Arquivos Principais

### Frontend
| Arquivo | Descrição |
|---------|-----------|
| `app/_layout.tsx` | Layout principal da aplicação |
| `app/triagem.tsx` | Tela de triagem inteligente |
| `app/MatchesPage.tsx` | Tela de resultados do match |
| `components/LawyerMatchCard.tsx` | Componente principal de match |
| `lib/services/api.ts` | Cliente API |
| `lib/contexts/AuthContext.tsx` | Contexto de autenticação |

### Backend
| Arquivo | Descrição |
|---------|-----------|
| `backend/main.py` | Entry point FastAPI |
| `backend/algoritmo_match.py` | Algoritmo v2.1 |
| `backend/triage_service.py` | Serviço de triagem IA |
| `backend/services/sign_service.py` | Integração DocuSign |
| `backend/celery_app.py` | Configuração Celery |

### Banco de Dados
| Arquivo | Descrição |
|---------|-----------|
| `supabase/migrations/*` | Todas as migrações SQL |
| `supabase/config.toml` | Configuração Supabase |

## 📊 Estatísticas do Projeto

- **Total de Arquivos**: ~200+
- **Linguagens**: TypeScript (60%), Python (30%), SQL (10%)
- **Linhas de Código**: ~15.000+
- **Componentes React**: 50+
- **Endpoints API**: 20+
- **Tabelas DB**: 15+

---

**Última atualização:** Janeiro 2025  
**Versão:** 2.1-stable
