# 🚀 LITIG-1 - Sistema de Match Jurídico Inteligente

Sistema completo de matching entre clientes e advogados usando inteligência artificial, com triagem inteligente e algoritmos de recomendação.

## 📋 Visão Geral

O LITIG-1 é uma plataforma inovadora que conecta clientes com advogados especializados através de:

- **Triagem Inteligente**: IA analisa casos e identifica área jurídica
- **Matching Algorítmico**: Algoritmo proprietário para melhor compatibilidade
- **Frontend Moderno**: Aplicativo 100% Flutter para Android, iOS, e Web.
- **Backend Robusto**: FastAPI + Supabase + PostgreSQL
- **Análise de Dados**: Embeddings e ML para recomendações

## 🏗️ Arquitetura do Sistema

```
LITIG-1/
├── apps/
│   └── app_flutter/          # ✅ Aplicativo Flutter (Android, iOS, Web)
├── packages/
│   └── backend/              # 🚀 API FastAPI + Serviços
├── flutter_migration/        # 📚 Documentação da migração Flutter
├── docs/                     # 📖 Documentação geral
└── infra/                    # 🔧 Infraestrutura (Redis, Prometheus)
```

## ✅ Status do Projeto

- [x] Arquitetura Clean Architecture
- [x] Sistema de autenticação (AuthBloc)
- [x] Chat triagem inteligente
- [x] Sistema de matches de advogados
- [x] Navegação com tabs shell
- [x] Tela de mensagens para cliente
- [x] Dashboard com dados integrados
- [x] Testes de integração abrangentes
- [x] Otimizações de performance
- [x] Deploy em produção
- [x] Build macOS, Android, iOS, Web funcionando

## 🚀 Quick Start

### Flutter App
```bash
# Navegar para o app Flutter
cd apps/app_flutter

# Instalar dependências
flutter pub get

# Executar app
flutter run
```

### Backend API
```bash
# Navegar para o backend
cd packages/backend

# Instalar dependências
pip install -r requirements.txt

# Executar servidor
python main.py
```

## 🔧 Tecnologias Utilizadas

### Frontend
- **Flutter**: Framework multiplataforma
- **Dart**: Linguagem para Flutter

### Backend
- **FastAPI**: Framework web Python
- **Supabase**: Backend-as-a-Service
- **PostgreSQL**: Banco de dados principal
- **Redis**: Cache e sessions
- **Celery**: Processamento assíncrono

### ML/AI
- **OpenAI**: Modelos de linguagem
- **Embeddings**: Vetorização de texto
- **scikit-learn**: Machine learning
- **Pandas**: Análise de dados

### Infraestrutura
- **Docker**: Containerização
- **Prometheus**: Monitoramento
- **Grafana**: Dashboards
- **GitHub Actions**: CI/CD

## 📚 Documentação

### Migração Flutter
- [📋 Comparação Técnica](./flutter_migration/FLUTTER_COMPARACAO_TECNICA.md)
- [🚀 Guia de Desenvolvimento](./flutter_migration/FLUTTER_DEVELOPMENT.md)
- [📈 Resumo Executivo](./flutter_migration/FLUTTER_EXECUTIVE_SUMMARY.md)
- [🗓️ Roadmap](./flutter_migration/FLUTTER_ROADMAP.md)
- [💰 Implementação Financeira](./flutter_migration/FLUTTER_FINANCIAL_IMPLEMENTATION.md)

### Sistema
- [🔍 Análise Funcional](./docs/system/ANALISE_FUNCIONAL.md)
- [🤖 Análise Gemini](./docs/system/ANALISE_GEMINI.md)
- [📡 Documentação API](./docs/system/API_DOCUMENTATION.md)

## 🧪 Testes

### Flutter
```bash
cd apps/app_flutter

# Testes unitários
flutter test

# Testes de integração
flutter drive --target=test_driver/app.dart
```

### Backend
```bash
cd packages/backend

# Testes unitários
pytest tests/

# Testes de integração
pytest tests/integration/
```

## 🔐 Configuração de Ambiente

### Variáveis de Ambiente
```bash
# Flutter
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
API_BASE_URL=http://localhost:8000

# Backend
DATABASE_URL=postgresql://...
REDIS_URL=redis://localhost:6379
OPENAI_API_KEY=your_openai_key
```

### Supabase Setup
```bash
# Instalar Supabase CLI
npm install -g supabase

# Fazer login
supabase login

# Linkar projeto
supabase link --project-ref your-project-ref
```

## 📊 Métricas de Performance

### Objetivos Flutter
- **60fps** consistente em animações
- **<3s** tempo de inicialização
- **<0.1%** crash rate

### Algoritmo de Matching
- **95%+** precisão na triagem
- **<2s** tempo de resposta
- **20+** fatores de compatibilidade
- **85%** satisfação dos usuários

## 🤝 Contribuindo

### Fluxo de Trabalho
1. Fork o repositório
2. Crie uma branch para sua feature
3. Implemente com testes
4. Faça PR com descrição detalhada

### Padrões de Código
- **Flutter**: Seguir dart_style
- **Python**: PEP 8 + black
- **TypeScript**: ESLint + Prettier
- **Git**: Commits semânticos

## 🐛 Problemas Conhecidos

### Flutter
- [x] ✅ Erro de build macOS (resolvido)
- [ ] Performance em listas grandes
- [ ] Integração com push notifications

### Backend
- [ ] Rate limiting refinado
- [ ] Otimização de queries
- [ ] Cache warming

## �� Changelog

### v1.1.0 (Fevereiro 2025)
- 🎉 Migração para Flutter concluída. O app React Native foi removido.
- 🚀 Deploy da versão Flutter em produção.

### v1.0.0 (Janeiro 2025)
- ✅ Correção erro build macOS
- ✅ Implementação chat triagem
- ✅ Sistema de matches funcionando
- ✅ Navegação com 5 abas
- ✅ Tela de mensagens cliente
- ✅ Arquitetura Clean implementada
- 🏗️ Setup da arquitetura

## 🔗 Links Úteis

- **Repositório**: [GitHub](https://github.com/NicholasJacob1990/LITIG)
- **Documentação**: [Docs](./docs/)
- **API**: [FastAPI Docs](http://localhost:8000/docs)
- **Supabase**: [Dashboard](https://app.supabase.com/)

## 📞 Contato

Para dúvidas ou sugestões:
- **Email**: contato@litig.com.br
- **GitHub**: [@NicholasJacob1990](https://github.com/NicholasJacob1990)

---

**Última atualização**: Fevereiro 2025
**Versão**: 1.1.0
**Status**: ✅ Ativo 