## Revisão Completa do Aplicativo (Frontend e Backend) – 2025

Este relatório lista achados por arquivo/diretório, com foco em: URLs locais/hardcodes, BLoCs não registrados, rotas duplicadas, chaves expostas, duplicações .bak, TODO/FIXME críticos e compatibilidade app ↔ API. Use este relatório junto com `PLANO_CORRECOES_IMPLEMENTACAO_PRODUCAO.md`.

### Itens críticos (resumo)
- Base URL divergente e hardcodes no app (8080 vs 8000) – ver seção Frontend.
- `SlaAnalyticsBloc` e `AdminBloc` não registrados, mas usados nas rotas – ver DI e Rotas.
- Rota `/triage` duplicada no `app_router.dart`.
- Supabase `anonKey` hardcoded em `apps/app_flutter/lib/main.dart`.
- Android release assinado com `debug`.

---

## Frontend (apps/app_flutter/lib)

### URLs locais/hardcoded
- `src/core/services/dio_service.dart`: usa `127.0.0.1/10.0.2.2:8080/api` por plataforma (diverge do backend em :8000). Centralizar via `ApiConfig.currentBaseUrl`.
- `injection_container.dart`:
  - `FirmRemoteDataSourceImpl`: `'http://localhost:8080/api'`
  - `CaseNotificationRemoteDataSource`: `'http://localhost:8000'` (mover para config)
  - `EnrichedLawyerRemoteDataSource`: `'http://localhost:8000'`
  - `EnrichedFirmDataSourceImpl`: `'http://localhost:8000'`
- Outras ocorrências relevantes: `unipile_service.dart`, `communications_service.dart`, `unified_messaging_service.dart`, `dashboard_remote_data_source.dart`, `cluster_remote_datasource.dart`, `notification_service.dart`, `lawyers_remote_data_source.dart`, `app_config.dart`, `api_service.dart`, `simple_api_service.dart`.

### DI (GetIt)
- `injection_container.dart`:
  - `SlaAnalyticsBloc`: há TODO de implementação e falta registro; porém rota `/sla-settings` o cria via `getIt<SlaAnalyticsBloc>()`.
  - `AdminBloc`: imports comentados; rotas `/admin*` criam via `getIt<AdminBloc>()`.

### Rotas (GoRouter)
- `src/router/app_router.dart`:
  - Rota `/triage` definida duas vezes (linhas ~423 e ~502) – consolidar em uma.
  - Admin pages usam `AdminBloc` não registrado (ver DI).

### Supabase/Firebase
- `lib/main.dart`: `Supabase.initialize` com `anonKey` hardcoded – mover para `--dart-define`.
- Firebase inicializa sem `firebase_options.dart` (não encontrado nesta revisão); alinhar com `flutterfire`.

### Deprecações
- Muitas ocorrências de `withOpacity(...)` (diversos arquivos) – planejar migração para `withValues(alpha: ...)` quando aplicável.

### Arquivos .bak/.bak2
- 40+ arquivos `.bak`/`.bak2` em widgets/screens (perfil, messaging, financial, cases). Manter somente o necessário; remover/arquivar em diretório `archive/` para reduzir ruído.

### TODO/FIXME críticos
- `partnership_repository_impl.dart`: `_baseUrl = 'https://api.litig.com'` e `Authorization: Bearer TOKEN` – parametrizar e integrar com Auth.
- Diversos TODOs de navegação, chamadas reais de API, e melhorias de tratamento de erro.

---

## Backend (packages/backend)

### CORS e URLs
- `api/main.py`: CORS com domínios `localhost` de vários frontends. Parametrizar para produção.
- Várias referências `http://localhost:8000` estão em docs/scripts (ok para docs). Em rotas/serviços, base da API é porta 8000.

### Endpoints relevantes para o app
- `routes/` contém: cases, offers, ratings, documents, chat, video_calls, partnerships, etc. Verificações pontuais:
  - Payments: não há endpoints diretos para `/payments/create-intent` e `/payments/pix` nesta revisão (verificar integração ou ajustar app).
  - Documents: presentes (upload/listagem/health/engines) mas caminhos diferem do app em alguns pontos; alinhar no consumo.
  - Cases extras (my-cases, time_entries/fees/messages): presentes em implementação alternativa (`main_routes.py/simple_server.py`). Avaliar consolidação no entrypoint principal.

### Observabilidade e limites
- `prometheus-fastapi-instrumentator` e `slowapi` estão nas dependências; integrar no `api/main.py` para métricas e rate limiting.

### Variáveis/Config
- `LTR_ENDPOINT` default para `http://ltr-service:8080` em vários pontos (ok em ambiente docker). Revisar para produção.

---

## Ações sugeridas por arquivo (amostra representativa)

- `apps/app_flutter/lib/src/core/services/dio_service.dart`: trocar base para `ApiConfig.currentBaseUrl`; remover lógica de porta local.
- `apps/app_flutter/lib/injection_container.dart`: parametrizar todas as URLs e registrar `SlaAnalyticsBloc`/Admin (ou feature-flag nas rotas até conclusão).
- `apps/app_flutter/lib/src/router/app_router.dart`: remover duplicidade de `/triage`.
- `apps/app_flutter/lib/main.dart`: remover `anonKey` e ler via `--dart-define`; evitar logs de segredos.
- `apps/app_flutter/android/app/build.gradle.kts`: configurar `signingConfigs.release` real.
- `apps/app_flutter/lib/src/core/config/api_config.dart`: consolidar base e expor `currentBaseUrl` como fonte única; usar nas services/datasources.
- `packages/backend/api/main.py`: adicionar instrumentação de métricas e rate limiting; revisar CORS para domínios finais.
- `apps/app_flutter/lib/src/features/lawyers/data/datasources/lawyers_remote_data_source.dart`: remover hardcodes; usar `DioService`/`ApiConfig`.
- `apps/app_flutter/lib/src/features/partnerships/data/repositories/partnership_repository_impl.dart`: remover `Bearer TOKEN`; integrar com Auth real.

---

## Quadro de compatibilidade App ↔ API (amostra)

- App chama `/match` (DioService.findMatches) → Backend expõe `/api/match` (OK; validar payload).
- App chama `/lawyers` (searchLawyers) → Backend expõe `/api/lawyers` (OK; validar filtros).
- App chama documentos `/documents/*` → Backend tem rotas em `routes/documents.py` mas caminhos diferem (ex.: `/documents/upload/{caseId}` no app vs endpoints OCR/document). Alinhar contratos.
- App chama pagamentos `/payments/*` → Não encontrados endpoints exatos nesta revisão; mapear/implementar.

---

## Conclusão

Os principais bloqueadores para produção são: base URL unificada, DI consistente (SLA/Admin), rota `/triage` duplicada, chaves Supabase no código e assinatura Android de release. Em seguida, alinhar contratos API e limpar hardcodes/arquivos .bak. Acompanhar com o plano em `PLANO_CORRECOES_IMPLEMENTACAO_PRODUCAO.md` e checklist de release.


