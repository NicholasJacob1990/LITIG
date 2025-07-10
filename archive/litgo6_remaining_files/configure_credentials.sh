#!/bin/bash

# Script para configurar credenciais de serviços externos no .env

ENV_FILE=".env"

echo "🔑 Configuração de Credenciais para LITGO5"
echo "-----------------------------------------"

# Função para ler e adicionar/atualizar variável no .env
update_env_var() {
    local var_name=$1
    local var_value=$2
    
    # Verifica se a variável já existe no arquivo .env
    if grep -q "^${var_name}=" "$ENV_FILE"; then
        # Se existe, atualiza o valor
        sed -i.bak "s|^${var_name}=.*|${var_name}=${var_value}|" "$ENV_FILE"
        rm "${ENV_FILE}.bak"
        echo "✅ Variável '${var_name}' atualizada."
    else
        # Se não existe, adiciona ao final do arquivo
        echo "${var_name}=${var_value}" >> "$ENV_FILE"
        echo "✅ Variável '${var_name}' adicionada."
    fi
}

# Garante que o arquivo .env exista
touch "$ENV_FILE"

echo "\n--- Google Calendar OAuth ---"
echo "Por favor, insira as credenciais obtidas do Google Cloud Console."
echo "Consulte o guia: GOOGLE_CALENDAR_SETUP_MANUAL.md"

# Solicita as credenciais do Google
read -p "Digite o seu GOOGLE_IOS_CLIENT_ID: " google_ios_client_id
read -p "Digite o seu GOOGLE_ANDROID_CLIENT_ID: " google_android_client_id
read -p "Digite o seu GOOGLE_WEB_CLIENT_ID: " google_web_client_id
read -sp "Digite o seu GOOGLE_WEB_CLIENT_SECRET: " google_web_client_secret
echo ""

# Atualiza o arquivo .env com as credenciais do Google
if [[ -n "$google_ios_client_id" ]]; then
    update_env_var "EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID" "$google_ios_client_id"
fi
if [[ -n "$google_android_client_id" ]]; then
    update_env_var "EXPO_PUBLIC_GOOGLE_ANDROID_CLIENT_ID" "$google_android_client_id"
fi
if [[ -n "$google_web_client_id" ]]; then
    update_env_var "EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID" "$google_web_client_id"
fi
if [[ -n "$google_web_client_secret" ]]; then
    update_env_var "GOOGLE_WEB_CLIENT_SECRET" "$google_web_client_secret"
fi

echo "\n-----------------------------------------"
echo "🎉 Configuração concluída!"
echo "O arquivo '$ENV_FILE' foi atualizado com sucesso."
echo "Lembre-se de NUNCA comitar o arquivo .env no Git."
echo "Reinicie o servidor de desenvolvimento para que as alterações tenham efeito." 