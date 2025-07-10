# 🚀 Migração de Fonte de Dados: DataJud para Jusbrasil

## 📋 Resumo da Migração

**Data:** 15 de Janeiro de 2025  
**Status:** ✅ **CONCLUÍDA**

Este documento registra a substituição do pipeline de sincronização de KPIs (Key Performance Indicators) de advogados, migrando da API pública **DataJud CNJ** para a **API PRO do Jusbrasil**.

---

## 🎯 Motivação

A migração foi realizada para aumentar a **confiabilidade, performance e qualidade** dos dados de taxa de sucesso dos advogados, que é uma feature crítica (`T`) no algoritmo de match.

| Critério | DataJud CNJ | Jusbrasil PRO API | Vantagem Jusbrasil |
|---|---|---|---|
| **Confiabilidade** | Instável, com timeouts | Alta (SLA definido) | 🟢 **Maior** |
| **Estrutura dos Dados**| JSON bruto, complexo | JSON estruturado | 🟢 **Melhor** |
| **Performance** | Lenta, com muitas consultas | Rápida, otimizada | 🟢 **Superior** |
| **Suporte** | Comunitário | Dedicado (plano PRO) | 🟢 **Garantido** |

---

## 🔧 O que Mudou?

### 1. **Nova Fonte de Dados**
- **Saiu:** API Pública DataJud CNJ
- **Entrou:** **Jusbrasil PRO API** (`https://api.jusbrasil.com.br/v2`)

### 2. **Novo Job de Sincronização**
- **Removido:** `backend/jobs/datajud_sync.py`
- **Adicionado:** `backend/jobs/jusbrasil_sync.py`
  - Implementação `async` com `httpx` para alta performance.
  - Lógica de extração de taxa de sucesso adaptada para o schema do Jusbrasil.

### 3. **Novas Variáveis de Ambiente**
- `JUS_API_URL`: URL base da API do Jusbrasil.
- `JUS_API_TOKEN`: Token de autenticação para a API PRO.

### 4. **Script de Execução Atualizado**
- **Removido:** `scripts/run_datajud_sync.py`
- **Adicionado:** `scripts/run_jusbrasil_sync.py`
  - Adaptado para executar o novo job assíncrono.
  - Inclui logging com rotação de arquivos.

### 5. **Documentação Atualizada**
- `Algoritmo/DataJud_job.md` → `Algoritmo/Jusbrasil_job.md`
- `Algoritmo/Async_architecture.md` → Diagrama atualizado.
- `IMPLEMENTACAO_DATAJUD_COMPLETA.md` → Removido.

---

## ✅ O que NÃO Mudou?

- **O Algoritmo de Match:** A lógica de cálculo do ranking de advogados permanece **inalterada**. A feature `T` (taxa de êxito) continua sendo um dos 7 pilares do cálculo, apenas sua **fonte de dados** foi trocada.
- **Estrutura do Banco de Dados:** O campo `lawyers.kpi.success_rate` continua sendo o destino final do dado.
- **Endpoints da API:** Nenhuma mudança foi necessária nos endpoints `/match` ou `/triage`.

---

## 🚀 Impacto da Migração

- **Maior Precisão:** Os dados do Jusbrasil são mais limpos e estruturados, resultando em um cálculo de taxa de sucesso mais preciso.
- **Melhor Performance:** O novo job assíncrono e a API mais rápida do Jusbrasil reduzem o tempo total de sincronização.
- **Alta Confiabilidade:** Menor chance de falhas por instabilidade da fonte de dados.
- **Manutenibilidade Simplificada:** A API do Jusbrasil é mais fácil de consumir, simplificando a manutenção do job.

---

## 🛠️ Como Executar o Novo Job

```bash
# Execução manual
python3 scripts/run_jusbrasil_sync.py

# Exemplo de agendamento via Cron (diariamente às 3:00)
0 3 * * * /usr/bin/python3 /path/to/project/scripts/run_jusbrasil_sync.py >> /path/to/project/logs/jusbrasil_sync.log 2>&1
```

A migração foi um sucesso e representa um passo importante para a **qualidade e robustez** da plataforma LITGO5. 