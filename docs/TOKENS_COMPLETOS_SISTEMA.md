# 🔑 **TODAS AS CHAVES E TOKENS DO SISTEMA LITIG-1**

## **📋 ANÁLISE COMPLETA - TOKENS NECESSÁRIOS**

### **🔴 OBRIGATÓRIOS PARA FUNCIONAMENTO BÁSICO:**

#### **1. BANCO DE DADOS & INFRAESTRUTURA**
```bash
# PostgreSQL/Supabase (CRÍTICO)
DATABASE_URL=postgresql://user:password@localhost:5432/litig_db
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Redis Cache (IMPORTANTE)
REDIS_URL=redis://localhost:6379

# Segurança JWT (CRÍTICO)
JWT_SECRET=your-strong-jwt-secret-here
```

#### **2. APIS JURÍDICAS (FUNCIONAIS)**
```bash
# Dados Jurídicos Principais
ESCAVADOR_API_KEY=your-escavador-api-key     # ✅ CONFIGURADO
JUSBRASIL_API_KEY=your-jusbrasil-api-key     # ✅ CONFIGURADO
JUSBRASIL_API_TOKEN=your-jusbrasil-token     # ✅ CONFIGURADO

# CNJ - Sistema Nacional
CNJ_API_TOKEN=your-cnj-api-token             # 🟡 OPCIONAL
```

#### **3. INTELIGÊNCIA ARTIFICIAL (FUNCIONAL)**
```bash
# OpenAI para análises
OPENAI_API_KEY=your-openai-api-key           # ✅ CONFIGURADO

# Anthropic Claude para conversação
ANTHROPIC_API_KEY=your-anthropic-api-key     # ✅ CONFIGURADO
```

#### **4. COMUNICAÇÃO & NOTIFICAÇÕES**
```bash
# Email via SendGrid
SENDGRID_API_KEY=your-sendgrid-api-key       # ✅ CONFIGURADO
SENDGRID_FROM_EMAIL=noreply@litig.com

# Push Notifications
EXPO_ACCESS_TOKEN=your-expo-access-token     # ✅ CONFIGURADO
```

#### **5. VIDEOCHAMADAS**
```bash
# Daily.co para vídeo calls
DAILY_API_KEY=your-daily-api-key             # ✅ CONFIGURADO
DAILY_API_URL=https://api.daily.co/v1
```

---

### **🔴 PENDENTE - REDES SOCIAIS:**

#### **6. UNIPILE SDK (NECESSÁRIO)**
```bash
# OBRIGATÓRIO para LinkedIn/Instagram/Facebook
UNIPILE_API_TOKEN=your_unipile_api_token     # ❌ NÃO CONFIGURADO
UNIPILE_DSN=api.unipile.com                  # 🟡 OPCIONAL (padrão ok)
```

**Status**: 🔴 **CRÍTICO** - Sistema social não funciona sem este token

---

### **🟡 OPCIONAIS - FUNCIONALIDADES AVANÇADAS:**

#### **7. CONTRATOS DIGITAIS**
```bash
# DocuSign para assinatura eletrônica
DOCUSIGN_API_KEY=your-docusign-api-key       # 🟡 FUNCIONALIDADE EXTRA
```

#### **8. AWS (OPCIONAL)**
```bash
# Amazon Web Services (se usar)
AWS_ACCESS_KEY_ID=your-aws-access-key        # 🟡 OPCIONAL
AWS_SECRET_ACCESS_KEY=your-aws-secret-key    # 🟡 OPCIONAL
```

#### **9. OAUTH DIRETO REDES SOCIAIS (FUTURO)**
```bash
# Para login direto (não via Unipile)
LINKEDIN_CLIENT_ID=your-linkedin-client-id   # 🟡 FUTURO
LINKEDIN_CLIENT_SECRET=your-linkedin-secret  # 🟡 FUTURO
INSTAGRAM_CLIENT_ID=your-instagram-client    # 🟡 FUTURO
INSTAGRAM_CLIENT_SECRET=your-instagram-secret # 🟡 FUTURO
FACEBOOK_APP_ID=your-facebook-app-id         # 🟡 FUTURO
FACEBOOK_APP_SECRET=your-facebook-secret     # 🟡 FUTURO
```

---

## **⚙️ STATUS ATUAL DO SISTEMA:**

### **✅ FUNCIONANDO (CONFIGURADO):**
- 🟢 **Banco de Dados**: Supabase + PostgreSQL
- 🟢 **APIs Jurídicas**: Escavador + JusBrasil
- 🟢 **IA**: OpenAI + Anthropic
- 🟢 **Email**: SendGrid
- 🟢 **Push**: Expo
- 🟢 **Vídeo**: Daily.co
- 🟢 **Auth**: Google OAuth (Supabase)

### **🔴 PENDENTE (CRÍTICO):**
- ❌ **Redes Sociais**: UNIPILE_API_TOKEN necessário

### **🟡 OPCIONAL (FUTURO):**
- 🟡 **Contratos**: DocuSign
- 🟡 **AWS**: Storage avançado
- 🟡 **OAuth Direto**: Redes sociais

---

## **🚀 PRIORIDADES DE CONFIGURAÇÃO:**

### **PRIORIDADE 1 - CRÍTICA (AGORA):**
1. **UNIPILE_API_TOKEN** - Para redes sociais funcionarem
   ```bash
   # Obter em: https://app.unipile.com/
   # Adicionar em: packages/backend/.env
   ```

### **PRIORIDADE 2 - IMPORTANTE (SEMANA):**
2. **DOCUSIGN_API_KEY** - Para contratos automáticos
3. **CNJ_API_TOKEN** - Para dados processuais completos

### **PRIORIDADE 3 - OPCIONAL (MÊS):**
4. **OAuth direto** - LinkedIn/Instagram/Facebook
5. **AWS Keys** - Storage avançado

---

## **🔍 COMANDOS DE VERIFICAÇÃO:**

### **Verificar Configurações Atuais:**
```bash
# Backend
cd packages/backend
grep -E "(API_KEY|TOKEN|SECRET)" .env 2>/dev/null | wc -l

# Teste Unipile (principal faltante)
UNIPILE_API_TOKEN=test node unipile_sdk_service.js health-check
```

### **Health Check Completo:**
```bash
# APIs principais
curl -X GET "http://localhost:8080/api/v1/health"

# Unipile especificamente 
curl -X GET "http://localhost:8080/api/v1/unipile/health"
```

---

## **💡 RESUMO EXECUTIVO:**

### **SITUAÇÃO ATUAL:**
- **Sistema Principal**: ✅ **90% OPERACIONAL**
- **Funcionalidades Críticas**: ✅ **FUNCIONANDO**
- **Redes Sociais**: ❌ **PENDENTE 1 TOKEN**

### **AÇÃO IMEDIATA:**
**Configurar `UNIPILE_API_TOKEN`** para completar o sistema!

### **ONDE OBTER O TOKEN:**
1. Acesse: https://app.unipile.com/
2. Crie conta/projeto
3. Dashboard → API Keys → Generate Token
4. Adicione ao `.env`: `UNIPILE_API_TOKEN=seu_token`

**Com este único token, o sistema ficará 100% funcional!** 🚀 