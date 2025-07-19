# 🔑 **CONFIGURAÇÃO DE TOKENS E CHAVES API**

## **📋 TOKENS NECESSÁRIOS PARA AUTENTICAÇÃO SOCIAL**

### **🔴 OBRIGATÓRIOS - SISTEMA PRINCIPAL:**

#### **1. SUPABASE (Google OAuth)**
```bash
# Já configurado e funcional
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

**Status**: ✅ **FUNCIONAL** - Google OAuth operacional

---

#### **2. UNIPILE SDK (LinkedIn/Instagram/Facebook)**
```bash
# Obrigatório para redes sociais
UNIPILE_API_TOKEN=your_unipile_api_token
UNIPILE_DSN=api.unipile.com  # Opcional, padrão já definido
```

**Status**: 🔴 **NECESSÁRIO** - Token não configurado

**Como obter**:
1. Acesse [Unipile Dashboard](https://app.unipile.com/)
2. Crie conta/projeto
3. Gere API Token na seção "API Keys"
4. Adicione ao arquivo `.env`

---

### **🟡 OPCIONAIS - OAUTH DIRETO (FUTURO):**

#### **3. LinkedIn OAuth (Supabase)**
```bash
# Para autenticação direta LinkedIn
LINKEDIN_CLIENT_ID=your_linkedin_client_id
LINKEDIN_CLIENT_SECRET=your_linkedin_client_secret
LINKEDIN_REDIRECT_URI=your_app_redirect_uri
```

**Status**: 🟡 **FUTURO** - Para login direto LinkedIn

**Como obter**:
1. [LinkedIn Developer Console](https://developer.linkedin.com/)
2. Crie aplicação OAuth
3. Configure Supabase Auth External Providers

---

#### **4. Instagram Basic Display API**
```bash
# Para autenticação direta Instagram
INSTAGRAM_CLIENT_ID=your_instagram_client_id
INSTAGRAM_CLIENT_SECRET=your_instagram_client_secret
```

**Status**: 🟡 **FUTURO** - Meta Developer Account necessário

---

#### **5. Facebook OAuth**
```bash
# Para autenticação direta Facebook  
FACEBOOK_APP_ID=your_facebook_app_id
FACEBOOK_APP_SECRET=your_facebook_app_secret
```

**Status**: 🟡 **FUTURO** - Meta Developer Account necessário

---

## **⚙️ CONFIGURAÇÃO ATUAL:**

### **✅ FUNCIONANDO:**
```bash
# Google OAuth via Supabase
✅ SUPABASE_URL - Configurado
✅ SUPABASE_KEY - Configurado  
✅ Google OAuth - Ativo na tela de login
```

### **🔴 PENDENTE:**
```bash
# Unipile para redes sociais
🔴 UNIPILE_API_TOKEN - NECESSÁRIO para LinkedIn/Instagram/Facebook
```

---

## **🚀 PASSOS PARA ATIVAR COMPLETAMENTE:**

### **PASSO 1 - OBTER TOKEN UNIPILE (OBRIGATÓRIO)**

1. **Acessar Unipile**:
   ```bash
   # Ir para: https://app.unipile.com/
   # Criar conta se necessário
   ```

2. **Gerar API Token**:
   ```bash
   # Dashboard > API Keys > Generate New Token
   # Copiar token gerado
   ```

3. **Configurar no Projeto**:
   ```bash
   # Adicionar ao arquivo .env:
   echo "UNIPILE_API_TOKEN=seu_token_aqui" >> .env
   ```

4. **Testar Configuração**:
   ```bash
   # Testar serviço Unipile
   UNIPILE_API_TOKEN=seu_token node unipile_sdk_service.js health-check
   ```

### **PASSO 2 - CONFIGURAR SUPABASE AUTH (OPCIONAL)**

Para LinkedIn/Instagram/Facebook OAuth direto:

1. **Supabase Dashboard**:
   ```bash
   # Ir para: https://app.supabase.com/
   # Projeto > Authentication > Providers
   ```

2. **Ativar Providers**:
   ```bash
   # Habilitar LinkedIn, Instagram, Facebook
   # Configurar Client IDs e Secrets
   ```

3. **Atualizar config.toml**:
   ```toml
   [auth.external.linkedin_oidc]
   enabled = true
   client_id = "env(LINKEDIN_CLIENT_ID)"
   secret = "env(LINKEDIN_CLIENT_SECRET)"
   ```

---

## **🔍 VERIFICAÇÃO DE STATUS:**

### **Comando de Verificação:**
```bash
# Verificar tokens configurados
curl -X GET "http://localhost:8080/api/v1/unipile/health"

# Resposta esperada:
{
  "status": "healthy",
  "has_token": true,
  "using_sdk": true,
  "connected_accounts": 0
}
```

### **Debug de Configuração:**
```bash
# Verificar variáveis de ambiente
echo "UNIPILE_API_TOKEN: ${UNIPILE_API_TOKEN:-NOT_SET}"
echo "SUPABASE_URL: ${SUPABASE_URL:-NOT_SET}"
```

---

## **📊 PRIORIDADES:**

### **🔴 CRÍTICO (AGORA):**
1. **UNIPILE_API_TOKEN** - Para redes sociais funcionarem

### **🟡 IMPORTANTE (FUTURO):**
2. **LinkedIn Client ID/Secret** - OAuth direto
3. **Meta App Credentials** - Instagram/Facebook OAuth

### **🟢 FUNCIONAL (JÁ ATIVO):**
4. **Google OAuth** - Login principal funcionando

---

## **💡 ESTRATÉGIA RECOMENDADA:**

1. **Fase 1** (Atual): Unipile para conexões sociais no perfil
2. **Fase 2** (Futuro): OAuth direto para login social
3. **Fase 3** (Avançado): Sistema híbrido completo

**PRIMEIRO PASSO**: Obter e configurar `UNIPILE_API_TOKEN` para ativar as funcionalidades sociais! 🚀 

## **📋 TOKENS NECESSÁRIOS PARA AUTENTICAÇÃO SOCIAL**

### **🔴 OBRIGATÓRIOS - SISTEMA PRINCIPAL:**

#### **1. SUPABASE (Google OAuth)**
```bash
# Já configurado e funcional
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

**Status**: ✅ **FUNCIONAL** - Google OAuth operacional

---

#### **2. UNIPILE SDK (LinkedIn/Instagram/Facebook)**
```bash
# Obrigatório para redes sociais
UNIPILE_API_TOKEN=your_unipile_api_token
UNIPILE_DSN=api.unipile.com  # Opcional, padrão já definido
```

**Status**: 🔴 **NECESSÁRIO** - Token não configurado

**Como obter**:
1. Acesse [Unipile Dashboard](https://app.unipile.com/)
2. Crie conta/projeto
3. Gere API Token na seção "API Keys"
4. Adicione ao arquivo `.env`

---

### **🟡 OPCIONAIS - OAUTH DIRETO (FUTURO):**

#### **3. LinkedIn OAuth (Supabase)**
```bash
# Para autenticação direta LinkedIn
LINKEDIN_CLIENT_ID=your_linkedin_client_id
LINKEDIN_CLIENT_SECRET=your_linkedin_client_secret
LINKEDIN_REDIRECT_URI=your_app_redirect_uri
```

**Status**: 🟡 **FUTURO** - Para login direto LinkedIn

**Como obter**:
1. [LinkedIn Developer Console](https://developer.linkedin.com/)
2. Crie aplicação OAuth
3. Configure Supabase Auth External Providers

---

#### **4. Instagram Basic Display API**
```bash
# Para autenticação direta Instagram
INSTAGRAM_CLIENT_ID=your_instagram_client_id
INSTAGRAM_CLIENT_SECRET=your_instagram_client_secret
```

**Status**: 🟡 **FUTURO** - Meta Developer Account necessário

---

#### **5. Facebook OAuth**
```bash
# Para autenticação direta Facebook  
FACEBOOK_APP_ID=your_facebook_app_id
FACEBOOK_APP_SECRET=your_facebook_app_secret
```

**Status**: 🟡 **FUTURO** - Meta Developer Account necessário

---

## **⚙️ CONFIGURAÇÃO ATUAL:**

### **✅ FUNCIONANDO:**
```bash
# Google OAuth via Supabase
✅ SUPABASE_URL - Configurado
✅ SUPABASE_KEY - Configurado  
✅ Google OAuth - Ativo na tela de login
```

### **🔴 PENDENTE:**
```bash
# Unipile para redes sociais
🔴 UNIPILE_API_TOKEN - NECESSÁRIO para LinkedIn/Instagram/Facebook
```

---

## **🚀 PASSOS PARA ATIVAR COMPLETAMENTE:**

### **PASSO 1 - OBTER TOKEN UNIPILE (OBRIGATÓRIO)**

1. **Acessar Unipile**:
   ```bash
   # Ir para: https://app.unipile.com/
   # Criar conta se necessário
   ```

2. **Gerar API Token**:
   ```bash
   # Dashboard > API Keys > Generate New Token
   # Copiar token gerado
   ```

3. **Configurar no Projeto**:
   ```bash
   # Adicionar ao arquivo .env:
   echo "UNIPILE_API_TOKEN=seu_token_aqui" >> .env
   ```

4. **Testar Configuração**:
   ```bash
   # Testar serviço Unipile
   UNIPILE_API_TOKEN=seu_token node unipile_sdk_service.js health-check
   ```

### **PASSO 2 - CONFIGURAR SUPABASE AUTH (OPCIONAL)**

Para LinkedIn/Instagram/Facebook OAuth direto:

1. **Supabase Dashboard**:
   ```bash
   # Ir para: https://app.supabase.com/
   # Projeto > Authentication > Providers
   ```

2. **Ativar Providers**:
   ```bash
   # Habilitar LinkedIn, Instagram, Facebook
   # Configurar Client IDs e Secrets
   ```

3. **Atualizar config.toml**:
   ```toml
   [auth.external.linkedin_oidc]
   enabled = true
   client_id = "env(LINKEDIN_CLIENT_ID)"
   secret = "env(LINKEDIN_CLIENT_SECRET)"
   ```

---

## **🔍 VERIFICAÇÃO DE STATUS:**

### **Comando de Verificação:**
```bash
# Verificar tokens configurados
curl -X GET "http://localhost:8080/api/v1/unipile/health"

# Resposta esperada:
{
  "status": "healthy",
  "has_token": true,
  "using_sdk": true,
  "connected_accounts": 0
}
```

### **Debug de Configuração:**
```bash
# Verificar variáveis de ambiente
echo "UNIPILE_API_TOKEN: ${UNIPILE_API_TOKEN:-NOT_SET}"
echo "SUPABASE_URL: ${SUPABASE_URL:-NOT_SET}"
```

---

## **📊 PRIORIDADES:**

### **🔴 CRÍTICO (AGORA):**
1. **UNIPILE_API_TOKEN** - Para redes sociais funcionarem

### **🟡 IMPORTANTE (FUTURO):**
2. **LinkedIn Client ID/Secret** - OAuth direto
3. **Meta App Credentials** - Instagram/Facebook OAuth

### **🟢 FUNCIONAL (JÁ ATIVO):**
4. **Google OAuth** - Login principal funcionando

---

## **💡 ESTRATÉGIA RECOMENDADA:**

1. **Fase 1** (Atual): Unipile para conexões sociais no perfil
2. **Fase 2** (Futuro): OAuth direto para login social
3. **Fase 3** (Avançado): Sistema híbrido completo

**PRIMEIRO PASSO**: Obter e configurar `UNIPILE_API_TOKEN` para ativar as funcionalidades sociais! 🚀 

## **📋 TOKENS NECESSÁRIOS PARA AUTENTICAÇÃO SOCIAL**

### **🔴 OBRIGATÓRIOS - SISTEMA PRINCIPAL:**

#### **1. SUPABASE (Google OAuth)**
```bash
# Já configurado e funcional
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

**Status**: ✅ **FUNCIONAL** - Google OAuth operacional

---

#### **2. UNIPILE SDK (LinkedIn/Instagram/Facebook)**
```bash
# Obrigatório para redes sociais
UNIPILE_API_TOKEN=your_unipile_api_token
UNIPILE_DSN=api.unipile.com  # Opcional, padrão já definido
```

**Status**: 🔴 **NECESSÁRIO** - Token não configurado

**Como obter**:
1. Acesse [Unipile Dashboard](https://app.unipile.com/)
2. Crie conta/projeto
3. Gere API Token na seção "API Keys"
4. Adicione ao arquivo `.env`

---

### **🟡 OPCIONAIS - OAUTH DIRETO (FUTURO):**

#### **3. LinkedIn OAuth (Supabase)**
```bash
# Para autenticação direta LinkedIn
LINKEDIN_CLIENT_ID=your_linkedin_client_id
LINKEDIN_CLIENT_SECRET=your_linkedin_client_secret
LINKEDIN_REDIRECT_URI=your_app_redirect_uri
```

**Status**: 🟡 **FUTURO** - Para login direto LinkedIn

**Como obter**:
1. [LinkedIn Developer Console](https://developer.linkedin.com/)
2. Crie aplicação OAuth
3. Configure Supabase Auth External Providers

---

#### **4. Instagram Basic Display API**
```bash
# Para autenticação direta Instagram
INSTAGRAM_CLIENT_ID=your_instagram_client_id
INSTAGRAM_CLIENT_SECRET=your_instagram_client_secret
```

**Status**: 🟡 **FUTURO** - Meta Developer Account necessário

---

#### **5. Facebook OAuth**
```bash
# Para autenticação direta Facebook  
FACEBOOK_APP_ID=your_facebook_app_id
FACEBOOK_APP_SECRET=your_facebook_app_secret
```

**Status**: 🟡 **FUTURO** - Meta Developer Account necessário

---

## **⚙️ CONFIGURAÇÃO ATUAL:**

### **✅ FUNCIONANDO:**
```bash
# Google OAuth via Supabase
✅ SUPABASE_URL - Configurado
✅ SUPABASE_KEY - Configurado  
✅ Google OAuth - Ativo na tela de login
```

### **🔴 PENDENTE:**
```bash
# Unipile para redes sociais
🔴 UNIPILE_API_TOKEN - NECESSÁRIO para LinkedIn/Instagram/Facebook
```

---

## **🚀 PASSOS PARA ATIVAR COMPLETAMENTE:**

### **PASSO 1 - OBTER TOKEN UNIPILE (OBRIGATÓRIO)**

1. **Acessar Unipile**:
   ```bash
   # Ir para: https://app.unipile.com/
   # Criar conta se necessário
   ```

2. **Gerar API Token**:
   ```bash
   # Dashboard > API Keys > Generate New Token
   # Copiar token gerado
   ```

3. **Configurar no Projeto**:
   ```bash
   # Adicionar ao arquivo .env:
   echo "UNIPILE_API_TOKEN=seu_token_aqui" >> .env
   ```

4. **Testar Configuração**:
   ```bash
   # Testar serviço Unipile
   UNIPILE_API_TOKEN=seu_token node unipile_sdk_service.js health-check
   ```

### **PASSO 2 - CONFIGURAR SUPABASE AUTH (OPCIONAL)**

Para LinkedIn/Instagram/Facebook OAuth direto:

1. **Supabase Dashboard**:
   ```bash
   # Ir para: https://app.supabase.com/
   # Projeto > Authentication > Providers
   ```

2. **Ativar Providers**:
   ```bash
   # Habilitar LinkedIn, Instagram, Facebook
   # Configurar Client IDs e Secrets
   ```

3. **Atualizar config.toml**:
   ```toml
   [auth.external.linkedin_oidc]
   enabled = true
   client_id = "env(LINKEDIN_CLIENT_ID)"
   secret = "env(LINKEDIN_CLIENT_SECRET)"
   ```

---

## **🔍 VERIFICAÇÃO DE STATUS:**

### **Comando de Verificação:**
```bash
# Verificar tokens configurados
curl -X GET "http://localhost:8080/api/v1/unipile/health"

# Resposta esperada:
{
  "status": "healthy",
  "has_token": true,
  "using_sdk": true,
  "connected_accounts": 0
}
```

### **Debug de Configuração:**
```bash
# Verificar variáveis de ambiente
echo "UNIPILE_API_TOKEN: ${UNIPILE_API_TOKEN:-NOT_SET}"
echo "SUPABASE_URL: ${SUPABASE_URL:-NOT_SET}"
```

---

## **📊 PRIORIDADES:**

### **🔴 CRÍTICO (AGORA):**
1. **UNIPILE_API_TOKEN** - Para redes sociais funcionarem

### **🟡 IMPORTANTE (FUTURO):**
2. **LinkedIn Client ID/Secret** - OAuth direto
3. **Meta App Credentials** - Instagram/Facebook OAuth

### **🟢 FUNCIONAL (JÁ ATIVO):**
4. **Google OAuth** - Login principal funcionando

---

## **💡 ESTRATÉGIA RECOMENDADA:**

1. **Fase 1** (Atual): Unipile para conexões sociais no perfil
2. **Fase 2** (Futuro): OAuth direto para login social
3. **Fase 3** (Avançado): Sistema híbrido completo

**PRIMEIRO PASSO**: Obter e configurar `UNIPILE_API_TOKEN` para ativar as funcionalidades sociais! 🚀 