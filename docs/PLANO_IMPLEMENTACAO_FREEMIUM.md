# 🚀 Plano de Implementação do Modelo Freemium - LITIG-1

## 📊 Análise do Código Atual

### 1. Estrutura de Autenticação Existente
- **Modelo de usuário** já possui sistema de roles e permissions flexível
- **Roles atuais**: client, lawyer, admin
- **User roles específicos**: lawyer_individual, lawyer_office, lawyer_associated, lawyer_platform_associate
- **Sistema de permissões** granular já implementado via `profile_permissions`

### 2. Infraestrutura de Tiers Identificada
- **Tabela `lawyer_tiers`** já existe com níveis: junior, pleno, senior, especialista
- Sistema de precificação por tier implementado
- Funções PostgreSQL para gerenciamento de tiers

### 3. Funcionalidades Premium Identificadas

#### 🏆 Candidatas Fortes para Premium:
1. **Sistema de Parcerias B2B** (`/partnerships/*`)
   - Criação de propostas de parceria
   - Geração automática de contratos
   - Analytics de parcerias
   - Histórico de colaborações

2. **Busca Avançada e Contextual** (`/search-contextual/*`)
   - Analytics de alocação
   - Processamento em lote
   - Presets de busca personalizados

3. **Integração Social (Unipile)** (`/unipile/*`)
   - Conexão com LinkedIn, Instagram, Facebook
   - Sincronização de perfil profissional
   - Monitoramento de presença digital

4. **Sistema de Chat em Tempo Real** (`/chat/*`)
   - WebSocket para comunicação instantânea
   - Salas privadas
   - Indicadores de leitura

5. **Videoconferência Integrada** (`/video-calls/*`)
   - Consultas por vídeo
   - Gravação de sessões (potencial)

6. **Dashboard Administrativo** (`/admin/*`)
   - Analytics avançado
   - Relatórios executivos
   - Monitoramento em tempo real

## 💼 Estratégia de Segmentação Proposta

### 🆓 Plano Gratuito (Essential)
**Para Advogados:**
- ✅ Cadastro e perfil básico
- ✅ Ser listado nas buscas
- ✅ Receber ofertas de casos
- ✅ Gestão de casos ativos
- ✅ Chat básico com clientes de casos ativos
- ✅ Dashboard pessoal simples

**Para Clientes:**
- ✅ Sempre gratuito
- ✅ Acesso completo à plataforma

### 💎 Plano Premium (Pro)
**Valor sugerido:** R$ 199/mês

**Funcionalidades Exclusivas:**
1. **🤝 Sistema Completo de Parcerias B2B**
   - Buscar e conectar com outros advogados
   - Propostas formais de parceria
   - Geração automática de contratos

2. **🔍 Busca Avançada de Parceiros**
   - Filtros especializados
   - Presets de busca salvos
   - Analytics de busca

3. **📱 Integração Social Profissional**
   - Conectar LinkedIn, Instagram
   - Enriquecimento automático do perfil
   - Social score melhorado

4. **📊 Analytics e Dashboards Avançados**
   - Métricas detalhadas de performance
   - Relatórios exportáveis
   - Insights de mercado

5. **⭐ Destaque no Ranking**
   - Boost no algoritmo de matchmaking
   - Badge "Pro" no perfil
   - Prioridade em recomendações

6. **🎯 Acesso Prioritário**
   - Casos de alto valor primeiro
   - Suporte prioritário
   - Features beta

## 🛠️ Implementação Técnica

### 1. Modelo de Dados

#### Adição ao User Entity:
```dart
// user.dart
class User extends Equatable {
  // ... campos existentes
  final String? subscriptionPlan; // 'free' | 'premium'
  final DateTime? subscriptionExpiresAt;
  final bool get isPremium => subscriptionPlan == 'premium' && 
    (subscriptionExpiresAt?.isAfter(DateTime.now()) ?? false);
}
```

#### Migration SQL:
```sql
-- 20250201_add_subscription_fields.sql
ALTER TABLE profiles
ADD COLUMN subscription_plan TEXT DEFAULT 'free' 
  CHECK (subscription_plan IN ('free', 'premium')),
ADD COLUMN subscription_expires_at TIMESTAMPTZ,
ADD COLUMN subscription_started_at TIMESTAMPTZ;

-- Índices para queries de subscription
CREATE INDEX idx_profiles_subscription_plan ON profiles(subscription_plan);
CREATE INDEX idx_profiles_subscription_expires ON profiles(subscription_expires_at);
```

### 2. Backend - Middleware de Verificação

```python
# auth/dependencies.py
async def require_premium(current_user: dict = Depends(get_current_user)):
    """Middleware para endpoints premium"""
    if current_user.get("subscription_plan") != "premium":
        raise HTTPException(
            status_code=403,
            detail="Esta funcionalidade requer assinatura Premium"
        )
    
    expires_at = current_user.get("subscription_expires_at")
    if expires_at and datetime.fromisoformat(expires_at) < datetime.utcnow():
        raise HTTPException(
            status_code=403,
            detail="Sua assinatura Premium expirou"
        )
    
    return current_user

# Aplicação em rotas premium
@router.post("/partnerships/", dependencies=[Depends(require_premium)])
async def create_partnership(...):
    ...
```

### 3. Frontend - Componentes de UI

#### Widget de Bloqueio Premium:
```dart
// premium_feature_lock.dart
class PremiumFeatureLock extends StatelessWidget {
  final Widget child;
  final bool isLocked;
  final String featureName;
  
  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;
    
    return Stack(
      children: [
        Opacity(opacity: 0.3, child: child),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black12, Colors.black26],
              ),
            ),
            child: Center(
              child: Card(
                color: Theme.of(context).primaryColor,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Funcionalidade Premium',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        featureName,
                        style: TextStyle(color: Colors.white70),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showUpgradeModal(context),
                        child: Text('Fazer Upgrade'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

#### Badge Premium em Cards:
```dart
// lawyer_match_card.dart - Adição do badge
if (lawyer.isPremium) 
  Positioned(
    top: 8,
    right: 8,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber, Colors.orange],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text('PRO', style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          )),
        ],
      ),
    ),
  ),
```

### 4. Navegação Condicional

```dart
// main_tabs_shell.dart - Modificação
Widget build(BuildContext context) {
  final user = context.watch<AuthBloc>().state.user;
  final isPremium = user?.isPremium ?? false;
  
  // Tabs condicionais
  if (tabInfo.requiresPremium && !isPremium) {
    destinations.add(
      NavigationDestination(
        icon: Stack(
          children: [
            Icon(tabInfo.icon, color: Colors.grey),
            Positioned(
              top: 0,
              right: 0,
              child: Icon(Icons.lock, size: 12, color: Colors.grey),
            ),
          ],
        ),
        label: tabInfo.label,
      ),
    );
  }
}
```

## 📋 Roadmap de Implementação

### Fase 1: Infraestrutura Base (1 semana)
- [ ] Adicionar campos de subscription ao banco
- [ ] Implementar middleware de verificação premium
- [ ] Criar serviço de gerenciamento de assinaturas
- [ ] Adicionar campo isPremium ao User entity

### Fase 2: UI/UX Premium (1 semana)
- [ ] Implementar PremiumFeatureLock widget
- [ ] Adicionar badges PRO aos cards
- [ ] Criar modal de upgrade
- [ ] Implementar navegação condicional

### Fase 3: Integração de Features (2 semanas)
- [ ] Proteger rotas de parcerias com middleware premium
- [ ] Limitar busca avançada para premium
- [ ] Implementar boost no ranking para premium
- [ ] Adicionar integração social apenas para premium

### Fase 4: Pagamento e Billing (1 semana)
- [ ] Integrar gateway de pagamento (Stripe/PagSeguro)
- [ ] Criar fluxo de assinatura
- [ ] Implementar renovação automática
- [ ] Adicionar gestão de assinatura no perfil

### Fase 5: Analytics e Monitoramento (1 semana)
- [ ] Dashboard de conversão free->premium
- [ ] Métricas de uso de features premium
- [ ] A/B testing de preços
- [ ] Relatórios de churn

## 🎯 KPIs de Sucesso

1. **Taxa de Conversão Free->Premium**: Meta 15%
2. **Churn Rate Mensal**: < 5%
3. **ARPU (Average Revenue Per User)**: R$ 150+
4. **Engagement Premium Features**: 80% dos premium usando features exclusivas
5. **NPS Premium Users**: > 50

## 💡 Recomendações Adicionais

1. **Trial Period**: Oferecer 7 dias grátis do Premium
2. **Preço Promocional**: Lançamento com 50% de desconto por 3 meses
3. **Referral Program**: Desconto para quem indica novos premium
4. **Bundle Escritórios**: Planos especiais para escritórios com múltiplos advogados
5. **Gamification**: Badges e achievements exclusivos para premium

## 🚨 Considerações Importantes

1. **Não bloquear features core**: Manter matching básico gratuito
2. **Comunicação clara**: Deixar evidente o que é premium desde o início
3. **Granularidade**: Permitir compra de features individuais no futuro
4. **Feedback Loop**: Coletar feedback constante dos usuários premium
5. **Suporte Premium**: Canal dedicado para assinantes