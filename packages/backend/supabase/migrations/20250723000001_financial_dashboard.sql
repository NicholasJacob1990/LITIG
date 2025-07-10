-- Tabela de pagamentos para advogados
CREATE TABLE IF NOT EXISTS public.lawyer_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL,
    case_id UUID REFERENCES public.cases(id) ON DELETE SET NULL,
    gross_amount DECIMAL(12,2) NOT NULL CHECK (gross_amount >= 0),
    platform_fee_percent DECIMAL(5,2) NOT NULL DEFAULT 10.00,
    platform_fee_amount DECIMAL(12,2) NOT NULL CHECK (platform_fee_amount >= 0),
    net_amount DECIMAL(12,2) NOT NULL CHECK (net_amount >= 0),
    fee_type VARCHAR(20) NOT NULL CHECK (fee_type IN ('fixed', 'success', 'hourly', 'subscription')),
    payment_method VARCHAR(50) DEFAULT 'bank_transfer',
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'paid', 'failed', 'cancelled')),
    due_date TIMESTAMPTZ,
    paid_at TIMESTAMPTZ,
    transaction_id VARCHAR(255),
    bank_reference VARCHAR(255),
    description TEXT,
    internal_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

COMMENT ON TABLE public.lawyer_payments IS 'Registra os pagamentos a serem efetuados aos advogados pela plataforma.';

-- Tabela de faturas para clientes
CREATE TABLE IF NOT EXISTS public.client_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    case_id UUID REFERENCES public.cases(id),
    total_amount DECIMAL(12, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled')),
    issue_date TIMESTAMPTZ DEFAULT NOW(),
    due_date TIMESTAMPTZ,
    paid_at TIMESTAMPTZ,
    payment_link VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.client_invoices IS 'Faturas geradas para os clientes pelos serviços prestados.';

-- Trigger para atualizar `updated_at`
CREATE OR REPLACE TRIGGER set_lawyer_payments_updated_at
BEFORE UPDATE ON public.lawyer_payments
FOR EACH ROW
EXECUTE FUNCTION public.moddatetime (updated_at);

CREATE OR REPLACE TRIGGER set_client_invoices_updated_at
BEFORE UPDATE ON public.client_invoices
FOR EACH ROW
EXECUTE FUNCTION public.moddatetime (updated_at); 