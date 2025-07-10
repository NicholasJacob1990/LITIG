### Fluxo Operacional — versão atualizada

*(agora a **síntese gerada pela IA** é entregue **simultaneamente ao cliente e ao advogado designado**)*

| Nº     | Fase                            | Ações do usuário / sistema                                                                                                                                                           | Entregas e observações                                                                           |
| ------ | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------ |
| **0**  | **On-boarding**                 | Cliente PF ou PJ cria conta, aceita Termo LGPD/OAB, concede (ou não) GPS.                                                                                                            | Validação CPF/CNPJ & armazenamento do consentimento.                                             |
| **1**  | **Entrada da dúvida**           | Cliente descreve o problema (texto ou voz).                                                                                                                                          | App envia texto ao **Serviço de IA**.                                                            |
| **2**  | **Triagem IA**                  | <span style="white-space:nowrap">IA-LLM</span> classifica área, urgência e formula 3-5 perguntas; cliente responde.                                                                  | IA produz **Síntese Jurídica** (JSON + texto legível) → **grava em `cases.summary_ai`**.         |
| **3**  | **Envio automático da síntese** | Assim que o JSON é salvo:<br>• **Push / e-mail** para o cliente: “Pré-análise do seu caso pronta”.<br>• Notificação interna “Novo caso aguardando atribuição” + link para a síntese. | *A síntese contém disclaimer: “Análise preliminar gerada por IA, sujeita a conferência humana.”* |
| **4**  | **Atribuição do advogado**      | Algoritmo rankeia profissionais (área + rating + distância). Sócio ou workflow automático designa advogado.                                                                          | Evento `case.assigned` dispara envio da síntese ao advogado (push + e-mail).                     |
| **5**  | **Boas-vindas**                 | Advogado lê a síntese, envia 1.ª mensagem ao cliente e, se necessário, solicita documentos adicionais.                                                                               | Log de leitura da síntese (timestamp) armazenado em `audit.read_log`.                            |
| **6**  | **Plano & pagamento**           | Cliente escolhe Ato / Hora / Êxito / Assinatura e paga via Stripe ou PIX.                                                                                                            | Webhook confirma → grava `transactions` e calcula comissão.                                      |
| **7**  | **Atendimento**                 | Chat ou vídeo (Daily). IA copiloto sugere jurisprudência em tempo real.                                                                                                              | Todas mensagens e anexos criptografados.                                                         |
| **8**  | **Encerramento da consulta**    | Cliente clica “Finalizar”. IA gera **Relatório de Atendimento** pré-preenchido com a síntese original + decisões tomadas; advogado revisa e assina.                                  | PDF entregue a ambas as partes; arquivamento LGPD.                                               |
| **9**  | **Avaliação & NPS**             | Cliente avalia 1-5 ⭐.                                                                                                                                                                | Rating retroalimenta algoritmo de match.                                                         |
| **10** | **Faturamento & repasse**       | Sistema efetua pagamento ao advogado conforme plano.                                                                                                                                 | Meta ≥ 98 % repasses sem intervenção manual.                                                     |
| **11** | **Encerramento administrativo** | Caso marcado “Concluído”, dados retidos 5 anos e depois pseudonimizados.                                                                                                             | Conformidade LGPD + Provimento 205.                                                              |

---

#### Pontos-chave da atualização

1. **Visibilidade total** – a síntese IA chega **antes** do pagamento, criando transparência e facilitando a decisão do cliente.
2. **Confirmação humana** – advogado deve revisar a síntese **obrigatoriamente** antes de prosseguir (registro de leitura em `audit.read_log`).
3. **Compliance** – enviar a mesma pré-análise ao cliente evita infração ao art. 34, VII do EOAB (proibição de exercer atividade sem informar cliente adequadamente).

Com essa alteração, o fluxo garante que o cliente e o advogado partem de um mesmo diagnóstico preliminar, acelerando o atendimento e reforçando confiança.




## Fluxo operacional completo do aplicativo

*(abrange clientes PF e PJ, habilitação de novos advogados e back-office)*

---

### A ▪ Jornada de **Cliente** (Pessoa Física ou Jurídica)

| Nº     | Fase                            | Ações do usuário                                                                                             | Processos automáticos / responsáveis                                                                                  |          |
| ------ | ------------------------------- | ------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- | -------- |
| **0**  | **On-boarding**                 | • Seleciona tipo **PF / PJ**.<br>• Cria conta (e-mail/telefone, senha ou OAuth).<br>• Aceita Termo LGPD/OAB. | • Validação CPF/CNPJ via API Receita / Serpro.<br>• Cria registro em `clients` (\`type='PF'                           | 'PJ'\`). |
| **1**  | **Identificação & KYC**         | • Anexa RG/CNH (PF) **ou** Contrato Social + doc. do representante (PJ).                                     | • OCR + checagem de integridade.<br>• Armazena arquivos criptografados.<br>• Se Face-Match habilitado, valida selfie. |          |
| **2**  | **Entrada da dúvida**           | Campo de texto ou voz descrevendo o problema.                                                                | Llama/GPT classifica área do direito e estima urgência / valor.                                                       |          |
| **3**  | **Triagem dinâmica**            | Responde 3-5 perguntas fechadas geradas pela IA.                                                             | IA produz **Resumo Jurídico** em JSON + lista de documentos recomendados.                                             |          |
| **4**  | **Painel do Caso**              | Visualiza cartão “Caso #123 – Trabalhista – alta urgência”.                                                  | WebSocket/Realtime atualiza status.                                                                                   |          |
| **5**  | **Match advogado**              | —                                                                                                            | Algoritmo rankeia advogados disponíveis (especialidade + rating + proximidade).                                       |          |
| **6**  | **Boas-vindas do advogado**     | Recebe 1ª mensagem privada; pode aceitar ou pedir outro profissional.                                        | Log de distribuição armazenado para auditoria OAB.                                                                    |          |
| **7**  | **Plano & pagamento**           | Escolhe **Ato / Hora / Êxito / Assinatura**.<br>Paga via Stripe ou PIX.                                      | Webhook confirma liquidação e grava `transactions` + `commission_pct`.                                                |          |
| **8**  | **Atendimento**                 | Chat ou vídeo (Daily).<br>Upload de docs, troca de mensagens.                                                | IA copiloto sugere jurisprudência; tudo criptografado.                                                                |          |
| **9**  | **Encerramento da consulta**    | Clica “Encerrar”; recebe **Relatório** em PDF e orçamento extra (se aplicável).                              | IA redige relatório → advogado revisa/assina digitalmente → PDF no Storage.                                           |          |
| **10** | **Avaliação & NPS**             | Dá nota 1-5 ⭐ + comentário.                                                                                  | Rating realimenta algoritmo de match.                                                                                 |          |
| **11** | **Fase prolongada** (opcional)  | Contrata contencioso/êxito; acompanha milestones.                                                            | Timesheet (plano Hora) ou % êxito; integra andamentos processuais.                                                    |          |
| **12** | **Faturamento final & repasse** | —                                                                                                            | Trigger calcula comissão, agenda pagamento ao advogado; caso marcado “Concluído”.                                     |          |

---

### B ▪ Funil de **Habilitação de Advogados**

| Etapa                         | Candidato                                                         | Sistema / RH Jurídico                                                                                                             |
| ----------------------------- | ----------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| **A. Pré-cadastro**           | E-mail + senha + aceite de intenção.                              | Cria `lawyer_applicants` status `PENDING_EMAIL`.                                                                                  |
| **B. Dados profissionais**    | Nome, nº OAB, seccional, CPF, especialidades.                     | API CNA valida situação regular.                                                                                                  |
| **C. Documentos**             | Upload OAB (frente/verso), RG, comprovante residência, currículo. | OCR lê nº OAB, salva criptografado.                                                                                               |
| **D. Questionário de ética**  | Declara impedimentos, conflitos, PEP.                             | Gera *risk score*.                                                                                                                |
| **E. Assinatura do contrato** | Assina digital (DocuSign / Click-wrap).                           | Hash + registro em `contracts`.                                                                                                   |
| **F. Revisão interna**        | —                                                                 | Painel admin verifica checklist, aprova ou rejeita → cria usuário `role='LAWYER'`, define `commission_pct`, envia onboarding kit. |

---

### C ▪ Back-office & Compliance

| Função                 | Atores               | Principais ações                                                                                                                     |
| ---------------------- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **Admin financeiro**   | Escritório           | Ajustar planos e comissões; reconciliar Stripe / PIX; gerar notas fiscais (PJ) ou recibos (PF).                                      |
| **Painel jurídico**    | Sócio responsável    | Acompanhar SLA, NPS, distribuição de casos; auditar logs de consentimento.                                                           |
| **Monitoria OAB/LGPD** | Equipe de compliance | • Checar validade de documentos e registro OAB.<br>• Pseudonimizar dados passados 5 anos.<br>• Gerar relatórios de acesso aos dados. |
| **DevOps / SRE**       | TI                   | Observabilidade (Sentry, Logs, OpenTelemetry), backups diários, atualização de dependências.                                         |

---

### D ▪ Notificações & Automação paralela

* **Push / e-mail / SMS** em cada transição de status.
* **Cron jobs**: lembrete de provas digitais prestes a vencer; renovação de doc. advogado.
* **Analytics** (Mixpanel, PostHog) coleta funil triagem → pagamento → NPS.

---

#### Resultado

Com esses estágios integrados, o aplicativo:

1. **Atende PF e PJ** com onboarding e faturamento adequados.
2. **Escala o quadro de advogados** via pipeline auditável e aderente à OAB.
3. Mantém **compliance** (LGPD / Prov. 205/2021) e eficiência financeira (repasses automáticos).

Este é o blueprint completo que serve de referência para design, implementação e governança contínua da plataforma.
