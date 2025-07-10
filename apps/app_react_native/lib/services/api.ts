import Constants from 'expo-constants';
import supabase from '../supabase';

// Mock data imports
import mockMatches from '../../mocks/matches.json';
import mockMyCases from '../../mocks/my-cases.json';

// A URL da API é pega das variáveis de ambiente do Expo
export const API_URL = Constants.expoConfig?.extra?.apiUrl || process.env.EXPO_PUBLIC_API_URL || 'http://127.0.0.1:8080/api';
const USE_MOCK_API = Constants.expoConfig?.extra?.useMockApi || process.env.USE_MOCK_API === 'true';


export async function getAuthHeaders() {
    const { data: { session } } = await supabase.auth.getSession();
    const headers: { [key: string]: string } = {
        'Content-Type': 'application/json',
    };
    if (session?.access_token) {
        headers['Authorization'] = `Bearer ${session.access_token}`;
    }
    return headers;
}

class AuthError extends Error {
  constructor(message = 'Sessão inválida. Por favor, faça login novamente.') {
    super(message);
    this.name = 'AuthError';
  }
}

/**
 * Wrapper centralizado para todas as chamadas fetch à API.
 * Lida com autenticação, tratamento de erros e expiração de token.
 */
async function apiFetch(endpoint: string, options: RequestInit = {}) {
  // --- MOCK INTERCEPTION ---
  if (USE_MOCK_API) {
    console.log(`[MOCK] Intercepting API call to: ${endpoint}`);
    await new Promise(resolve => setTimeout(resolve, 500)); // Simular delay de rede

    if (endpoint.startsWith('/match')) {
      return mockMatches;
    }
    if (endpoint.startsWith('/cases/my-cases')) {
      return mockMyCases;
    }
    // Adicionar outros endpoints mockados aqui...

    console.warn(`[MOCK] No mock found for endpoint: ${endpoint}. Falling back to network.`);
  }
  // --- END MOCK INTERCEPTION ---

  const { data: { session } } = await supabase.auth.getSession();
  
  const headers = {
    'Content-Type': 'application/json',
    ...(session?.access_token && { 'Authorization': `Bearer ${session.access_token}` }),
    ...options.headers,
  };

  try {
    const response = await fetch(`${API_URL}${endpoint}`, { ...options, headers });

    if (response.status === 401) {
      // Token inválido ou expirado. Deslogar o usuário.
      await supabase.auth.signOut();
      // O listener onAuthStateChange no _layout principal irá redirecionar para o login.
      throw new AuthError();
    }

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ detail: response.statusText }));
      throw new Error(errorData.detail || `Erro na API: ${response.status}`);
    }

    if (response.status === 204) {
      return null;
    }
    
    return response.json();

  } catch (error) {
    if (error instanceof AuthError) {
      throw error;
    }
    console.error(`Erro na chamada da API para ${endpoint}:`, error);
    throw new Error('Não foi possível conectar ao servidor. Verifique sua conexão com a internet.');
  }
}

// Interfaces
interface TriageTaskResponse {
    task_id: string;
    status: string;
    message: string;
}

export interface LawyerMatch {
    id: string;
    nome: string;
    expertise_areas: string[];
    score: number;
    distance_km: number;
    estimated_response_time_hours: number;
    rating: number;
    total_cases: number;
    estimated_success_rate: number;
    oab_numero?: string;
    uf?: string;
    avatar_url?: string;
    review_texts: string[];
    is_available: boolean;
    review_count?: number;
    experience?: number;
    consultation_types?: ('chat' | 'video' | 'presential')[];
    consultation_fee?: number;
    curriculo_json?: any;
}

export interface MatchResponse {
    success: boolean;
    case_id: string;
    lawyers: LawyerMatch[];
    total_lawyers_evaluated: number;
    algorithm_version: string;
    preset_used: string;
    execution_time_ms: number;
    weights_used: { [key: string]: number };
    case_complexity: 'LOW' | 'MEDIUM' | 'HIGH';
    ab_test_group?: string;
    model_version_used?: string;
}

interface MatchRequest {
    case: any;
    top_n: number;
    preset: 'fast' | 'expert' | 'balanced' | 'economic';
    max_consultation_fee?: number;
    max_hourly_rate?: number;
    tiers?: string[];
}

interface TriagePayload {
    texto_cliente: string;
    coords?: [number, number];
}

// Funções da API
export function findMatches(request: MatchRequest): Promise<MatchResponse> {
    return apiFetch('/match', {
        method: 'POST',
        body: JSON.stringify(request),
    });
}

export function startTriage(payload: TriagePayload): Promise<TriageTaskResponse> {
    return apiFetch('/triage', {
        method: 'POST',
        body: JSON.stringify(payload),
    });
}

export function getExplanation(caseId: string, lawyerIds: string[]): Promise<any> {
    return apiFetch('/explain', {
        method: 'POST',
        body: JSON.stringify({ case_id: caseId, lawyer_ids: lawyerIds }),
    });
}

export async function getCasesWithMatches(): Promise<any[]> {
    const { data, error } = await supabase.rpc('get_cases_with_matches_count');
    if (error) {
        console.error('Error fetching cases with matches:', error);
        throw new Error('Falha ao buscar casos com recomendações.');
    }
    return data || [];
}

export function getPersistedMatches(caseId: string): Promise<MatchResponse> {
    return apiFetch(`/cases/${caseId}/matches`, { method: 'GET' });
}

export interface LawyerKPIs {
  kpi: {
    success_rate: number;
    cv_score: number;
    [key: string]: any;
  };
  kpi_subarea: { [key: string]: number };
  kpi_softskill: number;
}

export async function getLawyerPerformance(): Promise<LawyerKPIs> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new AuthError("Usuário não autenticado");

    const { data, error } = await supabase
        .from('lawyers')
        .select('kpi, kpi_subarea, kpi_softskill')
        .eq('id', user.id)
        .single();

    if (error) {
        console.error('Error fetching lawyer performance:', error);
        throw new Error('Falha ao buscar dados de performance.');
    }
    return data as LawyerKPIs;
}

export interface ConversationResponse {
  reply: string;
}

export function continueTriageConversation(history: { role: string; content: string }[]): Promise<ConversationResponse> {
  return apiFetch('/triage/conversation', {
    method: 'POST',
    body: JSON.stringify({ history }),
  });
}

export function getDetailedAnalysis(caseId: string): Promise<any> {
  return apiFetch(`/cases/${caseId}/detailed-analysis`, {
    method: 'GET',
  });
}

export async function getPerformanceData(): Promise<any> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new AuthError("Usuário não autenticado");

  const { data, error } = await supabase
    .from('profiles')
    .select('kpi, kpi_subarea, kpi_softskill')
    .eq('id', user.id)
    .single();

  if (error) {
    console.error('Error fetching performance data:', error);
    throw new Error('Falha ao buscar dados de performance.');
  }
  return data;
}

export interface Review {
  id: string;
  contract_id: string;
  lawyer_id: string;
  client_id: string;
  rating: number;
  comment?: string;
  outcome?: string;
  communication_rating?: number;
  expertise_rating?: number;
  timeliness_rating?: number;
  would_recommend?: boolean;
  lawyer_response?: string;
  lawyer_responded_at?: string;
  response_edited_at?: string;
  response_edit_count?: number;
  created_at: string;
  updated_at: string;
}

export interface LawyerResponseCreate {
  message: string;
}

export interface LawyerResponseUpdate {
  message: string;
}

// === Matching v2 ===

export type Preset = 'balanced' | 'fast' | 'expert' | 'economic';

export interface Match {
  lawyer_id: string;
  nome: string;
  avatar_url?: string;
  is_available: boolean;
  primary_area: string;
  rating?: number;
  distance_km?: number;
  lat?: number;
  lng?: number;
  // Pontuações/opcionais
  fair?: number;
  equity?: number;
  features?: Record<string, any>;
}

export interface MatchResponseAPI {
  case_id: string;
  matches: Match[];
}

/**
 * Obtém recomendações de advogados para um determinado caso já criado.
 * Encaminha para o endpoint `/match` do backend, que aceita diversos ajustes finos.
 */
export function getMatchesForCase(
  caseId: string,
  params?: {
    preset?: Preset;
    k?: number;
    radius_km?: number;
  },
): Promise<MatchResponseAPI> {
  const searchParams = new URLSearchParams();
  if (params?.preset) searchParams.append('preset', params.preset);
  if (params?.k) searchParams.append('k', params.k.toString());
  if (params?.radius_km) searchParams.append('radius_km', params.radius_km.toString());

  const queryString = searchParams.toString();
  const endpoint = `/cases/${caseId}/matches${queryString ? `?${queryString}` : ''}`;

  return apiFetch(endpoint, { method: 'GET' });
}

/**
 * Busca os casos do usuário logado.
 */
export function getMyCases(): Promise<{ cases: any[] }> {
    return apiFetch('/cases/my-cases', { method: 'GET' });
}

// Reexporta para facilitar importação em outras partes do app
export type { Match as MatchResult };

const api = {
  get: (endpoint: string, options: RequestInit = {}) => apiFetch(endpoint, { ...options, method: 'GET' }),
  post: (endpoint: string, body: any, options: RequestInit = {}) => apiFetch(endpoint, { ...options, method: 'POST', body: JSON.stringify(body) }),
  patch: (endpoint: string, body: any, options: RequestInit = {}) => apiFetch(endpoint, { ...options, method: 'PATCH', body: JSON.stringify(body) }),
  put: (endpoint: string, body: any, options: RequestInit = {}) => apiFetch(endpoint, { ...options, method: 'PUT', body: JSON.stringify(body) }),
  delete: (endpoint: string, options: RequestInit = {}) => apiFetch(endpoint, { ...options, method: 'DELETE' }),
};

export default api; 