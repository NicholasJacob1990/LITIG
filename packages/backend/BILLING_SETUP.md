# 📋 Setup de Billing em Produção - LITIG

## 🎯 **Resumo**
Guia completo para configurar o sistema universal de billing com suporte a todos os tipos de usuário (clientes PF/PJ, advogados, escritórios) com Stripe, notificações e analytics.

---

## 🔧 **1. Configuração do Stripe**

### **1.1 Dashboard Stripe**
1. Acesse [https://dashboard.stripe.com](https://dashboard.stripe.com)
2. Crie ou acesse sua conta de produção
3. Anote as chaves de API:
   - `sk_live_...` (Secret Key)
   - `pk_live_...` (Publishable Key)

### **1.2 Criar Price IDs**
Execute no Stripe CLI ou Dashboard:

```bash
# Planos de Clientes
stripe prices create \
  --unit-amount 9990 \
  --currency brl \
  --recurring-interval month \
  --product-data name="Plano VIP" \
  --metadata entity_type=client

stripe prices create \
  --unit-amount 29990 \
  --currency brl \
  --recurring-interval month \
  --product-data name="Plano Enterprise" \
  --metadata entity_type=client

# Plano de Advogados
stripe prices create \
  --unit-amount 14990 \
  --currency brl \
  --recurring-interval month \
  --product-data name="Plano PRO" \
  --metadata entity_type=lawyer

# Planos de Escritórios
stripe prices create \
  --unit-amount 49990 \
  --currency brl \
  --recurring-interval month \
  --product-data name="Plano Partner" \
  --metadata entity_type=firm

stripe prices create \
  --unit-amount 99990 \
  --currency brl \
  --recurring-interval month \
  --product-data name="Plano Premium" \
  --metadata entity_type=firm
```

### **1.3 Configurar Webhooks**
1. Acesse: [https://dashboard.stripe.com/webhooks](https://dashboard.stripe.com/webhooks)
2. Clique em "Add endpoint"
3. URL: `https://api.litig.com.br/billing/webhooks/stripe`
4. Eventos para escutar:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
   - `checkout.session.completed`
   - `customer.created`
   - `customer.updated`

5. Copie o **Webhook Secret** (`whsec_...`)

---

## 🔐 **2. Variáveis de Ambiente**

### **2.1 Backend (.env)**
```bash
# Stripe Configuration
STRIPE_SECRET_KEY=sk_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
STRIPE_PUBLISHABLE_KEY=pk_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Price IDs (pegar do Stripe Dashboard)
STRIPE_VIP_PRICE_ID=price_1OxxxxxxxxxxxxVIP
STRIPE_ENTERPRISE_PRICE_ID=price_1OxxxxxxxxxxxxENT
STRIPE_PRO_PRICE_ID=price_1OxxxxxxxxxxxxPRO
STRIPE_PARTNER_PRICE_ID=price_1OxxxxxxxxxxxxPAR
STRIPE_PREMIUM_PRICE_ID=price_1OxxxxxxxxxxxxPRE

# URLs da aplicação
API_BASE_URL=https://api.litig.com.br
FRONTEND_URL=https://app.litig.com.br

# Email (SendGrid)
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
FROM_EMAIL=billing@litig.com.br
SUPPORT_EMAIL=suporte@litig.com.br

# SMS (Twilio)
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_PHONE_NUMBER=+5511999999999

# Analytics
MIXPANEL_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GOOGLE_ANALYTICS_ID=GA-XXXX-X

# Database
DATABASE_URL=postgresql+asyncpg://user:password@prod-db.litig.com.br:5432/litig_prod

# Supabase
SUPABASE_URL=https://xxxxxxxxxxxxxxxxxxxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### **2.2 Flutter (.env)**
```bash
# API Configuration
API_BASE_URL=https://api.litig.com.br
API_TIMEOUT=30000

# Stripe Public Key
STRIPE_PUBLISHABLE_KEY=pk_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Deep Links
DEEP_LINK_SCHEME=litig
BILLING_SUCCESS_URL=litig://billing/success
BILLING_CANCEL_URL=litig://billing/cancel
```

---

## 🗄️ **3. Migrações do Banco**

Execute as migrações na ordem:

```bash
# 1. Adicionar planos ao profiles
supabase db push 20250121000000_add_client_plan_to_profiles.sql

# 2. Criar tabelas de billing
supabase db push 20250121000001_add_billing_tables.sql

# 3. Adicionar analytics
supabase db push 20250121000002_add_billing_analytics.sql
```

### **3.1 Verificar Estrutura**
Confirme que as tabelas foram criadas:
- `public.billing_records`
- `public.billing_issues`  
- `public.plan_history`
- `public.billing_analytics`

---

## 🚀 **4. Deploy**

### **4.1 Backend (FastAPI)**
```bash
# Build da imagem
docker build -t litig-backend:latest .

# Deploy com variáveis de ambiente
docker run -d \
  --name litig-backend \
  --env-file .env \
  -p 8080:8080 \
  litig-backend:latest

# Verificar saúde
curl https://api.litig.com.br/health
```

### **4.2 Frontend (Flutter)**
```bash
# Build para produção
flutter build web --release

# Deploy para CDN/hosting
# (Firebase Hosting, Vercel, etc.)
```

---

## 🔍 **5. Testes de Integração**

### **5.1 Teste Manual**
1. **Acesse a app**: `https://app.litig.com.br`
2. **Faça login** como cliente/advogado/escritório
3. **Navegue para Perfil → Planos**
4. **Selecione um plano** e teste o checkout
5. **Verifique as notificações** (email + SMS)
6. **Confirme no Stripe Dashboard** a criação da subscription

### **5.2 Webhook Testing**
```bash
# Usar Stripe CLI para testar webhooks
stripe listen --forward-to https://api.litig.com.br/billing/webhooks/stripe

# Disparar evento de teste
stripe trigger customer.subscription.created
```

### **5.3 Logs para Monitorar**
```bash
# Backend logs
docker logs -f litig-backend

# Verificar eventos específicos
grep "Successfully upgraded" /var/log/litig-backend.log
grep "Notification sent" /var/log/litig-backend.log
grep "Analytics event tracked" /var/log/litig-backend.log
```

---

## 📊 **6. Monitoramento**

### **6.1 Métricas Importantes**
- **Taxa de Conversão**: Page views → Checkouts
- **Success Rate**: Checkouts → Subscriptions ativas
- **Churn Rate**: Cancelamentos por período
- **Revenue**: Por plano e tipo de entidade

### **6.2 Dashboards**
- **Stripe Dashboard**: Revenue, subscriptions ativas
- **Mixpanel**: Eventos de conversão
- **Internal**: `/billing/analytics` endpoints

### **6.3 Alertas**
Configure alertas para:
- Webhooks com falha (>5% error rate)
- Notifications não enviadas
- Checkout abandonment >70%
- Churn rate >10%

---

## 🐛 **7. Troubleshooting**

### **7.1 Problemas Comuns**

| Problema | Solução |
|----------|---------|
| Webhook 404 | Verificar URL e SSL certificate |
| Checkout não abre | Verificar Price IDs e CORS |
| Emails não chegam | Verificar SendGrid API key e domínio |
| Plano não atualiza | Verificar logs do webhook handler |

### **7.2 Debugging**
```bash
# Verificar webhook delivery
curl -X GET https://api.litig.com.br/billing/webhooks/test

# Testar notificação
curl -X POST https://api.litig.com.br/billing/test-notification \
  -H "Content-Type: application/json" \
  -d '{"user_id": "test-user", "plan": "VIP"}'

# Verificar analytics
curl -X GET https://api.litig.com.br/billing/analytics/client/30
```

---

## ✅ **8. Checklist de Produção**

- [ ] **Stripe**: Chaves, Price IDs, Webhooks configurados
- [ ] **Banco**: Migrações executadas
- [ ] **Envs**: Todas as variáveis configuradas
- [ ] **Deploy**: Backend e Frontend funcionando
- [ ] **DNS**: Domínios apontando corretamente
- [ ] **SSL**: Certificados válidos
- [ ] **Testes**: Fluxo completo testado
- [ ] **Monitoramento**: Logs e métricas funcionando
- [ ] **Notificações**: Email e SMS testados
- [ ] **Analytics**: Eventos sendo tracked

---

## 📞 **9. Suporte**

Em caso de problemas:
1. **Verificar logs** do backend e Stripe
2. **Consultar este README**
3. **Verificar status** das integrações
4. **Contatar equipe de dev** com logs específicos

**Sistema pronto para escalar com todos os tipos de usuário! 🚀** 