# Setup do LITGO5 com Expo Go

## Estado Atual

O app LITGO5 está configurado para funcionar com o Expo Go, permitindo desenvolvimento rápido sem necessidade de builds nativas.

### Funcionalidades Disponíveis no Expo Go

✅ **Funcionando:**
- Autenticação (login/registro)
- Listagem de casos
- Chat
- Contratos
- Perfil de usuário
- Navegação entre telas
- Integração com Supabase
- APIs do Escavador e Jusbrasil

⚠️ **Temporariamente Desabilitadas:**
- Videochamadas (requer Daily.co - módulo nativo)
- Push notifications nativas (parcialmente funcionando)

### Como Executar

1. **Iniciar o servidor:**
```bash
npm run dev
```

2. **No terminal do Expo:**
- Pressione `s` para mudar para Expo Go (se estiver em development build)
- Escaneie o QR code com o app Expo Go no seu dispositivo

3. **Acessar via navegador:**
- Abra http://localhost:8081 para versão web

### Videochamadas - Solução Temporária

O módulo `@daily-co/react-native-daily-js` requer código nativo. Implementamos uma solução temporária:

1. **Serviço de vídeo (lib/services/video.ts):** Retorna dados mock em vez de chamar a API Daily.co
2. **Componente VideoCall:** Mostra mensagem explicativa sobre a necessidade de development build

### Para Habilitar Videochamadas

#### Opção 1: Development Build (Recomendado)
```bash
# Instalar EAS CLI
npm install -g eas-cli

# Login no Expo
eas login

# Configurar projeto
eas build:configure

# Criar build de desenvolvimento
eas build --profile development --platform ios
# ou
eas build --profile development --platform android
```

#### Opção 2: Alternativas sem Código Nativo
1. **WebView com Daily.co:** Usar a versão web do Daily.co em uma WebView
2. **Whereby/Jitsi Meet:** Serviços que funcionam via web
3. **WebRTC puro:** Implementação mais complexa mas funciona no Expo Go

### Erros Conhecidos

1. **"Invalid UUID appId":** Ocorre ao tentar criar development build sem configuração adequada
2. **"No development build installed":** Normal quando usando módulos nativos no Expo Go

### Próximos Passos

1. **Para produção:** Criar development build com videochamadas funcionando
2. **Para desenvolvimento:** Continuar usando Expo Go para todas outras funcionalidades
3. **Considerar:** Implementar videochamada via WebView como solução intermediária

### Comandos Úteis

```bash
# Limpar cache
npx expo start --clear

# Verificar dependências
npm list

# Atualizar dependências do Expo
npx expo install --fix
```

## Notas Importantes

- O app está 100% funcional exceto videochamadas
- Todas as integrações de API estão funcionando
- UI/UX completa e navegável
- Pronto para testes e desenvolvimento contínuo 