import React, { useState, useEffect, useRef } from 'react';
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
import { useLocalSearchParams, useNavigation } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { Send, Paperclip, Phone, Video } from 'lucide-react-native';
import { useAuth } from '@/lib/contexts/AuthContext';
import {
  getCaseMessages,
  sendMessage,
  markMessagesAsRead,
  subscribeToCaseMessages,
  unsubscribeFromCaseMessages,
  MessageData
} from '@/lib/services/chat';
import { getCaseById } from '@/lib/services/cases';
import TopBar from '@/components/layout/TopBar';
import Avatar from '@/components/atoms/Avatar';

export default function CaseChat() {
  const navigation = useNavigation();
  const { user } = useAuth();
  const { caseId } = useLocalSearchParams<{ caseId: string }>();

  const [messages, setMessages] = useState<MessageData[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [caseData, setCaseData] = useState<any>(null);
  const scrollViewRef = useRef<ScrollView>(null);
  const subscriptionRef = useRef<any>(null);

  useEffect(() => {
    if (!caseId) return;
    loadCaseData();
    loadMessages();
    
    // Subscrever a novas mensagens
    subscriptionRef.current = subscribeToCaseMessages(caseId, (newMessage) => {
      setMessages(prev => [newMessage, ...prev]);
      // Marcar mensagens como lidas se não são do usuário atual
      if (newMessage.user_id !== user?.id) {
        markMessagesAsRead(caseId, user?.id || '');
      }
    });

    return () => {
      if (subscriptionRef.current) {
        unsubscribeFromCaseMessages(subscriptionRef.current);
      }
    };
  }, [caseId, user?.id]);

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
      setMessages(messagesData.reverse()); // Mais antigas primeiro
      
      // Marcar mensagens como lidas
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
      const message = await sendMessage(caseId, user?.id || '', newMessage.trim());
      setMessages(prev => [...prev, message]);
      setNewMessage('');
      
      // Scroll para o final
      setTimeout(() => {
        scrollViewRef.current?.scrollToEnd({ animated: true });
      }, 100);
    } catch (error) {
      console.error('Error sending message:', error);
      Alert.alert('Erro', 'Não foi possível enviar a mensagem');
    } finally {
      setSending(false);
    }
  };

  const formatMessageTime = (timestamp: string) => {
    const date = new Date(timestamp);
    const now = new Date();
    const isToday = date.toDateString() === now.toDateString();
    
    if (isToday) {
      return date.toLocaleTimeString('pt-BR', {
        hour: '2-digit',
        minute: '2-digit'
      });
    } else {
      return date.toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
      });
    }
  };

  const renderMessage = (message: MessageData, index: number) => {
    const isMyMessage = message.user_id === user?.id;
    const showAvatar = !isMyMessage && (
      index === 0 || 
      messages[index - 1]?.user_id !== message.user_id
    );

    return (
      <View
        key={message.id}
        style={[
          styles.messageContainer,
          isMyMessage ? styles.myMessageContainer : styles.otherMessageContainer
        ]}
      >
        {showAvatar && message.sender && (
          <Avatar
            src={message.sender.avatar}
            name={message.sender.name}
            size="small"
          />
        )}
        
        <View
          style={[
            styles.messageBubble,
            isMyMessage ? styles.myMessageBubble : styles.otherMessageBubble,
            !showAvatar && !isMyMessage && styles.messageWithoutAvatar
          ]}
        >
          {!isMyMessage && showAvatar && message.sender && (
            <Text style={styles.senderName}>{message.sender.name}</Text>
          )}
          
          <Text
            style={[
              styles.messageText,
              isMyMessage ? styles.myMessageText : styles.otherMessageText
            ]}
          >
            {message.content}
          </Text>
          
          <Text
            style={[
              styles.messageTime,
              isMyMessage ? styles.myMessageTime : styles.otherMessageTime
            ]}
          >
            {formatMessageTime(message.created_at)}
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
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#006CFF" />
          <Text style={styles.loadingText}>Carregando conversa...</Text>
        </View>
      </View>
    );
  }

  const otherUser = user?.id === caseData?.client_id
    ? caseData?.lawyer
    : caseData?.client;

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      keyboardVerticalOffset={80}
    >
      <StatusBar style="light" />
      <TopBar 
        title={otherUser?.name || 'Chat'}
        subtitle={caseData?.ai_analysis?.title || ''}
        showBack
        rightActions={[
          { icon: Video, onPress: () => Alert.alert('Vídeo Chamada', 'Funcionalidade em desenvolvimento') },
          { icon: Phone, onPress: () => Alert.alert('Ligação', 'Funcionalidade em desenvolvimento') },
        ]}
      />

      <ScrollView
        ref={scrollViewRef}
        style={styles.messagesContainer}
        contentContainerStyle={styles.messagesContent}
        showsVerticalScrollIndicator={false}
        onContentSizeChange={() => scrollViewRef.current?.scrollToEnd({ animated: true })}
      >
        {messages.length === 0 ? (
          <View style={styles.emptyState}>
            <Text style={styles.emptyStateTitle}>Nenhuma mensagem</Text>
            <Text style={styles.emptyStateDescription}>
              Inicie a conversa sobre seu caso jurídico
            </Text>
          </View>
        ) : (
          messages.map(renderMessage)
        )}
      </ScrollView>

      <View style={styles.inputContainer}>
        <TouchableOpacity style={styles.attachButton}>
          <Paperclip size={20} color="#6B7280" />
        </TouchableOpacity>
        
        <TextInput
          style={styles.textInput}
          placeholder="Digite sua mensagem..."
          placeholderTextColor="#9CA3AF"
          value={newMessage}
          onChangeText={setNewMessage}
          multiline
          maxLength={1000}
        />
        
        <TouchableOpacity
          style={[
            styles.sendButton,
            (!newMessage.trim() || sending) && styles.sendButtonDisabled
          ]}
          onPress={handleSendMessage}
          disabled={!newMessage.trim() || sending}
        >
          {sending ? (
            <ActivityIndicator size="small" color="#FFFFFF" />
          ) : (
            <Send size={20} color="#FFFFFF" />
          )}
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
    paddingHorizontal: 20,
  },
  loadingText: {
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#6B7280',
    marginTop: 16,
  },
  messagesContainer: {
    flex: 1,
    paddingHorizontal: 16,
  },
  messagesContent: {
    paddingVertical: 16,
    flexGrow: 1,
  },
  messageContainer: {
    flexDirection: 'row',
    marginBottom: 16,
    alignItems: 'flex-end',
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
    marginHorizontal: 8,
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
  messageWithoutAvatar: {
    marginLeft: 48, // Espaço para o avatar mesmo quando não visível
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
  myMessageText: {
    color: '#FFFFFF',
  },
  otherMessageText: {
    color: '#1F2937',
  },
  messageTime: {
    fontFamily: 'Inter-Regular',
    fontSize: 11,
    marginTop: 4,
  },
  myMessageTime: {
    color: 'rgba(255, 255, 255, 0.7)',
    textAlign: 'right',
  },
  otherMessageTime: {
    color: '#9CA3AF',
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#FFFFFF',
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
  },
  attachButton: {
    padding: 8,
    marginRight: 8,
  },
  textInput: {
    flex: 1,
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 20,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#1F2937',
    maxHeight: 100,
    backgroundColor: '#F9FAFB',
  },
  sendButton: {
    backgroundColor: '#006CFF',
    borderRadius: 20,
    padding: 12,
    marginLeft: 8,
    alignItems: 'center',
    justifyContent: 'center',
    width: 44,
    height: 44,
  },
  sendButtonDisabled: {
    backgroundColor: '#9CA3AF',
  },
  emptyState: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
  },
  emptyStateTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1F2937',
    marginBottom: 8,
  },
  emptyStateDescription: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
    lineHeight: 20,
  },
});