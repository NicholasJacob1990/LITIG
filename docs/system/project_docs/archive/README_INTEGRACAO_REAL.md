# 🔧 Integração Real: APIs Conectadas - LITGO5

## 📋 Visão Geral

Este documento detalha as implementações de **APIs reais** que conectam o LITGO5 com serviços externos, substituindo mocks e simulações por integrações funcionais.

## 🎯 Integrações Implementadas

### 1. 📅 Google Calendar - Integração Real

**Status**: ✅ Implementado com APIs reais

#### Arquivos Criados:
- `lib/services/google-calendar-real.ts` - Serviço real do Google Calendar
- `lib/contexts/RealCalendarContext.tsx` - Contexto com estado real
- `app/(tabs)/agenda-real.tsx` - Tela de agenda conectada

#### Funcionalidades:
- ✅ **OAuth 2.0 Real** - Autenticação com Google
- ✅ **Busca de Eventos** - Lista eventos do calendário do usuário
- ✅ **Criação de Eventos** - Cria eventos no Google Calendar
- ✅ **Renovação de Tokens** - Atualiza tokens automaticamente
- ✅ **Gerenciamento de Estado** - Context com dados reais

#### Configuração Necessária:

1. **Google Cloud Console**:
   ```
   https://console.cloud.google.com/apis/credentials
   ```

2. **APIs a Habilitar**:
   - Google Calendar API
   - Google Identity Toolkit API

3. **Credenciais OAuth 2.0**:
   - **iOS Client ID**: Para aplicativo iOS
   - **Android Client ID**: Para aplicativo Android  
   - **Web Client ID**: Para troca de tokens
   - **Web Client Secret**: Para autenticação segura

4. **Variáveis de Ambiente**:
   ```bash
   EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID=560320433156-xxx.apps.googleusercontent.com
   EXPO_PUBLIC_GOOGLE_ANDROID_CLIENT_ID=560320433156-xxx.apps.googleusercontent.com
   EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID=560320433156-xxx.apps.googleusercontent.com
   GOOGLE_WEB_CLIENT_SECRET=GOCSPX-xxxxxxxxxxxxxxxx
   ```

#### Como Usar:

```tsx
import { RealCalendarProvider, useRealCalendar } from '@/lib/contexts/RealCalendarContext';

function App() {
  return (
    <RealCalendarProvider>
      <AgendaScreen />
    </RealCalendarProvider>
  );
}

function AgendaScreen() {
  const { events, syncWithGoogle, createEvent, isConnected } = useRealCalendar();
  
  // Conectar ao Google Calendar
  const handleConnect = () => syncWithGoogle();
  
  // Criar evento
  const handleCreateEvent = () => {
    createEvent({
      title: 'Reunião Legal',
      description: 'Discussão do caso',
      startTime: new Date().toISOString(),
      endTime: new Date(Date.now() + 3600000).toISOString(),
    });
  };
}
```

---

### 2. 🗄️ Supabase Storage - Integração Real

**Status**: ✅ Implementado com APIs reais

#### Arquivos Criados:
- `lib/services/supabase-storage-real.ts` - Serviço real do Supabase Storage
- `supabase/migrations/20250704000000_create_real_storage_buckets.sql` - Configuração de buckets

#### Funcionalidades:
- ✅ **Upload de Imagens** - Seleção e upload via ImagePicker
- ✅ **Upload de Documentos** - Seleção e upload via DocumentPicker
- ✅ **Upload Base64** - Conversão e upload de dados base64
- ✅ **Download de Arquivos** - Download para sistema local
- ✅ **Gerenciamento de Buckets** - Criação e configuração automática
- ✅ **URLs Assinadas** - Acesso seguro a arquivos privados
- ✅ **Políticas RLS** - Segurança baseada em usuário

#### Buckets Configurados:

| Bucket | Propósito | Público | Tamanho Máx | Tipos Permitidos |
|--------|-----------|---------|-------------|------------------|
| `lawyer-documents` | Documentos de advogados | ❌ | 10MB | PDF, DOC, IMG |
| `case-documents` | Documentos de casos | ❌ | 50MB | PDF, DOC, XLS, IMG |
| `support_attachments` | Anexos de suporte | ❌ | 20MB | PDF, IMG, ZIP |
| `contracts` | Contratos assinados | ❌ | 30MB | PDF, HTML, DOC |
| `avatars` | Fotos de perfil | ✅ | 5MB | IMG |

#### Como Usar:

```tsx
import { realStorageService } from '@/lib/services/supabase-storage-real';

// Upload de imagem
const uploadImage = async () => {
  const result = await realStorageService.uploadImageFromPicker(
    'avatars',
    userId,
    { quality: 0.8 },
    (progress) => console.log(`${progress.percentage}%`)
  );
  console.log('URL:', result.url);
};

// Upload de documento
const uploadDocument = async () => {
  const result = await realStorageService.uploadDocumentFromPicker(
    'case-documents',
    userId,
    (progress) => console.log(`${progress.percentage}%`)
  );
  console.log('Arquivo salvo:', result.path);
};

// Download de arquivo
const downloadFile = async (filePath: string) => {
  const localUri = await realStorageService.downloadFile('case-documents', filePath);
  console.log('Baixado para:', localUri);
};
```

---

## 🚀 Como Configurar

### 1. Configurar Google Calendar

1. **Acesse o Google Cloud Console**:
   ```
   https://console.cloud.google.com/
   ```

2. **Crie ou selecione um projeto**

3. **Habilite APIs necessárias**:
   - Google Calendar API
   - Google Identity Toolkit API

4. **Configure OAuth Consent Screen**:
   - Tipo: External
   - Nome do app: LITGO5
   - Email de suporte: seu-email@gmail.com

5. **Crie credenciais OAuth 2.0**:

   **iOS Application**:
   - Bundle ID: `com.anonymous.boltexponativewind`
   
   **Web Application**:
   - Authorized redirect URIs:
     - `https://auth.expo.io/@seu_username/litgo5`
     - `http://localhost:19006`

6. **Configure variáveis de ambiente**:
   ```bash
   cp env.example .env
   # Edite .env com suas credenciais reais
   ```

### 2. Configurar Supabase Storage

1. **Execute a migração**:
   ```bash
   npx supabase migration up
   ```

2. **Verifique buckets criados**:
   - Acesse Supabase Dashboard > Storage
   - Confirme que todos os buckets foram criados
   - Verifique políticas RLS

3. **Teste upload**:
   ```bash
   # Execute o app e teste uploads
   npm run dev
   ```

---

## 🧪 Como Testar

### 1. Testar Google Calendar

```bash
# 1. Configure credenciais no .env
# 2. Execute o app
npm run dev

# 3. Navegue para agenda-real
# 4. Clique em "Conectar ao Google Calendar"
# 5. Faça login com sua conta Google
# 6. Verifique se eventos aparecem
# 7. Teste criação de evento
```

### 2. Testar Supabase Storage

```bash
# 1. Execute o app
npm run dev

# 2. Teste uploads em diferentes telas:
# - Registro de advogado (documentos)
# - Casos (anexos)
# - Perfil (avatar)

# 3. Verifique no Supabase Dashboard:
# - Storage > Buckets
# - Confirme arquivos salvos
# - Teste políticas de acesso
```

---

## 🔐 Segurança

### Google Calendar
- ✅ **OAuth 2.0** - Fluxo seguro de autenticação
- ✅ **Tokens Criptografados** - Armazenados no Supabase
- ✅ **Renovação Automática** - Tokens atualizados automaticamente
- ✅ **Escopos Limitados** - Apenas permissões necessárias

### Supabase Storage
- ✅ **RLS Policies** - Segurança baseada em usuário
- ✅ **Buckets Privados** - Acesso controlado
- ✅ **URLs Assinadas** - Acesso temporário seguro
- ✅ **Validação de Tipos** - Apenas arquivos permitidos
- ✅ **Limite de Tamanho** - Proteção contra abuse

---

## 📊 Monitoramento

### Logs de Integração

```typescript
// Google Calendar
console.log('Google Calendar conectado:', isConnected);
console.log('Eventos carregados:', events.length);
console.log('Último sync:', lastSyncTime);

// Supabase Storage
console.log('Upload progress:', progress.percentage + '%');
console.log('Arquivo salvo:', result.url);
console.log('Bucket utilizado:', bucketName);
```

### Métricas Sugeridas

- **Google Calendar**:
  - Taxa de sucesso de autenticação
  - Número de eventos sincronizados
  - Frequência de renovação de tokens

- **Supabase Storage**:
  - Número de uploads por bucket
  - Taxa de sucesso de uploads
  - Tamanho médio de arquivos
  - Utilização de storage por usuário

---

## 🛠️ Troubleshooting

### Google Calendar

**Erro: "Credenciais incorretas"**
```bash
# 1. Verifique variáveis de ambiente
echo $EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID

# 2. Confirme OAuth Consent Screen configurado
# 3. Verifique redirect URIs no Console Google
# 4. Teste com usuário de teste adicionado
```

**Erro: "Token expirado"**
```bash
# O sistema renova automaticamente
# Se persistir, reconecte manualmente
```

### Supabase Storage

**Erro: "Bucket não encontrado"**
```bash
# Execute migração
npx supabase migration up

# Verifique buckets
npx supabase storage ls
```

**Erro: "Permissão negada"**
```bash
# Verifique políticas RLS
# Confirme usuário autenticado
# Teste com usuário correto
```

---

## 📈 Próximos Passos

### Melhorias Planejadas

1. **Google Calendar**:
   - [ ] Sincronização bidirecional
   - [ ] Notificações de eventos
   - [ ] Calendários múltiplos
   - [ ] Recorrência de eventos

2. **Supabase Storage**:
   - [ ] Compressão automática de imagens
   - [ ] Versionamento de arquivos
   - [ ] Limpeza automática de arquivos órfãos
   - [ ] CDN para melhor performance

3. **Integrações Futuras**:
   - [ ] Outlook Calendar
   - [ ] Google Drive
   - [ ] Dropbox
   - [ ] OneDrive

---

## 📚 Recursos Adicionais

### Documentação Oficial
- [Google Calendar API](https://developers.google.com/calendar/api)
- [Supabase Storage](https://supabase.com/docs/guides/storage)
- [Expo Auth Session](https://docs.expo.dev/versions/latest/sdk/auth-session/)

### Exemplos de Código
- [Google Calendar React Native](https://github.com/expo/expo/tree/main/packages/expo-auth-session)
- [Supabase Storage Examples](https://github.com/supabase/supabase/tree/master/examples)

---

**✅ Status: Integrações reais implementadas e funcionais!**

As APIs estão conectadas e prontas para uso em produção. Configure as credenciais e teste as funcionalidades. 