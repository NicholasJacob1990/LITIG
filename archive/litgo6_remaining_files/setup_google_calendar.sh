#!/usr/bin/env bash
# -----------------------------------------------------------
# Script de Provisionamento – Integração Google Calendar
# Requisitos:
#   • gcloud CLI >= 466.0.0 (para o comando `gcloud alpha oauth`)
#   • Conta Google autenticada (`gcloud auth login`)
#   • Projeto com faturamento ativo
# -----------------------------------------------------------

# ======== 1. VARIÁVEIS – EDITE CONFORME SEU CASO ==========================
# ID do projeto (deve ser único na Google Cloud)
PROJECT_ID="litgo5-${USER}"
# Nome legível do projeto
PROJECT_NAME="LITGO5 Mobile"
# ID da conta de faturamento (obrigatório para ativar APIs)
BILLING_ACCOUNT="01B7BA-619DED-36A10D"  # Minha conta de faturamento 2
# (Opcional) ID da organização ou pasta
ORG_ID=""  # ex.: 123456789012 ou folders/987654321098

# Identificadores de pacote/bundle do app
ANDROID_PACKAGE=""              # ex.: com.seuapp.mobile
ANDROID_SHA1=""                 # SHA-1 da chave de assinatura
IOS_BUNDLE_ID="com.anonymous.boltexponativewind"

# URI de redirecionamento usado pelo Expo AuthSession (Web)
EXPO_REDIRECT_URI="https://auth.expo.io/@SEU_EXPO_USERNAME/litgo5"

# ========= FIM DA SEÇÃO DE VARIÁVEIS =====================================

set -euo pipefail

if [[ "$BILLING_ACCOUNT" == "XXXXXX-XXXXXX-XXXXXX" ]]; then
  echo "❌  Você precisa definir BILLING_ACCOUNT antes de executar o script." >&2
  exit 1
fi

# --------------- 2. Criação / Seleção do Projeto -------------------------

echo "\n>> Selecionando projeto $PROJECT_ID"
if ! gcloud projects describe "$PROJECT_ID" >/dev/null 2>&1 ; then
  echo ">> Projeto não existe. Criando..."
  gcloud projects create "$PROJECT_ID" \
    ${ORG_ID:+--organization="$ORG_ID"} \
    --name="$PROJECT_NAME"
  echo ">> Vinculando faturamento..."
  gcloud beta billing projects link "$PROJECT_ID" \
    --billing-account="$BILLING_ACCOUNT"
fi
gcloud config set project "$PROJECT_ID"

# --------------- 3. Ativar APIs Necessárias ------------------------------

echo ">> Habilitando APIs calendar, oauth2 e iamcredentials"
gcloud services enable calendar-json.googleapis.com oauth2.googleapis.com iamcredentials.googleapis.com

# --------------- 4. Criar OAuth Brand ------------------------------------

BRAND_NAME="litgo5_brand"
BRAND_PATH="projects/$PROJECT_ID/brands/$BRAND_NAME"
if ! gcloud alpha oauth brands describe "$BRAND_PATH" >/dev/null 2>&1 ; then
  echo ">> Criando OAuth brand INTERNAl"
  gcloud alpha oauth brands create \
    --project="$PROJECT_ID" \
    --application_title="$PROJECT_NAME" \
    --support_email="$(gcloud config get-value account)" \
    --brand_id="$BRAND_NAME"
fi

echo ">> OAuth brand pronto: $BRAND_PATH"

# --------------- 5. Criar Client IDs -------------------------------------

create_client() {
  local display_name="$1" ; shift
  gcloud alpha oauth clients create "$BRAND_PATH" "$@" --display_name="$display_name" --format="value(name)"
}

echo "\n>> Criando Client ID Web (Expo)"
WEB_CLIENT=$(create_client "LITGO5 – Expo (Web)" \
  --client_type=web \
  --redirect_uris="$EXPO_REDIRECT_URI")
WEB_INFO=$(gcloud alpha oauth clients describe "$WEB_CLIENT" --format=json)
WEB_CLIENT_ID=$(echo "$WEB_INFO" | jq -r '.name' | cut -d'/' -f6)
WEB_CLIENT_SECRET=$(echo "$WEB_INFO" | jq -r '.secret')

if [[ -n "$ANDROID_PACKAGE" && -n "$ANDROID_SHA1" ]]; then
  echo "\n>> Criando Client ID Android"
  ANDROID_CLIENT=$(create_client "LITGO5 – Android" \
    --client_type=android \
    --package_name="$ANDROID_PACKAGE" \
    --sha1_cert_fingerprints="$ANDROID_SHA1")
  ANDROID_CLIENT_ID=$(echo "$ANDROID_CLIENT" | awk -F/ '{print $NF}')
fi

echo "\n>> Criando Client ID iOS"
IOS_CLIENT=$(create_client "LITGO5 – iOS" \
  --client_type=ios \
  --bundle_id="$IOS_BUNDLE_ID")
IOS_CLIENT_ID=$(echo "$IOS_CLIENT" | awk -F/ '{print $NF}')

# --------------- 6. Resumo ----------------------------------------------

echo "\n╭─────────────────────────────────────────────────────────────"
echo "│  ✅  PROVISIONAMENTO CONCLUÍDO"
echo "├─────────────────────────────────────────────────────────────"
echo "│  Copie os IDs/secret para o projeto React Native:"
echo "│"
echo "│  • iOS Client ID:      $IOS_CLIENT_ID"
if [[ -n "${ANDROID_CLIENT_ID:-}" ]]; then
  echo "│  • Android Client ID:  $ANDROID_CLIENT_ID"
fi
echo "│  • Web Client ID:      $WEB_CLIENT_ID"
echo "│  • Web Client Secret:  $WEB_CLIENT_SECRET"
echo "│"
echo "│  Onde colocar?"
echo "│    lib/services/calendar.ts (ou variáveis .env)"
echo "│"
echo "│  Lembre-se de:"
echo "│    • Adicionar o \"scheme\" em app.json:  $ANDROID_PACKAGE"
echo "│    • Fugir de commits com segredos!"
echo "╰─────────────────────────────────────────────────────────────" 