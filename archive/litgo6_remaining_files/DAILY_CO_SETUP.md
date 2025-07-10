# Configuração do Daily.co para LITGO5

## 1. Criar Conta no Daily.co

1. Acesse https://dashboard.daily.co/signup
2. Crie uma conta gratuita
3. Após o login, vá para "Developers" → "API keys"
4. Copie sua API key

## 2. Configurar Variável de Ambiente

Adicione ao seu arquivo `.env`:

```bash
# Daily.co Configuration
EXPO_PUBLIC_DAILY_API_KEY=sua_api_key_aqui
```

## 3. Instalar Dependências Nativas

As dependências já foram instaladas, mas certifique-se de que estão presentes:

```bash
npm install @daily-co/react-native-daily-js
npm install @daily-co/react-native-webrtc
npm install react-native-background-timer
npm install @react-native-async-storage/async-storage
npm install base-64
```

## 4. Criar Development Build

### Opção A: Build Local (Recomendado para desenvolvimento)

```bash
# iOS
npx expo run:ios

# Android
npx expo run:android
```

### Opção B: EAS Build (Para distribuição)

1. **Configurar EAS**:
```bash
eas build:configure
```

2. **Criar build de desenvolvimento**:
```bash
# iOS
eas build --profile development --platform ios

# Android
eas build --profile development --platform android
```

3. **Instalar no dispositivo**:
- iOS: Baixe o arquivo .ipa e instale via TestFlight ou Xcode
- Android: Baixe o arquivo .apk e instale diretamente

## 5. Configuração do eas.json

Crie um arquivo `eas.json` na raiz do projeto:

```json
{
  "cli": {
    "version": ">= 5.0.0",
    "appVersionSource": "local"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": {
        "simulator": true
      }
    },
    "preview": {
      "distribution": "internal"
    },
    "production": {}
  },
  "submit": {
    "production": {}
  }
}
```

## 6. Testar Videochamadas

1. **Iniciar o servidor de desenvolvimento**:
```bash
npx expo start --dev-client
```

2. **Abrir no dispositivo com o development build instalado**

3. **Testar uma videochamada**:
   - Faça login como cliente
   - Navegue até um caso
   - Clique em "Iniciar Videochamada"

## Recursos do Daily.co Implementados

- ✅ Criação de salas dinâmicas
- ✅ Tokens de acesso seguros
- ✅ Controles de áudio/vídeo
- ✅ Gravação de chamadas
- ✅ Indicador de participantes
- ✅ Duração da chamada
- ✅ Status de conexão

## Solução de Problemas

### Erro: "Module not found"
- Certifique-se de ter instalado todas as dependências
- Limpe o cache: `npx expo start --clear`

### Erro: "Native module doesn't exist"
- Você precisa de um development build
- Não funcionará no Expo Go

### Erro: "Invalid API key"
- Verifique se a API key está correta no .env
- Certifique-se de usar `EXPO_PUBLIC_` no prefixo

## Limites do Plano Gratuito Daily.co

- 10.000 minutos de vídeo por mês
- Até 200 participantes simultâneos
- Gravação limitada a 10 horas/mês

Para produção, considere um plano pago. 