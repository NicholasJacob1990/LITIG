import React, { useMemo, useCallback, useEffect } from 'react';
import { View, StyleSheet, Alert, ActivityIndicator, Text, SafeAreaView } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { TouchableOpacity } from 'react-native';
import { MessageCircle } from 'lucide-react-native';
import { router } from 'expo-router';

function VideoConsultation() {
  const navigation = useNavigation();
  
  const handleBack = () => {
    if (navigation.canGoBack()) {
      navigation.goBack();
    } else {
      router.replace('/(tabs)/_internal/chat');
    }
  };

  const handleSwitchToChat = () => {
    Alert.alert(
      'Mudar para Chat',
      'Videochamada requer development build. Deseja continuar por chat?',
      [
        { text: 'Cancelar', style: 'cancel' },
        { 
          text: 'Continuar', 
          onPress: () => {
            router.replace('/(tabs)/_internal/chat');
          }
        }
      ]
    );
  };

  return (
    <View style={styles.container}>
      <View style={styles.centered}>
        <Text style={styles.errorText}>❌ Videochamada não disponível no Expo Go</Text>
        <Text style={styles.infoText}>
          Para usar videochamadas, você precisa de um development build.
        </Text>
        
        <View style={styles.buttonContainer}>
          <TouchableOpacity style={styles.backButton} onPress={handleBack}>
            <Text style={styles.backButtonText}>Voltar</Text>
          </TouchableOpacity>
          
          <TouchableOpacity style={styles.chatButton} onPress={handleSwitchToChat}>
            <MessageCircle size={20} color="#FFFFFF" />
            <Text style={styles.chatButtonText}>Continuar por Chat</Text>
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );
}

export default VideoConsultation;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1F2937',
  },
  callContainer: {
    flex: 1,
    position: 'relative',
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 10,
    color: 'white',
    fontSize: 16,
  },
  tile: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    alignItems: 'center',
  },
  video: {
    width: '100%',
    height: '100%',
  },
  placeholder: {
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: '#4B5563',
    justifyContent: 'center',
    alignItems: 'center',
  },
  placeholderText: {
    color: 'white',
    fontSize: 48,
    fontWeight: 'bold',
  },
  participantName: {
    position: 'absolute',
    bottom: 120,
    color: 'white',
    backgroundColor: 'rgba(0,0,0,0.5)',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
  },
  errorText: {
    color: 'white',
    fontSize: 20,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 10,
  },
  infoText: {
    color: 'white',
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 20,
    paddingHorizontal: 20,
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    width: '100%',
    paddingHorizontal: 20,
  },
  backButton: {
    backgroundColor: '#4B5563',
    paddingVertical: 10,
    paddingHorizontal: 20,
    borderRadius: 8,
    alignItems: 'center',
    flex: 1,
    marginRight: 10,
  },
  backButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
  },
  chatButton: {
    backgroundColor: '#007BFF',
    paddingVertical: 10,
    paddingHorizontal: 20,
    borderRadius: 8,
    alignItems: 'center',
    flex: 1,
    marginLeft: 10,
    flexDirection: 'row',
  },
  chatButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
    marginLeft: 5,
  },
}); 