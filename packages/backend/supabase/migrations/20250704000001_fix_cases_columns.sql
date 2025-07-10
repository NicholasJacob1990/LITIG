-- Adicionar colunas que estão faltando na tabela cases
DO $$ 
BEGIN
    -- Adicionar coluna area se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'cases' AND column_name = 'area') THEN
        ALTER TABLE cases ADD COLUMN area TEXT;
    END IF;
    
    -- Adicionar coluna subarea se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'cases' AND column_name = 'subarea') THEN
        ALTER TABLE cases ADD COLUMN subarea TEXT;
    END IF;
    
    -- Adicionar coluna summary_ai se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'cases' AND column_name = 'summary_ai') THEN
        ALTER TABLE cases ADD COLUMN summary_ai TEXT;
    END IF;
    
    -- Adicionar coluna risk_level se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'cases' AND column_name = 'risk_level') THEN
        ALTER TABLE cases ADD COLUMN risk_level TEXT DEFAULT 'medium';
    END IF;
    
    -- Adicionar coluna urgency_hours se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'cases' AND column_name = 'urgency_hours') THEN
        ALTER TABLE cases ADD COLUMN urgency_hours INTEGER DEFAULT 48;
    END IF;
    
    -- Adicionar coluna estimated_cost se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'cases' AND column_name = 'estimated_cost') THEN
        ALTER TABLE cases ADD COLUMN estimated_cost DECIMAL(10,2);
    END IF;
    
    -- Adicionar coluna confidence_score se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'cases' AND column_name = 'confidence_score') THEN
        ALTER TABLE cases ADD COLUMN confidence_score INTEGER DEFAULT 75;
    END IF;
END $$;

-- Atualizar casos existentes com dados de exemplo
UPDATE cases 
SET 
    area = COALESCE(area, 'Direito Civil'),
    subarea = COALESCE(subarea, 'Contratos'),
    risk_level = COALESCE(risk_level, 'medium'),
    urgency_hours = COALESCE(urgency_hours, 48),
    estimated_cost = COALESCE(estimated_cost, 2500.00),
    confidence_score = COALESCE(confidence_score, 80)
WHERE area IS NULL OR subarea IS NULL;
