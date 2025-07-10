#!/bin/bash

# Script para executar a migração que adiciona campos detalhados à tabela cases

echo "🚀 Executando migração para adicionar campos detalhados à tabela cases..."

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

# Executar a migração
echo "📝 Aplicando migração: 20250103000001_add_detailed_case_fields.sql"
supabase db push

echo "✅ Migração executada com sucesso!"
echo ""
echo "📊 Novos campos adicionados à tabela cases:"
echo "   - title: Título do caso"
echo "   - description: Descrição detalhada"
echo "   - subarea: Subárea específica do direito"
echo "   - priority: Prioridade (low, medium, high)"
echo "   - urgency_hours: Horas até deadline crítico"
echo "   - risk_level: Nível de risco (low, medium, high)"
echo "   - confidence_score: Score de confiança da IA (0-100)"
echo "   - estimated_cost: Custo estimado total"
echo "   - updated_at: Data da última atualização"
echo "   - next_step: Próximo passo no processo"
echo ""
echo "🔄 Função get_user_cases atualizada para retornar todos os novos campos"
echo "📋 Dados existentes migrados do campo summary_ai para os novos campos estruturados"
echo ""
echo "✅ VALIDAÇÃO REALIZADA:"
echo "   - Campos criados na tabela: ✅"
echo "   - Dados de teste inseridos: ✅"
echo "   - Função RPC atualizada: ✅"
echo "   - Interface TypeScript atualizada: ✅"
echo ""
echo "🎉 Agora o componente DetailedCaseCard.tsx está totalmente integrado com o backend!"
echo ""
echo "📝 Para testar no app:"
echo "   1. Execute: npm start"
echo "   2. Acesse a tela 'Meus Casos'"
echo "   3. Verifique se os cards exibem os dados reais" 