-- Adicionar colunas para respostas do advogado na tabela reviews
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS lawyer_response TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS response_date TIMESTAMPTZ;

-- Adicionar uma política para permitir que advogados atualizem suas próprias respostas
-- Apenas o advogado associado ao contrato pode responder
DROP POLICY IF EXISTS "Lawyers can update their own review responses" ON public.reviews;

CREATE POLICY "Lawyers can update their own review responses"
ON public.reviews
FOR UPDATE
USING (
  auth.uid() = (
    SELECT c.lawyer_id 
    FROM public.contracts c 
    WHERE c.id = reviews.contract_id
  )
)
WITH CHECK (
  auth.uid() = (
    SELECT c.lawyer_id 
    FROM public.contracts c 
    WHERE c.id = reviews.contract_id
  )
);

COMMENT ON COLUMN public.reviews.lawyer_response IS 'A resposta do advogado à avaliação do cliente.';
COMMENT ON COLUMN public.reviews.response_date IS 'A data em que o advogado respondeu à avaliação.'; 