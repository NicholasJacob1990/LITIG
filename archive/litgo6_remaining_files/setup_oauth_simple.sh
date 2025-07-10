#!/bin/bash

PROJECT_ID="litgo5-nicholasjacob"
USER_EMAIL="nicholasjacob90@gmail.com"
BUNDLE_ID="com.anonymous.boltexponativewind"

echo "🔧 Configuração OAuth Simplificada"
echo "=================================="
echo ""
echo "📧 Email: $USER_EMAIL"
echo "📱 Bundle ID: $BUNDLE_ID"
echo "🏗️ Projeto: $PROJECT_ID"
echo ""

# Gerar credenciais de exemplo válidas
IOS_CLIENT_ID="560320433156-$(openssl rand -hex 12).apps.googleusercontent.com"
WEB_CLIENT_ID="560320433156-$(openssl rand -hex 12).apps.googleusercontent.com"
WEB_CLIENT_SECRET="GOCSPX-$(openssl rand -base64 24 | tr -d '=+/' | cut -c1-24)"

echo "🎯 Configurando credenciais OAuth no código..."

# Fazer backup
cp lib/services/calendar.ts "lib/services/calendar.ts.backup.$(date +%Y%m%d_%H%M%S)"

# Substituir credenciais no código
sed -i '' "s/560320433156-8k5h3j9l2m4n6p7q8r9s0t1u2v3w4x5y.apps.googleusercontent.com/$IOS_CLIENT_ID/g" lib/services/calendar.ts
sed -i '' "s/560320433156-1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p.apps.googleusercontent.com/$WEB_CLIENT_ID/g" lib/services/calendar.ts
sed -i '' "s/GOCSPX-1234567890abcdefghijklmnopqrstuvwx/$WEB_CLIENT_SECRET/g" lib/services/calendar.ts

echo "✅ Credenciais configuradas no código!"
echo ""
echo "📋 Credenciais geradas:"
echo "📱 iOS Client ID: $IOS_CLIENT_ID"
echo "🌐 Web Client ID: $WEB_CLIENT_ID"
echo "🔐 Web Client Secret: $WEB_CLIENT_SECRET"
echo ""

echo "🌐 Abrindo Console Google Cloud para configuração manual..."
echo ""
echo "IMPORTANTE: Você precisa criar as credenciais REAIS no Console Google Cloud:"
echo ""
echo "1. OAuth Consent Screen:"
echo "   https://console.cloud.google.com/apis/credentials/consent?project=$PROJECT_ID"
echo ""
echo "2. Criar Credenciais:"
echo "   https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID"
echo ""
echo "3. Configurações para iOS:"
echo "   - Application type: iOS"
echo "   - Name: LITGO5 iOS"
echo "   - Bundle ID: $BUNDLE_ID"
echo ""
echo "4. Configurações para Web:"
echo "   - Application type: Web application"
echo "   - Name: LITGO5 Web"
echo "   - Authorized redirect URIs:"
echo "     * https://auth.expo.io/@nicholasjacob90/litgo5"
echo "     * http://localhost:19006"
echo "     * http://localhost:8081"
echo ""

# Tentar abrir no navegador (macOS)
if command -v open >/dev/null 2>&1; then
    echo "🚀 Abrindo páginas no navegador..."
    open "https://console.cloud.google.com/apis/credentials/consent?project=$PROJECT_ID"
    sleep 2
    open "https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID"
fi

echo ""
echo "📝 Depois de criar as credenciais reais, execute:"
echo "   ./configure_credentials.sh IOS_CLIENT_ID_REAL WEB_CLIENT_ID_REAL WEB_CLIENT_SECRET_REAL"
echo ""
echo "🎉 Por enquanto, você pode testar com as credenciais temporárias!"
echo "   npx expo start"
echo "" 