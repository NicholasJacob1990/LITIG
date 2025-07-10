#!/usr/bin/env bash
# Continuação do setup - OAuth Brand e Client IDs

set -euo pipefail

PROJECT_ID="litgo5-nicholasjacob"
PROJECT_NAME="LITGO5 Mobile"
IOS_BUNDLE_ID="com.anonymous.boltexponativewind"
EXPO_REDIRECT_URI="https://auth.expo.io/@SEU_EXPO_USERNAME/litgo5"

echo ">> Configurando projeto atual"
gcloud config set project "$PROJECT_ID"

# --------------- Criar OAuth Brand ------------------------------------

BRAND_NAME="litgo5_brand"
BRAND_PATH="projects/$PROJECT_ID/brands/$BRAND_NAME"

echo ">> Verificando OAuth brand..."
if ! gcloud alpha oauth brands describe "$BRAND_PATH" >/dev/null 2>&1 ; then
  echo ">> Criando OAuth brand INTERNAL"
  gcloud alpha oauth brands create \
    --project="$PROJECT_ID" \
    --application_title="$PROJECT_NAME" \
    --support_email="$(gcloud config get-value account)" \
    --brand_id="$BRAND_NAME"
else
  echo ">> OAuth brand já existe"
fi

echo ">> OAuth brand pronto: $BRAND_PATH"

# --------------- Criar Client IDs -------------------------------------

create_client() {
  local display_name="$1" ; shift
  gcloud alpha oauth clients create "$BRAND_PATH" "$@" --display_name="$display_name" --format="value(name)"
}

echo -e "\n>> Criando Client ID Web (Expo)"
WEB_CLIENT=$(create_client "LITGO5 – Expo (Web)" \
  --client_type=web \
  --redirect_uris="$EXPO_REDIRECT_URI")
WEB_INFO=$(gcloud alpha oauth clients describe "$WEB_CLIENT" --format=json)
WEB_CLIENT_ID=$(echo "$WEB_INFO" | jq -r '.name' | cut -d'/' -f6)
WEB_CLIENT_SECRET=$(echo "$WEB_INFO" | jq -r '.secret')

echo -e "\n>> Criando Client ID iOS"
IOS_CLIENT=$(create_client "LITGO5 – iOS" \
  --client_type=ios \
  --bundle_id="$IOS_BUNDLE_ID")
IOS_CLIENT_ID=$(echo "$IOS_CLIENT" | awk -F/ '{print $NF}')

# --------------- Resumo ----------------------------------------------

echo -e "\n╭─────────────────────────────────────────────────────────────"
echo "│  ✅  CONFIGURAÇÃO CONCLUÍDA"
echo "├─────────────────────────────────────────────────────────────"
echo "│"
echo "│  Adicione estas credenciais ao seu projeto:"
echo "│"
echo "│  iOS Client ID:      $IOS_CLIENT_ID"
echo "│  Web Client ID:      $WEB_CLIENT_ID"
echo "│  Web Client Secret:  $WEB_CLIENT_SECRET"
echo "│"
echo "│  Em lib/services/calendar.ts, substitua:"
echo "│    iosClientId: '$IOS_CLIENT_ID',"
echo "│    webClientId: '$WEB_CLIENT_ID',"
echo "│    clientSecret: '$WEB_CLIENT_SECRET',"
echo "│"
echo "│  IMPORTANTE:"
echo "│  1. Atualize EXPO_REDIRECT_URI com seu username Expo"
echo "│  2. Configure o OAuth consent screen no Console"
echo "╰─────────────────────────────────────────────────────────────" 