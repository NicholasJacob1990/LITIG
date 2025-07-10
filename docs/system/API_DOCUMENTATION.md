# 📡 Documentação da API - LITGO5

## 🎯 Visão Geral

A API LITGO5 é um sistema RESTful construído com FastAPI que oferece endpoints para triagem jurídica inteligente, matching de advogados e explicações geradas por IA.

### Base URL
- **Desenvolvimento**: `http://127.0.0.1:8000/api`
- **Produção**: `https://api.litgo.com/api`

### Autenticação
Todos os endpoints (exceto `/`) requerem autenticação JWT via header `Authorization: Bearer <token>`.

---

## 🔐 Autenticação

### Obter Token JWT
```bash
# Via Supabase Auth (frontend)
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password'
});

# Token disponível em: data.session.access_token
```

### Usar Token
```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..." \
     https://api.litgo.com/api/endpoint
```

---

## 📋 Endpoints Principais

### 1. Status da API

#### `GET /`
Verifica se a API está funcionando.

**Request:**
```bash
curl http://127.0.0.1:8000/
```

**Response:**
```json
{
  "status": "ok",
  "message": "Bem-vindo à API LITGO!"
}
```

---

### 2. Triagem Assíncrona

#### `POST /api/triage`
Inicia processo de triagem inteligente com IA.

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "texto_cliente": "Fui demitido sem justa causa e não recebi as verbas rescisórias. A empresa alegou que eu cometi falta grave, mas isso não é verdade. Preciso de ajuda para reverter essa situação.",
  "coords": [-23.5505, -46.6333]
}
```

**Response (202 Accepted):**
```json
{
  "task_id": "abc123-def456-ghi789",
  "status": "accepted", 
  "message": "A triagem do seu caso foi iniciada. Você será notificado quando estiver concluída."
}
```

**Exemplo cURL:**
```bash
curl -X POST http://127.0.0.1:8000/api/triage \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..." \
  -H "Content-Type: application/json" \
  -d '{
    "texto_cliente": "Fui demitido sem justa causa...",
    "coords": [-23.5505, -46.6333]
  }'
```

**Rate Limiting:** 60 requests/minute

---

### 3. Status da Triagem

#### `GET /api/triage/status/{task_id}`
Verifica o status de uma tarefa de triagem.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (Processando):**
```json
{
  "status": "pending"
}
```

**Response (Concluída):**
```json
{
  "status": "completed",
  "result": {
    "case_id": "case-789abc",
    "area": "Trabalhista",
    "subarea": "Rescisão Indireta", 
    "urgency_h": 48,
    "embedding": [0.1, 0.2, 0.3, ...]
  }
}
```

**Response (Falhou):**
```json
{
  "status": "failed",
  "error": "Erro na análise do Claude: Rate limit exceeded"
}
```

**Exemplo cURL:**
```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..." \
     http://127.0.0.1:8000/api/triage/status/abc123-def456-ghi789
```

---

### 4. Match de Advogados

#### `POST /api/match`
Encontra advogados compatíveis para um caso.

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "case_id": "case-789abc",
  "k": 5,
  "equity": 0.3
}
```

**Response (200 OK):**
```json
{
  "case_id": "case-789abc",
  "matches": [
    {
      "lawyer_id": "lw-001",
      "nome": "Dr. João Silva",
      "fair": 0.95,
      "equity": 0.8,
      "features": {
        "A": 1.0,
        "S": 0.9,
        "T": 0.85,
        "G": 0.7,
        "Q": 0.8,
        "U": 0.9,
        "R": 0.88
      },
      "avatar_url": "https://storage.supabase.co/avatars/lw-001.jpg",
      "is_available": true,
      "primary_area": "Trabalhista",
      "rating": 4.8,
      "distance_km": 2.5
    },
    {
      "lawyer_id": "lw-002", 
      "nome": "Dra. Maria Santos",
      "fair": 0.92,
      "equity": 0.9,
      "features": {
        "A": 1.0,
        "S": 0.8,
        "T": 0.9,
        "G": 0.6,
        "Q": 0.85,
        "U": 0.7,
        "R": 0.9
      },
      "avatar_url": "https://storage.supabase.co/avatars/lw-002.jpg",
      "is_available": true,
      "primary_area": "Trabalhista",
      "rating": 4.9,
      "distance_km": 5.2
    }
  ]
}
```

**Exemplo cURL:**
```bash
curl -X POST http://127.0.0.1:8000/api/match \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..." \
  -H "Content-Type: application/json" \
  -d '{
    "case_id": "case-789abc",
    "k": 5,
    "equity": 0.3
  }'
```

**Errors:**
- `404`: Caso não encontrado
- `422`: Parâmetros inválidos

---

### 5. Explicações de Match

#### `POST /api/explain`
Gera explicações personalizadas do por que determinados advogados foram recomendados.

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "case_id": "case-789abc",
  "lawyer_ids": ["lw-001", "lw-002"]
}
```

**Response (200 OK):**
```json
{
  "explanations": {
    "lw-001": "Dr. João Silva é uma excelente opção para seu caso! 🎯 Com 95% de compatibilidade e alta taxa de sucesso em casos trabalhistas similares ao seu, ele demonstra expertise específica em rescisão indireta. Além disso, seu escritório fica a apenas 2.5km de você, facilitando reuniões presenciais quando necessário.",
    "lw-002": "Dra. Maria Santos também é uma ótima escolha! ⭐ Embora esteja um pouco mais distante (5.2km), ela possui uma das maiores taxas de sucesso da plataforma (90%) e excelente avaliação dos clientes (4.9/5). Sua experiência em casos trabalhistas complexos pode ser decisiva para seu caso."
  }
}
```

**Exemplo cURL:**
```bash
curl -X POST http://127.0.0.1:8000/api/explain \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..." \
  -H "Content-Type: application/json" \
  -d '{
    "case_id": "case-789abc", 
    "lawyer_ids": ["lw-001", "lw-002"]
  }'
```

**Rate Limiting:** 30 requests/minute

---

## 📊 Códigos de Status HTTP

| Código | Significado | Quando Ocorre |
|--------|-------------|---------------|
| 200 | OK | Requisição bem-sucedida |
| 202 | Accepted | Tarefa assíncrona aceita |
| 400 | Bad Request | Parâmetros inválidos |
| 401 | Unauthorized | Token JWT inválido/expirado |
| 404 | Not Found | Recurso não encontrado |
| 422 | Unprocessable Entity | Erro de validação Pydantic |
| 429 | Too Many Requests | Rate limit excedido |
| 500 | Internal Server Error | Erro interno do servidor |

---

## 🔧 Modelos de Dados

### TriageRequest
```typescript
interface TriageRequest {
  texto_cliente: string;           // Relato do cliente (obrigatório)
  coords?: [number, number];       // Coordenadas [lat, lng] (opcional)
}
```

### MatchRequest  
```typescript
interface MatchRequest {
  case_id: string;                 // ID do caso (obrigatório)
  k?: number;                      // Número de matches (padrão: 5)
  equity?: number;                 // Peso da equidade (padrão: 0.3)
}
```

### ExplainRequest
```typescript
interface ExplainRequest {
  case_id: string;                 // ID do caso (obrigatório)
  lawyer_ids: string[];            // IDs dos advogados (obrigatório)
}
```

### MatchResult
```typescript
interface MatchResult {
  lawyer_id: string;               // ID único do advogado
  nome: string;                    // Nome completo
  fair: number;                    // Score final (0-1)
  equity: number;                  // Score de equidade (0-1)
  features: {                      // Scores individuais
    A: number;                     // Area Match (0-1)
    S: number;                     // Similarity (0-1)  
    T: number;                     // Taxa de sucesso (0-1)
    G: number;                     // Geolocalização (0-1)
    Q: number;                     // Qualificação (0-1)
    U: number;                     // Urgência (0-1)
    R: number;                     // Rating (0-1)
  };
  avatar_url?: string;             // URL da foto
  is_available: boolean;           // Disponibilidade
  primary_area: string;            // Área principal
  rating?: number;                 // Avaliação (0-5)
  distance_km?: number;            // Distância em km
}
```

---

## 🚀 Fluxo Completo de Uso

### 1. Fluxo Básico
```bash
# 1. Iniciar triagem
curl -X POST http://127.0.0.1:8000/api/triage \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"texto_cliente": "Meu caso jurídico..."}'

# Response: {"task_id": "abc123", "status": "accepted"}

# 2. Polling do status (repetir até completed)
curl -H "Authorization: Bearer $TOKEN" \
     http://127.0.0.1:8000/api/triage/status/abc123

# Response: {"status": "completed", "result": {"case_id": "case-456"}}

# 3. Buscar matches
curl -X POST http://127.0.0.1:8000/api/match \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"case_id": "case-456", "k": 3}'

# Response: {"matches": [...]}

# 4. Obter explicações
curl -X POST http://127.0.0.1:8000/api/explain \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"case_id": "case-456", "lawyer_ids": ["lw-1", "lw-2"]}'

# Response: {"explanations": {...}}
```

### 2. Exemplo JavaScript/TypeScript

```typescript
// Configuração
const API_URL = 'http://127.0.0.1:8000/api';
const token = 'eyJhbGciOiJIUzI1NiIs...';

// Função auxiliar
async function apiCall(endpoint: string, options: RequestInit = {}) {
  const response = await fetch(`${API_URL}${endpoint}`, {
    ...options,
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...options.headers,
    },
  });
  
  if (!response.ok) {
    throw new Error(`API Error: ${response.status}`);
  }
  
  return response.json();
}

// Fluxo completo
async function processarCaso(textoCliente: string) {
  try {
    // 1. Iniciar triagem
    const triageResponse = await apiCall('/triage', {
      method: 'POST',
      body: JSON.stringify({
        texto_cliente: textoCliente,
        coords: [-23.5505, -46.6333]
      })
    });
    
    console.log('Triagem iniciada:', triageResponse.task_id);
    
    // 2. Polling do status
    let status = 'pending';
    let result;
    
    while (status === 'pending') {
      await new Promise(resolve => setTimeout(resolve, 3000)); // 3s
      
      const statusResponse = await apiCall(`/triage/status/${triageResponse.task_id}`);
      status = statusResponse.status;
      result = statusResponse.result;
      
      console.log('Status:', status);
    }
    
    if (status === 'failed') {
      throw new Error('Triagem falhou');
    }
    
    // 3. Buscar matches
    const matchResponse = await apiCall('/match', {
      method: 'POST',
      body: JSON.stringify({
        case_id: result.case_id,
        k: 5
      })
    });
    
    console.log('Matches encontrados:', matchResponse.matches.length);
    
    // 4. Obter explicações para os top 3
    const topLawyers = matchResponse.matches.slice(0, 3).map(m => m.lawyer_id);
    
    const explanationResponse = await apiCall('/explain', {
      method: 'POST',
      body: JSON.stringify({
        case_id: result.case_id,
        lawyer_ids: topLawyers
      })
    });
    
    console.log('Explicações:', explanationResponse.explanations);
    
    return {
      case: result,
      matches: matchResponse.matches,
      explanations: explanationResponse.explanations
    };
    
  } catch (error) {
    console.error('Erro no processamento:', error);
    throw error;
  }
}

// Uso
processarCaso('Fui demitido sem justa causa...')
  .then(resultado => console.log('Processamento concluído:', resultado))
  .catch(erro => console.error('Erro:', erro));
```

---

## ⚠️ Rate Limiting

### Limites por Endpoint
- **`/triage`**: 60 requests/minute
- **`/explain`**: 30 requests/minute  
- **`/match`**: 60 requests/minute
- **`/triage/status/*`**: 120 requests/minute

### Headers de Rate Limit
```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 59
X-RateLimit-Reset: 1640995200
```

### Resposta de Rate Limit Excedido
```json
{
  "detail": "Rate limit exceeded: 60 per 1 minute"
}
```

---

## 🐛 Tratamento de Erros

### Estrutura de Erro Padrão
```json
{
  "detail": "Mensagem de erro descritiva"
}
```

### Erros Comuns

#### 401 Unauthorized
```json
{
  "detail": "Credenciais inválidas ou token expirado"
}
```

#### 404 Not Found
```json
{
  "detail": "Caso com ID 'case-123' não encontrado."
}
```

#### 422 Validation Error
```json
{
  "detail": [
    {
      "loc": ["body", "texto_cliente"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

#### 500 Internal Server Error
```json
{
  "detail": "Erro interno do servidor. Tente novamente."
}
```

---

## 🔍 Debugging e Logs

### Headers de Debug
```http
X-Request-ID: req-123abc
X-Trace-ID: trace-456def
```

### Logs Estruturados
```json
{
  "timestamp": "2025-01-15T10:30:00Z",
  "level": "INFO", 
  "message": "Triagem processada com sucesso",
  "context": {
    "user_id": "user-123",
    "case_id": "case-456",
    "duration_ms": 2500,
    "llm_model": "claude-3-5-sonnet"
  }
}
```

---

## 📈 Métricas e Monitoramento

### Endpoints de Saúde
```bash
# Status geral da API
curl http://127.0.0.1:8000/

# Métricas (futuro)
curl http://127.0.0.1:8000/metrics

# Health check (futuro)
curl http://127.0.0.1:8000/health
```

### Métricas Importantes
- **Latência de triagem**: Tempo médio de processamento
- **Taxa de sucesso**: % de triagens bem-sucedidas
- **Uso de LLM**: Tokens consumidos por modelo
- **Qualidade de matches**: Feedback dos usuários

---

## 🔄 Versionamento da API

### Versão Atual: v1
- **Base URL**: `/api` (equivale a `/api/v1`)
- **Compatibilidade**: Mantida até v2

### Futuras Versões
- **v2**: Melhorias de performance e novos endpoints
- **Deprecação**: v1 será mantida por 12 meses após v2

---

## 📚 Recursos Adicionais

### Postman Collection
```bash
# Importar collection
curl -o LITGO5.postman_collection.json \
     https://api.litgo.com/postman/collection.json
```

### OpenAPI Schema
```bash
# Acessar documentação interativa
http://127.0.0.1:8000/docs

# Schema JSON
http://127.0.0.1:8000/openapi.json
```

### SDKs Oficiais
- **JavaScript/TypeScript**: `npm install @litgo/api-client`
- **Python**: `pip install litgo-api-client`

---

**Última atualização:** Janeiro 2025  
**Versão da API:** v1.0  
**Suporte:** api-support@litgo.com 