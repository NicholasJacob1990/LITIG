# 📚 Índice da Documentação - LITGO5

## 🎯 Visão Geral

Este documento serve como **índice central** para toda a documentação do projeto LITGO5. Use-o para navegar rapidamente entre os diferentes aspectos do sistema.

**Status da Documentação**: ✅ Atualizada (Janeiro 2025)  
**Cobertura**: 100% dos componentes principais  
**Idioma**: Português (PT-BR)

---

## 📖 Documentação Principal

### 🏠 Introdução e Setup
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [README.md](./README.md) | Visão geral, quick start e arquitetura | ✅ Atualizado |
| [SETUP_INSTRUCTIONS.md](./SETUP_INSTRUCTIONS.md) | Instruções detalhadas de configuração | ✅ Completo |
| [env.example](./env.example) | Template de variáveis de ambiente | ✅ Completo |

### 🏗️ Arquitetura e Sistema
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [ARQUITETURA_SISTEMA.md](./ARQUITETURA_SISTEMA.md) | Arquitetura completa do sistema | ✅ Atualizado |
| [Algoritmo/Async_architecture.md](./Algoritmo/Async_architecture.md) | Arquitetura assíncrona detalhada | ✅ Atualizado |
| [FLUXO_NEGOCIO.md](./FLUXO_NEGOCIO.md) | Fluxos de negócio e processos | ✅ Completo |

### 👨‍💻 Desenvolvimento
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [GUIA_DESENVOLVIMENTO.md](./GUIA_DESENVOLVIMENTO.md) | Guia completo para desenvolvedores | ✅ Atualizado |
| [GUIA_RAPIDO_REFERENCIA.md](./GUIA_RAPIDO_REFERENCIA.md) | Referência rápida de comandos | ✅ Atualizado |
| [docker-compose.yml](./docker-compose.yml) | Configuração Docker | ✅ Funcional |

---

## 🤖 Algoritmo e IA

### 📊 Algoritmo de Match v2.1
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [Algoritmo/Algoritmo.md](./Algoritmo/Algoritmo.md) | Documentação completa do algoritmo | ✅ Atualizado |
| [Algoritmo/algoritmo_match_v2_1_stable_readable.py](./Algoritmo/algoritmo_match_v2_1_stable_readable.py) | Código fonte comentado | ✅ Funcional |
| [backend/algoritmo_match.py](./backend/algoritmo_match.py) | Implementação no backend | ✅ Sincronizado |

### 🎯 Learning-to-Rank (LTR)
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [Algoritmo/LTR_Pipeline.md](./Algoritmo/LTR_Pipeline.md) | Pipeline completo de LTR | ✅ Implementado |
| [backend/jobs/ltr_export.py](./backend/jobs/ltr_export.py) | ETL para dataset de treino | ✅ Funcional |
| [backend/jobs/ltr_train.py](./backend/jobs/ltr_train.py) | Treinamento do modelo | ✅ Funcional |

### 🧠 Inteligência Artificial
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [Algoritmo/LLM-triage.md](./Algoritmo/LLM-triage.md) | Especificação da triagem IA | ✅ Completo |
| [Algoritmo/LLM-explanation.md](./Algoritmo/LLM-explanation.md) | Sistema de explicações | ✅ Completo |
| [backend/services/triage_service.py](./backend/services/triage_service.py) | Implementação triagem | ✅ Funcional |

---

## 📡 API e Integrações

### 🔌 Documentação da API
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) | Documentação completa da API | ✅ Atualizado |
| [Algoritmo/API_contract_v2.md](./Algoritmo/API_contract_v2.md) | Contratos de API v2 | ✅ Atualizado |
| [backend/main.py](./backend/main.py) | Implementação FastAPI | ✅ Funcional |

### 🔗 Integrações Externas
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [Algoritmo/Jusbrasil_job.md](./Algoritmo/Jusbrasil_job.md) | Integração Jusbrasil API | ✅ Documentado |
| [INTEGRACAO_DOCUSIGN_COMPLETA.md](./INTEGRACAO_DOCUSIGN_COMPLETA.md) | Integração DocuSign | ✅ Implementado |
| [INTEGRACAO_VIDEOCHAMADA_DAILY.md](./INTEGRACAO_VIDEOCHAMADA_DAILY.md) | Integração Daily.co | ✅ Documentado |

---

## 🔧 Correções e Status

### 📊 Status do Projeto
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [STATUS_CORRECOES.md](./STATUS_CORRECOES.md) | Status atual das correções | ✅ Atualizado |
| [CORRECOES_CRITICAS.md](./CORRECOES_CRITICAS.md) | Problemas críticos identificados | ✅ Resolvido |
| [CORRECOES_APLICADAS.md](./CORRECOES_APLICADAS.md) | Histórico de correções | ✅ Atualizado |

### 🚀 Implementações
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [EXECUCAO_PLANO_SPRINT1.md](./EXECUCAO_PLANO_SPRINT1.md) | Execução Sprint 1 | ✅ Completo |
| [EXECUCAO_PLANO_SPRINT2.md](./EXECUCAO_PLANO_SPRINT2.md) | Execução Sprint 2 | ✅ Completo |
| [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md) | Resumo das implementações | ✅ Atualizado |

---

## 🧪 Testes e Qualidade

### 🔍 Testes
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [TESTES_E_QUALIDADE.md](./TESTES_E_QUALIDADE.md) | Estratégia de testes | ✅ Documentado |
| [PLANO_TESTES_REFINAMENTOS.md](./PLANO_TESTES_REFINAMENTOS.md) | Plano de refinamentos | ✅ Documentado |
| [backend/tests/](./backend/tests/) | Testes automatizados | ✅ Implementado |

### 📈 Monitoramento
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [prometheus/prometheus.yml](./prometheus/prometheus.yml) | Configuração Prometheus | ✅ Configurado |
| [docker-compose.observability.yml](./docker-compose.observability.yml) | Stack observabilidade | ✅ Disponível |
| [logs/](./logs/) | Logs estruturados | ✅ Funcionando |

---

## 🚀 Deploy e Produção

### 🐳 Containerização
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [backend/Dockerfile](./backend/Dockerfile) | Container do backend | ✅ Funcional |
| [docker-compose.yml](./docker-compose.yml) | Orquestração local | ✅ Funcional |
| [DEPLOY_E_INFRAESTRUTURA.md](./DEPLOY_E_INFRAESTRUTURA.md) | Guia de deploy | ✅ Documentado |

### ⚙️ Configuração
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [backend/requirements.txt](./backend/requirements.txt) | Dependências Python | ✅ Atualizado |
| [package.json](./package.json) | Dependências Node.js | ✅ Atualizado |
| [app.config.ts](./app.config.ts) | Configuração Expo | ✅ Configurado |

---

## 📱 Frontend e Mobile

### 🎨 Interface
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [app/](./app/) | Código fonte React Native | ✅ Implementado |
| [components/](./components/) | Componentes reutilizáveis | ✅ Organizados |
| [lib/services/](./lib/services/) | Serviços de API | ✅ Implementados |

### 📱 Configuração Mobile
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [android/](./android/) | Configuração Android | ✅ Configurado |
| [ios/](./ios/) | Configuração iOS | ✅ Configurado |
| [assets/](./assets/) | Assets do app | ✅ Organizados |

---

## 🔐 Segurança e Autenticação

### 🛡️ Segurança
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [backend/auth.py](./backend/auth.py) | Sistema de autenticação | ✅ Implementado |
| [lib/contexts/AuthContext.tsx](./lib/contexts/AuthContext.tsx) | Contexto de auth | ✅ Implementado |
| [CONFIGURACAO_OAUTH_GOOGLE_CALENDAR.md](./CONFIGURACAO_OAUTH_GOOGLE_CALENDAR.md) | OAuth Google | ✅ Documentado |

---

## 📋 Tutoriais e Guias

### 📚 Tutoriais
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [Algoritmo/tutorial-algoritmo.md](./Algoritmo/tutorial-algoritmo.md) | Tutorial do algoritmo | ✅ Atualizado |
| [Algoritmo/tutorial-algoritmo-beckend.md](./Algoritmo/tutorial-algoritmo-beckend.md) | Tutorial backend | ✅ Atualizado |
| [GOOGLE_CALENDAR_SETUP_MANUAL.md](./GOOGLE_CALENDAR_SETUP_MANUAL.md) | Setup Google Calendar | ✅ Completo |

### 🔧 Scripts e Automação
| Documento | Descrição | Status |
|-----------|-----------|--------|
| [scripts/](./scripts/) | Scripts de automação | ✅ Funcionais |
| [backend/jobs/](./backend/jobs/) | Jobs assíncronos | ✅ Implementados |
| [supabase/migrations/](./supabase/migrations/) | Migrações do banco | ✅ Atualizadas |

---

## 🗂️ Organização por Categoria

### 🚀 Para Começar Rapidamente
1. [README.md](./README.md) - Visão geral e quick start
2. [SETUP_INSTRUCTIONS.md](./SETUP_INSTRUCTIONS.md) - Configuração detalhada
3. [GUIA_RAPIDO_REFERENCIA.md](./GUIA_RAPIDO_REFERENCIA.md) - Comandos essenciais

### 🏗️ Para Entender a Arquitetura
1. [ARQUITETURA_SISTEMA.md](./ARQUITETURA_SISTEMA.md) - Visão completa
2. [Algoritmo/Async_architecture.md](./Algoritmo/Async_architecture.md) - Arquitetura assíncrona
3. [FLUXO_NEGOCIO.md](./FLUXO_NEGOCIO.md) - Processos de negócio

### 🤖 Para Entender o Algoritmo
1. [Algoritmo/Algoritmo.md](./Algoritmo/Algoritmo.md) - Documentação completa
2. [Algoritmo/LTR_Pipeline.md](./Algoritmo/LTR_Pipeline.md) - Pipeline de aprendizado
3. [Algoritmo/LLM-triage.md](./Algoritmo/LLM-triage.md) - Triagem inteligente

### 👨‍💻 Para Desenvolver
1. [GUIA_DESENVOLVIMENTO.md](./GUIA_DESENVOLVIMENTO.md) - Guia completo
2. [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) - Documentação da API
3. [TESTES_E_QUALIDADE.md](./TESTES_E_QUALIDADE.md) - Estratégia de testes

### 🚀 Para Deploy
1. [DEPLOY_E_INFRAESTRUTURA.md](./DEPLOY_E_INFRAESTRUTURA.md) - Guia de deploy
2. [docker-compose.yml](./docker-compose.yml) - Configuração Docker
3. [backend/Dockerfile](./backend/Dockerfile) - Container backend

---

## 🔄 Atualizações Recentes

### Janeiro 2025
- ✅ Atualizado README.md com status atual
- ✅ Corrigido Algoritmo/Async_architecture.md
- ✅ Sincronizado STATUS_CORRECOES.md
- ✅ Validado funcionamento completo do ambiente
- ✅ Documentado pipeline LTR implementado

### Dezembro 2024
- ✅ Implementado pipeline Learning-to-Rank
- ✅ Corrigido paths do algoritmo
- ✅ Configurado Docker Compose funcional
- ✅ Integrado Celery workers com Redis

---

## 📞 Suporte e Contribuição

### 🤝 Como Contribuir
1. Leia o [GUIA_DESENVOLVIMENTO.md](./GUIA_DESENVOLVIMENTO.md)
2. Verifique o [STATUS_CORRECOES.md](./STATUS_CORRECOES.md)
3. Consulte a documentação relevante
4. Faça suas alterações
5. Atualize a documentação correspondente

### 📋 Mantendo a Documentação
- **Sempre atualize** a documentação junto com o código
- **Use português** como idioma padrão
- **Mantenha links funcionais** entre documentos
- **Valide exemplos** de código e comandos
- **Atualize este índice** quando adicionar novos documentos

---

**Última atualização**: 04 de Janeiro de 2025  
**Responsável**: Equipe de desenvolvimento LITGO5  
**Versão da documentação**: v2.1 