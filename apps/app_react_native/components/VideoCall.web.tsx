import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { AlertCircle } from 'lucide-react-native';

interface VideoCallProps {
  roomUrl: string;
  token: string;
  sessionId: string;
  participantName: string;
  onCallEnd: () => void;
  onError: (error: string) => void;
}

export default function VideoCall({
  onCallEnd,
  onError
}: VideoCallProps) {
  React.useEffect(() => {
    // Informar sobre a limitação da plataforma
    onError('Videochamadas não estão disponíveis na versão web. Por favor, use o aplicativo mobile.');
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.content}>
        <AlertCircle size={64} color="#F59E0B" />
        <Text style={styles.title}>Videochamada não disponível na web</Text>
        <Text style={styles.description}>
          As videochamadas estão disponíveis apenas na versão mobile do aplicativo. 
          {'\n\n'}
          Para participar da videochamada, por favor:
        </Text>
        <View style={styles.instructionsList}>
          <Text style={styles.instructionItem}>• Baixe o aplicativo mobile</Text>
          <Text style={styles.instructionItem}>• Ou acesse pelo navegador do seu celular</Text>
        </View>
        
        <TouchableOpacity style={styles.backButton} onPress={onCallEnd}>
          <Text style={styles.backButtonText}>Voltar</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  content: {
    maxWidth: 400,
    alignItems: 'center',
  },
  title: {
    color: '#FFFFFF',
    fontSize: 24,
    fontWeight: 'bold',
    marginTop: 20,
    marginBottom: 16,
    textAlign: 'center',
  },
  description: {
    color: '#E5E7EB',
    fontSize: 16,
    lineHeight: 24,
    textAlign: 'center',
    marginBottom: 20,
  },
  instructionsList: {
    alignItems: 'flex-start',
    marginBottom: 32,
  },
  instructionItem: {
    color: '#E5E7EB',
    fontSize: 16,
    marginBottom: 8,
  },
  backButton: {
    backgroundColor: '#1E40AF',
    paddingHorizontal: 32,
    paddingVertical: 12,
    borderRadius: 8,
    minWidth: 120,
  },
  backButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
}); 