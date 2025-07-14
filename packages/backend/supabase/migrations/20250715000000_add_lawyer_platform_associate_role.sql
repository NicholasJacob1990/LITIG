-- Migration: Add lawyer_platform_associate role
-- Timestamp: 20250715000000
-- Description: Adiciona o novo role lawyer_platform_associate para Super Associados

-- Verificar se a tabela profiles existe e tem a coluna role
DO $$
BEGIN
    -- Verificar se a tabela profiles existe
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles' AND table_schema = 'public') THEN
        -- Verificar se a coluna role existe
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'role' AND table_schema = 'public') THEN
            -- Modificar a constraint CHECK para incluir o novo role
            ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
            ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check 
                CHECK (role IN ('client', 'lawyer', 'admin', 'lawyer_individual', 'lawyer_office', 'lawyer_associated', 'lawyer_platform_associate'));
        END IF;
    END IF;
END $$;

-- Adicionar coluna para identificar Super Associados na tabela lawyers se não existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lawyers' AND column_name = 'is_platform_associate' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.lawyers ADD COLUMN is_platform_associate BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- Adicionar coluna para contratos de associação se não existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lawyers' AND column_name = 'contract_required' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.lawyers ADD COLUMN contract_required BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- Adicionar coluna para status do contrato se não existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lawyers' AND column_name = 'contract_signed' AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.lawyers ADD COLUMN contract_signed BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_lawyers_is_platform_associate ON public.lawyers(is_platform_associate);
CREATE INDEX IF NOT EXISTS idx_lawyers_contract_required ON public.lawyers(contract_required);

-- Comentários para documentação
COMMENT ON COLUMN public.lawyers.is_platform_associate IS 'Indica se o advogado é Super Associado (associado do escritório titular LITGO)';
COMMENT ON COLUMN public.lawyers.contract_required IS 'Indica se o advogado precisa assinar contrato de associação';
COMMENT ON COLUMN public.lawyers.contract_signed IS 'Indica se o contrato de associação foi assinado';

-- Função para verificar se um advogado é Super Associado
CREATE OR REPLACE FUNCTION is_super_associate(lawyer_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (
        SELECT COALESCE(is_platform_associate, FALSE)
        FROM public.lawyers
        WHERE id = lawyer_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para buscar advogados elegíveis incluindo Super Associados
CREATE OR REPLACE FUNCTION get_eligible_lawyers_with_super_associates(
    legal_areas TEXT[],
    exclude_ids UUID[] DEFAULT '{}'::UUID[]
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    oab_number TEXT,
    primary_area TEXT,
    specialties TEXT[],
    is_available BOOLEAN,
    rating NUMERIC,
    is_platform_associate BOOLEAN,
    contract_signed BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.id,
        l.name,
        l.oab_number,
        l.primary_area,
        l.specialties,
        l.is_available,
        l.rating,
        COALESCE(l.is_platform_associate, FALSE) as is_platform_associate,
        COALESCE(l.contract_signed, FALSE) as contract_signed
    FROM public.lawyers l
    JOIN public.profiles p ON l.id = p.id
    WHERE 
        l.is_available = TRUE
        AND l.id != ALL(exclude_ids)
        AND (
            -- Advogados tradicionais
            p.role IN ('lawyer_individual', 'lawyer_office', 'lawyer_associated')
            OR 
            -- Super Associados com contrato assinado
            (p.role = 'lawyer_platform_associate' AND COALESCE(l.contract_signed, FALSE) = TRUE)
        )
        AND (
            legal_areas IS NULL 
            OR l.specialties && legal_areas 
            OR l.primary_area = ANY(legal_areas)
        )
    ORDER BY l.rating DESC, l.name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissões para as funções
GRANT EXECUTE ON FUNCTION is_super_associate TO authenticated;
GRANT EXECUTE ON FUNCTION get_eligible_lawyers_with_super_associates TO authenticated;
GRANT EXECUTE ON FUNCTION is_super_associate TO service_role;
GRANT EXECUTE ON FUNCTION get_eligible_lawyers_with_super_associates TO service_role; 