#!/bin/bash

# Script para implementar a estrutura completa de honorários

echo "🚀 Implementando estrutura completa de honorários..."

# Verificar se o Supabase CLI está instalado
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI não encontrado. Por favor, instale o Supabase CLI primeiro."
    echo "   npm install -g supabase"
    exit 1
fi

# Verificar se estamos no diretório correto
if [ ! -f "supabase/config.toml" ]; then
    echo "❌ Arquivo supabase/config.toml não encontrado. Certifique-se de estar no diretório raiz do projeto."
    exit 1
fi

echo "📝 Aplicando migração de estrutura de honorários..."
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f supabase/migrations/20250103000002_add_fee_structure.sql

if [ $? -eq 0 ]; then
    echo "✅ Migração de honorários aplicada com sucesso!"
else
    echo "❌ Erro ao aplicar migração de honorários."
    exit 1
fi

echo ""
echo "✅ IMPLEMENTAÇÃO COMPLETA DE HONORÁRIOS FINALIZADA!"
echo ""
echo "📊 Novos campos de honorários adicionados:"
echo "   - consultation_fee: Valor da consulta inicial"
echo "   - representation_fee: Valor dos honorários de representação"
echo "   - fee_type: Tipo de cobrança (fixed, success, hourly, plan, mixed)"
echo "   - success_percentage: Percentual de êxito"
echo "   - hourly_rate: Valor por hora"
echo "   - plan_type: Tipo de plano"
echo "   - payment_terms: Condições de pagamento"
echo ""
echo "🎨 Componentes criados/atualizados:"
echo "   - ✅ CostEstimate.tsx: Componente especializado para exibir custos"
echo "   - ✅ DetailedCaseCard.tsx: Atualizado para usar o novo componente"
echo "   - ✅ ImprovedCaseList.tsx: Passa os novos campos de honorários"
echo "   - ✅ CaseData interface: Expandida com campos de honorários"
echo ""
echo "💰 Tipos de honorários suportados:"
echo "   - 🔹 FIXO: Valor fechado para consulta + representação"
echo "   - 🔹 ÊXITO: Só paga se ganhar (% sobre valor obtido)"
echo "   - 🔹 POR HORA: Cobrança baseada no tempo trabalhado"
echo "   - 🔹 PLANO: Mensalidade ou pacote de serviços"
echo "   - 🔹 MISTO: Combinação de consulta fixa + representação"
echo ""
echo "📱 Como aparece no app:"
echo "   - Consulta e Representação exibidos separadamente"
echo "   - Adaptação automática ao tipo de honorário"
echo "   - Condições de pagamento detalhadas"
echo "   - Disclaimers para êxito e cobrança por hora"
echo ""
echo "🧪 Casos de teste criados:"
echo "   - Rescisão Trabalhista (MISTO): Consulta R$ 350 + Representação R$ 2.500"
echo "   - Danos Morais (ÊXITO): Consulta R$ 200 + 25% sobre valor obtido"
echo "   - Consultoria Jurídica (HORA): R$ 250/hora"
echo "   - Consultoria Fiscal (PLANO): R$ 800/mês"
echo ""
echo "🎉 Agora a estimativa de custos está totalmente implementada!"
echo "   Execute 'npm start' e acesse 'Meus Casos' para ver o resultado!" 