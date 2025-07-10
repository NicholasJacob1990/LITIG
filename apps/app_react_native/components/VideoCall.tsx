import React, { useCallback, useEffect, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ActivityIndicator } from 'react-native';
import {
  DailyProvider,
  useDaily,
  useParticipant,
  useVideoTrack,
  useLocalParticipant,
  useScreenShare,
  DailyVideo,
} from '@daily-co/daily-react';
import Daily, { DailyCall, DailyParticipant } from '@daily-co/react-native-daily-js';
import { Video, Mic, MicOff, VideoOff, Phone, ScreenShare, ScreenShareOff } from 'lucide-react-native';

interface VideoCallProps {
  roomUrl: string;
  token: string;
  onCallEnd: () => void;
  onError: (error: string) => void;
}

const ParticipantTile = ({ sessionId }: { sessionId: string }) => {
  const participant = useParticipant(sessionId);
  const videoTrack = useVideoTrack(sessionId);

  if (!participant) return null;

  return (
    <View style={styles.participantTile}>
      {videoTrack.state === 'playable' ? (
        <DailyVideo
          sessionId={sessionId}
          style={styles.video}
          mirror={participant.local}
          type="video"
        />
      ) : (
        <View style={styles.noVideoView}>
          <Text style={styles.participantName}>{participant.user_name || 'Participante'}</Text>
        </View>
      )}
      <View style={styles.micIndicator}>
        {participant.audio ? <Mic size={16} color="white" /> : <MicOff size={16} color="red" />}
      </View>
    </View>
  );
};

const VideoCallUI = ({ onCallEnd, onError }: { onCallEnd: () => void; onError: (error: string) => void; }) => {
  const daily = useDaily();
  const localParticipant = useLocalParticipant();
  const { isSharingScreen } = useScreenShare();

  const [isCameraOn, setIsCameraOn] = useState(true);
  const [isMicOn, setIsMicOn] = useState(true);

  useEffect(() => {
    if (!daily) return;
    const handleError = (e: any) => onError(e.errorMsg);
    daily.on('error', handleError);
    return () => {
      daily.off('error', handleError);
    };
  }, [daily, onError]);

  const toggleCamera = useCallback(() => {
    daily?.setLocalVideo(!isCameraOn);
    setIsCameraOn(p => !p);
  }, [daily, isCameraOn]);

  const toggleMic = useCallback(() => {
    daily?.setLocalAudio(!isMicOn);
    setIsMicOn(p => !p);
  }, [daily, isMicOn]);

  const toggleScreenShare = useCallback(() => {
    if (isSharingScreen) {
      daily?.stopScreenShare();
    } else {
      daily?.startScreenShare();
    }
  }, [daily, isSharingScreen]);
  
  const handleLeave = useCallback(() => {
    daily?.leave();
    onCallEnd();
  }, [daily, onCallEnd]);
  
  const remoteParticipants = daily?.participants() ?? {};

  return (
    <View style={styles.container}>
      <View style={styles.participantsContainer}>
        {localParticipant && <ParticipantTile sessionId={localParticipant.session_id} />}
        {Object.values(remoteParticipants).map((p: any) => (
          <ParticipantTile key={p.session_id} sessionId={p.session_id} />
        ))}
      </View>

      <View style={styles.controlsContainer}>
        <TouchableOpacity style={styles.controlButton} onPress={toggleMic}>
          {isMicOn ? <Mic size={24} color="white" /> : <MicOff size={24} color="white" />}
        </TouchableOpacity>
        <TouchableOpacity style={styles.controlButton} onPress={toggleCamera}>
          {isCameraOn ? <Video size={24} color="white" /> : <VideoOff size={24} color="white" />}
        </TouchableOpacity>
        <TouchableOpacity style={styles.controlButton} onPress={toggleScreenShare}>
          {isSharingScreen ? <ScreenShareOff size={24} color="white" /> : <ScreenShare size={24} color="white" />}
        </TouchableOpacity>
        <TouchableOpacity style={[styles.controlButton, styles.endCallButton]} onPress={handleLeave}>
          <Phone size={24} color="white" />
        </TouchableOpacity>
      </View>
    </View>
  );
};


export default function VideoCall({ roomUrl, token, onCallEnd, onError }: VideoCallProps) {
  const [daily, setDaily] = useState<DailyCall | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const callObject = Daily.createCallObject();
    setDaily(callObject);

    const joinCall = async () => {
      try {
        await callObject.join({ url: roomUrl, token });
        setIsLoading(false);
      } catch (e: any) {
        console.error("Failed to join Daily call", e);
        onError(e?.errorMsg || "Não foi possível conectar à chamada de vídeo.");
        setIsLoading(false);
      }
    };
    
    joinCall();
    
    return () => {
      callObject.leave();
    };
  }, [roomUrl, token, onError]);

  if (isLoading || !daily) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#FFFFFF" />
        <Text style={styles.loadingText}>Conectando...</Text>
      </View>
    );
  }

  return (
    <DailyProvider callObject={daily}>
      <VideoCallUI onCallEnd={onCallEnd} onError={onError} />
    </DailyProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000',
    justifyContent: 'space-between',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#000',
  },
  loadingText: {
    color: 'white',
    marginTop: 10,
  },
  participantsContainer: {
    flex: 1,
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  participantTile: {
    width: '50%',
    height: '50%',
    position: 'relative',
  },
  video: {
    width: '100%',
    height: '100%',
  },
  noVideoView: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#2C2C2E',
  },
  participantName: {
    color: 'white',
    fontSize: 18,
  },
  micIndicator: {
    position: 'absolute',
    bottom: 8,
    left: 8,
    backgroundColor: 'rgba(0,0,0,0.5)',
    borderRadius: 15,
    padding: 4,
  },
  controlsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    padding: 20,
    backgroundColor: 'rgba(0,0,0,0.5)',
  },
  controlButton: {
    padding: 15,
    borderRadius: 30,
    backgroundColor: '#2C2C2E',
  },
  endCallButton: {
    backgroundColor: '#FF3B30',
  },
}); 