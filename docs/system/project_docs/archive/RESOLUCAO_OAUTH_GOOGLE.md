# Resolução do Problema de Credenciais OAuth Google

## Problema Identificado
O erro "credenciais incorretas" pode ocorrer por várias razões, mesmo com as credenciais corretas configuradas.

## Credenciais Configuradas

### iOS
- Client ID: `[REMOVIDO_POR_SEGURANCA]`
- Bundle ID: `com.anonymous.boltexponativewind`

### Android  
- Client ID: `[REMOVIDO_POR_SEGURANCA]`
- Package: `com.anonymous.boltexponativewind`
- SHA-1: `5E:8F:16:06:2E:A3:CD:2C:4A:0D:54:78:76:BA:A6:F3:8C:AB:F6:25`

### Web
- Client ID: `[REMOVIDO_POR_SEGURANCA]`
- Client Secret: `[REMOVIDO_POR_SEGURANCA]`

## Possíveis Causas do Erro

### 1. OAuth Consent Screen não configurado
- Acesse: https://console.cloud.google.com/apis/credentials/consent?project=litgo5-nicholasjacob
- Verifique se o OAuth consent screen está configurado
- Adicione o email nicholasjacob90@gmail.com como usuário de teste se estiver em modo de teste

### 2. URIs de Redirecionamento
Para a credencial Web, verifique se os seguintes URIs estão configurados:
- `https://auth.expo.io/@nicholasjacob90/litgo5`
- `http://localhost:19006`
- `http://localhost:8081`

### 3. APIs não habilitadas
Verifique se a Google Calendar API está habilitada:
- https://console.cloud.google.com/apis/library/calendar-json.googleapis.com?project=litgo5-nicholasjacob

### 4. Problema de Cache
Execute os seguintes comandos para limpar o cache:
```bash
rm -rf .expo
rm -rf node_modules/.cache
npx expo start --clear
```

## Teste de Debug

Para debug detalhado, modifique temporariamente o arquivo `app/(tabs)/agenda.tsx` para ver o erro completo:

```javascript
const handleSync = useCallback(async () => {
  setIsSyncing(true);
  try {
    console.log('Iniciando autenticação Google...');
    console.log('Redirect URI:', redirectUri);
    await promptAsync();
  } catch (error) {
    console.error('Erro detalhado:', error);
    Alert.alert('Erro', JSON.stringify(error));
  } finally {
    setIsSyncing(false);
  }
}, [promptAsync, redirectUri]);
```

## Próximos Passos

1. Verifique o Console do Google Cloud
2. Teste em modo Web primeiro (mais fácil de debugar)
3. Verifique os logs do console do navegador
4. Se persistir, pode ser necessário recriar as credenciais 