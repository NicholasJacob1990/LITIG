#!/bin/bash
# Script para criar credenciais OAuth usando API REST do Google Cloud

set -e

PROJECT_ID="litgo5-nicholasjacob"
PROJECT_NUMBER="560320433156"
ACCESS_TOKEN=$(gcloud auth print-access-token)

echo "🔐 Criando credenciais OAuth para o projeto $PROJECT_ID..."

# Função para criar client OAuth
create_oauth_client() {
    local client_type=$1
    local client_name=$2
    local bundle_id=$3
    local redirect_uris=$4
    
    echo "📱 Criando client OAuth: $client_name"
    
    # Preparar payload baseado no tipo
    if [ "$client_type" = "ios" ]; then
        payload=$(cat <<EOF
{
  "clientId": "",
  "clientType": "IOS",
  "iosInfo": {
    "bundleId": "$bundle_id"
  },
  "clientName": "$client_name"
}
EOF
)
    else
        payload=$(cat <<EOF
{
  "clientId": "",
  "clientType": "WEB",
  "webInfo": {
    "redirectUris": [$redirect_uris]
  },
  "clientName": "$client_name"
}
EOF
)
    fi
    
    # Fazer requisição para criar client
    response=$(curl -s -X POST \
        "https://oauth2.googleapis.com/v2/projects/$PROJECT_NUMBER/oauthClients" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    echo "Resposta: $response"
    
    # Extrair client ID da resposta
    client_id=$(echo "$response" | grep -o '"clientId":"[^"]*' | cut -d'"' -f4)
    
    if [ -n "$client_id" ]; then
        echo "✅ Client ID criado: $client_id"
        echo "$client_id"
    else
        echo "❌ Erro ao criar client ID"
        echo "$response"
        return 1
    fi
}

# Criar client iOS
echo "📱 Criando client iOS..."
IOS_CLIENT_ID=$(create_oauth_client "ios" "LITGO5 iOS" "com.anonymous.boltexponativewind" "")

# Criar client Web
echo "🌐 Criando client Web..."
WEB_CLIENT_ID=$(create_oauth_client "web" "LITGO5 Web" "" '"https://auth.expo.io/@seu_username/litgo5", "http://localhost:19006"')

# Salvar credenciais em arquivo
cat > oauth_credentials.json <<EOF
{
  "ios_client_id": "$IOS_CLIENT_ID",
  "web_client_id": "$WEB_CLIENT_ID",
  "web_client_secret": "SERÁ_GERADO_AUTOMATICAMENTE",
  "project_id": "$PROJECT_ID"
}
EOF

echo "📄 Credenciais salvas em oauth_credentials.json"
echo ""
echo "📋 Resumo das credenciais:"
echo "iOS Client ID: $IOS_CLIENT_ID"
echo "Web Client ID: $WEB_CLIENT_ID"
echo ""
echo "🔧 Próximo passo: Configurar estas credenciais no código..." 