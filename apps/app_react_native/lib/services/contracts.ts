import supabase from '@/lib/supabase';
import { getAuthHeaders } from './api';
import Constants from 'expo-constants';

const API_URL = Constants.expoConfig?.extra?.apiUrl || process.env.EXPO_PUBLIC_API_URL || 'http://127.0.0.1:8080/api';

export interface Contract {
  id: string;
  case_id: string;
  lawyer_id: string;
  client_id: string;
  status: 'pending-signature' | 'active' | 'closed' | 'canceled';
  fee_model: {
    type: 'success' | 'fixed' | 'hourly';
    percent?: number;
    value?: number;
    rate?: number;
  };
  created_at: string;
  updated_at: string;
  signed_client?: string;
  signed_lawyer?: string;
  doc_url?: string;
  // Dados relacionados
  case_title?: string;
  case_area?: string;
  lawyer_name?: string;
  client_name?: string;
}

export type FeeModel = Contract['fee_model'];

export interface CreateContractRequest {
  case_id: string;
  lawyer_id: string;
  fee_model: FeeModel;
}

export type CreateContractData = CreateContractRequest;

export interface SignContractRequest {
  role: 'client' | 'lawyer';
  signature_data?: any;
}

export interface DocuSignStatus {
  envelope_id: string;
  status: string;
  created_date: string;
  completed_date?: string;
  recipients: Array<{
    name: string;
    email: string;
    status: string;
    signed_date?: string;
  }>;
}

export const contractsService = {
  /**
   * Valida modelo de honorários
   */
  validateFeeModel(feeModel: FeeModel): string | null {
    if (!feeModel.type) {
      return 'Tipo de honorário é obrigatório';
    }

    switch (feeModel.type) {
      case 'success':
        if (!feeModel.percent || feeModel.percent <= 0 || feeModel.percent > 100) {
          return 'Percentual deve estar entre 1% e 100%';
        }
        break;
      case 'fixed':
        if (!feeModel.value || feeModel.value <= 0) {
          return 'Valor fixo deve ser maior que zero';
        }
        break;
      case 'hourly':
        if (!feeModel.rate || feeModel.rate <= 0) {
          return 'Taxa por hora deve ser maior que zero';
        }
        break;
      default:
        return 'Tipo de honorário inválido';
    }

    return null;
  },

  /**
   * Cria um novo contrato
   */
  async createContract(data: CreateContractRequest): Promise<Contract> {
    const headers = await getAuthHeaders();
    const response = await fetch(`${API_URL}/contracts`, {
      method: 'POST',
      headers,
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.detail || 'Falha ao criar contrato');
    }

    return response.json();
  },

  /**
   * Busca contrato por ID
   */
  async getContract(contractId: string): Promise<Contract> {
    const headers = await getAuthHeaders();
    const response = await fetch(`${API_URL}/contracts/${contractId}`, {
      method: 'GET',
      headers,
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.detail || 'Falha ao buscar contrato');
    }

    return response.json();
  },

  /**
   * Lista contratos do usuário
   */
  async getContracts(status?: string): Promise<Contract[]> {
    const headers = await getAuthHeaders();
    const url = status ? `${API_URL}/contracts?status=${status}` : `${API_URL}/contracts`;
    const response = await fetch(url, {
      method: 'GET',
      headers,
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.detail || 'Falha ao listar contratos');
    }

    return response.json();
  },

  /**
   * Assina contrato
   */
  async signContract(contractId: string, signData: SignContractRequest): Promise<Contract> {
    const headers = await getAuthHeaders();
    const response = await fetch(`${API_URL}/contracts/${contractId}/sign`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify(signData),
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.detail || 'Falha ao assinar contrato');
    }

    return response.json();
  },

  /**
   * Cancela contrato
   */
  async cancelContract(contractId: string): Promise<Contract> {
    const headers = await getAuthHeaders();
    const response = await fetch(`${API_URL}/contracts/${contractId}/cancel`, {
      method: 'PATCH',
      headers,
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.detail || 'Falha ao cancelar contrato');
    }

    return response.json();
  },

  /**
   * Obtém URL do PDF do contrato
   */
  async getContractPdf(contractId: string): Promise<string> {
    const headers = await getAuthHeaders();
    const response = await fetch(`${API_URL}/contracts/${contractId}/pdf`, {
      method: 'GET',
      headers,
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.detail || 'Falha ao obter PDF do contrato');
    }

    const data = await response.json();
    return data.doc_url;
  },

  /**
   * Consulta status do envelope DocuSign
   */
  async getDocuSignStatus(contractId: string): Promise<DocuSignStatus> {
    const headers = await getAuthHeaders();
    const response = await fetch(`${API_URL}/contracts/${contractId}/docusign-status`, {
      method: 'GET',
      headers,
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.detail || 'Falha ao consultar status DocuSign');
    }

    return response.json();
  },

  /**
   * Baixa documento assinado do DocuSign
   */
  async downloadDocuSignDocument(contractId: string): Promise<Blob> {
    const headers = await getAuthHeaders();
    const response = await fetch(`${API_URL}/contracts/${contractId}/docusign-download`, {
      method: 'GET',
      headers,
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.detail || 'Falha ao baixar documento DocuSign');
    }

    return response.blob();
  },

  /**
   * Sincroniza status do contrato com DocuSign
   */
  async syncDocuSignStatus(contractId: string): Promise<Contract> {
    const headers = await getAuthHeaders();
    const response = await fetch(`${API_URL}/contracts/${contractId}/sync-docusign`, {
      method: 'POST',
      headers,
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.detail || 'Falha ao sincronizar status DocuSign');
    }

    return response.json();
  },

  /**
   * Verifica se contrato foi criado via DocuSign
   */
  isDocuSignContract(contract: Contract): boolean {
    return contract.doc_url?.startsWith('envelope_') || false;
  },

  /**
   * Formata status do DocuSign para exibição
   */
  formatDocuSignStatus(status: string): string {
    const statusMap: Record<string, string> = {
      'sent': 'Enviado para assinatura',
      'delivered': 'Entregue aos signatários',
      'completed': 'Completamente assinado',
      'declined': 'Recusado',
      'voided': 'Cancelado',
      'created': 'Criado'
    };

    return statusMap[status] || status;
  },

  /**
   * Obtém informações do signatário DocuSign
   */
  getSignerInfo(recipients: any[], userEmail: string): any {
    return recipients?.find(r => r.email === userEmail) || null;
  },

  /**
   * Formata modelo de honorários para exibição
   */
  formatFeeModel(feeModel: FeeModel): string {
    switch (feeModel.type) {
      case 'success':
        return `Honorários de êxito: ${feeModel.percent}%`;
      case 'fixed':
        return `Honorários fixos: R$ ${feeModel.value?.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}`;
      case 'hourly':
        return `Por hora: R$ ${feeModel.rate?.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}/h`;
      default:
        return 'Modelo não especificado';
    }
  },

  /**
   * Formata status do contrato para exibição
   */
  formatStatus(status: Contract['status']): string {
    const statusMap: Record<Contract['status'], string> = {
      'pending-signature': 'Aguardando assinatura',
      'active': 'Ativo',
      'closed': 'Finalizado',
      'canceled': 'Cancelado'
    };

    return statusMap[status] || status;
  },

  /**
   * Obtém cor do status para UI
   */
  getStatusColor(status: Contract['status']): string {
    const colorMap: Record<Contract['status'], string> = {
      'pending-signature': '#f59e0b', // amber
      'active': '#10b981', // green
      'closed': '#6b7280', // gray
      'canceled': '#ef4444' // red
    };

    return colorMap[status] || '#6b7280';
  },

  /**
   * Verifica se contrato pode ser assinado
   */
  canBeSigned(contract: Contract): boolean {
    return contract.status === 'pending-signature';
  },

  /**
   * Verifica se contrato está totalmente assinado
   */
  isFullySigned(contract: Contract): boolean {
    return !!(contract.signed_client && contract.signed_lawyer);
  },

  /**
   * Verifica se usuário já assinou o contrato
   */
  hasUserSigned(contract: Contract, userId: string): boolean {
    if (contract.client_id === userId) {
      return !!contract.signed_client;
    }
    if (contract.lawyer_id === userId) {
      return !!contract.signed_lawyer;
    }
    return false;
  },

  /**
   * Verifica se contrato pode ser assinado por um usuário específico
   */
  canBeSignedBy(contract: Contract, userId: string): boolean {
    if (contract.status !== 'pending-signature') {
      return false;
    }
    
    // Verifica se é cliente ou advogado e se ainda não assinou
    if (contract.client_id === userId) {
      return !contract.signed_client;
    }
    if (contract.lawyer_id === userId) {
      return !contract.signed_lawyer;
    }
    
    return false;
  },

  /**
   * Obtém texto do status do contrato
   */
  getStatusText(status: Contract['status']): string {
    const statusMap: Record<Contract['status'], string> = {
      'pending-signature': 'Pendente',
      'active': 'Ativo',
      'closed': 'Finalizado',
      'canceled': 'Cancelado'
    };

    return statusMap[status] || 'Desconhecido';
  },

  /**
   * Obtém status das assinaturas do contrato
   */
  getSignatureStatus(contract: Contract): {
    clientSigned: boolean;
    lawyerSigned: boolean;
    allSigned: boolean;
    pendingSignatures: string[];
  } {
    const clientSigned = !!contract.signed_client;
    const lawyerSigned = !!contract.signed_lawyer;
    const allSigned = clientSigned && lawyerSigned;
    
    const pendingSignatures: string[] = [];
    if (!clientSigned) pendingSignatures.push('cliente');
    if (!lawyerSigned) pendingSignatures.push('advogado');
    
    return {
      clientSigned,
      lawyerSigned,
      allSigned,
      pendingSignatures
    };
  }
}; 