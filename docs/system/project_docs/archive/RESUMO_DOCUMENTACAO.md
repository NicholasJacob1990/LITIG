# �� Resumo da Documentação - LITGO5

## 🎯 O que é o LITGO5?

O **LITGO5** é uma plataforma jurídica inteligente que conecta clientes a advogados especializados através de:
- 🤖 **IA para Triagem** - Análise automática de casos com Claude 3.5 Sonnet
- 🎯 **Algoritmo de Match v2.1** - 7 features ponderadas para encontrar o melhor advogado
- 📄 **Contratos Digitais** - Integração DocuSign para assinatura eletrônica
- 📱 **App Mobile/Web** - Interface moderna com React Native/Expo

## 📊 Números do Projeto

- **Linhas de Código**: ~15.000+
- **Componentes React**: 50+
- **Endpoints API**: 20+
- **Tabelas Database**: 15+
- **Coverage de Testes**: Backend 85% | Frontend 73%

## 🏗️ Arquitetura Simplificada

```
Cliente (Mobile/Web) → API (FastAPI) → IA (Claude/OpenAI)
                                     ↓
                                 Database (Supabase)
                                     ↓
                                 DocuSign (Contratos)
```

## 📚 Documentação Essencial

### Para Começar
1. **[README.md](./README.md)** - Quick start e visão geral
2. **[Guia de Desenvolvimento](./GUIA_DESENVOLVIMENTO.md)** - Setup do ambiente
3. **[Estrutura do Projeto](./ESTRUTURA_PROJETO.md)** - Organização dos arquivos

### Para Entender
1. **[Fluxo de Negócio](./FLUXO_NEGOCIO.md)** - As 8 fases do sistema
2. **[Algoritmo de Match](./Algoritmo/Algoritmo.md)** - Como funciona o matching
3. **[Arquitetura do Sistema](./ARQUITETURA_SISTEMA.md)** - Componentes e integrações

### Para Desenvolver
1. **[API Documentation](./API_DOCUMENTATION.md)** - Todos os endpoints
2. **[Testes e Qualidade](./TESTES_E_QUALIDADE.md)** - Como testar
3. **[Deploy e Infraestrutura](./DEPLOY_E_INFRAESTRUTURA.md)** - Como fazer deploy

## 🔑 Principais Features

### 1. Triagem Inteligente
- Cliente descreve o caso em texto ou áudio
- Claude 3.5 analisa e categoriza automaticamente
- Extrai área jurídica, urgência e resumo

### 2. Match de Advogados
- Algoritmo v2.1 com 7 features:
  - Area Match (30%) - Especialização
  - Similarity (25%) - Casos similares
  - Taxa Sucesso (15%) - Histórico
  - Geo (10%) - Proximidade
  - Qualificação (10%) - Experiência
  - Urgência (5%) - Disponibilidade
  - Rating (5%) - Avaliações

### 3. Contratos Digitais
- Integração completa com DocuSign
- Assinatura eletrônica juridicamente válida
- Fallback para HTML quando DocuSign indisponível

### 4. Comunicação
- Chat em tempo real
- Videochamadas integradas (Daily.co)
- Compartilhamento de documentos

## 💻 Stack Tecnológica

### Backend
- **Python 3.10+** com FastAPI
- **PostgreSQL** (Supabase) + pgvector
- **Redis** para cache e filas
- **Celery** para processamento assíncrono

### Frontend
- **React Native** + Expo SDK 50
- **TypeScript** + NativeWind
- **Expo Router** para navegação

### Integrações
- **Claude 3.5 Sonnet** - Triagem IA
- **OpenAI** - Embeddings
- **DocuSign** - Contratos
- **Google Calendar** - Agendamento
- **Daily.co** - Videochamadas

## 🚀 Como Começar

### 1. Clone e Configure
```bash
git clone https://github.com/litgo/litgo5.git
cd LITGO5
cp env.example .env
# Editar .env com suas chaves
```

### 2. Execute com Docker
```bash
docker-compose up --build
```

### 3. Acesse
- API: http://localhost:8000
- App: Expo Go no celular

## 📈 Modelo de Negócio

### Receitas
- **Taxa de Intermediação**: 10-15% dos contratos
- **Assinatura Premium**: R$ 199-499/mês para advogados
- **Serviços Adicionais**: DocuSign, videoconsulta

### Custos Principais
- **Claude API**: ~R$ 0,50/triagem
- **OpenAI**: ~R$ 0,02/embedding
- **DocuSign**: ~R$ 5,00/contrato
- **Infraestrutura**: ~R$ 3.000/mês

## 🎯 Roadmap

### Q1 2025 ✅
- [x] MVP com match básico
- [x] Integração DocuSign
- [ ] App iOS/Android nas lojas
- [ ] Dashboard para advogados

### Q2 2025 🎯
- [ ] IA para gerar petições
- [ ] Marketplace de serviços
- [ ] API para parceiros
- [ ] Expansão nacional

### Q3 2025 🚀
- [ ] Arbitragem online
- [ ] Financiamento de causas
- [ ] Seguro jurídico
- [ ] Expansão LATAM

## 📞 Suporte

- **Documentação**: [Índice Completo](./INDICE_DOCUMENTACAO.md)
- **Issues**: GitHub Issues
- **Email**: suporte@litgo.com

---

**Última atualização:** Janeiro 2025  
**Versão:** 2.1-stable  
**Status:** Production-ready 🚀
