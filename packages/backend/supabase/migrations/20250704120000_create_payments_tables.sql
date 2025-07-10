-- Tabela de Faturas (Invoices)
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    case_id UUID REFERENCES cases(id),
    status TEXT NOT NULL DEFAULT 'pending', -- pending, paid, overdue, cancelled
    amount_cents INTEGER NOT NULL,
    description TEXT,
    due_date TIMESTAMPTZ,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN invoices.status IS 'Status da fatura: pendente, paga, vencida, cancelada';
COMMENT ON COLUMN invoices.amount_cents IS 'Valor em centavos para evitar problemas de ponto flutuante';

-- Tabela de Transações
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    invoice_id UUID REFERENCES invoices(id),
    amount_cents INTEGER NOT NULL,
    type TEXT NOT NULL, -- payment, refund, credit
    gateway TEXT, -- stripe, manual, etc.
    gateway_transaction_id TEXT,
    status TEXT NOT NULL, -- succeeded, failed, pending
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN transactions.type IS 'Tipo de transação: pagamento, reembolso, crédito';
COMMENT ON COLUMN transactions.status IS 'Status da transação no gateway de pagamento';

-- Tabela de Métodos de Pagamento
CREATE TABLE IF NOT EXISTS payment_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    type TEXT NOT NULL, -- credit_card
    brand TEXT, -- Visa, Mastercard
    last4 TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    gateway_customer_id TEXT,
    gateway_method_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE payment_methods IS 'Armazena informações de métodos de pagamento dos usuários de forma segura (tokens, não dados sensíveis)';

-- Índices para otimização de consultas
CREATE INDEX IF NOT EXISTS idx_invoices_user_id ON invoices(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON payment_methods(user_id); 