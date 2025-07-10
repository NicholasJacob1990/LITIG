# MCP (Model Context Protocol) Integration

Este diretório contém a integração do MCP para o projeto LITGO5.

## Configuração

O arquivo `mcp.json` na raiz do projeto define os servidores MCP disponíveis:

- **filesystem**: Acesso ao sistema de arquivos local
- **github**: Integração com GitHub (requer token de acesso pessoal)
- **sqlite**: Acesso a bancos de dados SQLite

## Uso

```typescript
import { createMCPClient } from '@/lib/mcp';

// Criar cliente
const client = createMCPClient();

// Conectar ao servidor filesystem
await client.connectToServer('npx', [
  '-y',
  '@modelcontextprotocol/server-filesystem',
  '/path/to/directory'
]);

// Listar ferramentas disponíveis
const tools = await client.listTools();

// Chamar uma ferramenta
const result = await client.callTool('read_file', {
  path: './file.txt'
});

// Desconectar
await client.disconnect();
```

## Configurar Token do GitHub

Para usar o servidor GitHub, adicione seu token de acesso pessoal:

1. Crie um token em: https://github.com/settings/tokens
2. Adicione ao arquivo `.env`:
   ```
   GITHUB_PERSONAL_ACCESS_TOKEN=seu_token_aqui
   ```
3. Atualize o `mcp.json` para usar a variável de ambiente