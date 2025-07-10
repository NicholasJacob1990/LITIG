import * as FileSystem from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import { Platform } from 'react-native';
import { API_URL, getAuthHeaders } from './api';

/**
 * Simula o download de um relatório de caso em PDF do backend e o disponibiliza para o usuário.
 * Em um app real, esta função faria uma chamada a um endpoint que gera o PDF.
 *
 * @param caseId - O ID do caso para o qual o relatório será gerado.
 */
export async function downloadCaseReport(caseId: string): Promise<void> {
  // Simula a geração de um conteúdo de PDF (poderia ser um HTML convertido ou um PDF gerado no backend)
  const pdfContent = `
    <html>
      <body>
        <h1>Relatório do Caso #${caseId}</h1>
        <p>Este é um relatório gerado automaticamente para o caso ${caseId}.</p>
        <p>Data: ${new Date().toLocaleDateString()}</p>
        <h2>Detalhes do Caso</h2>
        <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit...</p>
        <h2>Andamento</h2>
        <p>...</p>
      </body>
    </html>
  `;

  const fileName = `relatorio_caso_${caseId}.pdf`;
  const fileUri = `${FileSystem.documentDirectory}${fileName}`;

  try {
    // Em uma implementação real, você faria o download de um endpoint
    // await FileSystem.downloadAsync(backendUrl, fileUri);

    // Para a simulação, vamos apenas criar um arquivo de texto com o conteúdo
    // A conversão para PDF real precisaria de uma biblioteca mais robusta ou um serviço de backend
    await FileSystem.writeAsStringAsync(fileUri, pdfContent, {
      encoding: FileSystem.EncodingType.UTF8,
    });

    // Verifica se o compartilhamento está disponível
    if (!(await Sharing.isAvailableAsync())) {
      alert('O compartilhamento não está disponível neste dispositivo.');
      return;
    }
    
    // Abre a UI de compartilhamento para que o usuário possa salvar/enviar o arquivo
    await Sharing.shareAsync(fileUri, {
      mimeType: 'application/pdf',
      dialogTitle: 'Salvar Relatório do Caso',
    });

  } catch (error) {
    console.error('Erro ao gerar/baixar relatório:', error);
    throw new Error('Falha ao processar o relatório do caso.');
  }
}

/**
 * Baixa o relatório de performance de um advogado em PDF.
 * @param lawyerId O ID do advogado para gerar o relatório.
 */
export const downloadLawyerPerformanceReport = async (lawyerId: string): Promise<void> => {
  try {
    const headers = await getAuthHeaders();

    const response = await fetch(`${API_URL}/reports/lawyer/${lawyerId}/performance`, {
      headers,
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.detail || 'Falha ao baixar o relatório de performance.');
    }

    const blob = await response.blob();
    const fileName = `relatorio_performance_${lawyerId}.pdf`;
    const fileUri = `${FileSystem.documentDirectory}${fileName}`;

    const reader = new FileReader();
    reader.readAsDataURL(blob);
    
    return new Promise((resolve, reject) => {
      reader.onloadend = async () => {
        try {
          const base64data = (reader.result as string).split(',')[1];
          await FileSystem.writeAsStringAsync(fileUri, base64data, {
            encoding: FileSystem.EncodingType.Base64,
          });

          if (await Sharing.isAvailableAsync()) {
            await Sharing.shareAsync(fileUri, {
              mimeType: 'application/pdf',
              dialogTitle: 'Compartilhar relatório de performance',
            });
          } else {
            alert('Não é possível compartilhar arquivos neste dispositivo.');
          }
          resolve();
        } catch (error) {
          reject(new Error('Não foi possível processar o relatório.'));
        }
      };
      reader.onerror = () => {
        reject(new Error('Falha ao ler os dados do relatório.'));
      };
    });

  } catch (error) {
    alert(error instanceof Error ? error.message : 'Ocorreu um erro desconhecido.');
    throw error;
  }
};

/**
 * Baixa o relatório de casos de um cliente em PDF.
 * @param clientId O ID do cliente para gerar o relatório.
 */
export const downloadClientCasesReport = async (clientId: string): Promise<void> => {
  try {
    const headers = await getAuthHeaders();

    const response = await fetch(`${API_URL}/reports/client/${clientId}/cases`, {
      headers,
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.detail || 'Falha ao baixar o relatório de casos.');
    }

    const blob = await response.blob();
    const fileName = `relatorio_casos_${clientId}.pdf`;
    const fileUri = `${FileSystem.documentDirectory}${fileName}`;

    const reader = new FileReader();
    reader.readAsDataURL(blob);
    
    return new Promise((resolve, reject) => {
      reader.onloadend = async () => {
        try {
          const base64data = (reader.result as string).split(',')[1];
          await FileSystem.writeAsStringAsync(fileUri, base64data, {
            encoding: FileSystem.EncodingType.Base64,
          });

          if (await Sharing.isAvailableAsync()) {
            await Sharing.shareAsync(fileUri, {
              mimeType: 'application/pdf',
              dialogTitle: 'Compartilhar relatório de casos',
            });
          } else {
            alert('Não é possível compartilhar arquivos neste dispositivo.');
          }
          resolve();
        } catch (error) {
          reject(new Error('Não foi possível processar o relatório.'));
        }
      };
      reader.onerror = () => {
        reject(new Error('Falha ao ler os dados do relatório.'));
      };
    });

  } catch (error) {
    alert(error instanceof Error ? error.message : 'Ocorreu um erro desconhecido.');
    throw error;
  }
}; 