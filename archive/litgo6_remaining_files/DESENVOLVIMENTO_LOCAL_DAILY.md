# Desenvolvimento Local com Daily.co

## Opção 1: Build Local (Mais Rápido)

### Para iOS (requer macOS com Xcode)

1. **Instalar CocoaPods** (se não tiver):
```bash
sudo gem install cocoapods
```

2. **Executar build local**:
```bash
npx expo run:ios
```

Isso irá:
- Gerar a pasta `ios` nativa
- Instalar pods necessários
- Compilar e executar no simulador

### Para Android

1. **Pré-requisitos**:
- Android Studio instalado
- Android SDK configurado
- Emulador ou dispositivo físico

2. **Executar build local**:
```bash
npx expo run:android
```

## Opção 2: Usar Expo Dev Client (Sem Daily.co por enquanto)

Se você não conseguir fazer o build local, pode continuar desenvolvendo sem videochamadas:

1. **Adicione ao seu .env**:
```bash
EXPO_PUBLIC_DAILY_API_KEY=test_key_temporaria
```

2. **Execute normalmente**:
```bash
npm run dev
```

3. **Use o chat como alternativa** às videochamadas

## Configuração Manual do Daily.co

1. **Crie uma conta gratuita**: https://dashboard.daily.co/signup

2. **Obtenha sua API key**:
   - Dashboard → Developers → API keys
   - Copie a chave

3. **Configure no .env**:
```bash
EXPO_PUBLIC_DAILY_API_KEY=sua_chave_aqui
```

## Testando Videochamadas

### Com Build Local:

1. Faça login como cliente
2. Navegue até um caso
3. Clique em "Videochamada com Advogado"
4. A interface Daily.co será carregada

### Recursos Disponíveis:

- ✅ Áudio/Vídeo bidirecional
- ✅ Controles de mute/unmute
- ✅ Ligar/desligar câmera
- ✅ Gravação de chamadas
- ✅ Contador de duração
- ✅ Indicador de participantes

## Problemas Comuns

### "Module not found"
```bash
# Limpar cache e reinstalar
rm -rf node_modules
npm install
npx expo start --clear
```

### "Native module doesn't exist"
- Você está no Expo Go - precisa do build local
- Execute: `npx expo run:ios` ou `npx expo run:android`

### Build iOS falha
```bash
# Limpar pods e reinstalar
cd ios
pod deintegrate
pod install
cd ..
npx expo run:ios
```

### Build Android falha
```bash
# Limpar build Android
cd android
./gradlew clean
cd ..
npx expo run:android
```

## Alternativa: WebView

Se não conseguir fazer funcionar nativamente, considere usar Daily.co via WebView:

```tsx
import { WebView } from 'react-native-webview';

<WebView
  source={{ uri: roomUrl }}
  allowsInlineMediaPlayback
  mediaPlaybackRequiresUserAction={false}
/>
```

Isso funciona no Expo Go mas com limitações de performance. 