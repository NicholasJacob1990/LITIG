import { Share, Alert, Platform } from 'react-native';
import * as FileSystem from 'expo-file-system';
import { CaseData } from './cases';
import * as Sharing from 'expo-sharing';

export interface ShareableContent {
  title: string;
  content: string;
  type: 'ai_summary' | 'detailed_analysis' | 'case_document' | 'performance_report';
  metadata?: {
    caseId?: string;
    lawyerName?: string;
    clientName?: string;
    generatedAt?: string;
    [key: string]: any;
  };
}

export interface ShareOptions {
  includeMetadata?: boolean;
  format?: 'text' | 'pdf' | 'html';
  recipients?: string[];
}

/**
 * Compartilha informações de um caso
 * @param caseData - Dados do caso
 * @param includeDocuments - Se deve incluir documentos
 */
export const shareCaseInfo = async (
  caseData: CaseData,
  includeDocuments: boolean = false
): Promise<void> => {
  try {
    const message = generateCaseShareMessage(caseData);
    
    const shareOptions: ShareOptions = {
      title: `Caso: ${caseData.title || 'Informações do Caso'}`,
      message
    };

    const result = await Share.share(shareOptions);
    
    if (result.action === Share.sharedAction) {
      console.log('Case info shared successfully');
    }
  } catch (error) {
    console.error('Error sharing case info:', error);
    Alert.alert('Erro', 'Não foi possível compartilhar as informações do caso');
  }
};

/**
 * Compartilha um documento específico
 * @param documentUrl - URL do documento
 * @param documentName - Nome do documento
 */
export const shareDocument = async (
  documentUrl: string,
  documentName: string
): Promise<void> => {
  try {
    // Verificar se o arquivo existe localmente
    const fileInfo = await FileSystem.getInfoAsync(documentUrl);
    
    if (fileInfo.exists) {
      const shareOptions: ShareOptions = {
        title: `Documento: ${documentName}`,
        url: documentUrl
      };
      
      const result = await Share.share(shareOptions);
      
      if (result.action === Share.sharedAction) {
        console.log('Document shared successfully');
      }
    } else {
      // Se não existe localmente, compartilhar apenas o link
      const shareOptions: ShareOptions = {
        title: `Documento: ${documentName}`,
        message: `Confira o documento: ${documentName}\n\nLink: ${documentUrl}`
      };
      
      await Share.share(shareOptions);
    }
  } catch (error) {
    console.error('Error sharing document:', error);
    Alert.alert('Erro', 'Não foi possível compartilhar o documento');
  }
};

/**
 * Compartilha o resumo da análise de IA
 * @param caseData - Dados do caso
 * @param aiAnalysis - Análise de IA
 */
export const shareAIAnalysis = async (
  caseData: CaseData,
  aiAnalysis: any
): Promise<void> => {
  try {
    const message = generateAIAnalysisShareMessage(caseData, aiAnalysis);
    
    const shareOptions: ShareOptions = {
      title: `Análise IA: ${caseData.title || 'Resumo do Caso'}`,
      message
    };

    const result = await Share.share(shareOptions);
    
    if (result.action === Share.sharedAction) {
      console.log('AI analysis shared successfully');
    }
  } catch (error) {
    console.error('Error sharing AI analysis:', error);
    Alert.alert('Erro', 'Não foi possível compartilhar a análise');
  }
};

/**
 * Compartilha informações de contato do advogado
 * @param lawyerInfo - Informações do advogado
 */
export const shareLawyerContact = async (lawyerInfo: {
  name: string;
  phone?: string;
  email?: string;
  specialty?: string;
}): Promise<void> => {
  try {
    const message = generateLawyerContactMessage(lawyerInfo);
    
    const shareOptions: ShareOptions = {
      title: `Contato: ${lawyerInfo.name}`,
      message
    };

    const result = await Share.share(shareOptions);
    
    if (result.action === Share.sharedAction) {
      console.log('Lawyer contact shared successfully');
    }
  } catch (error) {
    console.error('Error sharing lawyer contact:', error);
    Alert.alert('Erro', 'Não foi possível compartilhar o contato');
  }
};

/**
 * Gera mensagem de compartilhamento para informações do caso
 */
const generateCaseShareMessage = (caseData: CaseData): string => {
  const statusMap: Record<string, string> = {
    'pending': 'Pendente',
    'active': 'Ativo',
    'completed': 'Concluído',
    'summary_generated': 'Pré-análise'
  };

  const priorityMap: Record<string, string> = {
    'high': 'Alta',
    'medium': 'Média',
    'low': 'Baixa'
  };

  return `📋 *Informações do Caso*

*Título:* ${caseData.title || 'Não informado'}
*Descrição:* ${caseData.description || 'Não informado'}
*Status:* ${statusMap[caseData.status as string] || caseData.status}
*Prioridade:* ${priorityMap[caseData.priority as string] || caseData.priority}
*Data de Criação:* ${new Date(caseData.created_at).toLocaleDateString('pt-BR')}

${caseData.lawyer ? `*Advogado Responsável:* ${caseData.lawyer.name}
*Especialidade:* ${caseData.lawyer.specialty || 'Não informado'}` : ''}

---
Compartilhado via LITGO5 📱`;
};

/**
 * Gera mensagem de compartilhamento para análise de IA
 */
const generateAIAnalysisShareMessage = (caseData: CaseData, aiAnalysis: any): string => {
  return `🤖 *Análise Inteligente do Caso*

*Caso:* ${caseData.title || 'Não informado'}
*Confiança da Análise:* ${aiAnalysis.confidence || 'N/A'}%
*Área Jurídica:* ${aiAnalysis.legal_area || 'Não classificado'}
*Nível de Risco:* ${aiAnalysis.risk_level || 'Não avaliado'}
${aiAnalysis.estimated_cost ? `*Custo Estimado:* R$ ${aiAnalysis.estimated_cost.toLocaleString('pt-BR')}` : ''}

*Pontos Principais:*
${aiAnalysis.key_points ? aiAnalysis.key_points.map((point: string, index: number) => `${index + 1}. ${point}`).join('\n') : 'Não disponível'}

*Recomendações:*
${aiAnalysis.recommendations ? aiAnalysis.recommendations.map((rec: string, index: number) => `• ${rec}`).join('\n') : 'Não disponível'}

⚠️ *Aviso:* Esta análise é gerada por IA e tem caráter orientativo.

---
Compartilhado via LITGO5 📱`;
};

/**
 * Gera mensagem de compartilhamento para contato do advogado
 */
const generateLawyerContactMessage = (lawyerInfo: {
  name: string;
  phone?: string;
  email?: string;
  specialty?: string;
}): string => {
  return `👨‍💼 *Contato do Advogado*

*Nome:* ${lawyerInfo.name}
${lawyerInfo.specialty ? `*Especialidade:* ${lawyerInfo.specialty}` : ''}
${lawyerInfo.phone ? `*Telefone:* ${lawyerInfo.phone}` : ''}
${lawyerInfo.email ? `*E-mail:* ${lawyerInfo.email}` : ''}

---
Compartilhado via LITGO5 📱`;
};

/**
 * Copia texto para a área de transferência
 * @param text - Texto para copiar
 */
export const copyToClipboard = async (text: string): Promise<void> => {
  try {
    // Em React Native, podemos usar o Clipboard API
    // import { Clipboard } from 'react-native';
    // await Clipboard.setString(text);
    
    // Por enquanto, vamos usar o Share para simular a cópia
    await Share.share({
      message: text
    });
  } catch (error) {
    console.error('Error copying to clipboard:', error);
    Alert.alert('Erro', 'Não foi possível copiar o texto');
  }
};

/**
 * Gera um relatório completo do caso para compartilhamento
 * @param caseData - Dados do caso
 * @param aiAnalysis - Análise de IA (opcional)
 * @param documents - Lista de documentos (opcional)
 */
export const generateCaseReport = async (
  caseData: CaseData,
  aiAnalysis?: any,
  documents?: any[]
): Promise<string> => {
  const report = `📊 *RELATÓRIO COMPLETO DO CASO*

${generateCaseShareMessage(caseData)}

${aiAnalysis ? `\n🤖 *ANÁLISE INTELIGENTE*\n\n${generateAIAnalysisShareMessage(caseData, aiAnalysis).split('---')[0]}` : ''}

${documents && documents.length > 0 ? `\n📁 *DOCUMENTOS ANEXADOS*\n\n${documents.map((doc, index) => `${index + 1}. ${doc.name} (${doc.file_type})`).join('\n')}` : ''}

\n---
*Relatório gerado em:* ${new Date().toLocaleString('pt-BR')}
Compartilhado via LITGO5 📱`;

  return report;
};

/**
 * Compartilha relatório completo do caso
 * @param caseData - Dados do caso
 * @param aiAnalysis - Análise de IA (opcional)
 * @param documents - Lista de documentos (opcional)
 */
export const shareCaseReport = async (
  caseData: CaseData,
  aiAnalysis?: any,
  documents?: any[]
): Promise<void> => {
  try {
    const report = await generateCaseReport(caseData, aiAnalysis, documents);
    
    const shareOptions: ShareOptions = {
      title: `Relatório Completo: ${caseData.title || 'Caso'}`,
      message: report
    };

    const result = await Share.share(shareOptions);
    
    if (result.action === Share.sharedAction) {
      console.log('Case report shared successfully');
    }
  } catch (error) {
    console.error('Error sharing case report:', error);
    Alert.alert('Erro', 'Não foi possível compartilhar o relatório');
  }
};

class SharingService {
  /**
   * Compartilha conteúdo usando o sistema nativo de compartilhamento
   */
  async shareContent(content: ShareableContent, options: ShareOptions = {}) {
    try {
      const formattedContent = this.formatContent(content, options);
      
      if (await Sharing.isAvailableAsync()) {
        // Se é possível compartilhar arquivos, criar um arquivo temporário
        if (options.format === 'pdf' || options.format === 'html') {
          return await this.shareAsFile(content, options);
        } else {
          // Compartilhamento simples de texto
          return await this.shareAsText(formattedContent);
        }
      } else {
        // Fallback para copiar para clipboard
        return await this.copyToClipboard(formattedContent);
      }
    } catch (error) {
      console.error('Erro ao compartilhar:', error);
      Alert.alert('Erro', 'Não foi possível compartilhar o conteúdo.');
      return false;
    }
  }

  /**
   * Compartilha resumo de IA
   */
  async shareAISummary(aiAnalysis: any, caseData?: any) {
    const content: ShareableContent = {
      title: 'Resumo de Análise por IA - LITGO',
      content: this.formatAISummary(aiAnalysis),
      type: 'ai_summary',
      metadata: {
        caseId: caseData?.id,
        generatedAt: new Date().toISOString(),
        confidence: aiAnalysis.confidence
      }
    };

    return await this.shareContent(content, { includeMetadata: true });
  }

  /**
   * Compartilha análise jurídica detalhada
   */
  async shareDetailedAnalysis(analysis: any, caseData?: any) {
    const content: ShareableContent = {
      title: 'Análise Jurídica Detalhada - LITGO',
      content: this.formatDetailedAnalysis(analysis),
      type: 'detailed_analysis',
      metadata: {
        caseId: caseData?.id,
        lawyerName: caseData?.lawyer?.name,
        generatedAt: new Date().toISOString()
      }
    };

    return await this.shareContent(content, { 
      includeMetadata: true,
      format: 'html'
    });
  }

  /**
   * Compartilha relatório de performance (apenas advogados)
   */
  async sharePerformanceReport(performanceData: any, lawyerName: string) {
    const content: ShareableContent = {
      title: 'Relatório de Performance - LITGO',
      content: this.formatPerformanceReport(performanceData),
      type: 'performance_report',
      metadata: {
        lawyerName,
        generatedAt: new Date().toISOString(),
        period: 'Últimos 12 meses'
      }
    };

    return await this.shareContent(content, { 
      includeMetadata: true,
      format: 'pdf'
    });
  }

  /**
   * Formatar conteúdo para compartilhamento
   */
  private formatContent(content: ShareableContent, options: ShareOptions): string {
    let formatted = `${content.title}\n\n`;
    
    if (options.includeMetadata && content.metadata) {
      formatted += this.formatMetadata(content.metadata) + '\n\n';
    }
    
    formatted += content.content;
    
    // Adicionar disclaimer
    formatted += '\n\n---\n';
    formatted += 'Este documento foi gerado pela plataforma LITGO.\n';
    formatted += '© 2025 JACOBS Advogados Associados\n';
    formatted += 'Para mais informações, acesse: https://litgo.com.br';
    
    return formatted;
  }

  /**
   * Formatar resumo de IA
   */
  private formatAISummary(aiAnalysis: any): string {
    let content = '';
    
    content += `📋 RESUMO EXECUTIVO\n`;
    content += `Área Jurídica: ${aiAnalysis.legal_area || 'Não classificado'}\n`;
    content += `Nível de Risco: ${this.formatRiskLevel(aiAnalysis.risk_level)}\n`;
    content += `Confiança da Análise: ${aiAnalysis.confidence || 85}%\n\n`;
    
    if (aiAnalysis.key_points?.length) {
      content += `🎯 PONTOS PRINCIPAIS:\n`;
      aiAnalysis.key_points.forEach((point: string, index: number) => {
        content += `${index + 1}. ${point}\n`;
      });
      content += '\n';
    }
    
    if (aiAnalysis.recommendations?.length) {
      content += `💡 RECOMENDAÇÕES:\n`;
      aiAnalysis.recommendations.forEach((rec: string, index: number) => {
        content += `• ${rec}\n`;
      });
      content += '\n';
    }
    
    if (aiAnalysis.next_steps?.length) {
      content += `📝 PRÓXIMOS PASSOS:\n`;
      aiAnalysis.next_steps.forEach((step: string, index: number) => {
        content += `${index + 1}. ${step}\n`;
      });
      content += '\n';
    }
    
    if (aiAnalysis.estimated_cost) {
      content += `💰 ESTIMATIVA DE CUSTOS: R$ ${aiAnalysis.estimated_cost.toLocaleString('pt-BR')}\n\n`;
    }
    
    content += `⚠️ IMPORTANTE: Esta análise é gerada por inteligência artificial e tem caráter orientativo. Para decisões jurídicas importantes, consulte sempre um advogado especializado.`;
    
    return content;
  }

  /**
   * Formatar análise detalhada
   */
  private formatDetailedAnalysis(analysis: any): string {
    let content = '';
    
    content += `📊 ANÁLISE JURÍDICA DETALHADA\n\n`;
    
    if (analysis.classificacao) {
      content += `🏛️ CLASSIFICAÇÃO:\n`;
      content += `Área Principal: ${analysis.classificacao.area_principal}\n`;
      content += `Assunto: ${analysis.classificacao.assunto_principal}\n`;
      content += `Natureza: ${analysis.classificacao.natureza}\n\n`;
    }
    
    if (analysis.analise_viabilidade) {
      content += `⚖️ ANÁLISE DE VIABILIDADE:\n`;
      content += `Classificação: ${analysis.analise_viabilidade.classificacao}\n`;
      content += `Probabilidade de Êxito: ${analysis.analise_viabilidade.probabilidade_exito}\n`;
      content += `Complexidade: ${analysis.analise_viabilidade.complexidade}\n`;
      content += `Justificativa: ${analysis.analise_viabilidade.justificativa}\n\n`;
      
      if (analysis.analise_viabilidade.pontos_fortes?.length) {
        content += `✅ Pontos Fortes:\n`;
        analysis.analise_viabilidade.pontos_fortes.forEach((ponto: string) => {
          content += `• ${ponto}\n`;
        });
        content += '\n';
      }
      
      if (analysis.analise_viabilidade.pontos_fracos?.length) {
        content += `❌ Pontos Fracos:\n`;
        analysis.analise_viabilidade.pontos_fracos.forEach((ponto: string) => {
          content += `• ${ponto}\n`;
        });
        content += '\n';
      }
    }
    
    return content;
  }

  /**
   * Formatar relatório de performance
   */
  private formatPerformanceReport(data: any): string {
    let content = '';
    
    content += `📈 RELATÓRIO DE PERFORMANCE\n\n`;
    
    content += `📊 INDICADORES PRINCIPAIS:\n`;
    content += `Taxa de Sucesso: ${(data.kpi.success_rate * 100).toFixed(1)}%\n`;
    content += `Satisfação do Cliente: ${data.kpi.client_satisfaction.toFixed(1)}/5.0\n`;
    content += `Tempo Médio de Resposta: ${data.kpi.response_time_hours}h\n`;
    content += `Receita Total: R$ ${(data.kpi.total_earnings / 1000).toFixed(0)}k\n\n`;
    
    content += `📅 ESTATÍSTICAS DO MÊS:\n`;
    content += `Casos Concluídos: ${data.monthly_stats.cases_completed}\n`;
    content += `Novos Clientes: ${data.monthly_stats.new_clients}\n`;
    content += `Receita Mensal: R$ ${(data.monthly_stats.revenue / 1000).toFixed(1)}k\n`;
    content += `Avaliação Média: ${data.monthly_stats.avg_rating.toFixed(1)}/5.0\n\n`;
    
    if (data.kpi_subarea) {
      content += `🏛️ PERFORMANCE POR ÁREA:\n`;
      Object.entries(data.kpi_subarea).forEach(([area, score]: [string, any]) => {
        content += `${area}: ${(score * 100).toFixed(1)}%\n`;
      });
      content += '\n';
    }
    
    content += `🎯 HABILIDADES INTERPESSOAIS: ${(data.kpi_softskill * 100).toFixed(0)}%\n`;
    
    return content;
  }

  /**
   * Formatar metadados
   */
  private formatMetadata(metadata: any): string {
    let formatted = '📋 INFORMAÇÕES DO DOCUMENTO:\n';
    
    if (metadata.generatedAt) {
      formatted += `Data de Geração: ${new Date(metadata.generatedAt).toLocaleString('pt-BR')}\n`;
    }
    
    if (metadata.caseId) {
      formatted += `ID do Caso: ${metadata.caseId}\n`;
    }
    
    if (metadata.lawyerName) {
      formatted += `Advogado: ${metadata.lawyerName}\n`;
    }
    
    if (metadata.clientName) {
      formatted += `Cliente: ${metadata.clientName}\n`;
    }
    
    if (metadata.confidence) {
      formatted += `Nível de Confiança: ${metadata.confidence}%\n`;
    }
    
    return formatted;
  }

  /**
   * Formatar nível de risco
   */
  private formatRiskLevel(level: string): string {
    switch (level?.toLowerCase()) {
      case 'low': return 'Baixo 🟢';
      case 'medium': return 'Médio 🟡';
      case 'high': return 'Alto 🔴';
      default: return 'Não avaliado ⚪';
    }
  }

  /**
   * Compartilhar como texto simples
   */
  private async shareAsText(content: string): Promise<boolean> {
    try {
      if (Platform.OS === 'ios') {
        // No iOS, usar o Share nativo
        const Share = require('react-native').Share;
        await Share.share({ message: content });
      } else {
        // No Android, usar Expo Sharing
        const fileUri = await this.createTempFile(content, 'txt');
        await Sharing.shareAsync(fileUri);
      }
      return true;
    } catch (error) {
      console.error('Erro ao compartilhar texto:', error);
      return false;
    }
  }

  /**
   * Compartilhar como arquivo
   */
  private async shareAsFile(content: ShareableContent, options: ShareOptions): Promise<boolean> {
    try {
      const fileContent = this.formatContent(content, options);
      const extension = options.format === 'pdf' ? 'pdf' : 'html';
      const fileUri = await this.createTempFile(fileContent, extension);
      
      await Sharing.shareAsync(fileUri, {
        mimeType: options.format === 'pdf' ? 'application/pdf' : 'text/html',
        dialogTitle: `Compartilhar ${content.title}`
      });
      
      return true;
    } catch (error) {
      console.error('Erro ao compartilhar arquivo:', error);
      return false;
    }
  }

  /**
   * Copiar para clipboard como fallback
   */
  private async copyToClipboard(content: string): Promise<boolean> {
    try {
      const Clipboard = require('expo-clipboard');
      await Clipboard.setStringAsync(content);
      Alert.alert('Copiado', 'Conteúdo copiado para a área de transferência.');
      return true;
    } catch (error) {
      console.error('Erro ao copiar para clipboard:', error);
      return false;
    }
  }

  /**
   * Criar arquivo temporário
   */
  private async createTempFile(content: string, extension: string): Promise<string> {
    const fileName = `litgo_share_${Date.now()}.${extension}`;
    const fileUri = `${FileSystem.documentDirectory}${fileName}`;
    
    await FileSystem.writeAsStringAsync(fileUri, content, {
      encoding: FileSystem.EncodingType.UTF8
    });
    
    return fileUri;
  }
}

export const sharingService = new SharingService();