## Release Checklist – LITIG-1 (Backend + Flutter)

### 1) Infra/Segredos
- [ ] Definir `DATABASE_URL`, `REDIS_URL`, `ESCAVADOR_API_KEY`, `JUSBRASIL_API_KEY`, `STRIPE_*`, `SENDGRID_*` no ambiente (prod/staging)
- [ ] Configurar variáveis de CI/CD seguras (sem chaves em repositório)

### 2) Backend (FastAPI)
- [ ] Instalar deps: `pip install -r packages/backend/requirements.txt`
- [ ] Rodar migrações Alembic/Supabase (se aplicável)
- [ ] Habilitar CORS para domínios de produção (web/app)
- [ ] Instrumentação Prometheus e endpoint `/metrics` protegido
- [ ] Rate limiting com `slowapi` (limites por rota)
- [ ] Testes: `pytest packages/backend/tests -q` verdes
- [ ] Executar `uvicorn backend.api.main:app --host 0.0.0.0 --port 8000`

### 3) Flutter – Configuração
- [ ] Flavors criados: `dev`, `staging`, `prod`
- [ ] Base URL via `--dart-define API_BASE_URL=...` coerente com backend (`.../api`)
- [ ] Remover chaves Supabase hardcoded; usar `--dart-define SUPABASE_URL/SUPABASE_ANON_KEY`
- [ ] `flutterfire configure` executado; `firebase_options.dart` integrado
- [ ] iOS: `GoogleService-Info.plist` adicionado ao projeto (privado)
- [ ] Android: `google-services.json` adicionado ao projeto (privado)

### 4) Flutter – Build/Assinatura
- [ ] Android: configurar `signingConfigs.release` e substituir `signingConfig = debug`
- [ ] iOS: ajustar capabilities (Push, Background Modes), increment Build/Version
- [ ] Web: confirmar `--web-port`/CORS (se publicar web)
- [ ] `flutter build apk --flavor prod --dart-define API_BASE_URL=https://api.litig.app/api`
- [ ] `flutter build ios --flavor prod --release`

### 5) QA – Fluxos críticos
- [ ] Login/Logout e redirecionamento por role (GoRouter)
- [ ] Triagem inteligente `/triage` (apenas 1 rota no app)
- [ ] Casos: listar/detalhar; documentos: upload/listar/baixar
- [ ] Mensagens: envio/recebimento (mock/real dependendo do ambiente)
- [ ] Ofertas: listar, aceitar, rejeitar
- [ ] Pagamentos: intent/PIX
- [ ] Avaliações: enviar rating
- [ ] Video call: criar e ingressar
- [ ] Parcerias e perfis enriquecidos (quando habilitado)

### 6) Observabilidade e Segurança
- [ ] Logs saneados (sem segredos, prints de debug condicionados)
- [ ] Métricas Prometheus disponíveis; dashboards atualizados
- [ ] Rate limiting ativo; headers de segurança configurados (proxy)

### 7) Deploy
- [ ] Backend em Docker/K8s com health checks e auto-restart
- [ ] Banco e Redis monitorados
- [ ] Publicação Android (Play Console) / iOS (TestFlight/App Store)

### 8) Pós-Deploy
- [ ] Rodar smoke tests em produção
- [ ] Monitorar métricas, erros e latência
- [ ] Plano de rollback documentado


