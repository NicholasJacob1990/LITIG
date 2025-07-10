# 🗓️ Configuração OAuth - Google Calendar

## ✅ **Status Atual: PRONTO PARA CONFIGURAÇÃO**

### **Infraestrutura Completa:**
- ✅ Projeto Google Cloud: `litgo5-nicholasjacob`
- ✅ Faturamento vinculado: `01B7BA-619DED-36A10D`
- ✅ APIs habilitadas: Google Calendar, Identity Toolkit, IAM
- ✅ Código de integração: Implementado e funcional
- ✅ Interface de usuário: Tela de agenda com sincronização

---

## 🚀 **Passo a Passo Final**

### **1. Configure OAuth Consent Screen**
**Link direto:** https://console.cloud.google.com/apis/credentials/consent?project=litgo5-nicholasjacob

**Configurações:**
- **Tipo**: External
- **Nome do app**: LITGO5 Mobile
- **Email do usuário**: nicholasjacob90@gmail.com
- **Email do desenvolvedor**: nicholasjacob90@gmail.com
- **Domínios autorizados**: (deixe vazio)

### **2. Crie as Credenciais OAuth**
**Link direto:** https://console.cloud.google.com/apis/credentials?project=litgo5-nicholasjacob

**Clique em:** `CREATE CREDENTIALS` > `OAuth client ID`

#### **📱 Credencial iOS:**
- **Application type**: iOS
- **Name**: LITGO5 iOS
- **Bundle ID**: `com.anonymous.boltexponativewind`

#### **🌐 Credencial Web:**
- **Application type**: Web application
- **Name**: LITGO5 Web
- **Authorized redirect URIs**:
  - `https://auth.expo.io/@seu_username/litgo5`
  - `http://localhost:19006`

### **3. Configure no Código**
Após criar as credenciais, execute:

```bash
./configure_credentials.sh IOS_CLIENT_ID WEB_CLIENT_ID WEB_CLIENT_SECRET
```

**Exemplo:**
```bash
./configure_credentials.sh \
  "560320433156-abc123def456.apps.googleusercontent.com" \
  "560320433156-xyz789uvw012.apps.googleusercontent.com" \
  "GOCSPX-abcdef123456789"
```

### **4. Teste a Integração**
1. Reinicie o app: `npx expo start`
2. Acesse a aba **Agenda**
3. Clique em **Sincronizar**
4. Faça login com sua conta Google
5. Verifique se os eventos aparecem

---

## 🔍 **Informações Importantes**

### **Bundle ID do iOS:**
- Valor atual: `com.anonymous.boltexponativewind`
- Localização: `app.config.ts` → `ios.bundleIdentifier`

### **Username do Expo:**
- Substitua `@seu_username` pelo seu username real do Expo
- Formato: `https://auth.expo.io/@SEU_USERNAME_REAL/litgo5`

### **Redirect URIs:**
- **Desenvolvimento**: `http://localhost:19006`
- **Produção**: `https://auth.expo.io/@seu_username/litgo5`

---

## 📋 **Checklist Final**

- [ ] OAuth Consent Screen configurado
- [ ] iOS Client ID criado
- [ ] Web Client ID criado
- [ ] Web Client Secret obtido
- [ ] Credenciais configuradas no código
- [ ] Aplicativo testado
- [ ] Login Google funcionando
- [ ] Eventos sincronizando

---

## 🎯 **Resultado Esperado**

Após completar todos os passos:

1. **Tela de Agenda** funcionando perfeitamente
2. **Botão Sincronizar** conectando com Google
3. **Login OAuth** redirecionando corretamente
4. **Eventos do Google Calendar** aparecendo no app
5. **Sincronização automática** funcionando

---

## 🆘 **Suporte**

Se encontrar problemas:

1. **Verifique as URLs de redirect** no Console Google
2. **Confirme o Bundle ID** no iOS
3. **Teste primeiro na web** (`http://localhost:19006`)
4. **Verifique os logs** do Expo para erros OAuth

---

**🏆 Status: TUDO PRONTO PARA CONFIGURAÇÃO FINAL!** 