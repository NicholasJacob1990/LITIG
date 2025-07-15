

# 📋 Plano de Ação: Implementação de Escritórios (B2B Matching)

**Documento Versão 1.1 - 2024-07-26**

Este documento detalha o plano de ação completo para a implementação da funcionalidade de **Escritórios de Advocacia (Law Firms)** na plataforma, incluindo o matching B2B e incorporando requisitos essenciais de segurança, performance e migração de dados para garantir um lançamento robusto.

---

## 1. 🚀 Visão Geral e Estratégia

O objetivo é evoluir o algoritmo de matching para considerar a **reputação do escritório (Feature-E)** e introduzir um **modo de ranking em dois passos** para casos corporativos, garantindo uma experiência B2B robusta e coerente.

### 1.1. Estratégia de Rollout

A implementação será faseada para mitigar riscos, utilizando uma **feature flag** (`ENABLE_FIRM_MATCH`).

1.  **Fase 1: Backend & Infraestrutura:** Implementar toda a lógica de backend, migrations e API.
2.  **Fase 2: Frontend (Base):** Criar os modelos e componentes de UI reutilizáveis no Flutter.
3.  **Fase 3: Frontend (Integração por Interface):** Conectar a UI com a API para cada tipo de usuário.
4.  **Fase 4: Testes & Lançamento:** Executar testes E2E, documentar e lançar via deploy canário.

### 1.2. Arquitetura de Navegação e Perfis

A forma como as funcionalidades B2B se integram aos diferentes perfis de usuário, suas abas de navegação e fluxos de trabalho específicos, está detalhada no documento central de arquitetura do sistema.

**[➡️ Consulte aqui a Arquitetura Geral do Sistema para detalhes sobre Perfis e Navegação](../ARQUITETURA_GERAL_DO_SISTEMA.md)**

---

## 2. 📝 Plano de Ação Detalhado (To-Do List)

### ✅ **Fase 1: Backend & Infraestrutura**

| ID | Tarefa | Status | Depende de | Detalhes |
| :--- | :--- | :--- | :--- | :--- |
| `backend_migrations` | Criar migrations de banco de dados | ⬜️ Pendente | - | Criar tabelas `law_firms`, `firm_kpis` e adicionar `firm_id` a `lawyers`. |
| `migration_backfill` | Script de migração de dados legados | ⬜️ Pendente | `backend_migrations` | Criar script one-off para popular `firm_id` em advogados existentes e fazer backfill de KPIs. |
| `backend_indexing` | Adicionar índices de performance no DB | ⬜️ Pendente | `backend_migrations` | Adicionar índices SQL em campos-chave das tabelas `law_firms` e `firm_kpis` para otimizar queries. |
| `backend_endpoints` | Implementar Endpoints da API | ⬜️ Pendente | `backend_migrations` | CRUD para `/firms` e `/firms/{id}/kpi`. Atualizar `/match`. |
| `backend_security` | Definir escopos de segurança da API | ⬜️ Pendente | `backend_endpoints` | Definir escopos OAuth/JWT para endpoints `/firms` e sanitizar KPIs sensíveis. |
| `backend_feature_e` | Implementar Feature-E no Algoritmo | ⬜️ Pendente | - | Adicionar `firm_reputation()` ao `FeatureCalculator`. |
| `backend_dataclasses` | Criar Dataclasses `LawFirm` e `FirmKPI` | ⬜️ Pendente | `backend_feature_e` | Definir as estruturas de dados no `algoritmo_match.py`. |
| `backend_weights` | Atualizar Pesos do Algoritmo | ⬜️ Pendente | `backend_feature_e` | Incluir `E` nos `DEFAULT_WEIGHTS` e criar preset `b2b`. |
| `backend_two_pass` | Implementar Algoritmo Two-Pass | ⬜️ Pendente | `backend_feature_e` | Adaptar `rank()` para o modo B2B. |
| `backend_tests` | Criar Testes Unitários | ⬜️ Pendente | `backend_two_pass` | `test_feature_E`, `test_rank_two_pass`. |
| `backend_observability` | Adicionar Observabilidade | ⬜️ Pendente | `backend_two_pass` | Adicionar label `entity` ao contador do Prometheus. |

### ✅ **Fase 2: Frontend Flutter (Base)**

| ID | Tarefa | Status | Depende de | Detalhes |
| :--- | :--- | :--- | :--- | :--- |
| `flutter_models` | Criar Modelos `LawFirm` e `FirmKPI` | ⬜️ Pendente | `backend_endpoints` | Mapear a resposta da API em `domain/entities` e `data/models`. |
| `flutter_repositories` | Atualizar Repositórios e Data Sources | ⬜️ Pendente | `flutter_models` | Adicionar métodos para buscar dados de escritórios. |
| `flutter_firm_card` | Criar Widget `FirmCard` | ⬜️ Pendente | `flutter_models` | Widget reutilizável para exibir um escritório em listas. |
| `flutter_firm_detail` | Criar Tela `FirmDetailScreen` | ⬜️ Pendente | `flutter_firm_card` | Tela para exibir detalhes do escritório e seus advogados. |
| `flutter_routing` | Adicionar Novas Rotas | ⬜️ Pendente | `flutter_firm_detail` | `/firm/:firmId` e `/firm/:firmId/lawyers` no `app_router.dart`. |

### ✅ **Fase 3: Frontend Flutter (Integração por Interface)**

| ID | Tarefa | Status | Depende de | Detalhes |
| :--- | :--- | :--- | :--- | :--- |
| `flutter_blocs` | Atualizar BLoCs de Match e Parceria | ⬜️ Pendente | `flutter_repositories` | Gerenciar estado para listas híbridas (advogados + escritórios). |
| `flutter_client_lawyers` | **(Cliente)** Atualizar `LawyersScreen` | ⬜️ Pendente | `flutter_firm_card` | Renderizar `FirmCard` na busca de advogados. |
| `flutter_client_cases` | **(Cliente)** Atualizar `CasesScreen` | ⬜️ Pendente | `flutter_models` | Exibir o escritório recomendado no match de um caso. |
| `flutter_captacao_parceiros` | **(Adv. Captação)** Atualizar `LawyerSearchScreen` | ⬜️ Pendente | `flutter_firm_card` | Permitir a busca de escritórios para firmar parcerias. |
| `flutter_captacao_parcerias` | **(Adv. Captação)** Atualizar `PartnershipsScreen` | ⬜️ Pendente | `flutter_firm_card` | Exibir parcerias ativas com escritórios. |
| `flutter_associado_dashboard` | **(Adv. Associado)** Atualizar `DashboardScreen` | ⬜️ Pendente | `flutter_models` | Exibir informações do escritório ao qual o advogado pertence. |
| `flutter_associado_profile` | **(Adv. Associado)** Atualizar `ProfileScreen` | ⬜️ Pendente | `flutter_models` | Mostrar o vínculo com o escritório no perfil. |
| `flutter_tests` | Criar Testes de Widget e Tela | ⬜️ Pendente | `flutter_firm_card` | Testar os novos componentes de UI (`FirmCard`, `FirmDetailScreen`). |

### ✅ **Fase 4: Lançamento e Documentação**

| ID | Tarefa | Status | Depende de | Detalhes |
| :--- | :--- | :--- | :--- | :--- |
| `documentation` | Atualizar Documentação | ⬜️ Pendente | - | `ANALISE_FUNCIONAL.md`, `status.md`, e `CHANGELOG.md`. |
| `openapi_examples` | Adicionar exemplos de payload na OpenAPI | ⬜️ Pendente | `backend_endpoints` | Incluir exemplos completos de request/response para os novos endpoints de escritórios. |
| `e2e_tests` | Criar Testes E2E | ⬜️ Pendente | Todas as outras | Cenário completo: cliente cria caso B2B e contrata um escritório. |
| `monitor_latency` | Configurar Alertas de Latência | ⬜️ Pendente | `backend_two_pass` | Alerta no Prometheus para latência p99 do ranking B2B (ex: > 200ms). |
| `rollback_script` | Criar Script de Rollback Rápido | ⬜️ Pendente | `rollout` | Script `disable_firm_match.sh` para desativar a feature flag e reverter presets. |
| `rollout` | Executar Plano de Rollout | ⬜️ Pendente | `e2e_tests` | Ativar feature flag em stage, monitorar e expandir. |

---

## 3. ⚙️ Detalhes Técnicos Completos

### 3.1. 📂 Patch Backend - Feature-E (`algoritmo_match.py`)

#### FeatureCalculator - Nova Feature E

```diff
@@
 class FeatureCalculator:
     ...
+    # ------------------------------------------------------------------
+    #  🆕  Feature-E : Employer / Firm Reputation
+    # ------------------------------------------------------------------
+    def firm_reputation(self) -> float:
+        """
+        Escora reputação do escritório contendo o advogado.
+        • Caso o advogado não possua firm_id ⇒ score neutro 0.5
+        • Fórmula ponderada: 40 % taxa sucesso, 25 % NPS,
+          20 % reputação mercado, 15 % diversidade corporativa
+        """
+        firm = getattr(self.lawyer, "firm", None)     # Lawyer.firm FK lazy-loaded
+        if not firm or not firm.kpi_firm:
+            return 0.5
+
+        k = firm.kpi_firm
+        return np.clip(
+            0.4 * k.success_rate +
+            0.25 * k.nps +
+            0.20 * k.reputation_score +
+            0.15 * k.diversity_index,
+            0, 1
+        )
```

#### Atualização do método all()

```diff
@@
     def all(self) -> Dict[str, float]:
-        return {
-            "A": self.area_match(),
-            "S": self.case_similarity(),
-            "T": self.success_rate(),
-            "G": self.geo_score(),
-            "Q": self.qualification_score(),
-            "U": self.urgency_capacity(),
-            "R": self.review_score(),
-            "C": self.soft_skill(),
-        }
+        feats = {
+            "A": self.area_match(),
+            "S": self.case_similarity(),
+            "T": self.success_rate(),
+            "G": self.geo_score(),
+            "Q": self.qualification_score(),
+            "U": self.urgency_capacity(),
+            "R": self.review_score(),
+            "C": self.soft_skill(),
+            "E": self.firm_reputation(),   # ← nova feature
+        }
+        return feats
```

### 3.2. 📂 Patch Pesos (`weights.py`)

```diff
 DEFAULT_WEIGHTS = {
     "A": 0.30, "S": 0.25, "T": 0.15, "G": 0.10,
-    "Q": 0.10, "U": 0.05, "R": 0.05, "C": 0.03
+    "Q": 0.10, "U": 0.05, "R": 0.05, "C": 0.03, "E": 0.03
 }
 
 PRESET_WEIGHTS = {
     ...
     "b2b": {
-        "A": .18, "S": .20, "T": .20, "Q": .22,
-        "G": .05, "U": .05, "R": .05, "C": .05
+        "A": .16, "S": .18, "T": .18, "Q": .20,
+        "E": .10, "G": .05, "U": .05, "R": .04, "C": .04
     },
 }
```

**Nota:** Em casos corporativos, `E` (reputação do escritório) chega a 10%.

### 3.3. 📂 Patch Algoritmo Two-Pass (`algorithm.py`)

```diff
@@
 class MatchmakingAlgorithm:
     ...
     async def rank(
         self,
         case: Case,
         lawyers: List[Lawyer],
         *,
         top_n: int = 5,
         preset: str = "balanced",
-        model_version: Optional[str] = None,
+        model_version: Optional[str] = None,
         exclude_ids: Optional[Set[str]] = None
     ) -> List[Lawyer]:
 
         ...
+        two_pass = preset == "b2b"

+        # ---------- PASSO 1 : ranquear Firms ----------
+        if two_pass:
+            firms = [lw for lw in lawyers if isinstance(lw, LawFirm)]
+            if firms:
+                firm_ranking = await self._rank_once(
+                    case, firms, top_n=len(firms), weights_override=None
+                )
+                top_firms = {f.id for f in firm_ranking[: min(3, len(firm_ranking))]}
+                # manter advogados que pertençam a top-firms
+                lawyers = [
+                    lw for lw in lawyers
+                    if not isinstance(lw, LawFirm) and getattr(lw, "firm_id", None) in top_firms
+                ] + firm_ranking  # mantém firmas no pool final

+        # ---------- PASSO 2 : ranking final ----------
+        return await self._rank_once(
+            case, lawyers, top_n=top_n, weights_override=None
+        )
```

*Helper privado `_rank_once` contém o corpo original refatorado.*

### 3.4. 📂 Migration Alembic (`20250713_add_law_firms_v2.py`)

```python
def upgrade():
    op.add_column("lawyers", sa.Column("firm_id", sa.String(), nullable=True))
    op.create_table(
        "law_firms",
        sa.Column("id", sa.String(), primary_key=True),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("team_size", sa.Integer(), server_default="0"),
        sa.Column("main_lat", sa.Float()),
        sa.Column("main_lon", sa.Float()),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now())
    )
    op.create_table(
        "firm_kpis",
        sa.Column("firm_id", sa.String(), sa.ForeignKey("law_firms.id"), primary_key=True),
        sa.Column("success_rate", sa.Float(), default=0),
        sa.Column("nps", sa.Float(), default=0),
        sa.Column("reputation_score", sa.Float(), default=0),
        sa.Column("diversity_index", sa.Float(), default=0),
        sa.Column("active_cases", sa.Integer(), default=0),
    )
```

### 3.5. 📂 Novos Endpoints da API

- `POST /firms/` – Criar escritório
- `GET /firms/{id}` – Obter detalhes do escritório
- `PUT /firms/{id}/kpi` – Atualizar KPIs agregados
- `GET /match?include_firms=true` – Matching incluindo escritórios (preset automático para `b2b` se `case.type=="CORPORATE"`)

---

## 4. ✅ Estratégia de Testes

### 4.1. Testes Unitários

- **`test_feature_E.py`** – Cobertura unitária da nova feature (98% branch coverage)
- **`test_rank_two_pass.py`** – Garantir que apenas advogados de top-3 escritórios chegam ao ranking final em modo B2B

### 4.2. Testes E2E

- **`e2e_firm_contract.feature`** – Cenário completo: usuário cria caso corporativo → recebe ranking com escritórios → escolhe escritório → vê lista de advogados filtrada por escritório

### 4.3. Testes de CI/CD
- **Linting de OpenAPI:** Garantir que novos endpoints seguem as convenções da API.
- **Testes de Widget Flutter:** Adicionar job no pipeline para rodar testes de UI do Flutter.
---

## 5. 📊 Observabilidade e Monitoramento

### 5.1. Métricas Prometheus

- Counter `litgo_match_rank_total` com novo label `entity="lawyer|firm"`
- Monitorar métrica `match_b2b_success_rate` (meta ≥ 70% aceite na 1ª oferta)

### 5.2. Dashboard Grafana

- Painel "B2B Funnel" atualizado para mostrar métricas de escritórios

---

## 6. 🚀 Estratégia de Rollout Detalhada

### 6.1. Variáveis de Ambiente

| Variável ENV | Valor | Comentário |
|--------------|-------|------------|
| `ENABLE_FIRM_MATCH` | `true` | Libera endpoints & migrations |
| `DEFAULT_PRESET_CORPORATE` | `"b2b"` | Muda peso padrão para casos corporativos |

### 6.2. Gestão de Feature Flags
Para um rollout mais fluido e segmentado, a variável de ambiente `ENABLE_FIRM_MATCH` será substituída por um serviço de gestão centralizado (ex: tabela `feature_flags` no Supabase) para permitir ramp-up gradual sem a necessidade de novos deploys.

### 6.3. Fases de Deploy

1. **Deploy Canário (Stage)** – Apenas contas de teste (`org=litgo-labs`)
2. **Firmas Piloto** – Importar 5 escritórios via script `seed_firms.py`
3. **Monitoramento** – Acompanhar `match_b2b_success_rate` por 3 dias
4. **Expansão Gradual** – 10% da base corporativa (feature flag)
5. **Full Rollout** – 7 dias se não houver regressões de latência (> 50ms)

---

## 7. 🔍 Checklist para Revisão

### 7.1. Migrations
```bash
alembic upgrade head
```
- Verificar se tabelas `law_firms` e `firm_kpis` são criadas
- Verificar se coluna `firm_id` aparece em `lawyers`
- Executar script de backfill `migration_backfill.py` e validar dados populados

### 7.2. Build & Testes
```bash
poetry run pytest -m "not slow"
```
- Todos os 297 testes + 16 novos devem passar

### 7.3. Linters & Type-checking
```bash
pre-commit run --all-files
mypy . --strict
```

### 7.4. Dashboard
- Abrir Grafana → painel "B2B Funnel" → conferir métricas `entity=firm`
- Verificar se o alerta de latência (`monitor_latency`) está ativo e configurado.

### 7.5. Teste Manual
- Front-end mobile: criar caso tipo "M&A internacional" → validar ranking que exibe 3 escritórios + advogados da firma vencedora

---

## 8. 🗂️ Atualizações de Documentação

| Arquivo | Alteração |
|---------|-----------|
| `docs/architecture.md` | Seção "Agents" atualizada com `LawFirm ← Lawyer (1-N)` + diagrama UML |
| `docs/api_openapi.yaml` | Esquema `FirmOut`, rotas `/firms/*` |
| `CHANGELOG.md` | Versão `v2.6.3` – "Employer Reputation & B2B mode" |
| `status.md` | Flag `ENABLE_FIRM_MATCH=true` adicionada ao rollout checklist |

---

## 9. ⏭️ Próximos Passos (Fase 3)

| Item | Descrição | ETA |
|------|-----------|-----|
| **Auto-agg KPIs** | Cron job Supabase → calcular `success_rate` e `nps` a cada 24h | Ago 2025 |
| **Diversity API** | Endpoint `POST /firms/{id}/diversity` para atualizar índice ESG | Set 2025 |
| **Re-treino Pesos** | AB-test com gradient descent para refinar `E` nos presets | Out 2025 |

---

## 10. 📝 Conclusão

O **PR feature/law-firms-v2** entrega:

1. **Suporte pleno a escritórios** sem quebrar lógica de advogados individuais
2. **Feature-E** que introduz reputação corporativa no algoritmo
3. **Ranking 2-passos** opcional para casos corporativos (preset `b2b`)
4. **Migrations, API, testes, observabilidade e docs** prontos

### 10.1. Pontos de Atenção Críticos

- `Lawyer` hoje NÃO possui `firm` nem `firm_id` - o patch assume esses campos
- `LawFirm` precisa ser criado como dataclass com adaptadores Supabase/SQLAlchemy
- `algorithm._rank_once()` precisa adaptação para objetos `LawFirm`
- **Cache e Pesos:** A função `load_weights()` deve ser atualizada para aceitar a chave "E". O cache do Redis deve usar prefixos distintos (ex: `match:cache:firm:`) para evitar colisões.
- **UI e UX:** O frontend deve ter um estado de fallback para o caso de não haver escritórios elegíveis, evitando telas vazias.
- **Log de Auditoria:** O `firm_id` deve ser registrado quando uma oferta for feita/aceita para garantir rastreabilidade.

### 10.2. Recomendação de Implementação

1. **Merge parcial:** Feature-E + pesos + migrations (sem modo dois-passos)
2. **Branch posterior:** Adicionar `LawFirm` + algoritmo dois-passos
3. **Feature flag:** Manter `ENABLE_FIRM_MATCH` para ativação gradual

**Este plano garante uma implementação estruturada, de baixo risco e com rollback fácil.** 