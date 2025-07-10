#!/bin/bash

# Script para formatação automática do código Python
# Executa black e isort em todo o código backend

echo "🔧 Formatando código Python..."

# Aplicar Black (formatação)
echo "📝 Aplicando Black..."
black backend/ tests/ --line-length 100

# Aplicar isort (organização de imports)
echo "📦 Organizando imports com isort..."
isort backend/ tests/

# Verificar se há arquivos modificados
if git diff --quiet; then
    echo "✅ Nenhuma alteração de formatação necessária!"
else
    echo "⚠️  Arquivos formatados. Revisar as alterações:"
    git diff --name-only
fi

echo "🎉 Formatação concluída!" 