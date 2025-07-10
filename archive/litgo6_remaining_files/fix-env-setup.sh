#!/bin/bash

# Script para corrigir automaticamente as variáveis de ambiente do Supabase
# Execução: bash fix-env-setup.sh

echo "🔧 Corrigindo configuração das variáveis de ambiente..."

# Backup do arquivo .env existente (se houver)
if [ -f ".env" ]; then
    echo "📦 Fazendo backup do arquivo .env existente..."
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Backup salvo como .env.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Copiar env.example para .env
echo "📋 Copiando env.example para .env..."
cp env.example .env

echo "✅ Arquivo .env criado com as variáveis corretas!"

# Verificar se as variáveis estão corretas
echo ""
echo "🔍 Verificando variáveis no arquivo .env:"
echo "EXPO_PUBLIC_SUPABASE_URL: $(grep EXPO_PUBLIC_SUPABASE_URL .env | cut -d'=' -f2)"
echo "EXPO_PUBLIC_SUPABASE_ANON_KEY: $(grep EXPO_PUBLIC_SUPABASE_ANON_KEY .env | wc -c | xargs echo 'Definida -' && echo 'caracteres')"

echo ""
echo "🚀 Próximos passos:"
echo "1. Pare o Metro Bundler atual (Ctrl+C)"
echo "2. Execute: npx expo start --clear"
echo "3. Verifique os logs de debug no console"

echo ""
echo "✨ Correção concluída! O app deve funcionar agora." 