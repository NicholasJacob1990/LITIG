import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  Alert,
  ActivityIndicator
} from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { Send, Paperclip, Phone, Video } from 'lucide-react-native';
import { useAuth } from '@/lib/contexts/AuthContext';
import {
  getCaseMessages,
  sendMessage,
  markMessagesAsRead,
  subscribeToCaseMessages,
  MessageData
} from '@/lib/services/chat';
import { getCaseById } from '@/lib/services/cases';
import TopBar from '@/components/layout/TopBar';
import Avatar from '@/components/atoms/Avatar';

export default function CaseChat() {
  const { user } = useAuth();
  const { caseId } = useLocalSearchParams<{ caseId: string }>();

  const [messages, setMessages] = useState<MessageData[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [caseData, setCaseData] = useState<any>(null);
  const scrollViewRef = useRef<ScrollView>(null);

  const handleNewMessage = useCallback((newMessage: MessageData) => {
    setMessages(prevMessages => {
      // Evitar duplicatas
      if (prevMessages.some(msg => msg.id === newMessage.id)) {
        return prevMessages;
      }
      return [newMessage, ...prevMessages];
    });

    if (newMessage.sender_id !== user?.id) {
      markMessagesAsRead(caseId, user?.id || '');
    }
  }, [caseId, user?.id]);

  useEffect(() => {
    if (!caseId) return;

    loadCaseData();
    loadMessages();
    
    const subscription = subscribeToCaseMessages(caseId, handleNewMessage);

    return () => {
      subscription.unsubscribe();
    };
  }, [caseId, handleNewMessage]);

  const loadCaseData = async () => {
    try {
      const data = await getCaseById(caseId);
      setCaseData(data);
    } catch (error) {
      console.error('Error loading case data:', error);
    }
  };

  const loadMessages = async () => {
    if (!caseId) return;
    try {
      setLoading(true);
      const messagesData = await getCaseMessages(caseId);
      setMessages(messagesData.sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime()));
      await markMessagesAsRead(caseId, user?.id || '');
    } catch (error) {
      console.error('Error loading messages:', error);
      Alert.alert('Erro', 'Não foi possível carregar as mensagens');
    } finally {
      setLoading(false);
    }
  };

  const handleSendMessage = async () => {
    if (!newMessage.trim() || sending || !caseId) return;

    try {
      setSending(true);
      await sendMessage({
        case_id: caseId,
        sender_id: user?.id || '',
        content: newMessage.trim(),
      });
      setNewMessage('');
    } catch (error) {
      console.error('Error sending message:', error);
      Alert.alert('Erro', 'Não foi possível enviar a mensagem');
    } finally {
      setSending(false);
    }
  };

  const renderMessage = (message: MessageData, index: number) => {
    const isMyMessage = message.sender_id === user?.id;
    const showAvatar = !isMyMessage && (
      index === 0 || 
      messages[index - 1]?.sender_id !== message.sender_id
    );

    const senderName = isMyMessage 
      ? 'Você' 
      : message.sender?.full_name || 'Usuário Desconhecido';
    const senderAvatar = message.sender?.avatar_url;

    return (
      <View key={message.id} style={[styles.messageContainer, isMyMessage ? styles.myMessageContainer : styles.otherMessageContainer]}>
        {showAvatar && (
          <Avatar src={senderAvatar} name={senderName} size="small"/>
        )}
        <View style={[styles.messageBubble, isMyMessage ? styles.myMessageBubble : styles.otherMessageBubble, !showAvatar && !isMyMessage && { marginLeft: 40 }]}>
          {!isMyMessage && showAvatar && <Text style={styles.senderName}>{senderName}</Text>}
          <Text style={[styles.messageText, isMyMessage ? styles.myMessageText : styles.otherMessageText]}>
            {message.content}
          </Text>
          <Text style={[styles.messageTime, isMyMessage ? styles.myMessageTime : styles.otherMessageTime]}>
            {new Date(message.created_at).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })}
          </Text>
        </View>
      </View>
    );
  };

  if (loading) {
    return (
      <View style={styles.container}>
        <StatusBar style="light" />
        <TopBar title="Chat" showBack />
        <View style={styles.loadingContainer}><ActivityIndicator size="large" color="#006CFF" /></View>
      </View>
    );
  }

  const otherUser = user?.id === caseData?.client_id ? caseData?.lawyer : caseData?.client;

  return (
    <KeyboardAvoidingView style={styles.container} behavior={Platform.OS === 'ios' ? 'padding' : 'height'} keyboardVerticalOffset={80}>
      <StatusBar style="light" />
      <TopBar 
        title={otherUser?.name || 'Chat'}
        subtitle={caseData?.title || ''}
        showBack
        rightActions={[
          { icon: Video, onPress: () => Alert.alert('Vídeo Chamada', 'Funcionalidade em desenvolvimento') },
          { icon: Phone, onPress: () => Alert.alert('Ligação', 'Funcionalidade em desenvolvimento') },
        ]}
      />

      <ScrollView
        ref={scrollViewRef}
        style={styles.messagesContainer}
        contentContainerStyle={{ flexGrow: 1, justifyContent: 'flex-end', paddingVertical: 16 }}
        onContentSizeChange={() => scrollViewRef.current?.scrollToEnd({ animated: true })}
      >
        {messages.map(renderMessage)}
      </ScrollView>

      <View style={styles.inputContainer}>
        <TouchableOpacity style={styles.attachButton}><Paperclip size={20} color="#6B7280" /></TouchableOpacity>
        <TextInput style={styles.textInput} placeholder="Digite sua mensagem..." value={newMessage} onChangeText={setNewMessage} multiline />
        <TouchableOpacity style={[styles.sendButton, !newMessage.trim() && styles.sendButtonDisabled]} onPress={handleSendMessage} disabled={!newMessage.trim() || sending}>
          {sending ? <ActivityIndicator size="small" color="#FFFFFF" /> : <Send size={20} color="#FFFFFF" />}
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  messagesContainer: {
    flex: 1,
    paddingHorizontal: 16,
  },
  messageContainer: {
    flexDirection: 'row',
    marginBottom: 16,
    alignItems: 'flex-end',
    gap: 8,
  },
  myMessageContainer: {
    justifyContent: 'flex-end',
  },
  otherMessageContainer: {
    justifyContent: 'flex-start',
  },
  messageBubble: {
    maxWidth: '75%',
    padding: 12,
    borderRadius: 16,
  },
  myMessageBubble: {
    backgroundColor: '#006CFF',
    borderBottomRightRadius: 4,
  },
  otherMessageBubble: {
    backgroundColor: '#FFFFFF',
    borderBottomLeftRadius: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  senderName: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 12,
    color: '#6B7280',
    marginBottom: 4,
  },
  messageText: {
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    lineHeight: 22,
  },
  myMessageText: { color: '#FFFFFF' },
  otherMessageText: { color: '#1F2937' },
  messageTime: {
    fontFamily: 'Inter-Regular',
    fontSize: 11,
    marginTop: 4,
    alignSelf: 'flex-end',
  },
  myMessageTime: { color: 'rgba(255, 255, 255, 0.7)' },
  otherMessageTime: { color: '#9CA3AF' },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#FFFFFF',
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
  },
  attachButton: { padding: 8, marginRight: 8 },
  textInput: {
    flex: 1,
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 20,
    paddingHorizontal: 16,
    paddingVertical: Platform.OS === 'ios' ? 12 : 8,
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#1F2937',
    maxHeight: 100,
    backgroundColor: '#F9FAFB',
  },
  sendButton: {
    backgroundColor: '#006CFF',
    borderRadius: 20,
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
    marginLeft: 8,
  },
  sendButtonDisabled: { backgroundColor: '#9CA3AF' },
});