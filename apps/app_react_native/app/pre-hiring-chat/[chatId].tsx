import React, { useState, useEffect, useRef, useCallback } from 'react';
import { View, Text, StyleSheet, TextInput, TouchableOpacity, ScrollView, ActivityIndicator, Image, KeyboardAvoidingView, Platform } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { useAuth } from '@/lib/contexts/AuthContext';
import { getPreHiringMessages, sendPreHiringMessage, subscribeToChat, PreHiringMessage } from '@/lib/services/chat';
import { Send, ArrowLeft, Check, CheckCheck } from 'lucide-react-native';
import { RealtimeChannel } from '@supabase/supabase-js';

export default function PreHiringChatScreen() {
  const { chatId } = useLocalSearchParams<{ chatId: string }>();
  const { user } = useAuth();
  const [messages, setMessages] = useState<PreHiringMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const scrollViewRef = useRef<ScrollView>(null);
  const channelRef = useRef<RealtimeChannel | null>(null);

  const fetchMessages = async () => {
    if (!chatId) return;
    try {
      setLoading(true);
      const fetchedMessages = await getPreHiringMessages(chatId);
      setMessages(fetchedMessages);
    } catch (error) {
      console.error("Error fetching messages:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMessages();

    if (chatId) {
      const channel = subscribeToChat(chatId, (newMessagePayload) => {
        setMessages(currentMessages => {
          if (currentMessages.some(m => m.id === newMessagePayload.id)) {
            return currentMessages;
          }
          return [...currentMessages, newMessagePayload];
        });
      });
      channelRef.current = channel;
    }

    return () => {
      if (channelRef.current) {
        channelRef.current.unsubscribe();
      }
    };
  }, [chatId]);

  const handleSend = async () => {
    if (!newMessage.trim() || !chatId || !user) return;

    const optimisticMessage: PreHiringMessage = {
      id: Math.random().toString(),
      chat_id: chatId,
      sender_id: user.id,
      content: newMessage.trim(),
      created_at: new Date().toISOString(),
      sender: {
        full_name: user.user_metadata.full_name,
        avatar_url: user.user_metadata.avatar_url,
      }
    };

    setMessages(current => [...current, optimisticMessage]);
    setNewMessage('');

    try {
      await sendPreHiringMessage(chatId, newMessage.trim());
    } catch (error) {
      console.error("Error sending message:", error);
      // Revert optimistic update on error
      setMessages(current => current.filter(m => m.id !== optimisticMessage.id));
    }
  };

  if (loading) {
    return <ActivityIndicator style={styles.centered} size="large" color="#1E40AF" />;
  }

  return (
    <KeyboardAvoidingView 
      style={styles.container}
      behavior={Platform.OS === "ios" ? "padding" : "height"}
      keyboardVerticalOffset={90}
    >
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <ArrowLeft size={24} color="#FFF" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Conversa</Text>
      </View>

      <ScrollView
        ref={scrollViewRef}
        style={styles.messagesContainer}
        contentContainerStyle={{ paddingVertical: 10 }}
        onContentSizeChange={() => scrollViewRef.current?.scrollToEnd({ animated: true })}
      >
        {messages.map((msg) => (
          <View key={msg.id} style={[
            styles.messageBubble,
            msg.sender_id === user?.id ? styles.myMessage : styles.otherMessage
          ]}>
            <Text style={styles.messageText}>{msg.content}</Text>
            <Text style={styles.messageTime}>{new Date(msg.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</Text>
          </View>
        ))}
      </ScrollView>

      <View style={styles.inputContainer}>
        <TextInput
          style={styles.input}
          value={newMessage}
          onChangeText={setNewMessage}
          placeholder="Digite sua mensagem..."
          placeholderTextColor="#9CA3AF"
        />
        <TouchableOpacity style={styles.sendButton} onPress={handleSend}>
          <Send size={20} color="#FFF" />
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F0F4F8' },
  centered: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#1E40AF',
    paddingTop: 50,
    paddingBottom: 15,
    paddingHorizontal: 15,
  },
  backButton: { padding: 5, marginRight: 15 },
  headerTitle: { color: '#FFF', fontSize: 20, fontWeight: 'bold' },
  messagesContainer: { flex: 1, paddingHorizontal: 10 },
  messageBubble: {
    padding: 12,
    borderRadius: 20,
    marginVertical: 4,
    maxWidth: '80%',
  },
  myMessage: {
    backgroundColor: '#3B82F6',
    alignSelf: 'flex-end',
    borderBottomRightRadius: 4,
  },
  otherMessage: {
    backgroundColor: '#FFF',
    alignSelf: 'flex-start',
    borderBottomLeftRadius: 4,
  },
  messageText: { fontSize: 16, color: '#000' },
  messageTime: { fontSize: 10, color: '#6B7280', alignSelf: 'flex-end', marginTop: 4 },
  inputContainer: {
    flexDirection: 'row',
    padding: 10,
    backgroundColor: '#FFF',
    borderTopWidth: 1,
    borderColor: '#E5E7EB',
  },
  input: {
    flex: 1,
    height: 40,
    backgroundColor: '#F3F4F6',
    borderRadius: 20,
    paddingHorizontal: 15,
    marginRight: 10,
  },
  sendButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#1E40AF',
    justifyContent: 'center',
    alignItems: 'center',
  },
}); 