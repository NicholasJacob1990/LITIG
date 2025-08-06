# Gemini CLI Integration para Cursor

Esta extensão integra o Gemini CLI no Cursor, permitindo usar o Google Gemini diretamente na interface do editor.

## Funcionalidades

- **Chat Interativo**: Abra um chat com o Gemini CLI
- **Análise de Código**: Analise código selecionado e receba sugestões
- **Geração de Testes**: Gere testes unitários para o arquivo atual
- **Explicação de Código**: Peça explicações para código selecionado

## Comandos Disponíveis

### 1. Gemini CLI: Chat
- **Atalho**: `Cmd+Shift+G` (Mac) / `Ctrl+Shift+G` (Windows/Linux)
- **Descrição**: Abre um prompt para conversar com o Gemini CLI
- **Uso**: Digite sua pergunta e receba a resposta em um arquivo markdown

### 2. Gemini CLI: Analisar Código
- **Atalho**: `Cmd+Shift+A` (Mac) / `Ctrl+Shift+A` (Windows/Linux)
- **Descrição**: Analisa o código selecionado e sugere melhorias
- **Uso**: Selecione código e execute o comando

### 3. Gemini CLI: Gerar Testes
- **Descrição**: Gera testes unitários para o arquivo atual
- **Uso**: Execute no arquivo que deseja testar

### 4. Gemini CLI: Explicar Código
- **Descrição**: Explica o código selecionado em português
- **Uso**: Selecione código e execute o comando

## Instalação

### Pré-requisitos

1. **Gemini CLI instalado**:
   ```bash
   pipx install gemini-cli
   ```

2. **Chave da API configurada**:
   - Obtenha uma chave em [Google AI Studio](https://aistudio.google.com/)
   - Configure no arquivo `~/.config/gemini-cli.toml`:
     ```toml
     [api]
     token = "sua_chave_api_aqui"
     ```

### Instalação da Extensão

1. Copie esta pasta para `~/.cursor/extensions/gemini-cli-integration`
2. Compile a extensão:
   ```bash
   cd ~/.cursor/extensions/gemini-cli-integration
   npm install
   npm run compile
   ```
3. Reinicie o Cursor

## Uso

### Via Interface Gráfica
- Use o ícone no topo do editor (barra de navegação)
- Acesse via Command Palette (`Cmd+Shift+P`)

### Via Atalhos de Teclado
- `Cmd+Shift+G`: Abrir chat
- `Cmd+Shift+A`: Analisar código selecionado

### Via Command Palette
1. Pressione `Cmd+Shift+P`
2. Digite "Gemini CLI"
3. Escolha o comando desejado

## Configuração

### Personalizar Prompts

Você pode modificar os prompts padrão editando o arquivo `src/extension.ts`:

```typescript
// Exemplo de prompt personalizado
const prompt = `Analise este código Python e sugira melhorias específicas para performance:\n\n${code}`;
```

### Configurar Saída

As respostas são salvas em `/tmp/gemini-cli-output.md` e abertas automaticamente no editor.

## Troubleshooting

### Erro: "Gemini CLI não encontrado"
- Verifique se o Gemini CLI está instalado: `gemini-cli --help`
- Instale se necessário: `pipx install gemini-cli`

### Erro: "Token não encontrado"
- Configure sua chave da API no arquivo `~/.config/gemini-cli.toml`
- Ou use variável de ambiente: `export GEMINI_API_KEY="sua_chave"`

### Extensão não aparece
- Verifique se a extensão está na pasta correta
- Compile novamente: `npm run compile`
- Reinicie o Cursor

## Desenvolvimento

### Estrutura do Projeto
```
gemini-cli-integration/
├── src/
│   └── extension.ts      # Código principal
├── package.json          # Configuração da extensão
├── tsconfig.json         # Configuração TypeScript
└── README.md            # Este arquivo
```

### Compilar
```bash
npm run compile
```

### Desenvolver
```bash
npm run watch
```

## Contribuição

Para contribuir com melhorias:

1. Faça suas alterações no código
2. Compile: `npm run compile`
3. Teste no Cursor
4. Envie suas sugestões

## Licença

MIT License - Use livremente para projetos pessoais e comerciais.

---

**Desenvolvido para integração perfeita com o Cursor e Gemini CLI**
