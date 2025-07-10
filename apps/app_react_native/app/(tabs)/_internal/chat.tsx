import React, { useState, useCallback } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, ActivityIndicator, RefreshControl } from 'react-native';
import { useFocusEffect, router } from 'expo-router';
import { useNavigation } from '@react-navigation/native';
import { getChatList } from '@/lib/services/chat';
import supabase from '@/lib/supabase';
import { MessageSquare, Briefcase } from 'lucide-react-native';
import { useAuth } from '@/lib/contexts/AuthContext';
import { timeAgo } from '@/lib/utils/time'; // Assumindo que você tem um utilitário de tempo

interface MergedChat {
  id: string;
  type: 'pre-hiring' | 'case';
  title: string;
  lastMessage: string;
  lastMessageAt: string;
  avatarUrl?: string;
}

export default function ChatListScreen() {
  const { user } = useAuth();
  const navigation = useNavigation<any>();
  const [chats, setChats] = useState<MergedChat[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchChats = async () => {
    if (!user) return;

    try {
      // 1. Fetch Pre-hiring chats
      const preHiringChatsData = await getChatList();
      const preHiringChats: MergedChat[] = preHiringChatsData.map(chat => ({
        id: chat.id,
        type: 'pre-hiring',
        title: chat.lawyer.full_name,
        lastMessage: chat.last_message?.content || 'Nenhuma mensagem ainda.',
        lastMessageAt: chat.last_message?.created_at || chat.updated_at,
        avatarUrl: chat.lawyer.avatar_url,
      }));

      // 2. Fetch Case chats
      const { data: caseChatsData, error: caseError } = await supabase.rpc('get_user_cases', { p_user_id: user.id });
      if (caseError) throw caseError;

      const caseChats: MergedChat[] = caseChatsData.map((c: any) => ({
        id: c.id,
        type: 'case',
        title: user.id === c.client_id ? c.lawyer_name || 'Advogado não atribuído' : c.client_name || 'Cliente',
        lastMessage: c.ai_analysis?.description || 'Detalhes do caso',
        lastMessageAt: c.updated_at,
        avatarUrl: user.id === c.client_id ? c.lawyer_avatar : c.client_avatar,
      }));

      // 3. Merge and sort
      const allChats = [...preHiringChats, ...caseChats];
      allChats.sort((a, b) => new Date(b.lastMessageAt).getTime() - new Date(a.lastMessageAt).getTime());
      
      setChats(allChats);
    } catch (error) {
      console.error("Error fetching chats:", error);
      // Alert.alert('Erro', 'Não foi possível carregar as conversas.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useFocusEffect(
    useCallback(() => {
      setLoading(true);
      fetchChats();
    }, [user])
  );

  const onRefresh = useCallback(() => {
    setRefreshing(true);
    fetchChats();
  }, [user]);

  const handleChatPress = (chat: MergedChat) => {
    if (chat.type === 'pre-hiring') {
      router.push(`/pre-hiring-chat/${chat.id}`);
    } else {
      router.push({
        pathname: '/(tabs)/cases/CaseChat',
        params: { caseId: chat.id },
      });
    }
  };

  if (loading && !refreshing) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color="#1E40AF" />
      </View>
    );
  }

  if (!chats.length) {
    return (
      <View style={styles.centered}>
        <MessageSquare size={48} color="#9CA3AF" />
        <Text style={styles.emptyText}>Nenhuma conversa encontrada.</Text>
        <Text style={styles.emptySubText}>Inicie uma conversa com um advogado para vê-la aqui.</Text>
      </View>
    );
  }

  return (
    <ScrollView 
      style={styles.container}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
    >
      {chats.map(chat => (
        <TouchableOpacity key={`${chat.type}-${chat.id}`} style={styles.chatItem} onPress={() => handleChatPress(chat)}>
          <View style={styles.avatarContainer}>
            {/* Adicionar Avatar aqui se tiver a URL */}
            <View style={styles.iconContainer}>
              {chat.type === 'pre-hiring' 
                ? <MessageSquare size={24} color="#1E40AF" /> 
                : <Briefcase size={24} color="#059669" />}
            </View>
          </View>
          <View style={styles.chatContent}>
            <View style={styles.chatHeader}>
              <Text style={styles.chatTitle}>{chat.title}</Text>
              <Text style={styles.chatTime}>{timeAgo(chat.lastMessageAt)}</Text>
            </View>
            <Text style={styles.lastMessage} numberOfLines={1}>{chat.lastMessage}</Text>
          </View>
        </TouchableOpacity>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F9FAFB',
    padding: 20,
  },
  emptyText: {
    marginTop: 16,
    fontSize: 18,
    fontFamily: 'Inter-SemiBold',
    color: '#374151',
  },
  emptySubText: {
    marginTop: 8,
    fontSize: 14,
    fontFamily: 'Inter-Regular',
    color: '#6B7280',
    textAlign: 'center',
  },
  chatItem: {
    flexDirection: 'row',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
  },
  avatarContainer: {
    marginRight: 12,
  },
  iconContainer: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: '#E0E7FF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  chatContent: {
    flex: 1,
  },
  chatHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  chatTitle: {
    fontSize: 16,
    fontFamily: 'Inter-SemiBold',
    color: '#1F2937',
  },
  chatTime: {
    fontSize: 12,
    fontFamily: 'Inter-Regular',
    color: '#6B7280',
  },
  lastMessage: {
    fontSize: 14,
    fontFamily: 'Inter-Regular',
    color: '#4B5563',
  },
}); 