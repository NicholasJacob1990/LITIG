-- Adicionar colunas para dados do Jusbrasil nos advogados
ALTER TABLE lawyers 
ADD COLUMN IF NOT EXISTS kpi_subarea JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS total_cases INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_jusbrasil_sync TIMESTAMP WITH TIME ZONE;

-- Criar índice para pesquisa no kpi_subarea
CREATE INDEX IF NOT EXISTS idx_lawyers_kpi_subarea ON lawyers USING GIN (kpi_subarea);

-- Tabela para armazenar casos históricos dos advogados
CREATE TABLE IF NOT EXISTS lawyer_cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID NOT NULL REFERENCES lawyers(id) ON DELETE CASCADE,
    numero_processo TEXT NOT NULL,
    area TEXT NOT NULL,
    subarea TEXT NOT NULL,
    classe TEXT,
    assunto TEXT,
    outcome BOOLEAN, -- True = vitória, False = derrota, NULL = em andamento
    resumo TEXT,
    embedding VECTOR(384), -- Embedding do resumo para similaridade
    data_distribuicao TEXT,
    valor_acao DECIMAL(15,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraint para evitar duplicatas
    UNIQUE(lawyer_id, numero_processo)
);

-- Índices para otimizar consultas
CREATE INDEX IF NOT EXISTS idx_lawyer_cases_lawyer_id ON lawyer_cases(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_lawyer_cases_area_subarea ON lawyer_cases(area, subarea);
CREATE INDEX IF NOT EXISTS idx_lawyer_cases_outcome ON lawyer_cases(outcome);
CREATE INDEX IF NOT EXISTS idx_lawyer_cases_embedding ON lawyer_cases USING ivfflat (embedding vector_cosine_ops);

-- Tabela para armazenar embeddings históricos (para case similarity)
CREATE TABLE IF NOT EXISTS lawyer_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID NOT NULL REFERENCES lawyers(id) ON DELETE CASCADE,
    embedding VECTOR(384) NOT NULL,
    outcome BOOLEAN NOT NULL, -- True = vitória, False = derrota
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para embeddings
CREATE INDEX IF NOT EXISTS idx_lawyer_embeddings_lawyer_id ON lawyer_embeddings(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_lawyer_embeddings_embedding ON lawyer_embeddings USING ivfflat (embedding vector_cosine_ops);

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- Trigger para atualizar updated_at na tabela lawyer_cases
CREATE TRIGGER update_lawyer_cases_updated_at
    BEFORE UPDATE ON lawyer_cases
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Política RLS para lawyer_cases
ALTER TABLE lawyer_cases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Advogados podem ver seus próprios casos"
    ON lawyer_cases FOR SELECT
    USING (lawyer_id = auth.uid());

CREATE POLICY "Apenas sistema pode inserir/atualizar casos"
    ON lawyer_cases FOR ALL
    USING (false);

-- Política RLS para lawyer_embeddings
ALTER TABLE lawyer_embeddings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Embeddings são apenas para uso interno"
    ON lawyer_embeddings FOR ALL
    USING (false);

-- Comentários para documentação
COMMENT ON TABLE lawyer_cases IS 'Casos históricos dos advogados extraídos da API Jusbrasil';
COMMENT ON COLUMN lawyer_cases.outcome IS 'True = vitória, False = derrota, NULL = em andamento';
COMMENT ON COLUMN lawyer_cases.embedding IS 'Embedding do resumo do caso para cálculo de similaridade';
COMMENT ON COLUMN lawyer_cases.numero_processo IS 'Número único do processo no formato CNJ';

COMMENT ON TABLE lawyer_embeddings IS 'Embeddings históricos para case similarity ponderada no algoritmo de match';
COMMENT ON COLUMN lawyer_embeddings.outcome IS 'Outcome do caso (vitória/derrota) para ponderação de similaridade';

COMMENT ON COLUMN lawyers.kpi_subarea IS 'KPI granular por área/subárea em formato JSON: {"area/subarea": success_rate}';
COMMENT ON COLUMN lawyers.total_cases IS 'Total de casos processados pelo advogado';
COMMENT ON COLUMN lawyers.last_jusbrasil_sync IS 'Data da última sincronização com a API Jusbrasil';

-- Inserir dados de exemplo para teste (apenas em desenvolvimento)
DO $$
BEGIN
    -- Verificar se é ambiente de desenvolvimento
    IF current_setting('app.environment', true) = 'development' THEN
        -- Inserir alguns casos de exemplo
        INSERT INTO lawyer_cases (
            lawyer_id, numero_processo, area, subarea, classe, assunto,
            outcome, resumo, data_distribuicao, valor_acao
        ) VALUES (
            (SELECT id FROM lawyers LIMIT 1),
            '1234567-89.2023.8.26.0001',
            'Trabalhista',
            'Rescisão',
            'Reclamação Trabalhista',
            'Rescisão indireta do contrato de trabalho',
            true,
            'Caso de rescisão indireta por falta de pagamento de salários. Área: Trabalhista Subárea: Rescisão Classe: Reclamação Trabalhista',
            '2023-01-15',
            25000.00
        ),
        (
            (SELECT id FROM lawyers LIMIT 1),
            '9876543-21.2023.8.26.0002',
            'Trabalhista',
            'Horas Extras',
            'Reclamação Trabalhista',
            'Horas extras não pagas',
            true,
            'Caso de horas extras não pagas durante período de trabalho. Área: Trabalhista Subárea: Horas Extras Classe: Reclamação Trabalhista',
            '2023-02-20',
            15000.00
        ) ON CONFLICT (lawyer_id, numero_processo) DO NOTHING;
    END IF;
END $$; 