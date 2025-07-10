# 📊 Fluxo de Negócio - LITGO5

## 🎯 Visão Geral do Fluxo

O LITGO5 implementa um fluxo de negócio completo desde a entrada do cliente até a formalização do contrato com o advogado, passando por **9 fases distintas**.

## 🔄 As 9 Fases do Sistema

### Fase 1: Entrada do Cliente
- Cliente acessa o app/web
- Descreve o caso (texto/áudio)
- Localização capturada automaticamente

### Fase 2: Triagem Inteligente
- Claude 3.5 Sonnet analisa o caso
- Extração de área jurídica
- Análise de urgência

### Fase 3: Geração de Embeddings
- OpenAI text-embedding-3-small
- Vetor de 384 dimensões
- Armazenado no pgvector

### Fase 4: Matching de Advogados
- Algoritmo v2.1 com 7 features
- Cálculo de scores ponderados
- Aplicação de equidade

### Fase 5: Apresentação de Resultados
- Lista ordenada de advogados
- Score de compatibilidade
- Informações relevantes

### Fase 6: Pré-contratação
- Chat integrado
- Videochamada opcional
- Compartilhamento de documentos

### Fase 7: Aceitação da Proposta
- Cliente aceita proposta
- Sistema cria pré-contrato
- Notificações enviadas

### Fase 8: Formalização do Contrato
- Integração DocuSign
- Assinatura eletrônica
- Contrato ativado

### ⭐ **Fase 9: Feedback e Avaliação** (NOVA)
**Objetivo:** Coletar feedback do cliente para melhorar futuros matches

**Quando ocorre:** Após conclusão do contrato (status = "closed")

**Processo:**
- Sistema notifica cliente para avaliar
- Modal de avaliação é exibido
- Cliente preenche:
  - ⭐ Avaliação geral (1-5 estrelas) - **obrigatório**
  - 💬 Comentário opcional
  - 🎯 Resultado percebido (ganhou/perdeu/acordo/em andamento)
  - ⭐ Avaliações específicas: comunicação, expertise, pontualidade
  - 👍 Recomendaria o advogado? (sim/não)

**Impacto no Sistema:**
- Alimenta a **Feature R (review_score)** do algoritmo v2.1
- **Não afeta** a **Feature T (success_rate)** que vem do Jusbrasil
- Job noturno atualiza `kpi.avaliacao_media` dos advogados
- Futuros matches consideram a satisfação dos clientes

**Regras de Negócio:**
- Apenas clientes podem avaliar
- Uma avaliação por contrato
- Editável por 7 dias após criação
- Deletável por 24 horas após criação

## 💰 Modelo de Negócio

### Fontes de Receita
- Taxa de Intermediação: 10-15% do contrato
- Assinatura Premium: R$ 199-499/mês
- Serviços Adicionais: DocuSign, videoconsulta

### Custos Operacionais
- Claude API: ~R$ 0,50/triagem
- OpenAI: ~R$ 0,02/caso
- DocuSign: ~R$ 5,00/envelope
- Infraestrutura: ~R$ 3.000/mês

## 🎯 Benefícios da Fase 9

### Para o Algoritmo
- **Separação Clara**: T (objetivo) vs R (subjetivo)
- **Qualidade dos Matches**: Reviews impactam ranking futuro
- **Equilíbrio**: 15% peso para dados oficiais + 5% para experiência do cliente

### Para os Usuários
- **Transparência**: Clientes veem avaliações reais
- **Melhoria Contínua**: Advogados recebem feedback
- **Confiança**: Sistema considera experiência real dos usuários

### Para o Negócio
- **Retenção**: Clientes satisfeitos retornam
- **Qualidade**: Advogados ruins são naturalmente filtrados
- **Diferencial**: Único sistema que combina dados oficiais + experiência

---

**Última atualização:** Janeiro 2025  
**Versão:** 2.0 (com Fase 9 implementada)


## 🎯 Visão Geral do Fluxo

O LITGO5 implementa um fluxo de negócio completo desde a entrada do cliente até a formalização do contrato com o advogado, passando por **9 fases distintas**.

## 🔄 As 9 Fases do Sistema

### Fase 1: Entrada do Cliente
- Cliente acessa o app/web
- Descreve o caso (texto/áudio)
- Localização capturada automaticamente

### Fase 2: Triagem Inteligente
- Claude 3.5 Sonnet analisa o caso
- Extração de área jurídica
- Análise de urgência

### Fase 3: Geração de Embeddings
- OpenAI text-embedding-3-small
- Vetor de 384 dimensões
- Armazenado no pgvector

### Fase 4: Matching de Advogados
- Algoritmo v2.1 com 7 features
- Cálculo de scores ponderados
- Aplicação de equidade

### Fase 5: Apresentação de Resultados
- Lista ordenada de advogados
- Score de compatibilidade
- Informações relevantes

### Fase 6: Pré-contratação
- Chat integrado
- Videochamada opcional
- Compartilhamento de documentos

### Fase 7: Aceitação da Proposta
- Cliente aceita proposta
- Sistema cria pré-contrato
- Notificações enviadas

### Fase 8: Formalização do Contrato
- Integração DocuSign
- Assinatura eletrônica
- Contrato ativado

### ⭐ **Fase 9: Feedback e Avaliação** (NOVA)
**Objetivo:** Coletar feedback do cliente para melhorar futuros matches

**Quando ocorre:** Após conclusão do contrato (status = "closed")

**Processo:**
- Sistema notifica cliente para avaliar
- Modal de avaliação é exibido
- Cliente preenche:
  - ⭐ Avaliação geral (1-5 estrelas) - **obrigatório**
  - 💬 Comentário opcional
  - 🎯 Resultado percebido (ganhou/perdeu/acordo/em andamento)
  - ⭐ Avaliações específicas: comunicação, expertise, pontualidade
  - 👍 Recomendaria o advogado? (sim/não)

**Impacto no Sistema:**
- Alimenta a **Feature R (review_score)** do algoritmo v2.1
- **Não afeta** a **Feature T (success_rate)** que vem do Jusbrasil
- Job noturno atualiza `kpi.avaliacao_media` dos advogados
- Futuros matches consideram a satisfação dos clientes

**Regras de Negócio:**
- Apenas clientes podem avaliar
- Uma avaliação por contrato
- Editável por 7 dias após criação
- Deletável por 24 horas após criação

## 💰 Modelo de Negócio

### Fontes de Receita
- Taxa de Intermediação: 10-15% do contrato
- Assinatura Premium: R$ 199-499/mês
- Serviços Adicionais: DocuSign, videoconsulta

### Custos Operacionais
- Claude API: ~R$ 0,50/triagem
- OpenAI: ~R$ 0,02/caso
- DocuSign: ~R$ 5,00/envelope
- Infraestrutura: ~R$ 3.000/mês

## 🎯 Benefícios da Fase 9

### Para o Algoritmo
- **Separação Clara**: T (objetivo) vs R (subjetivo)
- **Qualidade dos Matches**: Reviews impactam ranking futuro
- **Equilíbrio**: 15% peso para dados oficiais + 5% para experiência do cliente

### Para os Usuários
- **Transparência**: Clientes veem avaliações reais
- **Melhoria Contínua**: Advogados recebem feedback
- **Confiança**: Sistema considera experiência real dos usuários

### Para o Negócio
- **Retenção**: Clientes satisfeitos retornam
- **Qualidade**: Advogados ruins são naturalmente filtrados
- **Diferencial**: Único sistema que combina dados oficiais + experiência

---

**Última atualização:** Janeiro 2025  
**Versão:** 2.0 (com Fase 9 implementada)
