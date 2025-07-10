import React from 'react';
import { View, TouchableOpacity, StyleSheet, Text, SafeAreaView } from 'react-native';
import { Video, Mic, PhoneOff, MicOff, VideoOff } from 'lucide-react-native';
import { BlurView } from 'expo-blur';

interface VideoCallUIProps {
  onLeave: () => void;
  onToggleCamera: () => void;
  onToggleMic: () => void;
  isCameraOn: boolean;
  isMicOn: boolean;
}

export default function VideoCallUI({
  onLeave,
  onToggleCamera,
  onToggleMic,
  isCameraOn,
  isMicOn,
}: VideoCallUIProps) {
  return (
    <SafeAreaView style={styles.container}>
      <BlurView intensity={80} tint="dark" style={styles.controls}>
        <TouchableOpacity
          style={[styles.button, !isMicOn && styles.buttonOff]}
          onPress={onToggleMic}>
          {isMicOn ? <Mic size={28} color="white" /> : <MicOff size={28} color="white" />}
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.button, !isCameraOn && styles.buttonOff]}
          onPress={onToggleCamera}>
          {isCameraOn ? <Video size={28} color="white" /> : <VideoOff size={28} color="white" />}
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.button, styles.hangupButton]}
          onPress={onLeave}>
          <PhoneOff size={28} color="white" />
        </TouchableOpacity>
      </BlurView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    alignItems: 'center',
  },
  controls: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    padding: 20,
    borderRadius: 30,
    overflow: 'hidden',
    width: '80%',
    marginBottom: 30,
  },
  button: {
    width: 60,
    height: 60,
    borderRadius: 30,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
  },
  buttonOff: {
    backgroundColor: 'rgba(255, 255, 255, 0.4)',
  },
  hangupButton: {
    backgroundColor: '#E53935',
  },
}); 