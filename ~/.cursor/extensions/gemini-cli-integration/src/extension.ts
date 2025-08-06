import * as vscode from 'vscode';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export function activate(context: vscode.ExtensionContext) {
    console.log('Gemini CLI Integration ativada!');

    // Comando: Abrir chat do Gemini CLI
    let openChat = vscode.commands.registerCommand('gemini-cli.openChat', async () => {
        const prompt = await vscode.window.showInputBox({
            prompt: 'Digite sua pergunta para o Gemini CLI:',
            placeHolder: 'Ex: Analise este código e sugira melhorias'
        });

        if (prompt) {
            await runGeminiCLI(prompt);
        }
    });

    // Comando: Analisar código selecionado
    let analyzeCode = vscode.commands.registerCommand('gemini-cli.analyzeCode', async () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('Nenhum editor ativo');
            return;
        }

        const selection = editor.selection;
        const code = editor.document.getText(selection);
        
        if (!code.trim()) {
            vscode.window.showErrorMessage('Selecione algum código primeiro');
            return;
        }

        const prompt = `Analise este código e sugira melhorias:\n\n${code}`;
        await runGeminiCLI(prompt);
    });

    // Comando: Gerar testes para o arquivo atual
    let generateTests = vscode.commands.registerCommand('gemini-cli.generateTests', async () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('Nenhum editor ativo');
            return;
        }

        const document = editor.document;
        const code = document.getText();
        const fileName = document.fileName.split('/').pop() || 'arquivo';
        const language = document.languageId;

        const prompt = `Gere testes unitários para este código ${language}:\n\n${code}\n\nNome do arquivo: ${fileName}`;
        await runGeminiCLI(prompt);
    });

    // Comando: Explicar código selecionado
    let explainCode = vscode.commands.registerCommand('gemini-cli.explainCode', async () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('Nenhum editor ativo');
            return;
        }

        const selection = editor.selection;
        const code = editor.document.getText(selection);
        
        if (!code.trim()) {
            vscode.window.showErrorMessage('Selecione algum código primeiro');
            return;
        }

        const prompt = `Explique este código em português:\n\n${code}`;
        await runGeminiCLI(prompt);
    });

    context.subscriptions.push(openChat, analyzeCode, generateTests, explainCode);
}

async function runGeminiCLI(prompt: string): Promise<void> {
    try {
        // Verificar se o Gemini CLI está instalado
        try {
            await execAsync('gemini-cli --help');
        } catch (error) {
            vscode.window.showErrorMessage(
                'Gemini CLI não encontrado. Instale com: pipx install gemini-cli'
            );
            return;
        }

        // Mostrar progresso
        vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: "Executando Gemini CLI...",
            cancellable: false
        }, async (progress) => {
            try {
                // Executar o comando Gemini CLI
                const { stdout, stderr } = await execAsync(`gemini-cli "${prompt.replace(/"/g, '\\"')}"`);
                
                if (stderr) {
                    console.error('Erro do Gemini CLI:', stderr);
                }

                // Criar ou abrir arquivo de saída
                const outputFile = vscode.Uri.file('/tmp/gemini-cli-output.md');
                const outputContent = `# Resposta do Gemini CLI

**Prompt:** ${prompt}

---

${stdout}

---

*Gerado em: ${new Date().toLocaleString('pt-BR')}*
`;

                // Escrever no arquivo temporário
                const writeData = Buffer.from(outputContent, 'utf8');
                await vscode.workspace.fs.writeFile(outputFile, writeData);

                // Abrir o arquivo no editor
                const document = await vscode.workspace.openTextDocument(outputFile);
                await vscode.window.showTextDocument(document, vscode.ViewColumn.Beside);

                vscode.window.showInformationMessage('Resposta do Gemini CLI gerada com sucesso!');

            } catch (error) {
                console.error('Erro ao executar Gemini CLI:', error);
                vscode.window.showErrorMessage(
                    `Erro ao executar Gemini CLI: ${error instanceof Error ? error.message : 'Erro desconhecido'}`
                );
            }
        });

    } catch (error) {
        console.error('Erro na extensão Gemini CLI:', error);
        vscode.window.showErrorMessage(
            `Erro na extensão Gemini CLI: ${error instanceof Error ? error.message : 'Erro desconhecido'}`
        );
    }
}

export function deactivate() {
    console.log('Gemini CLI Integration desativada!');
}
