# Job · Sincronização Jusbrasil → KPI.success_rate
Este documento descreve o job assíncrono responsável por atualizar a taxa de sucesso (`success_rate`) dos advogados, utilizando a API do Jusbrasil como fonte de dados.

## Fluxo do Job
1.  **Disparo**: O job é executado periodicamente (ex: diariamente às 3:00 AM) via `cron` ou orquestrador similar.
2.  **Busca de Advogados**: O script consulta o banco de dados Supabase para obter a lista de todos os advogados ativos que possuem um número de OAB.
3.  **Consulta à API Jusbrasil**: Para cada advogado, o job faz uma chamada à API do Jusbrasil (`https://api.jusbrasil.com.br/v2/advogados/{oab}/processos`) usando a OAB e um token de autenticação.
4.  **Cálculo da Taxa de Sucesso**: O script analisa os resultados dos processos retornados pela API. Ele conta o número de casos com resultado "procedente" e divide pelo número total de casos para calcular a taxa de sucesso.
5.  **Atualização no Banco**: O valor da `success_rate` é atualizado no campo `kpi` (JSONB) do advogado correspondente no Supabase.
6.  **Logging**: Todo o processo é registrado com logs estruturados (JSON), incluindo início, fim, sucessos e falhas, facilitando o monitoramento.

## Exemplo de Código (`backend/jobs/jusbrasil_sync.py`)
```python
async def fetch_success_rate_for_lawyer(client: httpx.AsyncClient, oab_number: str) -> float:
    """Consulta Jusbrasil e calcula taxa de êxito do advogado."""
    headers = {"Authorization": f"Bearer {JUS_API_TOKEN}"}
    request_url = f"{JUS_API_URL}/advogados/{oab_number}/processos"
    
    response = await client.get(request_url, headers=headers)
    data = response.json()
    
    processes = data.get("data", [])
    wins = sum(1 for p in processes if p.get("resultado") == "procedente")
    total_cases = len(processes)
    
    return wins / total_cases if total_cases > 0 else 0.0
```

## Configuração
- **Variáveis de Ambiente**:
  - `JUS_API_URL`: URL base da API do Jusbrasil.
  - `JUS_API_TOKEN`: Token de autenticação para a API.
- **Agendamento (Cron)**:
  ```cron
  0 3 * * * /usr/bin/python3 /path/to/project/backend/jobs/jusbrasil_sync.py
  ```

Este job garante que a feature **T (Taxa de Êxito)** do algoritmo de match seja alimentada por dados atualizados e de uma fonte confiável, impactando diretamente a qualidade do ranking de advogados.
