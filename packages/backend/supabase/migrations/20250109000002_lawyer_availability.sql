-- Adicionar colunas de disponibilidade à tabela profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS availability_status VARCHAR(20) DEFAULT 'available' CHECK (availability_status IN ('available', 'busy', 'vacation', 'inactive'));
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS max_concurrent_cases INTEGER DEFAULT 10 CHECK (max_concurrent_cases > 0 AND max_concurrent_cases <= 50);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS auto_pause_at_limit BOOLEAN DEFAULT true;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS vacation_start TIMESTAMPTZ;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS vacation_end TIMESTAMPTZ;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS availability_message TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_availability_update TIMESTAMPTZ DEFAULT NOW();

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
    SELECT 
        availability_status, max_concurrent_cases, vacation_start, vacation_end, auto_pause_at_limit
    INTO 
        lawyer_status, max_cases, vacation_start, vacation_end, auto_pause
    FROM profiles WHERE id = lawyer_uuid AND user_type = 'LAWYER';
    
    IF NOT FOUND THEN RETURN FALSE; END IF;
    IF lawyer_status = 'inactive' THEN RETURN FALSE; END IF;
    IF lawyer_status = 'vacation' AND NOW() BETWEEN vacation_start AND vacation_end THEN RETURN FALSE; END IF;
    IF lawyer_status = 'busy' THEN RETURN FALSE; END IF;
    
    SELECT COUNT(*) INTO current_cases FROM cases WHERE lawyer_id = lawyer_uuid AND status IN ('in_progress', 'pending_documents', 'under_review', 'pending_signature');
    
    IF auto_pause AND current_cases >= max_cases THEN RETURN FALSE; END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 