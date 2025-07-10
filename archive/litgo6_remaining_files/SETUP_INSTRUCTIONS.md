# Instruções de Configuração - Análise de CV por IA

## 📋 Pré-requisitos

- Acesso ao painel do Supabase (https://supabase.com/dashboard)
- Projeto Supabase já configurado
- Variáveis de ambiente configuradas no arquivo `.env`

## 🗄️ 1. Aplicar Migração do Banco de Dados

### Opção A: Via SQL Editor (Recomendado)

1. **Acesse o Supabase Dashboard**
   - Vá para https://supabase.com/dashboard
   - Selecione seu projeto: `upkwyiehehovsddwpijf`

2. **Abra o SQL Editor**
   - No menu lateral, clique em "SQL Editor"
   - Clique em "New Query"

3. **Execute a Migração**
   - Copie todo o conteúdo do arquivo `apply_cv_migration.sql`
   - Cole no editor SQL
   - Clique em "Run" para executar

4. **Verifique a Execução**
   - Verifique se não há erros na execução
   - Confirme que novos campos foram adicionados à tabela `lawyers`

### Opção B: Via Supabase CLI (Alternativa)

```bash
# Se preferir usar o CLI (pode ter conflitos)
supabase db reset
supabase db push
```

## 🗂️ 2. Configurar Storage Bucket

### Via SQL Editor

1. **No mesmo SQL Editor**
   - Abra uma nova query
   - Copie todo o conteúdo do arquivo `setup_storage_bucket.sql`
   - Cole no editor SQL
   - Clique em "Run" para executar

2. **Verificar Bucket Criado**
   - Vá para "Storage" no menu lateral
   - Confirme que o bucket `lawyer-documents` foi criado
   - Verifique as configurações:
     - Tipo: Privado
     - Limite: 5MB
     - Tipos permitidos: PDF, TXT, JPG, PNG

### Via Interface Supabase (Alternativa)

1. **Acesse Storage**
   - No menu lateral, clique em "Storage"
   - Clique em "Create bucket"

2. **Configurar Bucket**
   - Nome: `lawyer-documents`
   - Público: ❌ (Deixar privado)
   - Limite de arquivo: `5MB`
   - Tipos permitidos: `application/pdf, text/plain, image/jpeg, image/png`

3. **Configurar Políticas RLS**
   - Vá para "Policies" na seção Storage
   - Adicione as políticas do arquivo `setup_storage_bucket.sql`

## 🔧 3. Verificar Configuração

### Teste de Banco de Dados

Execute esta query no SQL Editor para verificar:

```sql
-- Verificar se os campos foram adicionados
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'lawyers' 
AND column_name IN ('cv_url', 'cv_analysis', 'experience', 'bio')
ORDER BY column_name;

-- Verificar função de completude
SELECT calculate_profile_completion('00000000-0000-0000-0000-000000000000');

-- Verificar trigger
SELECT trigger_name, event_manipulation, action_timing 
FROM information_schema.triggers 
WHERE trigger_name = 'update_lawyers_profile_updated_at';
```

### Teste de Storage

Execute esta query para verificar o bucket:

```sql
-- Verificar bucket criado
SELECT * FROM storage.buckets WHERE id = 'lawyer-documents';

-- Verificar políticas
SELECT policyname, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND policyname LIKE '%documents%';
```

## 🧪 4. Testar Funcionalidade

### Teste Manual

1. **Cadastro de Advogado**
   - Execute o app: `npm run dev`
   - Vá para tela de cadastro de advogado
   - Teste upload de CV no Step 3

2. **Verificar Processamento**
   - Upload de arquivo PDF ou TXT
   - Verificar se análise por IA funciona
   - Confirmar preenchimento automático

3. **Verificar Banco de Dados**
   ```sql
   -- Ver dados processados
   SELECT name, cv_url, cv_processed_at, profile_completion_percentage 
   FROM lawyers 
   WHERE cv_url IS NOT NULL;
   ```

## 🚨 Troubleshooting

### Problemas Comuns

1. **Erro "column already exists"**
   - Normal se executar o script duas vezes
   - Use `IF NOT EXISTS` (já incluído no script)

2. **Erro de permissão no Storage**
   - Verifique se RLS está habilitado
   - Confirme políticas de storage

3. **API OpenAI não funciona**
   - Verifique `EXPO_PUBLIC_OPENAI_API_KEY` no `.env`
   - Confirme que a chave tem créditos

4. **OCR.space falha**
   - API gratuita tem limites
   - Considere usar chave própria

### Logs para Debug

```sql
-- Ver logs de erro
SELECT * FROM auth.audit_log_entries 
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;

-- Ver uploads recentes
SELECT * FROM storage.objects 
WHERE bucket_id = 'lawyer-documents'
ORDER BY created_at DESC;
```

## ✅ Checklist de Configuração

- [ ] Migração do banco aplicada com sucesso
- [ ] Bucket `lawyer-documents` criado
- [ ] Políticas RLS configuradas
- [ ] Função `calculate_profile_completion` funciona
- [ ] Trigger `update_lawyers_profile_updated_at` ativo
- [ ] Variáveis de ambiente configuradas
- [ ] App executa sem erros
- [ ] Upload de CV funciona
- [ ] Análise por IA processa
- [ ] Dados são salvos no banco

## 📞 Suporte

Se encontrar problemas:

1. Verifique logs do console do navegador
2. Confira logs do Supabase Dashboard
3. Teste com arquivo PDF simples primeiro
4. Verifique conectividade com APIs externas

---

**Importante**: Após a configuração, faça backup do banco de dados e teste com dados de exemplo antes de usar em produção. 