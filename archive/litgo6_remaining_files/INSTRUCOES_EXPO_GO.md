# Instruções para Usar o App LITGO5 com Expo Go

## ⚠️ IMPORTANTE: O servidor já está rodando!

O servidor Expo já está em execução. Você verá um QR code no terminal.

## Como Mudar para Expo Go

1. **No terminal onde o Expo está rodando**, você verá estas opções:
   ```
   › Press s │ switch to Expo Go
   › Press a │ open Android
   › Press i │ open iOS simulator
   ```

2. **Pressione a tecla `s`** para alternar para o modo Expo Go

3. **Após pressionar `s`**, você verá:
   - A mensagem mudará para "Using Expo Go"
   - Um novo QR code será gerado
   - O formato do QR code mudará de `myapp://expo-development-client/...` para `exp://...`

## Como Acessar o App

### No Dispositivo Móvel (iOS/Android)

1. **Instale o Expo Go**:
   - iOS: [App Store](https://apps.apple.com/br/app/expo-go/id982107779)
   - Android: [Google Play](https://play.google.com/store/apps/details?id=host.exp.exponent)

2. **Escaneie o QR Code**:
   - iOS: Use a câmera do iPhone
   - Android: Use o scanner dentro do app Expo Go

3. **O app será carregado** automaticamente

### No Navegador Web

1. Abra: http://localhost:8081
2. O app funcionará no navegador (com algumas limitações)

## Funcionalidades Disponíveis

✅ **100% Funcionais**:
- Login/Registro
- Lista de Casos (Meus Casos)
- Chat
- Contratos
- Perfil
- Navegação completa

⚠️ **Temporariamente Indisponíveis**:
- Videochamadas (mostrará mensagem explicativa)

## Solução de Problemas

### Se aparecer "Using development build"
- Pressione `s` no terminal para mudar para Expo Go

### Se o QR code não funcionar
- Certifique-se de estar na mesma rede Wi-Fi
- Verifique se o endereço IP está correto (192.168.15.5)

### Se houver erros de módulos nativos
- Isso é normal - videochamadas requerem development build
- Use o chat como alternativa

## Navegação no App

1. **Tela Inicial**: Login ou registro
2. **Após login**: Dashboard com abas inferiores
3. **Abas disponíveis**:
   - Início
   - Meus Casos
   - Chat
   - Contratos
   - Perfil

## Notas

- O app está totalmente funcional exceto videochamadas
- Todas as integrações de API estão operacionais
- Os dados são salvos no Supabase em tempo real 