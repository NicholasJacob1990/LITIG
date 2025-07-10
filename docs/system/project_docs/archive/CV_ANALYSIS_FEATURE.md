# Funcionalidade de Análise de CV por IA

## Visão Geral

A funcionalidade de análise de CV por IA foi implementada para automatizar o preenchimento do perfil do advogado durante o processo de cadastro. Esta funcionalidade utiliza:

- **Extração de texto**: OCR.space API para extrair texto de PDFs
- **Análise por IA**: OpenAI GPT-4o-mini para estruturar informações
- **Preenchimento automático**: Dados extraídos são usados para popular o perfil

## Fluxo de Funcionamento

### 1. Upload do CV
- Advogado faz upload de CV (PDF ou TXT) no Step 3 do cadastro
- Sistema verifica tamanho (máximo 5MB) e formato
- Arquivo é armazenado temporariamente para processamento

### 2. Extração de Texto
- Para PDFs: Usa OCR.space API com configurações otimizadas para português
- Para TXT: Leitura direta do arquivo
- Validação de conteúdo mínimo (100 caracteres)

### 3. Análise por IA
- Texto extraído é enviado para OpenAI GPT-4o-mini
- IA estrutura informações seguindo schema JSON predefinido
- Extrai dados como: experiência, especialidades, formação, certificações, etc.

### 4. Preenchimento Automático
- Campos do formulário são preenchidos automaticamente
- Dados são salvos no banco de dados com estrutura completa
- Perfil do advogado é atualizado com porcentagem de completude

## Campos Extraídos

### Informações Pessoais
- Nome completo
- E-mail
- Telefone
- Endereço
- LinkedIn
- Website

### Dados Profissionais
- Número da OAB
- Anos de experiência total
- Áreas de especialização
- Anos de experiência por área
- Resumo profissional

### Formação e Certificações
- Educação (graduação, pós-graduação)
- Certificações profissionais
- Cursos complementares

### Competências
- Habilidades técnicas
- Idiomas
- Publicações
- Prêmios e reconhecimentos

### Configurações de Atendimento
- Tipos de consulta preferidos
- Valores de consulta (estimados se não informados)
- Horários de disponibilidade
- Atendimento de emergência

## Estrutura do Banco de Dados

### Novos Campos na Tabela `lawyers`

```sql
-- Campos para CV e análise
cv_url text                          -- URL do CV armazenado
cv_analysis jsonb                    -- Análise completa em JSON
cv_processed_at timestamp           -- Data do processamento

-- Campos do perfil expandido
bio text                            -- Resumo profissional
education text[]                    -- Formação acadêmica
certifications text[]               -- Certificações
professional_experience text[]      -- Experiência profissional
skills text[]                       -- Habilidades
awards text[]                       -- Prêmios
publications text[]                 -- Publicações
bar_associations text[]             -- Associações
practice_areas text[]               -- Áreas de atuação
phone varchar(20)                   -- Telefone
email varchar(255)                  -- E-mail
website varchar(255)                -- Website
linkedin varchar(255)               -- LinkedIn
office_address text                 -- Endereço do escritório
office_hours text                   -- Horário de funcionamento
graduation_year integer             -- Ano de formatura
postgraduate_courses text[]         -- Cursos de pós-graduação
specialization_years jsonb          -- Anos por especialização
professional_summary text           -- Resumo profissional
availability_schedule jsonb         -- Horários de disponibilidade
consultation_methods text[]         -- Métodos de consulta
emergency_availability boolean      -- Disponibilidade emergencial
profile_completion_percentage integer -- % de completude do perfil
profile_updated_at timestamp        -- Última atualização do perfil
```

## APIs Utilizadas

### OCR.space API
- **Endpoint**: `https://api.ocr.space/parse/image`
- **Configuração**: Português, OCR Engine 2, detecção de orientação
- **Limitações**: API gratuita com limite de uso

### OpenAI API
- **Modelo**: GPT-4o-mini
- **Temperatura**: 0.3 (mais determinístico)
- **Formato**: JSON estruturado
- **Tokens**: Máximo 4096

## Tratamento de Erros

### Erros de Upload
- Arquivo muito grande (>5MB)
- Formato não suportado
- Falha na conexão

### Erros de Processamento
- Texto insuficiente extraído
- Falha na API de OCR
- Erro na análise por IA
- Falha ao salvar no banco

### Fallbacks
- Cadastro continua mesmo com falha na análise de CV
- Campos podem ser preenchidos manualmente
- Análise pode ser reprocessada posteriormente

## Benefícios

### Para o Advogado
- Cadastro mais rápido e eficiente
- Redução de erros de digitação
- Perfil mais completo automaticamente
- Experiência de usuário melhorada

### Para a Plataforma
- Perfis mais ricos e detalhados
- Melhor matching com clientes
- Dados estruturados para análises
- Diferencial competitivo

## Configuração Necessária

### Variáveis de Ambiente
```bash
EXPO_PUBLIC_OPENAI_API_KEY=your_openai_api_key
EXPO_PUBLIC_SUPABASE_URL=your_supabase_url
EXPO_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Buckets do Supabase
- `lawyer-documents`: Para armazenar CVs e documentos
- Configurar políticas de acesso apropriadas

## Melhorias Futuras

1. **Suporte a mais formatos**: DOC, DOCX
2. **OCR local**: Reduzir dependência de APIs externas
3. **Validação de dados**: Verificar consistência das informações
4. **Reprocessamento**: Permitir nova análise de CV
5. **Análise de foto**: Extrair foto do CV para avatar
6. **Integração com OAB**: Validar número da OAB automaticamente

## Monitoramento

### Métricas Importantes
- Taxa de sucesso na extração de texto
- Taxa de sucesso na análise por IA
- Tempo médio de processamento
- Qualidade dos dados extraídos
- Uso das APIs externas

### Logs
- Todos os erros são logados com detalhes
- Análises bem-sucedidas são registradas
- Tempo de processamento é monitorado 