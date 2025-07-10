import React, { useEffect, useState, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert, Dimensions } from 'react-native';
import { 
  Video as VideoIcon, 
  Mic, 
  MicOff, 
  VideoOff, 
  Phone, 
  MessageCircle, 
  Settings, 
  Users, 
  Clock, 
  Star,
  PhoneOff
} from 'lucide-react-native';
import DailyIframe, { 
  DailyCall, 
  DailyEvent, 
  DailyEventObject,
  DailyParticipant 
} from '@daily-co/react-native-daily-js';
import { useAuth } from '@/lib/contexts/AuthContext';
import { updateVideoSessionStatus } from '@/lib/services/video';

interface VideoCallProps {
  roomUrl: string;
  token: string;
  sessionId: string;
  participantName: string;
  onCallEnd: () => void;
  onError: (error: string) => void;
}

const { width, height } = Dimensions.get('window');

export default function VideoCall({
  roomUrl,
  token,
  sessionId,
  participantName,
  onCallEnd,
  onError
}: VideoCallProps) {
  const { user } = useAuth();
  const [callObject, setCallObject] = useState<DailyCall | null>(null);
  const [callState, setCallState] = useState<string>('new');
  const [participants, setParticipants] = useState<{ [id: string]: DailyParticipant }>({});
  const [isMuted, setIsMuted] = useState(false);
  const [isVideoOff, setIsVideoOff] = useState(false);
  const [callDuration, setCallDuration] = useState(0);
  const [isRecording, setIsRecording] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const callStartTime = useRef<number | null>(null);
  const durationInterval = useRef<NodeJS.Timeout | null>(null);

  // Inicializar chamada
  useEffect(() => {
    const initCall = async () => {
      try {
        // Criar objeto de chamada Daily
        const call = DailyIframe.createCallObject({
          url: roomUrl,
          token: token,
        });

        setCallObject(call);

        // Event listeners
        call
          .on('joined-meeting', handleJoinedMeeting)
          .on('left-meeting', handleLeftMeeting)
          .on('participant-joined', handleParticipantJoined)
          .on('participant-left', handleParticipantLeft)
          .on('participant-updated', handleParticipantUpdated)
          .on('error', handleError)
          .on('recording-started', () => setIsRecording(true))
          .on('recording-stopped', () => setIsRecording(false));

        // Entrar na reunião
        await call.join();
        
      } catch (err) {
        console.error('Erro ao inicializar chamada:', err);
        setError('Erro ao conectar à videochamada');
        onError('Erro ao conectar à videochamada');
      }
    };

    initCall();

    return () => {
      if (callObject) {
        callObject.destroy();
      }
      if (durationInterval.current) {
        clearInterval(durationInterval.current);
      }
    };
  }, [roomUrl, token]);

  // Event handlers
  const handleJoinedMeeting = async (event: DailyEventObject) => {
    console.log('Entrou na reunião:', event);
    setCallState('joined');
    
    // Atualizar status da sessão
    try {
      await updateVideoSessionStatus(sessionId, 'active');
    } catch (err) {
      console.error('Erro ao atualizar status da sessão:', err);
    }

    // Iniciar contador de duração
    callStartTime.current = Date.now();
    durationInterval.current = setInterval(() => {
      if (callStartTime.current) {
        setCallDuration(Math.floor((Date.now() - callStartTime.current) / 1000));
      }
    }, 1000);

    // Atualizar participantes
    if (callObject) {
      setParticipants(callObject.participants());
    }
  };

  const handleLeftMeeting = async (event: DailyEventObject) => {
    console.log('Saiu da reunião:', event);
    setCallState('left');
    
    // Parar contador
    if (durationInterval.current) {
      clearInterval(durationInterval.current);
    }

    // Atualizar status da sessão
    if (callStartTime.current) {
      const duration = Math.floor((Date.now() - callStartTime.current) / 60000); // em minutos
      try {
        await updateVideoSessionStatus(sessionId, 'ended', { duration_minutes: duration });
      } catch (err) {
        console.error('Erro ao atualizar status final da sessão:', err);
      }
    }

    onCallEnd();
  };

  const handleParticipantJoined = (event: DailyEventObject) => {
    console.log('Participante entrou:', event.participant);
    if (callObject) {
      setParticipants(callObject.participants());
    }
  };

  const handleParticipantLeft = (event: DailyEventObject) => {
    console.log('Participante saiu:', event.participant);
    if (callObject) {
      setParticipants(callObject.participants());
    }
  };

  const handleParticipantUpdated = (event: DailyEventObject) => {
    if (callObject) {
      setParticipants(callObject.participants());
    }
  };

  const handleError = (event: DailyEventObject) => {
    console.error('Erro na chamada Daily:', event.error);
    setError(event.error?.msg || 'Erro na videochamada');
    onError(event.error?.msg || 'Erro na videochamada');
  };

  // Controles da chamada
  const toggleMute = async () => {
    if (!callObject) return;
    
    try {
      const newMutedState = !isMuted;
      await callObject.setLocalAudio(!newMutedState);
      setIsMuted(newMutedState);
    } catch (err) {
      console.error('Erro ao alternar mute:', err);
    }
  };

  const toggleVideo = async () => {
    if (!callObject) return;
    
    try {
      const newVideoState = !isVideoOff;
      await callObject.setLocalVideo(!newVideoState);
      setIsVideoOff(newVideoState);
    } catch (err) {
      console.error('Erro ao alternar vídeo:', err);
    }
  };

  const toggleRecording = async () => {
    if (!callObject) return;
    
    try {
      if (isRecording) {
        await callObject.stopRecording();
      } else {
        await callObject.startRecording();
      }
    } catch (err) {
      console.error('Erro ao alternar gravação:', err);
      Alert.alert('Erro', 'Não foi possível alterar o estado da gravação');
    }
  };

  const endCall = () => {
    Alert.alert(
      'Encerrar Chamada',
      'Tem certeza que deseja encerrar a videochamada?',
      [
        { text: 'Cancelar', style: 'cancel' },
        { 
          text: 'Encerrar', 
          style: 'destructive',
          onPress: async () => {
            if (callObject) {
              await callObject.leave();
            }
          }
        }
      ]
    );
  };

  const formatDuration = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  // Obter informações do outro participante
  const otherParticipants = Object.values(participants).filter(p => !p.local);
  const otherParticipant = otherParticipants[0];

  if (error) {
    return (
      <View style={styles.errorContainer}>
        <Text style={styles.errorText}>❌ {error}</Text>
        <TouchableOpacity style={styles.retryButton} onPress={onCallEnd}>
          <Text style={styles.retryButtonText}>Voltar</Text>
        </TouchableOpacity>
      </View>
    );
  }

  if (callState === 'new' || callState === 'loading') {
    return (
      <View style={styles.loadingContainer}>
        <VideoIcon size={48} color="#FFFFFF" />
        <Text style={styles.loadingText}>Conectando...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* Área principal de vídeo */}
      <View style={styles.videoContainer}>
        {/* Vídeo do Daily.co será renderizado aqui automaticamente */}
        
        {/* Indicador de gravação */}
        {isRecording && (
          <View style={styles.recordingIndicator}>
            <View style={styles.recordingDot} />
            <Text style={styles.recordingText}>GRAVANDO</Text>
          </View>
        )}

        {/* Informações da chamada */}
        <View style={styles.callInfo}>
          <View style={styles.participantInfo}>
            <Text style={styles.participantName}>
              {otherParticipant?.user_name || 'Participante'}
            </Text>
            <Text style={styles.participantStatus}>
              {otherParticipant ? 'Online' : 'Aguardando...'}
            </Text>
          </View>
          
          <View style={styles.callDuration}>
            <Clock size={16} color="#FFFFFF" />
            <Text style={styles.durationText}>{formatDuration(callDuration)}</Text>
          </View>
        </View>
      </View>

      {/* Controles */}
      <View style={styles.controls}>
        <View style={styles.controlRow}>
          {/* Mute Button */}
          <TouchableOpacity 
            style={[styles.controlButton, isMuted && styles.controlButtonActive]} 
            onPress={toggleMute}
          >
            {isMuted ? <MicOff size={24} color="#FFFFFF" /> : <Mic size={24} color="#FFFFFF" />}
          </TouchableOpacity>

          {/* Video Button */}
          <TouchableOpacity 
            style={[styles.controlButton, isVideoOff && styles.controlButtonActive]} 
            onPress={toggleVideo}
          >
            {isVideoOff ? <VideoOff size={24} color="#FFFFFF" /> : <VideoIcon size={24} color="#FFFFFF" />}
          </TouchableOpacity>

          {/* End Call Button */}
          <TouchableOpacity 
            style={[styles.controlButton, styles.endCallButton]} 
            onPress={endCall}
          >
            <PhoneOff size={24} color="#FFFFFF" />
          </TouchableOpacity>

          {/* Settings */}
          <TouchableOpacity style={styles.controlButton}>
            <Settings size={24} color="#FFFFFF" />
          </TouchableOpacity>
        </View>

        {/* Recording Control */}
        <TouchableOpacity 
          style={[styles.recordingButton, isRecording && styles.recordingButtonActive]} 
          onPress={toggleRecording}
        >
          <Text style={[styles.recordingButtonText, isRecording && styles.recordingButtonTextActive]}>
            {isRecording ? 'Parar Gravação' : 'Iniciar Gravação'}
          </Text>
        </TouchableOpacity>
      </View>

      {/* Participantes */}
      <View style={styles.participantsInfo}>
        <Users size={16} color="#FFFFFF" />
        <Text style={styles.participantsText}>
          {Object.keys(participants).length} participante(s)
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000',
  },
  videoContainer: {
    flex: 1,
    position: 'relative',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#000000',
  },
  loadingText: {
    color: '#FFFFFF',
    fontSize: 18,
    marginTop: 16,
    fontFamily: 'Inter-Medium',
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
    marginBottom: 20,
    fontFamily: 'Inter-Medium',
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
  recordingIndicator: {
    position: 'absolute',
    top: 20,
    right: 20,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(239, 68, 68, 0.9)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    zIndex: 10,
  },
  recordingDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#FFFFFF',
    marginRight: 6,
  },
  recordingText: {
    color: '#FFFFFF',
    fontFamily: 'Inter-SemiBold',
    fontSize: 12,
  },
  callInfo: {
    position: 'absolute',
    top: 20,
    left: 20,
    right: 100,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    zIndex: 10,
  },
  participantInfo: {
    flex: 1,
  },
  participantName: {
    color: '#FFFFFF',
    fontFamily: 'Inter-Bold',
    fontSize: 18,
    marginBottom: 2,
  },
  participantStatus: {
    color: '#E5E7EB',
    fontFamily: 'Inter-Regular',
    fontSize: 14,
  },
  callDuration: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
  },
  durationText: {
    color: '#FFFFFF',
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
  },
  controls: {
    padding: 20,
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
  },
  controlRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 16,
    marginBottom: 20,
  },
  controlButton: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  controlButtonActive: {
    backgroundColor: '#EF4444',
  },
  endCallButton: {
    backgroundColor: '#EF4444',
  },
  recordingButton: {
    alignSelf: 'center',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  recordingButtonActive: {
    backgroundColor: '#EF4444',
    borderColor: '#EF4444',
  },
  recordingButtonText: {
    color: '#FFFFFF',
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
  },
  recordingButtonTextActive: {
    color: '#FFFFFF',
  },
  participantsInfo: {
    position: 'absolute',
    bottom: 120,
    left: 20,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
  },
  participantsText: {
    color: '#FFFFFF',
    fontFamily: 'Inter-Medium',
    fontSize: 12,
  },
});
