# 🤖 Chatbot de Triagem Jurídica com IA

## ✨ Funcionalidade Implementada

O aplicativo agora possui um **chatbot inteligente** powered by OpenAI (ChatGPT) que realiza triagem jurídica conversacional, exatamente como estava no LITGO anterior.

## 🚀 Como Funciona

### 1. Fluxo do Usuário
- **Tela Inicial** → Botão "Iniciar Consulta com IA"
- **Chat Triagem** → Conversa inteligente com LEX-9000 (assistente IA)
- **Síntese Jurídica** → Análise completa gerada automaticamente

### 2. Interface de Chat
- ✅ Chat em tempo real com IA especializada em direito brasileiro
- ✅ Indicador de digitação animado
- ✅ Perguntas inteligentes baseadas no caso
- ✅ Análise completa ao final (3-10 perguntas)

### 3. IA Jurídica (LEX-9000)
- 🧠 **Modelo**: GPT-4o-mini (rápido e econômico)
- ⚖️ **Especialização**: Direito brasileiro completo
- 📊 **Output**: Análise estruturada em JSON
- 🎯 **Triagem**: 3-10 perguntas adaptativas

## 🔧 Configuração Necessária

### 1. Chave OpenAI
Configure sua chave no arquivo `.env`:
```bash
EXPO_PUBLIC_OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxx
```

### 2. Dependências
```bash
npm install
```

### 3. Executar
```bash
npx expo start
```

## 📱 Testando o Chatbot

### Casos para Testar:

1. **Direito Trabalhista**
   ```
   "Fui demitido sem justa causa e não recebi todas as verbas rescisórias"
   ```

2. **Direito Civil**
   ```
   "Comprei um produto com defeito e a loja se recusa a trocar"
   ```

3. **Direito de Família**
   ```
   "Preciso ajuda com divórcio consensual e pensão alimentícia"
   ```

### O que Esperar:
- IA fará perguntas específicas para cada área
- Coletará informações sobre documentos, prazos, valores
- Gerará síntese jurídica completa
- Classificará urgência e viabilidade

## 🎯 Recursos do LEX-9000

### Análise Completa Inclui:
- **Classificação**: Área jurídica e subárea específica
- **Viabilidade**: Chances de sucesso do caso
- **Urgência**: Nível crítico/alto/médio/baixo
- **Documentos**: Lista do que é necessário
- **Estratégia**: Sugestões de próximos passos
- **Custos**: Estimativa de complexidade
- **Legislação**: Leis e jurisprudência aplicáveis

### Perguntas Inteligentes:
- ✅ Adaptadas à área do direito identificada
- ✅ Foco em viabilidade e estratégia
- ✅ Considera prazos e prescrição
- ✅ Avalia documentação disponível

## 🔍 Arquivos Implementados

```
app/chat-triagem.tsx     # Interface de chat principal
app/sintese.tsx          # Tela de síntese jurídica
components/AITypingIndicator.tsx  # Animação de digitação
lib/openai.ts           # Integração com OpenAI API
```

## 💡 Exemplo de Conversa

```
LEX-9000: Olá! Sou o LEX-9000, seu assistente jurídico. 
          Qual problema jurídico você está enfrentando?

Usuário:  Fui demitido sem aviso prévio

LEX-9000: Entendo, questão trabalhista. Há quanto tempo 
          você trabalhava na empresa?

Usuário:  2 anos

LEX-9000: Você recebeu alguma verba rescisória ou foi 
          demitido sem receber nada?

Usuário:  Recebi apenas o salário do mês

LEX-9000: Você possui a carteira de trabalho assinada 
          e comprovantes de pagamento?

Usuário:  Sim, tenho tudo

LEX-9000: Perfeito! Concluí a análise do seu caso...
```

## 🚨 Próximos Passos

Após a síntese, o usuário será direcionado para:
1. Visualizar análise completa
2. Atribuição de advogado especialista
3. Escolha de plano de atendimento
4. Início do atendimento jurídico

---

**✅ Implementação concluída conforme LITGO anterior** 