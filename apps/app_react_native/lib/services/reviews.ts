import { API_URL, getAuthHeaders } from './api';
import type { Review, LawyerResponseCreate, LawyerResponseUpdate } from './api';

export interface ReviewCreatePayload {
    rating: number;
    comment?: string;
    outcome?: 'won' | 'lost' | 'settled' | 'ongoing';
    communication_rating?: number;
    expertise_rating?: number;
    timeliness_rating?: number;
    would_recommend?: boolean;
}

export class ReviewsService {
  /**
   * Criar uma nova avaliação para um contrato
   */
  static async createReview(contractId: string, reviewData: ReviewCreatePayload): Promise<Review> {
    const headers = await getAuthHeaders();
    const result = await fetch(`${API_URL}/reviews/contracts/${contractId}`, {
      method: 'POST',
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(reviewData),
    });

    if (!result.ok) {
      const errorData = await result.json().catch(() => ({ detail: result.statusText }));
      throw new Error(`Erro ao criar avaliação: ${errorData.detail || result.statusText}`);
    }
    
    return result.json();
  }

  /**
   * Responder a uma avaliação (advogado)
   */
  static async respondToReview(reviewId: string, response: LawyerResponseCreate): Promise<Review> {
    const headers = await getAuthHeaders();
    const result = await fetch(`${API_URL}/reviews/${reviewId}/respond`, {
      method: 'POST',
      headers,
      body: JSON.stringify(response),
    });
    
    if (!result.ok) {
      throw new Error(`Erro ao responder avaliação: ${result.statusText}`);
    }
    
    return result.json();
  }

  /**
   * Editar resposta a uma avaliação (advogado)
   */
  static async updateReviewResponse(reviewId: string, response: LawyerResponseUpdate): Promise<Review> {
    const headers = await getAuthHeaders();
    const result = await fetch(`${API_URL}/reviews/${reviewId}/response`, {
      method: 'PUT',
      headers,
      body: JSON.stringify(response),
    });
    
    if (!result.ok) {
      throw new Error(`Erro ao editar resposta: ${result.statusText}`);
    }
    
    return result.json();
  }

  /**
   * Remover resposta a uma avaliação (advogado)
   */
  static async deleteReviewResponse(reviewId: string): Promise<void> {
    const headers = await getAuthHeaders();
    const result = await fetch(`${API_URL}/reviews/${reviewId}/response`, {
      method: 'DELETE',
      headers,
    });
    
    if (!result.ok) {
      throw new Error(`Erro ao remover resposta: ${result.statusText}`);
    }
  }

  /**
   * Obter avaliações recebidas pelo advogado atual
   */
  static async getMyLawyerReviews(params?: {
    limit?: number;
    offset?: number;
    needsResponse?: boolean;
  }): Promise<Review[]> {
    const headers = await getAuthHeaders();
    const searchParams = new URLSearchParams();
    
    if (params?.limit) searchParams.append('limit', params.limit.toString());
    if (params?.offset) searchParams.append('offset', params.offset.toString());
    if (params?.needsResponse) searchParams.append('needs_response', 'true');

    const result = await fetch(`${API_URL}/reviews/lawyers/my-reviews?${searchParams}`, {
      method: 'GET',
      headers,
    });
    
    if (!result.ok) {
      throw new Error(`Erro ao buscar avaliações: ${result.statusText}`);
    }
    
    return result.json();
  }

  /**
   * Obter avaliações de um advogado específico
   */
  static async getLawyerReviews(lawyerId: string, params?: {
    limit?: number;
    offset?: number;
  }): Promise<Review[]> {
    const headers = await getAuthHeaders();
    const searchParams = new URLSearchParams();
    
    if (params?.limit) searchParams.append('limit', params.limit.toString());
    if (params?.offset) searchParams.append('offset', params.offset.toString());

    const result = await fetch(`${API_URL}/reviews/lawyers/${lawyerId}/reviews?${searchParams}`, {
      method: 'GET',
      headers,
    });
    
    if (!result.ok) {
      throw new Error(`Erro ao buscar avaliações do advogado: ${result.statusText}`);
    }
    
    return result.json();
  }

  /**
   * Obter avaliação de um contrato específico
   */
  static async getContractReview(contractId: string): Promise<Review> {
    const headers = await getAuthHeaders();
    const result = await fetch(`${API_URL}/reviews/contracts/${contractId}/review`, {
      method: 'GET',
      headers,
    });
    
    if (!result.ok) {
      throw new Error(`Erro ao buscar avaliação do contrato: ${result.statusText}`);
    }
    
    return result.json();
  }

  /**
   * Verificar se uma resposta pode ser editada
   */
  static canEditResponse(review: Review): boolean {
    if (!review.lawyer_response || !review.lawyer_responded_at) {
      return false;
    }

    const respondedAt = new Date(review.lawyer_responded_at);
    const now = new Date();
    const hoursSinceResponse = (now.getTime() - respondedAt.getTime()) / (1000 * 60 * 60);

    return hoursSinceResponse <= 24 && (review.response_edit_count || 0) < 3;
  }

  /**
   * Verificar se uma resposta pode ser removida
   */
  static canDeleteResponse(review: Review): boolean {
    if (!review.lawyer_response || !review.lawyer_responded_at) {
      return false;
    }

    const respondedAt = new Date(review.lawyer_responded_at);
    const now = new Date();
    const hoursSinceResponse = (now.getTime() - respondedAt.getTime()) / (1000 * 60 * 60);

    return hoursSinceResponse <= 1;
  }

  /**
   * Verificar se um advogado pode responder a uma avaliação
   */
  static canRespondToReview(review: Review): boolean {
    return !review.lawyer_response;
  }

  /**
   * Formatar data de resposta para exibição
   */
  static formatResponseDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }
}

/**
 * Busca a avaliação mais recente de um advogado
 * @param lawyerId O ID do advogado
 */
export const getLatestReview = async (lawyerId: string): Promise<Review | null> => {
  try {
    const reviews = await ReviewsService.getLawyerReviews(lawyerId, { limit: 1 });
    if (reviews && reviews.length > 0) {
      return reviews[0];
    }
    return null;
  } catch (error) {
    console.warn(`Could not fetch latest review for lawyer ${lawyerId}:`, error);
    return null;
  }
};

export default ReviewsService; 