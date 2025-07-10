| #       | Fase / Momento                     | Ações do **Usuário**                                                                                          | Processos / Serviços do **Sistema**                                                                                      | Dados / Saídas visíveis           |
| ------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | --------------------------------- |
| **0**   | **Cadastro & KYC**                 | Escolhe PF ou PJ → preenche CPF/CNPJ, e-mail, telefone, senha → aceita Termos LGPD/OAB → concede (ou não) GPS | • Validação CPF/CNPJ (Receita/Serpro)<br>• Armazena consentimentos (hash)<br>• Upload docs → OCR → Storage criptografado | Conta criada & tela inicial       |
| **1**   | **Entrada da dúvida**              | Digita ou dita o problema em linguagem natural                                                                | Envia texto a **IA /triage**                                                                                             | Indicador “Analisando…”           |
| **2-A** | **Perguntas de triagem**           | Responde 3-5 perguntas objetivas                                                                              | IA ajusta urgência + complexidade                                                                                        | Barra de progresso                |
| **2-B** | **Síntese Jurídica**               | —                                                                                                             | IA gera **Resumo (markdown + JSON)** e grava em `cases.summary_ai`                                                       | “Pré-análise pronta”              |
| **2-C** | **Entrega da síntese**             | —                                                                                                             | Push/e-mail ao cliente **e** notificação interna de novo caso                                                            | Ambos recebem a mesma pré-análise |
| **3-A** | **Busca por distância**            | Permite GPS ou digita CEP                                                                                     | Função `lawyers_nearby(lat,lng,radius,area,filters)` (PostGIS)                                                           | Mapa + lista de advogados         |
| **3-B** | **Filtros**                        | Ajusta Raio, Área, Idioma, ★ mínima, Disponível, Modalidade                                                   | Query é refeita em tempo real                                                                                            | Lista atualizada                  |
| **3-C** | **Escolha**                        | Toca num card **ou** “Sistema escolher”                                                                       | Grava `case.assigned`; envia síntese ao advogado                                                                         | Confirmação de atribuição         |
| **4**   | **Plano & pagamento**              | Seleciona Chat / Vídeo / Presencial → paga (Stripe ou PIX)                                                    | Webhook registra `transaction` + `% comissão`                                                                            | Tela “Pagamento aprovado”         |
| **5**   | **Atendimento**                    | Conversa por chat ou vídeo; envia docs                                                                        | • Daily (WebRTC) sala segura<br>• IA copiloto sugere petições, jurisprudência                                            | Mensagens + sugestões IA          |
| **6**   | **Relatório pós-consulta**         | —                                                                                                             | IA compila relato + próximos passos → advogado revisa e assina → PDF no storage                                          | Push com download do PDF          |
| **7**   | **Avaliação & NPS**                | Dá 1–5 ★ e comentário                                                                                         | Salva em `ratings`; recálculo de ranking                                                                                 | Agradecimento + próxima etapa     |
| **8**   | **Execução prolongada** *opcional* | Contrata ação judicial / plano hora                                                                           | Cria subcaso (Hour / Êxito); timesheet ou milestones                                                                     | Painel de progresso               |
| **9**   | **Faturamento & repasse**          | —                                                                                                             | Cron checa liquidação, calcula valor do advogado, agenda repasse automático                                              | Histórico de pagamentos           |
| **10**  | **Encerramento administrativo**    | —                                                                                                             | Marca caso “Concluído”; dados retidos 5 anos → pseudonimizados                                                           | Notificação de encerramento       |

---

### Funil de Habilitação de Advogados

| Etapa               | Ação do **Candidato**               | Passos do **Sistema / RH Jurídico**                           | Status / Saída        |
| ------------------- | ----------------------------------- | ------------------------------------------------------------- | --------------------- |
| Pré-cadastro        | E-mail, senha, aceite de intenção   | `lawyer_applicants → PENDING_EMAIL`                           | Link verificação      |
| Dados profissionais | Nome, nº OAB, seccional, CPF, áreas | API CNA valida registro                                       | `PENDING_DOCS`        |
| Documentos          | Upload OAB, RG, endereço, currículo | OCR + Storage                                                 | `PENDING_REVIEW`      |
| Questionário ética  | Declara conflitos, impedimentos     | Calcula risk-score                                            | —                     |
| Contrato associação | Assinatura digital (DocuSign)       | Hash salvo em `contracts`                                     | `SIGNED`              |
| Revisão interna     | —                                   | Sócio aprova → cria `users(role='LAWYER')`, define % comissão | Advogado “Disponível” |

---

**Notas-chave de conformidade**

* Mesmo **Resumo IA** enviado a cliente e advogado → transparência (OAB).
* Distância exibida sem endereço exato antes do pagamento → privacidade (LGPD).
* Logs imutáveis: busca geográfica, leitura de síntese, distribuição de caso, consentimentos.
