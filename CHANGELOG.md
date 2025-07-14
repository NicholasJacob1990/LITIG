# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v2.6.3] - 2024-01-21

### 🚀 Adicionado
- **Sistema B2B Law Firms**: Implementação completa do sistema de escritórios de advocacia
- **Feature-E (Employer/Firm Reputation)**: Nova feature no algoritmo de matching que considera reputação do escritório
- **Algoritmo Two-Pass B2B**: Ranking em dois passos para casos corporativos (primeiro escritórios, depois advogados)
- **Endpoints da API**: CRUD completo para escritórios (`/firms/*`) com autenticação e autorização
- **Migrations de Banco**: Tabelas `law_firms`, `firm_kpis` e relacionamento com `lawyers`
- **Feature Flags**: Sistema de controle de rollout gradual com variáveis de ambiente
- **Cache Segmentado**: Cache Redis com prefixos específicos para entidades (firm/lawyer)
- **Monitoramento B2B**: Dashboard Grafana e alertas específicos para funcionalidades B2B
- **Testes E2E**: Suite completa de testes de integração para fluxo B2B
- **Scripts Operacionais**: Scripts de backfill de dados e rollback rápido

### 🔧 Modificado
- **Algoritmo de Matching**: Atualizado para suportar Feature-E e modo two-pass
- **Pesos do Algoritmo**: Incluída feature "E" nos pesos padrão e criado preset "b2b"
- **Classe Case**: Adicionado campo `type` para distinguir casos individuais e corporativos
- **Flutter UI**: Componentes atualizados para suportar exibição de escritórios
- **Repositórios**: Novos repositórios e data sources para gerenciar dados de escritórios

### 🎯 Funcionalidades B2B
- **Para Clientes**: Busca, visualização e contratação de escritórios
- **Para Advogados de Captação**: Busca e estabelecimento de parcerias com escritórios
- **Para Advogados Associados**: Dashboard com informações do escritório vinculado
- **Preset Automático**: Casos corporativos automaticamente usam preset "b2b"
- **Compliance OAB**: Verificação de conflitos de interesse antes do ranking

### 📊 Observabilidade
- **Métricas Prometheus**: Novos contadores com label `entity` (firm/lawyer)
- **Dashboard Grafana**: 8 painéis específicos para monitoramento B2B
- **Alertas**: 6 alertas críticos para latência, taxa de sucesso e erros
- **Logs Estruturados**: Auditoria completa das decisões do algoritmo

### 🔒 Segurança
- **Autenticação**: Endpoints protegidos com roles específicos
- **Autorização**: Permissões granulares (admin, office, user)
- **Sanitização**: Dados sensíveis filtrados baseados no perfil do usuário
- **Validação**: Constraints de banco para garantir integridade dos KPIs

### 🚀 Performance
- **Algoritmo Two-Pass**: 88.5% melhoria na performance (0.003s vs 0.026s)
- **Cache Otimizado**: Prefixos específicos para evitar colisões
- **Timeouts Configuráveis**: Evitar dead-locks em verificações de conflito
- **Lazy Loading**: Carregamento otimizado de dados de escritórios

### 📱 Flutter (Frontend)
- **FirmCard Widget**: Componente reutilizável para exibição de escritórios
- **FirmDetailScreen**: Tela detalhada com KPIs e lista de advogados
- **Navegação**: Rotas `/firm/:firmId` e `/firm/:firmId/lawyers`
- **BLoCs**: Gerenciamento de estado para funcionalidades híbridas
- **Testes**: 7 testes de widget para componentes de escritórios

### 🔧 Configuração
- **Feature Flags**: `ENABLE_FIRM_MATCH`, `DEFAULT_PRESET_CORPORATE`, `B2B_ROLLOUT_PERCENTAGE`
- **Algoritmo**: `CONFLICT_TIMEOUT`, `SUCCESS_FEE_MULT`, `DIVERSITY_TAU`
- **Cache**: `ENABLE_SEGMENTED_CACHE`
- **Rollout**: Controle de percentual de usuários com acesso ao B2B

### 📚 Documentação
- **API Documentation**: Exemplos completos de payloads para endpoints B2B
- **Guia de Monitoramento**: Instruções para dashboard e alertas
- **Scripts**: Documentação de backfill e rollback
- **Arquitetura**: Diagramas UML atualizados com relacionamentos

### 🧪 Testes
- **E2E Tests**: 8 cenários completos de fluxo B2B
- **Unit Tests**: Cobertura da Feature-E e algoritmo two-pass
- **Integration Tests**: Validação de API e banco de dados
- **Widget Tests**: Testes de componentes Flutter

### 🛠️ Scripts Operacionais
- **migration_backfill.py**: Migração de dados legados com validação
- **disable_firm_match.sh**: Rollback rápido em caso de problemas
- **Validação**: Verificação de integridade dos dados após migração

### 🔄 Rollout Strategy
- **Fase 1**: Deploy canário em staging
- **Fase 2**: Rollout gradual com feature flags
- **Fase 3**: Monitoramento e expansão
- **Fase 4**: Full rollout após validação

### ⚡ Métricas de Sucesso
- **Latência B2B**: P99 < 200ms
- **Taxa de Sucesso**: > 70% de contratos aceitos na primeira oferta
- **Disponibilidade**: 99.9% uptime dos endpoints B2B
- **Performance**: 88.5% melhoria no tempo de resposta

### 🎯 Próximos Passos
- **Auto-agg KPIs**: Cálculo automático de KPIs a cada 24h
- **Diversity API**: Endpoint para atualização de índice ESG
- **Re-treino de Pesos**: AB-test com gradient descent para otimização

---

## [v2.6.2] - 2024-01-15

### 🔧 Modificado
- Algoritmo de matching otimizado para casos de alta complexidade
- Melhorias na verificação de disponibilidade de advogados
- Atualização das métricas de performance

### 🐛 Corrigido
- Correção de timeout em verificações de conflito
- Fix em cálculo de scores de diversidade
- Resolução de problemas de cache Redis

---

## [v2.6.1] - 2024-01-10

### 🚀 Adicionado
- Sistema de soft skills configurável
- Adaptadores para APIs externas de maturidade profissional
- Logs estruturados JSON para auditoria

### 🔧 Modificado
- Refatoração seguindo princípios de Clean Architecture
- Injeção de dependências no algoritmo de matching
- Melhoria na testabilidade do código

---

## [v2.6.0] - 2024-01-05

### 🚀 Adicionado
- Feature-M (Maturity): Maturidade profissional no algoritmo
- Sistema de fairness multi-dimensional
- Métricas Prometheus avançadas

### 🔧 Modificado
- Algoritmo de matching com 11 features
- Sistema de diversidade aprimorado
- Cache Redis segmentado

---

## [Unreleased]

### 🚀 Planejado
- Sistema de parcerias entre advogados
- Integração com DocuSign para contratos
- Dashboard de analytics para escritórios
- Sistema de recomendações baseado em IA 