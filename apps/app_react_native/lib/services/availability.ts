import { API_URL, getAuthHeaders } from './api';

export interface AvailabilitySettings {
  availability_status?: 'available' | 'busy' | 'vacation' | 'inactive';
  max_concurrent_cases?: number;
  vacation_start?: string;
  vacation_end?: string;
}

export const availabilityService = {
  async getSettings(): Promise<AvailabilitySettings> {
    const headers = await getAuthHeaders();
    const response = await fetch(`${API_URL}/lawyers/availability`, { headers });
    if (!response.ok) {
      throw new Error('Falha ao buscar configurações de disponibilidade.');
    }
    return response.json();
  },

  async updateSettings(settings: AvailabilitySettings): Promise<void> {
    const headers = await getAuthHeaders();
    await fetch(`${API_URL}/lawyers/availability`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify(settings),
    });
  },
}; 