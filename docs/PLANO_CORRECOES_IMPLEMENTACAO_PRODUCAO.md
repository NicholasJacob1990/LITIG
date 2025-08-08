## Objetivo

Documentar um plano holístico para corrigir falhas, finalizar funcionalidades e colocar o LITIG-1 em produção com segurança, performance e observabilidade, seguindo SOLID e sem remoções/simplificações indevidas.

## Estado atual verificado (confie, mas verifique)

- **Backend (FastAPI)**: rotas presentes em `packages/backend/routes/` (muitas rotas, incluindo `cases.py`, `offers.py`, `ratings.py`, `video_calls.py`). Entrypoint principal: `packages/backend/api/main.py` (porta 8000, prefixo `/api`, CORS configurado). Versão simplificada para Docker: `packages/backend/main_simple.py`.
- **Frontend (Flutter)**: features em `apps/app_flutter/lib/src/features/` (auth, cases, lawyers, partnerships, financial, ratings, cluster_insights, etc.).
- **DI (GetIt)**: registro central em `apps/app_flutter/lib/injection_container.dart` com dezenas de datasources/repos/usecases/BLoCs.
- **Navegação**: `apps/app_flutter/lib/src/router/app_router.dart` usa `go_router` com rotas complexas e shells.
- **Config HTTP**: `apps/app_flutter/lib/src/core/services/dio_service.dart` usa base `http://127.0.0.1/10.0.2.2:8080/api` (dependendo da plataforma). `ApiConfig` suporta `API_BASE_URL` via `--dart-define`.
- **Testes**: 
  - Flutter: `apps/app_flutter/integration_test/*` (fluxos de busca, auto-context, B2B, etc.).
  - Backend: `packages/backend/tests/*` (unit/integration/e2e) e scripts de verificação.

## Falhas e inconsistências (priorização)

- **P0 – BLoCs não registrados vs rotas**
  - `SlaAnalyticsBloc` é solicitado em `/sla-settings`, mas não há registro correspondente no `injection_container.dart` (apenas TODO). A navegação quebra ao abrir essa rota.
  - `AdminBloc` é solicitado em rotas `/admin*` em `app_router.dart`, porém os registros do Admin estão comentados no `injection_container.dart`. Resultado: crash ao navegar ou injetar.

- **P0 – Divergência de Base URL**
  - `DioService` usa `:8080/api`, enquanto o backend oficial roda em `:8000` com `/api`. Há datasources específicos usando `http://localhost:8000` hardcoded (ex.: `CaseNotificationRemoteDataSource`, Enriched Lawyer/Firm), gerando inconsistência e CORS.

- **P0 – Duplicidade de rotas**
  - Rota `/triage` definida duas vezes em `app_router.dart`. Risco de comportamento inesperado.

- **P0 – Supabase hardcoded**
  - `apps/app_flutter/lib/main.dart` inicializa Supabase com `anonKey` hardcoded. Isso inviabiliza produção e expõe segredo.

- **P1 – Múltiplos entrypoints Flutter**
  - Existem `main.dart`, `main_login.dart`, `main_minimal.dart`, `main_simple.dart`. Ausência de flavors formais (dev/staging/prod) e risco de confusão entre executáveis.

- **P1 – Firebase**
  - App inicializa `Firebase.initializeApp()` mas não está padronizado com `flutterfire`/`firebase_options.dart`. É necessário garantir `GoogleService-Info.plist`/`google-services.json`, permissões iOS e capabilities de Push.

- **P1 – Android release**
  - `android/app/build.gradle.kts` usa `signingConfig = debug` em `release`. É preciso configurar assinatura de release segura.

- **P2 – Observabilidade e defesa**
  - `prometheus-fastapi-instrumentator`, `slowapi` disponíveis, porém não integrados no entrypoint principal. Oportunidade para métricas e rate limiting.
  - Logs `print` de debug em `app_router.dart` (redirecionamento por role) devem ser guardados por flag de debug.

## Plano de correções (técnico)

- **Unificar Base URL do app**
  - Adotar `ApiConfig.currentBaseUrl` em `DioService` para fonte única da base.
  - Parametrizar por `--dart-define API_BASE_URL="https://api.litig.app/api"` (prod), `http://127.0.0.1:8000/api` (dev). Remover hardcodes `:8080` e `:8000` espalhados nos datasources e centralizar via config.

- **Registrar BLoCs requeridos pelas rotas**
  - Implementar/reativar `SlaAnalyticsBloc` mínimo e registrar no `injection_container.dart`.
  - Para Admin: ou implementar repositórios/usecases mínimos e registrar `AdminBloc`, ou aplicar feature-flag que oculte rotas admin até a conclusão. Não remover rotas (exigir flag).

- **Deduplicar rotas**
  - Consolidar `/triage` em uma única definição no `app_router.dart`.

- **Supabase seguro**
  - Remover `anonKey` hardcoded do `main.dart`.
  - Ler `SUPABASE_URL` e `SUPABASE_ANON_KEY` via `--dart-define` (dev/staging/prod) ou via Remote Config/segredos. Garantir que não haja logs com chaves.

- **Flavors formais do Flutter**
  - Introduzir flavors `dev`, `staging`, `prod`, com `main_dev.dart`, `main_staging.dart`, `main_prod.dart` chamando uma factory comum (mantendo entrypoints legados para compatibilidade). Scripts de execução com os `--dart-define` adequados.

- **Firebase**
  - Rodar `flutterfire configure`, gerar `firebase_options.dart` e garantir `GoogleService-Info.plist`/`google-services.json` (fora do repositório público). Revisar permissões iOS (Push Notifications, Background Modes) e `UNUserNotificationCenter`.

- **Android release**
  - Criar `signingConfigs { release { ... } }` com keystore segura e substituir `signingConfig = debug` no `build.gradle.kts`.

- **Observabilidade e limites**
  - Backend: adicionar `PrometheusFastAPIInstrumentator` em `packages/backend/api/main.py`. Opcional: `/metrics` protegido.
  - Habilitar rate limiting via `slowapi` por IP/rota.

- **Higiene de logs**
  - Substituir `print` por logger condicionado a `kDebugMode` no app.

## Plano de implementação por fases

- **Fase 0 – Preparação** (0,5 dia)
  - Criar branch `hardening-prod`.
  - Habilitar CI (lint/test/build) para Flutter e FastAPI.

- **Fase 1 – Correções P0** (1–2 dias)
  - Unificar Base URL e corrigir datasources.
  - Registrar `SlaAnalyticsBloc` e `AdminBloc` (ou feature-flag de Admin temporária).
  - Deduplicar rota `/triage`.
  - Remover Supabase hardcoded; parametrizar via `--dart-define`.

- **Fase 2 – P1 (Flavors, Firebase, Android release)** (1–2 dias)
  - Implementar flavors e scripts de build.
  - Configurar `flutterfire` e arquivos nativos.
  - Ajustar assinatura Android de release.

- **Fase 3 – Observabilidade e proteção** (1 dia)
  - Instrumentar Prometheus, habilitar `slowapi`, revisar CORS/domínios.

- **Fase 4 – QA e E2E** (1–2 dias)
  - Rodar `integration_test` do Flutter e `packages/backend/tests` (unit/integration/e2e). Corrigir regressões.
  - Testes manuais críticos (login, triagem, casos, ofertas, pagamentos, avaliações, video calls).

- **Fase 5 – Go-live** (0,5 dia)
  - Deploy backend (Docker/K8s) com `DATABASE_URL`, `REDIS_URL`, chaves de terceiros.
  - Deploy Flutter Web (se aplicável), publicação Android (Play Console) e iOS (TestFlight/App Store).

## Itens de trabalho detalhados (por componente)

- **Frontend**
  - `DioService`: ler base de `ApiConfig.currentBaseUrl` e remover divergências 8080/8000.
  - `injection_container.dart`: registrar `SlaAnalyticsBloc`; implementar gating para Admin até registro completo.
  - `app_router.dart`: deduplicar `/triage`, proteger logs e verificar `ChatRoomsScreen`/tabs.
  - Supabase/Firebase: parametrização por flavors + `flutterfire`.
  - Auditar chamadas a endpoints existentes no backend (`/cases`, `/offers`, `/ratings`, `/video-call`, `/payments`).

- **Backend**
  - `api/main.py`: adicionar instrumentação Prometheus e rate limiting; validar CORS de produção (domínios web/móveis).
  - Variáveis de ambiente obrigatórias: `DATABASE_URL`, `REDIS_URL`, `ESCAVADOR_API_KEY`, `JUSBRASIL_API_KEY`, `STRIPE_*`, `SENDGRID_*`.
  - Executar migrações Alembic e Supabase (diretório `supabase/migrations`).

## Testes e critérios de aceite

- **Automatizados**
  - Todos os testes em `apps/app_flutter/integration_test` e `packages/backend/tests` verdes.
  - Análise estática sem erros críticos.

- **Manuais (smoke)**
  - Login → Dashboard redirecionado conforme role.
  - Triagem → Gera caso e apresenta matches com explainability.
  - Casos → Documentos (upload/listagem) e mensagens.
  - Ofertas → Aceitar/rejeitar.
  - Pagamentos → Intent/PIX flow.
  - Avaliações → Submissão da nota.
  - Video calls → Criação/join de sala.

## Riscos e mitigação

- **Divergência de ambientes**: mitigar com flavors e `--dart-define` claros.
- **Chaves expostas**: mitigar com segredos fora do repositório, CI com variáveis encriptadas.
- **Libs pesadas (torch/pycaret)**: imagem de build dedicada e cache de dependências; avaliar extras opcionais.
- **CORS**: validar domínios finais (web/app) antes do go-live.

## Próximos passos imediatos

- Corrigir P0 (Base URL, BLoCs, rota duplicada, Supabase) e abrir PR.
- Configurar flavors e `flutterfire`.
- Rodar suíte de testes completa e estabilizar.


