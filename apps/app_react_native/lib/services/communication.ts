import { Alert, Linking, Platform } from 'react-native';
import { router } from 'expo-router';

export interface CommunicationOptions {
  lawyerId: string;
  caseId?: string;
  clientId?: string;
  lawyerName?: string;
  lawyerPhone?: string;
}

class CommunicationService {
  /**
   * Iniciar videochamada com advogado
   */
  async startVideoCall(options: CommunicationOptions) {
    try {
      if (!options.lawyerId) {
        Alert.alert('Erro', 'ID do advogado não encontrado');
        return false;
      }

      // Verificar se há uma sessão de vídeo ativa
      const hasActiveSession = await this.checkActiveVideoSession(options.lawyerId);
      
      if (hasActiveSession) {
        Alert.alert(
          'Videochamada em Andamento',
          'Há uma videochamada ativa com este advogado. Deseja entrar na sala?',
          [
            { text: 'Cancelar', style: 'cancel' },
            { 
              text: 'Entrar', 
              onPress: () => this.joinExistingVideoCall(options)
            }
          ]
        );
        return true;
      }

      // Criar nova videochamada
      return await this.createVideoCall(options);
    } catch (error) {
      console.error('Erro ao iniciar videochamada:', error);
      Alert.alert('Erro', 'Não foi possível iniciar a videochamada');
      return false;
    }
  }

  /**
   * Fazer ligação telefônica
   */
  async makePhoneCall(options: CommunicationOptions) {
    try {
      if (!options.lawyerPhone) {
        Alert.alert(
          'Telefone Indisponível',
          'O telefone do advogado não está disponível. Tente enviar uma mensagem ou agendar uma videochamada.',
          [{ text: 'OK' }]
        );
        return false;
      }

      const phoneNumber = this.formatPhoneNumber(options.lawyerPhone);
      
      Alert.alert(
        'Fazer Ligação',
        `Deseja ligar para ${options.lawyerName || 'o advogado'}?\n${phoneNumber}`,
        [
          { text: 'Cancelar', style: 'cancel' },
          { 
            text: 'Ligar', 
            onPress: () => this.dialPhoneNumber(phoneNumber)
          }
        ]
      );

      return true;
    } catch (error) {
      console.error('Erro ao fazer ligação:', error);
      Alert.alert('Erro', 'Não foi possível fazer a ligação');
      return false;
    }
  }

  /**
   * Abrir chat com advogado
   */
  async openChat(options: CommunicationOptions) {
    try {
      if (!options.caseId) {
        Alert.alert('Erro', 'ID do caso não encontrado');
        return false;
      }

      router.push({
        pathname: '/(tabs)/cases/CaseChat',
        params: { 
          caseId: options.caseId,
          lawyerId: options.lawyerId
        }
      });

      return true;
    } catch (error) {
      console.error('Erro ao abrir chat:', error);
      Alert.alert('Erro', 'Não foi possível abrir o chat');
      return false;
    }
  }

  /**
   * Verificar se há sessão de vídeo ativa
   */
  private async checkActiveVideoSession(lawyerId: string): Promise<boolean> {
    try {
      // Implementar verificação real com a API
      // Por enquanto, simular verificação
      return false;
    } catch (error) {
      console.error('Erro ao verificar sessão ativa:', error);
      return false;
    }
  }

  /**
   * Criar nova videochamada
   */
  private async createVideoCall(options: CommunicationOptions): Promise<boolean> {
    try {
      // Navegar para tela de videochamada
      router.push({
        pathname: '/(tabs)/video-consultation',
        params: {
          lawyerId: options.lawyerId,
          caseId: options.caseId || '',
          mode: 'create'
        }
      });

      return true;
    } catch (error) {
      console.error('Erro ao criar videochamada:', error);
      return false;
    }
  }

  /**
   * Entrar em videochamada existente
   */
  private async joinExistingVideoCall(options: CommunicationOptions): Promise<boolean> {
    try {
      router.push({
        pathname: '/(tabs)/video-consultation',
        params: {
          lawyerId: options.lawyerId,
          caseId: options.caseId || '',
          mode: 'join'
        }
      });

      return true;
    } catch (error) {
      console.error('Erro ao entrar na videochamada:', error);
      return false;
    }
  }

  /**
   * Formatar número de telefone
   */
  private formatPhoneNumber(phone: string): string {
    // Remove caracteres não numéricos
    const cleaned = phone.replace(/\D/g, '');
    
    // Formata para padrão brasileiro
    if (cleaned.length === 11) {
      return `(${cleaned.slice(0, 2)}) ${cleaned.slice(2, 7)}-${cleaned.slice(7)}`;
    } else if (cleaned.length === 10) {
      return `(${cleaned.slice(0, 2)}) ${cleaned.slice(2, 6)}-${cleaned.slice(6)}`;
    }
    
    return phone;
  }

  /**
   * Discar número de telefone
   */
  private async dialPhoneNumber(phoneNumber: string): Promise<void> {
    try {
      const url = `tel:${phoneNumber.replace(/\D/g, '')}`;
      const canOpen = await Linking.canOpenURL(url);
      
      if (canOpen) {
        await Linking.openURL(url);
      } else {
        Alert.alert(
          'Erro',
          'Não foi possível abrir o aplicativo de telefone'
        );
      }
    } catch (error) {
      console.error('Erro ao discar:', error);
      Alert.alert('Erro', 'Não foi possível fazer a ligação');
    }
  }

  /**
   * Agendar consulta
   */
  async scheduleConsultation(options: CommunicationOptions) {
    try {
      if (!options.caseId) {
        Alert.alert('Erro', 'ID do caso não encontrado');
        return false;
      }

      router.push({
        pathname: '/(tabs)/cases/ScheduleConsult',
        params: { 
          caseId: options.caseId,
          lawyerId: options.lawyerId
        }
      });

      return true;
    } catch (error) {
      console.error('Erro ao agendar consulta:', error);
      Alert.alert('Erro', 'Não foi possível agendar a consulta');
      return false;
    }
  }

  /**
   * Verificar disponibilidade do advogado
   */
  async checkLawyerAvailability(lawyerId: string): Promise<{
    isAvailable: boolean;
    status: 'available' | 'busy' | 'offline';
    nextAvailable?: string;
  }> {
    try {
      // Implementar verificação real com a API
      // Por enquanto, simular disponibilidade
      return {
        isAvailable: Math.random() > 0.3,
        status: Math.random() > 0.5 ? 'available' : 'busy',
        nextAvailable: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString()
      };
    } catch (error) {
      console.error('Erro ao verificar disponibilidade:', error);
      return {
        isAvailable: false,
        status: 'offline'
      };
    }
  }

  /**
   * Enviar mensagem rápida
   */
  async sendQuickMessage(options: CommunicationOptions, message: string) {
    try {
      // Implementar envio de mensagem rápida
      Alert.alert(
        'Mensagem Enviada',
        `Sua mensagem foi enviada para ${options.lawyerName || 'o advogado'}. Você receberá uma resposta em breve.`
      );
      
      return true;
    } catch (error) {
      console.error('Erro ao enviar mensagem:', error);
      Alert.alert('Erro', 'Não foi possível enviar a mensagem');
      return false;
    }
  }
}

export const communicationService = new CommunicationService(); 