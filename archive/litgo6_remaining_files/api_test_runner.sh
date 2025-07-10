#!/bin/bash
export SUPABASE_JWT="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJyb2xlIjoiYXV0aGVudGljYXRlZCJ9.s6S69qT4d_8S_g-A9g_s-X8b-Z_y-t7a_d_e_f_g"
API_URL="http://localhost:8000/api"
echo "�� Iniciando teste da pipeline completa da API..."
echo -e "\n1. Enviando caso para triagem..."
TRIAGE_PAYLOAD='{"texto_cliente":"Fui demitido da minha empresa sem justa causa e não me pagaram as verbas rescisórias. Preciso de ajuda urgente.", "coords":[-23.5505, -46.6333]}'
TASK_RESPONSE=$(curl -s -X POST "$API_URL/triage" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $SUPABASE_JWT" \
     -d "$TRIAGE_PAYLOAD")
TASK_ID=$(echo $TASK_RESPONSE | jq -r '.task_id')
if [ -z "$TASK_ID" ] || [ "$TASK_ID" == "null" ]; then
    echo "❌ Falha ao iniciar a triagem. Resposta:"
    echo $TASK_RESPONSE
    exit 1
fi
echo "✅ Tarefa de triagem iniciada com sucesso. Task ID: $TASK_ID"
echo "   Aguardando 5 segundos para o processamento..."
sleep 5
echo -e "\n2. Verificando status da tarefa..."
STATUS_RESPONSE=$(curl -s -H "Authorization: Bearer $SUPABASE_JWT" "$API_URL/triage/status/$TASK_ID")
STATUS=$(echo $STATUS_RESPONSE | jq -r '.status')
if [ "$STATUS" != "completed" ]; then
    echo "⚠️ A tarefa ainda não foi concluída. Status: $STATUS"
    echo "   Resposta completa:"
    echo $STATUS_RESPONSE
fi
CASE_ID=$(echo $STATUS_RESPONSE | jq -r '.result.case_id')
if [ -z "$CASE_ID" ] || [ "$CASE_ID" == "null" ]; then
    echo "❌ Não foi possível obter o Case ID da triagem."
    exit 1
fi
echo "✅ Triagem concluída! Case ID: $CASE_ID"
echo -e "\n3. Solicitando match para o caso..."
MATCH_PAYLOAD="{\"case_id\": \"$CASE_ID\", \"k\": 3, \"equity\": 0.5}"
MATCH_RESPONSE=$(curl -s -X POST "$API_URL/match" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SUPABASE_JWT" \
    -d "$MATCH_PAYLOAD")
MATCH_COUNT=$(echo $MATCH_RESPONSE | jq '.matches | length')
if [ "$MATCH_COUNT" -gt 0 ]; then
    echo "✅ Match encontrado com $MATCH_COUNT advogado(s)."
    echo "   Exemplo de match:"
    echo $MATCH_RESPONSE | jq '.matches[0]'
else
    echo "⚠️ Nenhum match encontrado ou erro na resposta."
    echo $MATCH_RESPONSE
fi
echo -e "\n🎉 Teste da pipeline da API concluído."
