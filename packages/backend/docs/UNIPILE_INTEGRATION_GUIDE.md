# Guia de Integração Unipile

## Visão Geral

Este guia documenta a integração com a API oficial do Unipile para extração de dados de comunicação profissional, baseado na documentação oficial em `https://developer.unipile.com/reference/accountscontroller_listaccounts`.

## Configuração

### Variáveis de Ambiente

```bash
# Token de autenticação da API Unipile (obrigatório)
UNIPILE_API_TOKEN=seu_token_aqui

# URL base da API (opcional, usa padrão se não especificado)
UNIPILE_BASE_URL=https://api.unipile.com

# DSN personalizado (opcional)
UNIPILE_DSN=seu_dsn_aqui
```

### Headers de Autenticação

A API do Unipile utiliza o header `X-API-KEY` para autenticação:

```python
headers = {
    "X-API-KEY": "seu_token_aqui",
    "Content-Type": "application/json",
    "Accept": "application/json"
}
```

## Endpoints Implementados

### 1. Listar Contas (`/accounts`)

**Endpoint oficial**: `GET /api/v1/accounts`

**Parâmetros de consulta**:
- `limit`: Limite de resultados (padrão: 100)
- `offset`: Offset para paginação (padrão: 0)

**Estrutura de resposta esperada**:
```json
{
  "data": [
    {
      "account_id": "12345",
      "provider": "gmail",
      "email": "user@example.com",
      "status": "active",
      "last_sync": "2024-01-15T10:30:00Z"
    }
  ],
  "total": 1,
  "pagination": {
    "limit": 100,
    "offset": 0,
    "has_more": false
  }
}
```

### 2. Obter Perfil (`/profile/{email}`)

**Endpoint**: `GET /api/v1/profile/{email}`

**Resposta**:
```json
{
  "provider_id": "user123",
  "provider": "linkedin",
  "name": "João Silva",
  "email": "joao@example.com",
  "profile_data": {
    "connections": 500,
    "industry": "Legal Services"
  }
}
```

### 3. Dados de Comunicação (`/lawyer/{oab}/communication`)

**Endpoint**: `GET /api/v1/lawyer/{oab_number}/communication`

**Parâmetros**:
- `email`: Email do advogado (opcional)

**Resposta**:
```json
{
  "communication_score": 0.85,
  "email_activity": {
    "sent_count": 150,
    "received_count": 200,
    "response_rate": 0.95
  },
  "linkedin_activity": {
    "connections": 800,
    "posts_count": 25,
    "engagement_rate": 0.12
  }
}
```

## Tratamento de Erros

### Códigos de Status HTTP

- **200**: Sucesso
- **401**: Token de API inválido
- **429**: Rate limit atingido
- **500**: Erro interno do servidor

### Exemplo de Tratamento

```python
async def handle_unipile_response(response):
    if response.status == 200:
        return await response.json()
    elif response.status == 401:
        logger.error("Token de API inválido para Unipile")
        return None
    elif response.status == 429:
        logger.warning("Rate limit atingido na API Unipile")
        # Implementar retry com backoff
        return None
    else:
        error_text = await response.text()
        logger.error(f"Erro Unipile: {response.status} - {error_text}")
        return None
```

## Uso no Sistema LITGO

### Integração com Hybrid Legal Data Service

O Unipile é integrado como uma fonte de dados no sistema híbrido:

```python
# Posição 2 na hierarquia de fontes
TRANSPARENCY_SOURCES = {
    DataSource.ESCAVADOR: 0.30,    # 1º lugar
    DataSource.UNIPILE: 0.20,      # 2º lugar - dados de comunicação
    DataSource.JUSBRASIL: 0.25,    # 3º lugar
    DataSource.CNJ: 0.15,          # 4º lugar
    DataSource.OAB: 0.07,          # 5º lugar
    DataSource.INTERNAL: 0.03      # 6º lugar
}
```

### Cálculo de Score de Comunicação

O score é calculado baseado em:
- **Atividade de email** (40%): Volume e taxa de resposta
- **Atividade LinkedIn** (35%): Conexões e engajamento
- **Rede profissional** (25%): Qualidade das conexões

```python
def _calculate_communication_score(self, metrics: Dict) -> float:
    """Calcula score de comunicação baseado nas métricas."""
    email_score = metrics.get("email_activity", {}).get("response_rate", 0) * 0.4
    linkedin_score = min(metrics.get("linkedin_activity", {}).get("engagement_rate", 0), 1.0) * 0.35
    network_score = min(metrics.get("professional_network", {}).get("quality_score", 0), 1.0) * 0.25
    
    return min(email_score + linkedin_score + network_score, 1.0)
```

## Testes e Validação

### Endpoint de Health Check

```bash
curl -X GET "http://localhost:8080/api/v1/unipile/health" \
  -H "Authorization: Bearer seu_token_jwt"
```

### Teste de Integração

```bash
curl -X POST "http://localhost:8080/api/v1/unipile/test-integration?test_email=teste@example.com" \
  -H "Authorization: Bearer seu_token_jwt"
```

## Monitoramento e Logs

### Métricas Importantes

- Taxa de sucesso das requisições
- Tempo de resposta médio
- Erros de rate limiting
- Contas conectadas ativas

### Logs Estruturados

```python
logger.info(f"Listadas {len(accounts)} contas do Unipile")
logger.warning("Rate limit atingido na API Unipile")
logger.error(f"Erro ao listar contas Unipile: {response.status} - {error_text}")
```

## Segurança

### Boas Práticas

1. **Nunca** exponha o token de API em logs
2. Use HTTPS para todas as requisições
3. Implemente retry com backoff exponencial
4. Configure timeouts apropriados (15s para operações normais)
5. Monitore tentativas de acesso não autorizadas

### Configuração de Produção

```python
# Timeout mais longo para operações críticas
async with session.get(url, headers=headers, params=params, timeout=15) as response:
    # Tratamento de resposta
```

## Troubleshooting

### Problemas Comuns

1. **Token inválido**: Verifique se `UNIPILE_API_TOKEN` está configurado corretamente
2. **Rate limiting**: Implemente retry com backoff
3. **Timeout**: Aumente o timeout para operações complexas
4. **Estrutura de dados**: Verifique se a resposta da API mudou

### Debug

```python
# Habilitar logs detalhados
logging.getLogger("backend.services.unipile_service").setLevel(logging.DEBUG)
```

## Atualizações Futuras

- Suporte a webhooks para notificações em tempo real
- Cache Redis para dados de comunicação
- Métricas Prometheus para monitoramento
- Suporte a múltiplas contas por advogado 