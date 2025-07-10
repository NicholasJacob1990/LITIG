### Componentes da Arquitetura – **MVP Mobile-First**

*(cada item inclui as peças essenciais + motivos de adoção)*

---

#### ● Front-End (Mobile)

* **React Native 0.74** – base nativa iOS/Android; integra APIs de câmera, localização, push, biometria.
* **Expo Router 3** – navegação por arquivos, builds OTA pela EAS, zero configuração de certificados.
* **TypeScript estrito** – mesma linguagem do back-end futuro e dos testes.
* **NativeWind (Tailwind v4)** + **shadcn/ui-mobile** – design system unificado, compartilhável com web.
* **Bibliotecas nativas integradas**

  * `expo-location` (GPS) para capturar latitude/longitude do cliente.
  * `react-native-mapbox-gl` ou `react-native-maps` (Google) para mostrar advogados no mapa com clustering.
  * `stripe-react-native` (PaymentSheet) + deeplink PIX.
  * `daily-react-native` (WebRTC) para chat/vídeo jurídico.

---

#### ● Back-End

* **Supabase Cloud**

  * PostgreSQL 15 + PostGIS para consultas geoespaciais (`lawyers_nearby`).
  * Auth (JWT curta) com refresh; MFA opcional para advogados.
  * Storage criptografado para RG, contratos sociais, relatórios PDF.
  * Realtime (WebSocket) para atualizar status de casos e disponibilidade de advogados.
* **Edge / API Gateway**

  * Route Handlers (Node) expostos em `api.*` para webhooks Stripe/PIX e uploads grandes.
  * Workers Bun/Node com BullMQ para OCR de documentos, emissão de notas fiscais e notificações programadas.

---

#### ○ Serviço de Análise Jurídica (IA)

* **Micro-serviço stateless** (FastAPI Python ou NestJS TS).

  * **/triage** → GPT-4o / Claude retorna área jurídica, urgência e perguntas dinâmicas.
  * **/summary** → gera rascunho do Relatório de Atendimento (Markdown → PDF).
  * Streaming **SSE** compatível com React Native (fetch + readable stream) para feedback em tempo real.
  * Cache Redis dos prompts para reduzir custo de tokens.
  * Versionamento de prompts → branch por seccional/área se necessário.

---

#### ● Banco de Dados

* **PostgreSQL 15** (Supabase)

  * Schemas: `public` (clientes, casos, advogados) • `billing` (transações, repasses) • `audit` (logs LGPD/OAB).
  * Extensões: **PostGIS** (distância), **pgcrypto** (hash/hmac de documentos), **pgjwt** (auth).
  * Políticas **Row-Level Security**: cliente enxerga apenas seus registros; advogado vê apenas casos atribuídos.
  * Backups PITR + snapshots diários em bucket S3 compatível.

---

#### ● Infraestrutura

* **EAS Build & Submit** – gera IPA (iOS) e AAB (Android) em nuvem; OTA updates via `eas update`.
* **Cloudflare** – CDN global, WAF, DDoS, rate-limit.
* **Supabase Cloud** – banco, storage e edge functions na região São Paulo.
* **Grafana Cloud** – métricas (Prometheus), logs (Loki) e traces (Tempo) agregados.
* **Sentry React Native** – crash reporting; Sentry Performance para backend.

---

#### ● Segurança

* **Comunicação**: TLS 1.3, HSTS, Certificate Pinning no app (react-native-ssl-pinning).
* **Dados em repouso**:

  * Arquivos: AES-256 (Supabase Storage, bucket cifrado).
  * Chaves sensíveis no app: Secure Store / Keychain (iOS) e Keystore (Android).
* **Controles LGPD**: consentimento granular (location, push, docs), portabilidade via export JSON; pseudonimização automática após 5 anos.
* **Compliance OAB (Prov. 205/2021)**: logs de distribuição de casos (WORM), publicidade apenas institucional, exibição de razão social/CNPJ/OAB no app.
* **Proteções OWASP Mobile Top-10**: obfuscação de bundle JavaScript, verificação de integridade (Expo Secure Store + CodePush hash), rate-limiting em logins e pagamentos.

---

### Por que esta arquitetura é adequada ao foco mobile?

1. **Time-to-market**: React Native + Expo entrega builds de teste em horas (TestFlight / Play Internal).
2. **Experiência nativa completa**: GPS, mapa interativo, push “high priority”, biometria, PaymentSheet.
3. **Escalonável**: micro-serviço de IA separado e banco PostGIS respondem a picos sem afetar UX.
4. **Compliance** embutida: RLS, logs imutáveis, chaves seguras no dispositivo e criptografia forte em trânsito/repouso.
