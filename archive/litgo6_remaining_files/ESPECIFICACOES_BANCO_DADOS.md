# 🗄️ ESPECIFICAÇÕES DE BANCO DE DADOS
## Melhorias do Perfil do Advogado - LITGO5

---

## 📊 **DIAGRAMA DE RELACIONAMENTOS**

```
profiles (advogados)
    ↓ 1:N
lawyer_accepted_documents ← N:1 → platform_documents
    ↓ 1:N
lawyer_payments ← N:1 → contracts ← N:1 → cases
    ↓ 1:N
reviews → lawyer_response (campo adicional)
```

---

## 🏗️ **MIGRAÇÕES POR FUNCIONALIDADE**

### **MIGRAÇÃO 1: Portal de Documentos**
```sql
-- 20250109000000_platform_documents.sql

-- Tabela de documentos da plataforma (contratos, políticas, etc.)
CREATE TABLE platform_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL CHECK (type IN ('contract', 'policy', 'manual', 'ethics', 'commission')),
    version VARCHAR(20) NOT NULL,
    document_url TEXT NOT NULL,
    file_size BIGINT,
    mime_type VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    requires_acceptance BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- Índices para performance
CREATE INDEX idx_platform_documents_type ON platform_documents(type);
CREATE INDEX idx_platform_documents_active ON platform_documents(is_active) WHERE is_active = true;

-- Tabela de aceites de documentos por advogados
CREATE TABLE lawyer_accepted_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    document_id UUID NOT NULL REFERENCES platform_documents(id) ON DELETE CASCADE,
    accepted_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT,
    acceptance_method VARCHAR(50) DEFAULT 'web', -- 'web', 'mobile', 'api'
    UNIQUE(lawyer_id, document_id)
);

-- Índices para consultas rápidas
CREATE INDEX idx_lawyer_accepted_docs_lawyer ON lawyer_accepted_documents(lawyer_id);
CREATE INDEX idx_lawyer_accepted_docs_document ON lawyer_accepted_documents(document_id);
CREATE INDEX idx_lawyer_accepted_docs_date ON lawyer_accepted_documents(accepted_at);

-- RLS (Row Level Security)
ALTER TABLE platform_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE lawyer_accepted_documents ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Public documents are viewable by lawyers" ON platform_documents
    FOR SELECT USING (
        is_active = true AND 
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND user_type = 'LAWYER')
    );

CREATE POLICY "Lawyers can view their accepted documents" ON lawyer_accepted_documents
    FOR SELECT USING (lawyer_id = auth.uid());

CREATE POLICY "Lawyers can accept documents" ON lawyer_accepted_documents
    FOR INSERT WITH CHECK (lawyer_id = auth.uid());

-- Função para verificar se advogado aceitou documento específico
CREATE OR REPLACE FUNCTION has_lawyer_accepted_document(
    lawyer_uuid UUID, 
    doc_type VARCHAR(50)
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM lawyer_accepted_documents lad
        JOIN platform_documents pd ON lad.document_id = pd.id
        WHERE lad.lawyer_id = lawyer_uuid 
        AND pd.type = doc_type 
        AND pd.is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_platform_documents_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER platform_documents_updated_at
    BEFORE UPDATE ON platform_documents
    FOR EACH ROW
    EXECUTE FUNCTION update_platform_documents_updated_at();
```

### **MIGRAÇÃO 2: Dashboard Financeiro**
```sql
-- 20250109000001_financial_dashboard.sql

-- Tabela de pagamentos para advogados
CREATE TABLE lawyer_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    contract_id UUID REFERENCES contracts(id) ON DELETE SET NULL,
    case_id UUID REFERENCES cases(id) ON DELETE SET NULL,
    
    -- Valores financeiros
    gross_amount DECIMAL(12,2) NOT NULL CHECK (gross_amount >= 0),
    platform_fee_percent DECIMAL(5,2) NOT NULL DEFAULT 10.00,
    platform_fee_amount DECIMAL(12,2) NOT NULL CHECK (platform_fee_amount >= 0),
    net_amount DECIMAL(12,2) NOT NULL CHECK (net_amount >= 0),
    
    -- Tipo e método
    fee_type VARCHAR(20) NOT NULL CHECK (fee_type IN ('fixed', 'success', 'hourly', 'subscription')),
    payment_method VARCHAR(50) DEFAULT 'bank_transfer',
    
    -- Status e datas
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'paid', 'failed', 'cancelled')),
    due_date TIMESTAMPTZ,
    paid_at TIMESTAMPTZ,
    
    -- Referências externas
    transaction_id VARCHAR(255),
    bank_reference VARCHAR(255),
    
    -- Metadados
    description TEXT,
    internal_notes TEXT,
    
    -- Auditoria
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- Índices para performance
CREATE INDEX idx_lawyer_payments_lawyer ON lawyer_payments(lawyer_id);
CREATE INDEX idx_lawyer_payments_status ON lawyer_payments(status);
CREATE INDEX idx_lawyer_payments_paid_date ON lawyer_payments(paid_at) WHERE paid_at IS NOT NULL;
CREATE INDEX idx_lawyer_payments_due_date ON lawyer_payments(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_lawyer_payments_contract ON lawyer_payments(contract_id) WHERE contract_id IS NOT NULL;

-- RLS
ALTER TABLE lawyer_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lawyers can view their payments" ON lawyer_payments
    FOR SELECT USING (lawyer_id = auth.uid());

-- Função para calcular métricas financeiras do advogado
CREATE OR REPLACE FUNCTION get_lawyer_financial_metrics(lawyer_uuid UUID)
RETURNS TABLE (
    current_month_earnings DECIMAL,
    last_month_earnings DECIMAL,
    quarterly_earnings DECIMAL,
    yearly_earnings DECIMAL,
    total_earnings DECIMAL,
    pending_receivables DECIMAL,
    average_monthly_earnings DECIMAL,
    total_cases_paid INTEGER,
    last_payment_date TIMESTAMPTZ
) AS $$
DECLARE
    current_month_start DATE := DATE_TRUNC('month', NOW());
    last_month_start DATE := DATE_TRUNC('month', NOW() - INTERVAL '1 month');
    quarter_start DATE := DATE_TRUNC('quarter', NOW());
    year_start DATE := DATE_TRUNC('year', NOW());
BEGIN
    RETURN QUERY
    SELECT 
        -- Ganhos do mês atual
        COALESCE(SUM(CASE 
            WHEN paid_at >= current_month_start 
            THEN net_amount ELSE 0 END), 0) as current_month_earnings,
        
        -- Ganhos do mês passado
        COALESCE(SUM(CASE 
            WHEN paid_at >= last_month_start 
            AND paid_at < current_month_start
            THEN net_amount ELSE 0 END), 0) as last_month_earnings,
        
        -- Ganhos do trimestre
        COALESCE(SUM(CASE 
            WHEN paid_at >= quarter_start
            THEN net_amount ELSE 0 END), 0) as quarterly_earnings,
        
        -- Ganhos do ano
        COALESCE(SUM(CASE 
            WHEN paid_at >= year_start
            THEN net_amount ELSE 0 END), 0) as yearly_earnings,
        
        -- Total de ganhos
        COALESCE(SUM(CASE 
            WHEN status = 'paid' THEN net_amount ELSE 0 END), 0) as total_earnings,
        
        -- Recebíveis pendentes
        COALESCE(SUM(CASE 
            WHEN status IN ('pending', 'processing') THEN net_amount ELSE 0 END), 0) as pending_receivables,
        
        -- Média mensal (últimos 12 meses)
        COALESCE(SUM(CASE 
            WHEN paid_at >= NOW() - INTERVAL '12 months' 
            AND status = 'paid'
            THEN net_amount ELSE 0 END) / 12, 0) as average_monthly_earnings,
        
        -- Total de casos pagos
        COUNT(CASE WHEN status = 'paid' THEN 1 END)::INTEGER as total_cases_paid,
        
        -- Data do último pagamento
        MAX(CASE WHEN status = 'paid' THEN paid_at END) as last_payment_date
            
    FROM lawyer_payments 
    WHERE lawyer_id = lawyer_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para obter tendência mensal (últimos 12 meses)
CREATE OR REPLACE FUNCTION get_lawyer_monthly_trend(lawyer_uuid UUID)
RETURNS TABLE (
    month_year TEXT,
    total_amount DECIMAL,
    case_count INTEGER,
    avg_amount_per_case DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(DATE_TRUNC('month', paid_at), 'YYYY-MM') as month_year,
        COALESCE(SUM(net_amount), 0) as total_amount,
        COUNT(*)::INTEGER as case_count,
        COALESCE(AVG(net_amount), 0) as avg_amount_per_case
    FROM lawyer_payments
    WHERE lawyer_id = lawyer_uuid
    AND status = 'paid'
    AND paid_at >= NOW() - INTERVAL '12 months'
    GROUP BY DATE_TRUNC('month', paid_at)
    ORDER BY month_year;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para atualizar updated_at
CREATE TRIGGER lawyer_payments_updated_at
    BEFORE UPDATE ON lawyer_payments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### **MIGRAÇÃO 3: Gestão de Disponibilidade**
```sql
-- 20250109000002_lawyer_availability.sql

-- Adicionar colunas de disponibilidade à tabela profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS availability_status VARCHAR(20) DEFAULT 'available' 
    CHECK (availability_status IN ('available', 'busy', 'vacation', 'inactive'));

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS max_concurrent_cases INTEGER DEFAULT 10 
    CHECK (max_concurrent_cases > 0 AND max_concurrent_cases <= 50);

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS auto_pause_at_limit BOOLEAN DEFAULT true;

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS vacation_start TIMESTAMPTZ;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS vacation_end TIMESTAMPTZ;

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS availability_message TEXT;

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_availability_update TIMESTAMPTZ DEFAULT NOW();

-- Índices para consultas de disponibilidade
CREATE INDEX IF NOT EXISTS idx_profiles_availability ON profiles(availability_status) 
    WHERE user_type = 'LAWYER';

CREATE INDEX IF NOT EXISTS idx_profiles_vacation ON profiles(vacation_start, vacation_end) 
    WHERE vacation_start IS NOT NULL;

-- Função para verificar se advogado pode receber novos casos
CREATE OR REPLACE FUNCTION can_lawyer_receive_cases(lawyer_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
    lawyer_status VARCHAR(20);
    max_cases INTEGER;
    current_cases INTEGER;
    vacation_start TIMESTAMPTZ;
    vacation_end TIMESTAMPTZ;
    auto_pause BOOLEAN;
BEGIN
    -- Buscar configurações do advogado
    SELECT 
        availability_status, 
        max_concurrent_cases,
        vacation_start,
        vacation_end,
        auto_pause_at_limit
    INTO 
        lawyer_status, 
        max_cases,
        vacation_start,
        vacation_end,
        auto_pause
    FROM profiles 
    WHERE id = lawyer_uuid AND user_type = 'LAWYER';
    
    -- Se não encontrou o advogado, retorna false
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Verificar status básico
    IF lawyer_status = 'inactive' THEN
        RETURN FALSE;
    END IF;
    
    -- Verificar férias
    IF lawyer_status = 'vacation' AND 
       vacation_start IS NOT NULL AND 
       vacation_end IS NOT NULL AND
       NOW() BETWEEN vacation_start AND vacation_end THEN
        RETURN FALSE;
    END IF;
    
    -- Se status é 'busy', não aceita novos casos
    IF lawyer_status = 'busy' THEN
        RETURN FALSE;
    END IF;
    
    -- Contar casos ativos
    SELECT COUNT(*) INTO current_cases
    FROM cases 
    WHERE lawyer_id = lawyer_uuid 
    AND status IN ('in_progress', 'pending_documents', 'under_review', 'pending_signature');
    
    -- Verificar limite de casos se auto_pause está ativo
    IF auto_pause AND current_cases >= max_cases THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para atualizar automaticamente status baseado em limites
CREATE OR REPLACE FUNCTION auto_update_lawyer_availability()
RETURNS TRIGGER AS $$
DECLARE
    current_cases INTEGER;
    max_cases INTEGER;
    auto_pause BOOLEAN;
BEGIN
    -- Buscar configurações do advogado
    SELECT max_concurrent_cases, auto_pause_at_limit
    INTO max_cases, auto_pause
    FROM profiles 
    WHERE id = NEW.lawyer_id;
    
    -- Se auto_pause não está ativo, não faz nada
    IF NOT auto_pause THEN
        RETURN NEW;
    END IF;
    
    -- Contar casos ativos do advogado
    SELECT COUNT(*) INTO current_cases
    FROM cases 
    WHERE lawyer_id = NEW.lawyer_id 
    AND status IN ('in_progress', 'pending_documents', 'under_review', 'pending_signature');
    
    -- Se atingiu o limite, mudar status para 'busy'
    IF current_cases >= max_cases THEN
        UPDATE profiles 
        SET availability_status = 'busy',
            last_availability_update = NOW()
        WHERE id = NEW.lawyer_id 
        AND availability_status = 'available';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para atualizar disponibilidade automaticamente
CREATE TRIGGER auto_lawyer_availability_update
    AFTER INSERT OR UPDATE OF status ON cases
    FOR EACH ROW
    WHEN (NEW.lawyer_id IS NOT NULL)
    EXECUTE FUNCTION auto_update_lawyer_availability();

-- View para estatísticas de disponibilidade
CREATE OR REPLACE VIEW lawyer_availability_stats AS
SELECT 
    p.id as lawyer_id,
    p.full_name,
    p.availability_status,
    p.max_concurrent_cases,
    COUNT(c.id) as current_active_cases,
    (p.max_concurrent_cases - COUNT(c.id)) as remaining_capacity,
    can_lawyer_receive_cases(p.id) as can_receive_new_cases,
    p.last_availability_update
FROM profiles p
LEFT JOIN cases c ON p.id = c.lawyer_id 
    AND c.status IN ('in_progress', 'pending_documents', 'under_review', 'pending_signature')
WHERE p.user_type = 'LAWYER'
GROUP BY p.id, p.full_name, p.availability_status, p.max_concurrent_cases, p.last_availability_update;
```

### **MIGRAÇÃO 4: Gestão de Reputação**
```sql
-- 20250109000003_review_responses.sql

-- Adicionar colunas para respostas do advogado na tabela reviews
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS lawyer_response TEXT;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS lawyer_responded_at TIMESTAMPTZ;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS response_edited_at TIMESTAMPTZ;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS response_edit_count INTEGER DEFAULT 0;

-- Índice para consultas de respostas
CREATE INDEX IF NOT EXISTS idx_reviews_with_response ON reviews(lawyer_responded_at) 
    WHERE lawyer_response IS NOT NULL;

-- RLS para permitir advogado responder suas avaliações
CREATE POLICY "Lawyers can respond to their reviews" ON reviews
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM cases c 
            WHERE c.id = reviews.case_id 
            AND c.lawyer_id = auth.uid()
        )
        AND (
            lawyer_response IS NULL 
            OR lawyer_responded_at > NOW() - INTERVAL '24 hours'
        )
    );

-- Função para validar resposta do advogado
CREATE OR REPLACE FUNCTION validate_lawyer_response()
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar se o advogado pode responder (é o advogado do caso)
    IF NOT EXISTS (
        SELECT 1 FROM cases c 
        WHERE c.id = NEW.case_id 
        AND c.lawyer_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Apenas o advogado responsável pode responder à avaliação';
    END IF;
    
    -- Se já existe resposta, verificar se ainda pode editar (24h)
    IF OLD.lawyer_response IS NOT NULL AND 
       OLD.lawyer_responded_at < NOW() - INTERVAL '24 hours' THEN
        RAISE EXCEPTION 'Não é possível editar resposta após 24 horas';
    END IF;
    
    -- Limitar tamanho da resposta
    IF LENGTH(NEW.lawyer_response) > 1000 THEN
        RAISE EXCEPTION 'Resposta não pode ter mais que 1000 caracteres';
    END IF;
    
    -- Atualizar timestamps
    IF OLD.lawyer_response IS NULL THEN
        -- Primeira resposta
        NEW.lawyer_responded_at = NOW();
        NEW.response_edit_count = 0;
    ELSE
        -- Editando resposta existente
        NEW.response_edited_at = NOW();
        NEW.response_edit_count = OLD.response_edit_count + 1;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para validar respostas
CREATE TRIGGER validate_review_response
    BEFORE UPDATE OF lawyer_response ON reviews
    FOR EACH ROW
    WHEN (NEW.lawyer_response IS DISTINCT FROM OLD.lawyer_response)
    EXECUTE FUNCTION validate_lawyer_response();

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
        related_id,
        created_at
    ) 
    SELECT 
        c.client_id,
        'review_response',
        'Advogado respondeu sua avaliação',
        'Seu advogado respondeu à avaliação que você fez. Confira a resposta!',
        NEW.id,
        NOW()
    FROM cases c
    WHERE c.id = NEW.case_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para notificação (apenas para novas respostas, não edições)
CREATE TRIGGER review_response_notification
    AFTER UPDATE OF lawyer_response ON reviews
    FOR EACH ROW
    WHEN (OLD.lawyer_response IS NULL AND NEW.lawyer_response IS NOT NULL)
    EXECUTE FUNCTION notify_client_of_response();

-- View para estatísticas de respostas
CREATE OR REPLACE VIEW lawyer_response_stats AS
SELECT 
    p.id as lawyer_id,
    p.full_name,
    COUNT(r.id) as total_reviews,
    COUNT(r.lawyer_response) as total_responses,
    ROUND(
        COUNT(r.lawyer_response)::DECIMAL / NULLIF(COUNT(r.id), 0) * 100, 
        2
    ) as response_rate_percent,
    AVG(r.rating) as average_rating,
    COUNT(CASE WHEN r.lawyer_response IS NOT NULL THEN r.rating END) as avg_rating_with_response
FROM profiles p
LEFT JOIN cases c ON p.id = c.lawyer_id
LEFT JOIN reviews r ON c.id = r.case_id
WHERE p.user_type = 'LAWYER'
GROUP BY p.id, p.full_name;
```

---

## 🔍 **CONSULTAS ÚTEIS PARA MONITORAMENTO**

### **Documentos mais acessados:**
```sql
SELECT 
    pd.title,
    pd.type,
    COUNT(lad.id) as acceptance_count,
    MAX(lad.accepted_at) as last_acceptance
FROM platform_documents pd
LEFT JOIN lawyer_accepted_documents lad ON pd.id = lad.document_id
WHERE pd.is_active = true
GROUP BY pd.id, pd.title, pd.type
ORDER BY acceptance_count DESC;
```

### **Top advogados por faturamento:**
```sql
SELECT 
    p.full_name,
    COUNT(lp.id) as total_payments,
    SUM(lp.net_amount) as total_earnings,
    AVG(lp.net_amount) as avg_payment
FROM profiles p
JOIN lawyer_payments lp ON p.id = lp.lawyer_id
WHERE lp.status = 'paid'
AND lp.paid_at >= NOW() - INTERVAL '30 days'
GROUP BY p.id, p.full_name
ORDER BY total_earnings DESC
LIMIT 10;
```

### **Advogados com maior taxa de resposta:**
```sql
SELECT 
    lawyer_id,
    full_name,
    total_reviews,
    total_responses,
    response_rate_percent,
    average_rating
FROM lawyer_response_stats
WHERE total_reviews >= 5
ORDER BY response_rate_percent DESC, average_rating DESC
LIMIT 20;
```

---

**Especificações v1.0**  
**Janeiro 2025 - LITGO5** 