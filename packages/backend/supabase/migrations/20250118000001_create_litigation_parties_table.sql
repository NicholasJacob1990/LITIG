-- Migration: Create litigation_parties table
-- Date: 2025-01-18
-- Description: Tabela para armazenar partes processuais (autor, réu, terceiros) em casos contenciosos

-- Create enum for party types
CREATE TYPE party_type AS ENUM ('plaintiff', 'defendant', 'third_party', 'intervenient');

-- Create litigation_parties table
CREATE TABLE litigation_parties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type party_type NOT NULL,
    document_number VARCHAR(50), -- CPF/CNPJ
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    legal_representative VARCHAR(255), -- Nome do representante legal se for PJ
    legal_representative_document VARCHAR(50), -- CPF do representante
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Create indexes for better performance
CREATE INDEX idx_litigation_parties_case_id ON litigation_parties(case_id);
CREATE INDEX idx_litigation_parties_type ON litigation_parties(type);
CREATE INDEX idx_litigation_parties_name ON litigation_parties(name);
CREATE INDEX idx_litigation_parties_document ON litigation_parties(document_number) WHERE document_number IS NOT NULL;

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_litigation_parties_updated_at
    BEFORE UPDATE ON litigation_parties
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add RLS policies
ALTER TABLE litigation_parties ENABLE ROW LEVEL SECURITY;

-- Allow users to see parties of their own cases
CREATE POLICY "Users can view parties of their cases" ON litigation_parties
    FOR SELECT USING (
        case_id IN (
            SELECT id FROM cases 
            WHERE client_id = auth.uid() 
            OR assigned_lawyer_id = auth.uid()
            OR id IN (
                SELECT case_id FROM case_allocations 
                WHERE allocated_to = auth.uid()
            )
        )
    );

-- Allow lawyers to insert parties for their cases
CREATE POLICY "Lawyers can insert parties for their cases" ON litigation_parties
    FOR INSERT WITH CHECK (
        case_id IN (
            SELECT id FROM cases 
            WHERE assigned_lawyer_id = auth.uid()
            OR id IN (
                SELECT case_id FROM case_allocations 
                WHERE allocated_to = auth.uid()
            )
        )
    );

-- Allow lawyers to update parties for their cases
CREATE POLICY "Lawyers can update parties for their cases" ON litigation_parties
    FOR UPDATE USING (
        case_id IN (
            SELECT id FROM cases 
            WHERE assigned_lawyer_id = auth.uid()
            OR id IN (
                SELECT case_id FROM case_allocations 
                WHERE allocated_to = auth.uid()
            )
        )
    );

-- Allow lawyers to delete parties for their cases
CREATE POLICY "Lawyers can delete parties for their cases" ON litigation_parties
    FOR DELETE USING (
        case_id IN (
            SELECT id FROM cases 
            WHERE assigned_lawyer_id = auth.uid()
            OR id IN (
                SELECT case_id FROM case_allocations 
                WHERE allocated_to = auth.uid()
            )
        )
    );

-- Insert some sample data for testing
INSERT INTO litigation_parties (case_id, name, type, document_number, address, phone, email) VALUES
-- Assumindo que existe um caso com ID específico, ajustar conforme necessário
(
    (SELECT id FROM cases LIMIT 1), 
    'João Silva Santos', 
    'plaintiff', 
    '123.456.789-00', 
    'Rua das Flores, 123, São Paulo, SP',
    '(11) 99999-9999',
    'joao.silva@email.com'
),
(
    (SELECT id FROM cases LIMIT 1), 
    'Empresa XYZ Ltda', 
    'defendant', 
    '12.345.678/0001-90', 
    'Av. Paulista, 1000, São Paulo, SP',
    '(11) 3333-3333',
    'contato@empresaxyz.com.br'
);

-- Add comment to table
COMMENT ON TABLE litigation_parties IS 'Tabela para armazenar informações das partes processuais em casos contenciosos';
COMMENT ON COLUMN litigation_parties.type IS 'Tipo da parte: plaintiff (autor), defendant (réu), third_party (terceiro), intervenient (interveniente)';
COMMENT ON COLUMN litigation_parties.legal_representative IS 'Nome do representante legal para pessoas jurídicas'; 