import { API_URL, getAuthHeaders } from './api';

export interface PlatformDocument {
  id: string;
  title: string;
  description: string;
  type: 'contract' | 'policy' | 'manual' | 'ethics';
  version: string;
  is_current: boolean;
  accepted_at?: string;
  document_url: string;
}

export const platformDocumentsService = {
  async getDocuments(): Promise<PlatformDocument[]> {
    const headers = await getAuthHeaders();
    const response = await fetch(`${API_URL}/platform-documents`, { headers });
    if (!response.ok) {
      throw new Error('Falha ao buscar documentos');
    }
    return response.json();
  },

  async acceptDocument(documentId: string): Promise<void> {
    const headers = await getAuthHeaders();
    const response = await fetch(`${API_URL}/platform-documents/${documentId}/accept`, {
      method: 'POST',
      headers,
    });
    if (!response.ok) {
      throw new Error('Falha ao aceitar o documento');
    }
  },

  async getDownloadUrl(documentId: string): Promise<string> {
    const headers = await getAuthHeaders();
    const response = await fetch(`${API_URL}/platform-documents/${documentId}/download-url`, { headers });
    if (!response.ok) {
      throw new Error('Falha ao obter URL de download');
    }
    const data = await response.json();
    return data.url;
  },
}; 