# 🚀 ROADMAP DE MELHORIAS - PERFIL DO ADVOGADO
## LITGO5 - Plano de Desenvolvimento Q1 2025

---

## 📋 **VISÃO GERAL**

Este documento detalha o plano de implementação de 4 funcionalidades estratégicas para enriquecer a experiência do advogado na plataforma LITGO5, aumentando retenção, satisfação e produtividade.

### **Funcionalidades Planejadas:**
1. 📄 **Portal de Documentos da Plataforma**
2. 💰 **Dashboard Financeiro Detalhado**  
3. ⏰ **Gestão de Disponibilidade e Foco**
4. ⭐ **Gestão de Reputação Ativa**

### **Cronograma Geral:**
- **Sprint 1-2:** Portal de Documentos (2 semanas)
- **Sprint 3-4:** Dashboard Financeiro (2 semanas)
- **Sprint 5:** Gestão de Disponibilidade (1 semana)
- **Sprint 6:** Gestão de Reputação (1 semana)

**Total:** 6 sprints / 8 semanas

---

## 🏃‍♂️ **SPRINT 1-2: PORTAL DE DOCUMENTOS DA PLATAFORMA**

### **Objetivo:**
Criar uma área onde o advogado pode consultar permanentemente todos os documentos relacionados ao seu relacionamento com a plataforma.

### **User Stories:**
- **Como advogado**, quero acessar meu contrato de associação a qualquer momento para consultar termos e condições
- **Como advogado**, quero visualizar a política de comissionamento atual para entender minha remuneração
- **Como advogado**, quero ter acesso ao código de ética e manuais de uso da plataforma

### **Especificações Técnicas:**

#### **Frontend (React Native)**
```typescript
// Nova tela: app/(tabs)/profile/platform-documents.tsx
interface PlatformDocument {
  id: string;
  title: string;
  description: string;
  type: 'contract' | 'policy' | 'manual' | 'ethics';
  version: string;
  accepted_at: string;
  document_url: string;
  is_current: boolean;
}
```

#### **Backend (FastAPI)**
```python
# Novo endpoint: backend/routes/lawyer_documents.py
@router.get("/lawyer/documents")
async def get_lawyer_documents(
    current_user: User = Depends(get_current_user)
):
    """Retorna documentos da plataforma aceitos pelo advogado"""
    
# Novo endpoint: backend/routes/lawyer_documents.py  
@router.get("/lawyer/documents/{document_id}/download")
async def download_document(
    document_id: str,
    current_user: User = Depends(get_current_user)
):
    """Download seguro de documento específico"""
```

#### **Banco de Dados**
```sql
-- Nova tabela: platform_documents
CREATE TABLE platform_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL, -- 'contract', 'policy', 'manual', 'ethics'
    version VARCHAR(20) NOT NULL,
    document_url TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Nova tabela: lawyer_accepted_documents
CREATE TABLE lawyer_accepted_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID REFERENCES profiles(id),
    document_id UUID REFERENCES platform_documents(id),
    accepted_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT,
    UNIQUE(lawyer_id, document_id)
);
```

### **Tarefas Detalhadas:**

#### **Sprint 1 (Semana 1):**
- [ ] **Dia 1-2:** Criar migração de banco de dados
- [ ] **Dia 3:** Implementar endpoints backend
- [ ] **Dia 4:** Criar serviço de documentos no frontend
- [ ] **Dia 5:** Estrutura básica da tela de documentos

#### **Sprint 2 (Semana 2):**
- [ ] **Dia 1-2:** Interface completa da tela de documentos
- [ ] **Dia 3:** Implementar download seguro de PDFs
- [ ] **Dia 4:** Adicionar item no menu do perfil do advogado
- [ ] **Dia 5:** Testes e ajustes finais

### **Critérios de Aceitação:**
- ✅ Advogado pode visualizar lista de documentos aceitos
- ✅ Download de PDFs funciona corretamente
- ✅ Histórico de versões é mantido
- ✅ Interface é intuitiva e responsiva

---

## 💰 **SPRINT 3-4: DASHBOARD FINANCEIRO DETALHADO**

### **Objetivo:**
Transformar a tela "Meu Desempenho" em um dashboard financeiro completo com métricas de faturamento, extratos e previsões.

### **User Stories:**
- **Como advogado**, quero ver meu faturamento mensal/trimestral para acompanhar minha evolução
- **Como advogado**, quero um extrato detalhado de todos os repasses recebidos
- **Como advogado**, quero previsão de recebíveis de contratos de êxito

### **Especificações Técnicas:**

#### **Frontend (React Native)**
```typescript
// Expandir: app/(tabs)/profile/performance.tsx
interface FinancialDashboard {
  current_month_earnings: number;
  last_month_earnings: number;
  quarterly_earnings: number;
  total_earnings: number;
  pending_receivables: number;
  payment_history: PaymentRecord[];
  earnings_by_type: EarningsByType;
  monthly_trend: MonthlyTrend[];
}

interface PaymentRecord {
  id: string;
  case_id: string;
  case_title: string;
  amount: number;
  fee_type: 'fixed' | 'success' | 'hourly';
  paid_at: string;
  status: 'paid' | 'pending' | 'processing';
}
```

#### **Backend (FastAPI)**
```python
# Expandir: backend/routes/lawyers.py
@router.get("/lawyer/financial-dashboard")
async def get_financial_dashboard(
    current_user: User = Depends(get_current_user)
):
    """Dashboard financeiro completo do advogado"""

@router.get("/lawyer/payment-history")
async def get_payment_history(
    page: int = 1,
    limit: int = 20,
    current_user: User = Depends(get_current_user)
):
    """Histórico paginado de pagamentos"""
```

#### **Banco de Dados**
```sql
-- Nova tabela: lawyer_payments
CREATE TABLE lawyer_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID REFERENCES profiles(id),
    contract_id UUID REFERENCES contracts(id),
    case_id UUID REFERENCES cases(id),
    amount DECIMAL(10,2) NOT NULL,
    fee_type VARCHAR(20) NOT NULL, -- 'fixed', 'success', 'hourly'
    gross_amount DECIMAL(10,2),
    platform_fee DECIMAL(10,2),
    net_amount DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'processing', 'paid', 'failed'
    paid_at TIMESTAMPTZ,
    payment_method VARCHAR(50),
    transaction_id VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Função para calcular métricas financeiras
CREATE OR REPLACE FUNCTION get_lawyer_financial_metrics(lawyer_uuid UUID)
RETURNS TABLE (
    current_month_earnings DECIMAL,
    last_month_earnings DECIMAL,
    quarterly_earnings DECIMAL,
    total_earnings DECIMAL,
    pending_receivables DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        -- Ganhos do mês atual
        COALESCE(SUM(CASE 
            WHEN EXTRACT(MONTH FROM paid_at) = EXTRACT(MONTH FROM NOW()) 
            AND EXTRACT(YEAR FROM paid_at) = EXTRACT(YEAR FROM NOW())
            THEN net_amount ELSE 0 END), 0) as current_month_earnings,
        
        -- Ganhos do mês passado
        COALESCE(SUM(CASE 
            WHEN paid_at >= DATE_TRUNC('month', NOW() - INTERVAL '1 month')
            AND paid_at < DATE_TRUNC('month', NOW())
            THEN net_amount ELSE 0 END), 0) as last_month_earnings,
        
        -- Ganhos do trimestre
        COALESCE(SUM(CASE 
            WHEN paid_at >= DATE_TRUNC('quarter', NOW())
            THEN net_amount ELSE 0 END), 0) as quarterly_earnings,
        
        -- Total de ganhos
        COALESCE(SUM(CASE 
            WHEN status = 'paid' THEN net_amount ELSE 0 END), 0) as total_earnings,
        
        -- Recebíveis pendentes
        COALESCE(SUM(CASE 
            WHEN status = 'pending' THEN net_amount ELSE 0 END), 0) as pending_receivables
            
    FROM lawyer_payments 
    WHERE lawyer_id = lawyer_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### **Tarefas Detalhadas:**

#### **Sprint 3 (Semana 3):**
- [ ] **Dia 1:** Criar migração e função de métricas financeiras
- [ ] **Dia 2-3:** Implementar endpoints de dashboard financeiro
- [ ] **Dia 4:** Criar componentes de gráficos (react-native-chart-kit)
- [ ] **Dia 5:** Interface básica do dashboard

#### **Sprint 4 (Semana 4):**
- [ ] **Dia 1-2:** Implementar extrato de pagamentos
- [ ] **Dia 3:** Adicionar filtros e paginação
- [ ] **Dia 4:** Gráficos de tendência e métricas
- [ ] **Dia 5:** Testes e otimizações

### **Critérios de Aceitação:**
- ✅ Dashboard mostra métricas financeiras em tempo real
- ✅ Extrato de pagamentos é detalhado e navegável
- ✅ Gráficos são informativos e responsivos
- ✅ Performance é adequada mesmo com muitos dados

---

## ⏰ **SPRINT 5: GESTÃO DE DISPONIBILIDADE E FOCO**

### **Objetivo:**
Permitir que o advogado configure sua disponibilidade e limite de casos simultâneos, melhorando qualidade do serviço.

### **User Stories:**
- **Como advogado**, quero definir meu status de disponibilidade para controlar novos casos
- **Como advogado**, quero configurar um limite máximo de casos simultâneos
- **Como sistema**, quero respeitar essas configurações no algoritmo de match

### **Especificações Técnicas:**

#### **Frontend (React Native)**
```typescript
// Nova tela: app/(tabs)/profile/availability-settings.tsx
interface AvailabilitySettings {
  status: 'available' | 'busy' | 'vacation' | 'inactive';
  max_concurrent_cases: number;
  current_active_cases: number;
  auto_pause_at_limit: boolean;
  vacation_start?: string;
  vacation_end?: string;
  custom_message?: string;
}
```

#### **Backend (FastAPI)**
```python
# Expandir: backend/routes/lawyers.py
@router.put("/lawyer/availability")
async def update_availability(
    settings: AvailabilitySettings,
    current_user: User = Depends(get_current_user)
):
    """Atualiza configurações de disponibilidade do advogado"""

@router.get("/lawyer/availability")
async def get_availability(
    current_user: User = Depends(get_current_user)
):
    """Retorna configurações atuais de disponibilidade"""
```

#### **Banco de Dados**
```sql
-- Adicionar colunas à tabela profiles
ALTER TABLE profiles ADD COLUMN availability_status VARCHAR(20) DEFAULT 'available';
ALTER TABLE profiles ADD COLUMN max_concurrent_cases INTEGER DEFAULT 10;
ALTER TABLE profiles ADD COLUMN auto_pause_at_limit BOOLEAN DEFAULT true;
ALTER TABLE profiles ADD COLUMN vacation_start TIMESTAMPTZ;
ALTER TABLE profiles ADD COLUMN vacation_end TIMESTAMPTZ;
ALTER TABLE profiles ADD COLUMN availability_message TEXT;

-- Função para verificar se advogado pode receber novos casos
CREATE OR REPLACE FUNCTION can_lawyer_receive_cases(lawyer_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
    lawyer_status VARCHAR(20);
    max_cases INTEGER;
    current_cases INTEGER;
    vacation_start TIMESTAMPTZ;
    vacation_end TIMESTAMPTZ;
BEGIN
    -- Buscar configurações do advogado
    SELECT 
        availability_status, 
        max_concurrent_cases,
        vacation_start,
        vacation_end
    INTO 
        lawyer_status, 
        max_cases,
        vacation_start,
        vacation_end
    FROM profiles 
    WHERE id = lawyer_uuid;
    
    -- Verificar status básico
    IF lawyer_status = 'inactive' THEN
        RETURN FALSE;
    END IF;
    
    -- Verificar férias
    IF lawyer_status = 'vacation' AND 
       NOW() BETWEEN vacation_start AND vacation_end THEN
        RETURN FALSE;
    END IF;
    
    -- Contar casos ativos
    SELECT COUNT(*) INTO current_cases
    FROM cases 
    WHERE lawyer_id = lawyer_uuid 
    AND status IN ('in_progress', 'pending_documents', 'under_review');
    
    -- Verificar limite de casos
    IF current_cases >= max_cases THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### **Tarefas Detalhadas:**

#### **Sprint 5 (Semana 5):**
- [ ] **Dia 1:** Migração de banco e função de disponibilidade
- [ ] **Dia 2:** Endpoints de configuração de disponibilidade
- [ ] **Dia 3:** Interface de configurações de disponibilidade
- [ ] **Dia 4:** Integração com algoritmo de match
- [ ] **Dia 5:** Testes e validações

### **Critérios de Aceitação:**
- ✅ Advogado pode configurar status e limites
- ✅ Sistema respeita configurações no match
- ✅ Interface é clara e intuitiva
- ✅ Algoritmo funciona corretamente com novos filtros

---

## ⭐ **SPRINT 6: GESTÃO DE REPUTAÇÃO ATIVA**

### **Objetivo:**
Permitir que advogados respondam às avaliações dos clientes, demonstrando engajamento e profissionalismo.

### **User Stories:**
- **Como advogado**, quero responder às avaliações dos meus clientes
- **Como cliente**, quero ver as respostas do advogado às avaliações
- **Como visitante**, quero ver o diálogo entre cliente e advogado nas avaliações

### **Especificações Técnicas:**

#### **Frontend (React Native)**
```typescript
// Expandir: components/molecules/ReviewCard.tsx
interface ReviewWithResponse {
  id: string;
  rating: number;
  comment: string;
  client_name: string;
  created_at: string;
  lawyer_response?: {
    message: string;
    responded_at: string;
  };
  can_respond: boolean;
}
```

#### **Backend (FastAPI)**
```python
# Expandir: backend/routes/reviews.py
@router.post("/reviews/{review_id}/respond")
async def respond_to_review(
    review_id: str,
    response: ReviewResponse,
    current_user: User = Depends(get_current_user)
):
    """Advogado responde a uma avaliação"""

@router.put("/reviews/{review_id}/response")
async def update_review_response(
    review_id: str,
    response: ReviewResponse,
    current_user: User = Depends(get_current_user)
):
    """Advogado edita sua resposta (até 24h após criação)"""
```

#### **Banco de Dados**
```sql
-- Adicionar colunas à tabela reviews
ALTER TABLE reviews ADD COLUMN lawyer_response TEXT;
ALTER TABLE reviews ADD COLUMN lawyer_responded_at TIMESTAMPTZ;
ALTER TABLE reviews ADD COLUMN response_edited_at TIMESTAMPTZ;

-- Política para permitir advogado responder suas próprias avaliações
CREATE POLICY "Lawyers can respond to their reviews" ON reviews
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM cases c 
            WHERE c.id = reviews.case_id 
            AND c.lawyer_id = auth.uid()
        )
    );

-- Função para notificar cliente sobre resposta
CREATE OR REPLACE FUNCTION notify_client_of_response()
RETURNS TRIGGER AS $$
BEGIN
    -- Inserir notificação para o cliente
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        related_id
    ) 
    SELECT 
        c.client_id,
        'review_response',
        'Advogado respondeu sua avaliação',
        'Seu advogado respondeu à avaliação que você fez. Confira a resposta!',
        NEW.id
    FROM cases c
    WHERE c.id = NEW.case_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER review_response_notification
    AFTER UPDATE OF lawyer_response ON reviews
    FOR EACH ROW
    WHEN (OLD.lawyer_response IS NULL AND NEW.lawyer_response IS NOT NULL)
    EXECUTE FUNCTION notify_client_of_response();
```

### **Tarefas Detalhadas:**

#### **Sprint 6 (Semana 6):**
- [ ] **Dia 1:** Migração de banco e trigger de notificação
- [ ] **Dia 2:** Endpoints de resposta a avaliações
- [ ] **Dia 3:** Interface para responder avaliações
- [ ] **Dia 4:** Exibição de respostas nas telas de avaliação
- [ ] **Dia 5:** Testes e ajustes finais

### **Critérios de Aceitação:**
- ✅ Advogado pode responder avaliações
- ✅ Respostas são exibidas adequadamente
- ✅ Cliente é notificado sobre respostas
- ✅ Interface mantém bom UX

---

## 📊 **MÉTRICAS DE SUCESSO**

### **KPIs por Funcionalidade:**

#### **Portal de Documentos:**
- **Adoção:** 80% dos advogados acessam pelo menos 1x por mês
- **Satisfação:** NPS > 8 na pesquisa de usabilidade
- **Suporte:** Redução de 40% em tickets sobre "termos do contrato"

#### **Dashboard Financeiro:**
- **Engajamento:** Tempo médio na tela > 3 minutos
- **Frequência:** 60% dos advogados acessam semanalmente
- **Conversão:** Aumento de 20% na retenção de advogados

#### **Gestão de Disponibilidade:**
- **Qualidade:** Aumento de 15% na nota média dos advogados
- **Eficiência:** Redução de 25% em casos abandonados
- **Satisfação:** Melhoria no NPS dos advogados

#### **Gestão de Reputação:**
- **Participação:** 40% das avaliações recebem resposta
- **Impacto:** Aumento de 10% na nota média após implementação
- **Engajamento:** Melhoria na percepção de profissionalismo

---

## 🛠️ **CONSIDERAÇÕES TÉCNICAS**

### **Dependências:**
- **react-native-chart-kit:** Para gráficos financeiros
- **react-native-pdf:** Para visualização de documentos
- **expo-document-picker:** Para uploads de documentos

### **Infraestrutura:**
- **Supabase Storage:** Para armazenar documentos da plataforma
- **Redis:** Para cache de métricas financeiras
- **Webhooks:** Para notificações em tempo real

### **Segurança:**
- **Criptografia:** Documentos sensíveis criptografados
- **Auditoria:** Log de todos os acessos a documentos
- **Permissões:** RLS rigoroso para dados financeiros

---

## 🎯 **PRÓXIMOS PASSOS**

1. **Aprovação do Roadmap:** Validar prioridades com stakeholders
2. **Setup do Ambiente:** Configurar branches e ambientes de desenvolvimento
3. **Kick-off Sprint 1:** Iniciar desenvolvimento do Portal de Documentos
4. **Monitoramento:** Acompanhar métricas e ajustar conforme necessário

---

**Documento criado em:** Janeiro 2025  
**Versão:** 1.0  
**Responsável:** Equipe de Desenvolvimento LITGO5  
**Próxima Revisão:** Março 2025 