import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';
import { spawn } from 'child_process';

export class MCPClient {
  private client: Client;
  private transport: StdioClientTransport;

  constructor() {
    this.client = new Client({
      name: 'litgo5-client',
      version: '1.0.0',
    });
  }

  async connectToServer(command: string, args: string[], env?: Record<string, string>) {
    const childProcess = spawn(command, args, {
      env: { ...process.env, ...env },
      stdio: ['pipe', 'pipe', 'pipe'],
    });

    this.transport = new StdioClientTransport({
      inputStream: childProcess.stdout,
      outputStream: childProcess.stdin,
      errorStream: childProcess.stderr,
    });

    await this.client.connect(this.transport);
    
    return this.client;
  }

  async listTools() {
    const tools = await this.client.listTools();
    return tools;
  }

  async listResources() {
    const resources = await this.client.listResources();
    return resources;
  }

  async callTool(name: string, args: any) {
    const result = await this.client.callTool({
      name,
      arguments: args,
    });
    return result;
  }

  async readResource(uri: string) {
    const result = await this.client.readResource({
      uri,
    });
    return result;
  }

  async disconnect() {
    if (this.transport) {
      await this.transport.close();
    }
  }
}

export const createMCPClient = () => new MCPClient();