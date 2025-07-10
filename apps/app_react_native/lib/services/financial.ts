import { API_URL, getAuthHeaders } from './api';

export interface MonthlyBilling {
  month: string;
  value: number;
}

export interface LawyerFinancials {
  total_billed: number;
  total_received: number;
  active_contracts: number;
  avg_ticket: number;
  monthly_billing: MonthlyBilling[];
}

export interface PaymentRecord {
  id: string;
  case_title: string;
  net_amount: number;
  paid_at: string;
  status: string;
}

export const financialReportsService = {
  async getLawyerFinancials(): Promise<LawyerFinancials> {
    const headers = await getAuthHeaders();
    const response = await fetch(`${API_URL}/financials/dashboard`, { headers });
    if (!response.ok) {
      throw new Error('Falha ao buscar dados do dashboard financeiro.');
    }
    return response.json();
  },

  async getPaymentHistory(page: number, limit: number): Promise<PaymentRecord[]> {
    const headers = await getAuthHeaders();
    const response = await fetch(`${API_URL}/financials/payment-history?page=${page}&limit=${limit}`, { headers });
    if (!response.ok) {
      throw new Error('Falha ao buscar histórico de pagamentos.');
    }
    return response.json();
  },
}; 