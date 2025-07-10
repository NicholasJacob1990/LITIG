import { View, Text, StyleSheet, TouchableOpacity, Alert, ActivityIndicator } from 'react-native';
import { useState, useEffect } from 'react';
import { MessageCircle } from 'lucide-react-native';
import { StatusBar } from 'expo-status-bar';
import { router, useLocalSearchParams } from 'expo-router';
import { useAuth } from '@/lib/contexts/AuthContext';

function VideoConsultationScreen() {
  const { lawyerId, caseId, sessionId } = useLocalSearchParams<{ 
    lawyerId: string; 
    caseId: string;
    sessionId?: string;
  }>();
  const { user } = useAuth();
  
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Mock lawyer data - em produção, buscar do banco de dados
  const lawyer = {
    id: lawyerId,
    name: 'Dr. Carlos Mendes',
    specialty: 'Direito Trabalhista',
    rating: 4.8,
    avatar: 'https://images.pexels.com/photos/2182970/pexels-photo-2182970.jpeg?auto=compress&cs=tinysrgb&w=400',
  };

  useEffect(() => {
    initializeVideoCall();
  }, []);

  const initializeVideoCall = async () => {
    if (!user || !lawyerId) {
      setError('Dados insuficientes para iniciar a videochamada');
      setIsLoading(false);
      return;
    }

    try {
      setIsLoading(true);
      
      // Simulação de carregamento
      await new Promise(resolve => setTimeout(resolve, 1000));
      setError('Videochamada requer desenvolvimento build. Use chat por enquanto.');
       
    } catch (err) {
      console.error('Erro ao inicializar videochamada:', err);
      setError(err instanceof Error ? err.message : 'Erro ao inicializar videochamada');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCallEnd = () => {
    // Navegar de volta para a tela anterior
    if (router.canGoBack()) {
      router.back();
    } else {
      router.replace('/(tabs)/_internal/chat');
    }
  };

  const handleError = (errorMessage: string) => {
    setError(errorMessage);
    Alert.alert(
      'Erro na Videochamada',
      errorMessage,
      [
        {
          text: 'Tentar Novamente',
          onPress: () => {
            setError(null);
            initializeVideoCall();
          }
        },
        {
          text: 'Voltar',
          style: 'cancel',
          onPress: handleCallEnd
        }
      ]
    );
  };

  const handleSwitchToChat = () => {
    Alert.alert(
      'Mudar para Chat',
      'Deseja continuar a consulta por chat?',
      [
        { text: 'Cancelar', style: 'cancel' },
        { 
          text: 'Continuar', 
          onPress: () => {
            // Encerrar videochamada e ir para chat
            router.replace('/(tabs)/_internal/chat');
          }
        }
      ]
    );
  };

  // Tela de loading
  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <StatusBar style="light" />
        <ActivityIndicator size="large" color="#FFFFFF" />
        <Text style={styles.loadingText}>Preparando videochamada...</Text>
        <Text style={styles.loadingSubtext}>
          Conectando com {lawyer.name}
        </Text>
      </View>
    );
  }

  // Tela de erro
  return (
    <View style={styles.errorContainer}>
      <StatusBar style="light" />
      <Text style={styles.errorText}>❌ {error || 'Videochamada não disponível no Expo Go'}</Text>
      <View style={styles.errorActions}>
        <TouchableOpacity 
          style={styles.backButton} 
          onPress={handleCallEnd}
        >
          <Text style={styles.backButtonText}>Voltar</Text>
        </TouchableOpacity>
      </View>
      
      {/* Opção de mudar para chat */}
      <TouchableOpacity 
        style={styles.chatFallbackButton}
        onPress={handleSwitchToChat}
      >
        <MessageCircle size={20} color="#FFFFFF" />
        <Text style={styles.chatFallbackText}>Continuar por Chat</Text>
      </TouchableOpacity>
    </View>
  );
}

export default VideoConsultationScreen;

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#000000',
    padding: 20,
  },
  loadingText: {
    color: '#FFFFFF',
    fontSize: 18,
    marginTop: 20,
    fontFamily: 'Inter-SemiBold',
    textAlign: 'center',
  },
  loadingSubtext: {
    color: '#E5E7EB',
    fontSize: 14,
    marginTop: 8,
    fontFamily: 'Inter-Regular',
    textAlign: 'center',
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#000000',
    padding: 20,
  },
  errorText: {
    color: '#EF4444',
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 30,
    fontFamily: 'Inter-Medium',
    lineHeight: 24,
  },
  errorActions: {
    flexDirection: 'row',
    gap: 16,
    marginBottom: 30,
  },
  retryButton: {
    backgroundColor: '#1E40AF',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
  },
  retryButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontFamily: 'Inter-SemiBold',
  },
  backButton: {
    backgroundColor: '#374151',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
  },
  backButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontFamily: 'Inter-SemiBold',
  },
  chatFallbackButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: 'rgba(34, 197, 94, 0.2)',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#22C55E',
  },
  chatFallbackText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontFamily: 'Inter-Medium',
  },
}); 