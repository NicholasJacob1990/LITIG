# 📋 Implementação de Movimentações Processuais Detalhadas - Escavador SDK

## 🎯 **Objetivo**

Conectar dados reais do Escavador SDK ao frontend Flutter, substituindo os mocks atuais por **linha do tempo detalhada** com movimentações processuais reais, mantendo 100% de compatibilidade visual.

---

## 🏗️ **Arquitetura Implementada**

### **Backend (100% Completo)**

#### **1. Novo Endpoint: `/api/v1/process-movements/`**
- 📍 **`GET /{cnj}/detailed`** - Movimentações detalhadas com classificação
- 📍 **`GET /{cnj}/summary`** - Resumo formatado para ProcessStatusSection

#### **2. Classificador Inteligente de Movimentações**
```python
MovementClassifier.classify_movement(content) → {
    "type": "PETICAO|DECISAO|JUNTADA|CITACAO|AUDIENCIA|CONCLUSAO|OUTROS",
    "icon": "📄|⚖️|📎|📨|🏛️|📋|📌",
    "color": "#3B82F6|#8B5CF6|#10B981|#F59E0B|#EF4444|#6B7280|#9CA3AF",
    "description": "Descrição amigável do tipo"
}
```

#### **3. Métodos do EscavadorClient**
- ✅ `get_detailed_process_movements(cnj, limit)` - Extrai movimentações via SDK V2
- ✅ `get_process_status_summary(cnj)` - Converte para formato do frontend

#### **4. Mapeamento de Fases Processuais**
```python
FASE_MAPPING = {
    "PETICAO" → "Petição Inicial",
    "CITACAO" → "Citação das Partes", 
    "JUNTADA" → "Juntada de Documentos",
    "AUDIENCIA" → "Audiência de Conciliação",
    "CONCLUSAO" → "Conclusão para Decisão",
    "DECISAO" → "Decisão Judicial"
}
```

---

## 📊 **Estrutura de Dados**

### **Compatibilidade 100% com Frontend**

O endpoint `/api/v1/process-movements/{cnj}/summary` retorna:

```json
{
  "current_phase": "Em Andamento",
  "description": "Seu processo está avançando conforme o planejado...",
  "progress_percentage": 65.0,
  "phases": [
    {
      "name": "Petição Inicial",
      "description": "Apresentação formal da causa à justiça.",
      "is_completed": true,
      "is_current": false,
      "completed_at": "2024-01-15T10:30:00Z",
      "documents": []  // Tratados em aba separada
    }
  ],
  "cnj": "1234567-89.2024.1.23.4567",
  "outcome": "andamento|vitoria|derrota"
}
```

### **Elementos Visuais Mapeados**

| Campo Frontend | Origem Escavador | Processamento |
|---|---|---|
| `current_phase` | Outcome + Última movimentação | Classificação NLP |
| `description` | Dinâmica baseada no outcome | Template personalizado |
| `progress_percentage` | Fase atual + Outcome | Cálculo baseado em fases |
| `phases[].name` | Tipo de movimentação | Mapeamento semântico |
| `phases[].is_completed` | Data da movimentação | true se tem data |
| `phases[].is_current` | Índice da fase | Última fase ativa |

---

## 🔄 **Fluxo de Dados**

```mermaid
graph TD
    A[Frontend Flutter] --> B[GET /api/v1/process-movements/{cnj}/summary]
    B --> C[EscavadorClient.get_process_status_summary()]
    C --> D[SDK V2: Processo.movimentacoes()]
    D --> E[MovementClassifier.classify_movement()]
    E --> F[Mapeamento para ProcessStatus]
    F --> G[JSON compatível com frontend]
    G --> H[ProcessStatusSection.build()]
```

---

## 🎨 **Elementos Visuais Preservados**

### **Todos os detalhes do mock atual são mantidos:**

1. **🏷️ Badge de Status** - `current_phase` com cores dinâmicas
2. **📊 Barra de Progresso** - `progress_percentage` calculado dinamicamente  
3. **🟢🟡⚪ Círculos coloridos** - `is_completed`/`is_current` determinam cor
4. **📝 Descrições detalhadas** - Texto real das movimentações do Escavador
5. **📅 Datas de conclusão** - `completed_at` das movimentações reais
6. **📁 Botões de ação** - Mantidos (Documentos + Ver Completo)

### **SEM documentos duplicados:**
- ✅ `documents: []` - Documentos tratados em aba separada
- ✅ Foco apenas no andamento/timeline processual

---

## 🧪 **Testes Realizados**

### ✅ **Classificador de Movimentações**
- 6 tipos de movimentação testados
- Palavras-chave funcionando corretamente
- Ícones e cores atribuídos adequadamente

### ✅ **Estrutura de Dados**
- Campos obrigatórios presentes
- Formato JSON compatível
- Hierarquia de fases preservada

### ✅ **Endpoints Criados**
- Rotas registradas no FastAPI
- Autenticação integrada
- Error handling implementado

---

## 🚀 **Próximos Passos (Frontend)**

### **1. Criar Serviço de API**
```dart
// lib/src/features/cases/data/datasources/process_movements_api.dart
class ProcessMovementsApiDataSource {
  Future<ProcessStatus> getProcessStatus(String cnj) async {
    final response = await _dio.get('/api/v1/process-movements/$cnj/summary');
    return ProcessStatus.fromJson(response.data);
  }
}
```

### **2. Atualizar Repository**
```dart
// lib/src/features/cases/data/repositories/case_repository_impl.dart
@override
Future<ProcessStatus> getProcessStatus(String cnj) async {
  return await _processMovementsApi.getProcessStatus(cnj);
}
```

### **3. Modificar BLoC**
```dart
// lib/src/features/cases/presentation/bloc/case_detail_bloc.dart
// Substituir _getMockProcessStatus() por chamada real à API
```

### **4. Configurar Injeção de Dependência**
```dart
// lib/injection_container.dart
sl.registerLazySingleton(() => ProcessMovementsApiDataSource(dio: sl()));
```

---

## ⚙️ **Configuração de Produção**

### **Variáveis de Ambiente**
```bash
# .env
ESCAVADOR_API_KEY=sua_chave_real_aqui
```

### **Teste com CNJ Real**
```bash
curl -H "Authorization: Bearer TOKEN" \
  http://localhost:8000/api/v1/process-movements/0000000-00.0000.0.00.0000/summary
```

---

## 📈 **Benefícios Alcançados**

1. **🔗 Dados Reais** - Movimentações direto dos tribunais via Escavador
2. **🎯 Compatibilidade Total** - Zero mudanças no UI existente
3. **📱 UX Preservado** - Mesma experiência visual para o usuário
4. **⚡ Performance** - SDK oficial + cache inteligente
5. **🛡️ Robustez** - Error handling + fallbacks
6. **🔧 Manutenibilidade** - Código limpo e documentado

---

## 📞 **Suporte**

- 📁 **Arquivos Criados:**
  - `routes/process_movements.py` - Endpoints da API
  - `scripts/test_process_movements_integration.py` - Testes
  - Métodos adicionados em `services/escavador_integration.py`

- 📋 **Endpoints Disponíveis:**
  - `GET /api/v1/process-movements/{cnj}/detailed`
  - `GET /api/v1/process-movements/{cnj}/summary`

**🎉 Backend 100% pronto! Aguardando conexão do frontend.** 