# Gemini CLI - Guia de Uso

## Instalação ✅

O Gemini CLI foi instalado com sucesso via pipx:

```bash
pipx install gemini-cli
```

## Configuração

### 1. Obter Chave da API

1. Acesse [Google AI Studio](https://aistudio.google.com/)
2. Faça login com sua conta Google
3. Crie uma nova chave da API
4. Copie a chave gerada

### 2. Configurar a Chave

**Opção A: Arquivo de configuração**
Edite o arquivo `~/.config/gemini-cli.toml`:

```toml
[api]
token = "sua_chave_api_aqui"
```

**Opção B: Variável de ambiente**
```bash
export GEMINI_API_KEY="sua_chave_api_aqui"
```

**Opção C: Linha de comando**
```bash
gemini-cli --token "sua_chave_api_aqui" "seu prompt aqui"
```

## Uso Básico

### Comandos Simples
```bash
# Pergunta direta
gemini-cli "Explique o que é machine learning"

# Geração de código
gemini-cli "Escreva uma função Python para ordenar uma lista"

# Tradução
gemini-cli "Traduza 'Hello World' para português"
```

### Modo Interativo
```bash
# Iniciar sessão interativa
gemini-cli
```

### Streaming de Resposta
```bash
# Ver resposta sendo gerada em tempo real
gemini-cli --stream "Conte uma história sobre um robô"
```

### Formato Markdown
```bash
# Resposta formatada em markdown
gemini-cli --markdown "Crie uma lista de tarefas para um projeto"
```

## Uso Avançado

### Contexto de Sistema
```bash
gemini-cli --context "Você é um especialista em Python" "Como otimizar este código?"
```

### Limitar Tamanho
```bash
gemini-cli --limit 100 "Resuma este texto em poucas palavras"
```

### Arquivo de Configuração Personalizado
```bash
gemini-cli --config-file ./meu-config.toml "seu prompt"
```

## Exemplos Práticos para LITIG-1

### Análise de Código
```bash
gemini-cli "Analise este código Python e sugira melhorias: [cole o código]"
```

### Geração de Testes
```bash
gemini-cli "Gere testes unitários para esta função: [cole a função]"
```

### Documentação
```bash
gemini-cli "Crie documentação para esta API: [descreva a API]"
```

### Debugging
```bash
gemini-cli "Ajude a debugar este erro: [cole o erro]"
```

## Configurações Avançadas

### Arquivo de Configuração Completo
```toml
[api]
token = "sua_chave_api_aqui"

[generation_config]
top_p = 0.8
top_k = 40
candidate_count = 1
max_output_tokens = 2048
stop_sequences = []

[defaults]
stream = true
markdown = true
```

### Parâmetros de Geração
- `top_p`: Controla diversidade (0.0-1.0)
- `top_k`: Número de tokens considerados
- `max_output_tokens`: Tamanho máximo da resposta
- `stop_sequences`: Sequências que param a geração

## Troubleshooting

### Erro de Token
```
Token not found. Please provide a token via --token argument
```
**Solução**: Configure a chave da API conforme instruções acima.

### Erro de Rede
```
Connection error or timeout
```
**Solução**: Verifique sua conexão com a internet.

### Limite de Rate
```
Rate limit exceeded
```
**Solução**: Aguarde alguns minutos antes de fazer nova requisição.

## Integração com LITIG-1

O Gemini CLI pode ser usado para:

1. **Análise de Código**: Revisar código do backend e frontend
2. **Geração de Testes**: Criar testes automatizados
3. **Documentação**: Gerar documentação técnica
4. **Debugging**: Ajudar a resolver problemas
5. **Refatoração**: Sugerir melhorias de código
6. **Análise de Dados**: Processar dados do sistema

## Comandos Úteis

```bash
# Verificar instalação
gemini-cli --help

# Testar conexão
gemini-cli --token "sua_chave" "Teste de conexão"

# Configurar alias (adicione ao ~/.zshrc)
alias gemini="gemini-cli --token 'sua_chave'"
```

## Recursos Adicionais

- **Streaming**: Respostas em tempo real
- **Markdown**: Formatação rica
- **Contexto**: Manter conversas
- **Configuração**: Personalização avançada
- **Multi-modelo**: Suporte a diferentes modelos Gemini

---

**Status**: ✅ Instalado e configurado
**Versão**: 0.2.5
**Próximo passo**: Configure sua chave da API para começar a usar!
