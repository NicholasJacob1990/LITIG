import React, { useState, useEffect, useRef, useCallback } from 'react';
import { 
  View, 
  Text, 
  TextInput, 
  StyleSheet, 
  ScrollView, 
  TouchableOpacity, 
  ActivityIndicator, 
  KeyboardAvoidingView, 
  Platform, 
  SafeAreaView,
  Alert
} from 'react-native';
import { useRouter } from 'expo-router';
import { Paperclip, Send, Bot } from 'lucide-react-native';
import { continueTriageConversation, startTriage } from '@/lib/services/api';
import { runHybridTriageAnalysis, checkTriageStatus } from '@/lib/openai';
import { useAuth } from '@/lib/contexts/AuthContext';
import { StatusBar } from 'expo-status-bar';
import { LinearGradient } from 'expo-linear-gradient';
import AITypingIndicator from '@/components/AITypingIndicator';

interface Message {
  role: 'user' | 'assistant';
  content: string;
}

const ChatTriageScreen = () => {
  const router = useRouter();
  const { user } = useAuth();
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [triageEnded, setTriageEnded] = useState(false);
  const scrollViewRef = useRef<ScrollView>(null);

  const startConversation = useCallback(async () => {
    if (messages.length > 0) return;
    setIsLoading(true);
    try {
      const response = await continueTriageConversation([]);
      setMessages([{ role: 'assistant', content: response.reply }]);
    } catch (error) {
      console.error("Erro ao iniciar a conversa:", error);
      setMessages([{ role: 'assistant', content: "Olá! Sou o Justus, seu assistente jurídico. Para começarmos, por favor, descreva seu problema." }]);
    } finally {
      setIsLoading(false);
    }
  }, [messages.length]);

  useEffect(() => {
    startConversation();
  }, [startConversation]);

  const handleSend = async () => {
    if (input.trim() === '' || isLoading) return;

    const userMessage: Message = { role: 'user', content: input };
    const newMessages = [...messages, userMessage];
    setMessages(newMessages);
    setInput('');
    setIsLoading(true);

    try {
      const response = await continueTriageConversation(newMessages);
      
      if (response.reply.includes('[END_OF_TRIAGE]')) {
        setTriageEnded(true);
        const finalMessage = response.reply.replace('[END_OF_TRIAGE]', '').trim();
        if (finalMessage) {
            setMessages(prev => [...prev, { role: 'assistant', content: finalMessage }]);
        }
      } else {
        setMessages(prev => [...prev, { role: 'assistant', content: response.reply }]);
      }
    } catch (error) {
      console.error("Erro ao enviar mensagem:", error);
      setMessages(prev => [...prev, { role: 'assistant', content: "Desculpe, estou com problemas para conectar. Por favor, tente novamente." }]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleFinishTriage = async () => {
      setIsLoading(true);
      const transcript = messages.map(m => `${m.role === 'user' ? 'Cliente' : 'Assistente'}: ${m.content}`).join('\n\n');
      
      try {
        if (!user) {
            Alert.alert("Erro", "Você precisa estar logado para iniciar uma triagem.");
            setIsLoading(false);
            return;
        }

        // Usar o novo Pipeline de Triagem Híbrida
        const result = await runHybridTriageAnalysis(transcript, user.id);
        
        if (result.success) {
          Alert.alert(
            "Análise Iniciada", 
            `Sua análise foi iniciada com sucesso usando estratégia ${result.strategy}. Você será notificado quando os resultados estiverem prontos e eles aparecerão na aba 'Recomendações'.`
          );

          // Navega para a nova aba de recomendações
          router.push('/(tabs)/recommendations');
        } else {
          // Fallback para método antigo se o híbrido falhar
          console.warn("Pipeline híbrido falhou, usando método tradicional:", result.error);
          const task = await startTriage({ texto_cliente: transcript });
          
          Alert.alert("Análise Iniciada", "Sua análise foi iniciada com sucesso. Você será notificado quando os resultados estiverem prontos e eles aparecerão na aba 'Recomendações'.");
          router.push('/(tabs)/recommendations');
        }

      } catch (error) {
          console.error("Erro ao finalizar triagem:", error);
          Alert.alert("Erro", "Não foi possível iniciar a análise do seu caso. Tente novamente mais tarde.");
      } finally {
          setIsLoading(false);
      }
  };

  useEffect(() => {
    scrollViewRef.current?.scrollToEnd({ animated: true });
  }, [messages]);
  
  const renderMessage = (message: Message, index: number) => (
    <View key={index} style={[styles.messageContainer, message.role === 'user' ? styles.userMessageContainer : styles.botMessageContainer]}>
        <View style={[styles.messageBubble, message.role === 'user' ? styles.userBubble : styles.botBubble]}>
            <Text style={message.role === 'user' ? styles.userText : styles.botText}>{message.content}</Text>
        </View>
    </View>
  );

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar style="dark" />
      <KeyboardAvoidingView 
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        style={{ flex: 1 }}
        keyboardVerticalOffset={Platform.OS === "ios" ? 64 : 0}
      >
        <LinearGradient colors={['#FFFFFF', '#F9FAFB']} style={styles.header}>
            <Text style={styles.headerTitle}>Triagem Conversacional</Text>
            <Text style={styles.headerSubtitle}>Converse com nosso assistente para explicar seu caso</Text>
        </LinearGradient>

        <ScrollView ref={scrollViewRef} contentContainerStyle={styles.messagesContainer}>
          {messages.map(renderMessage)}
          {isLoading && <AITypingIndicator />}
        </ScrollView>

        {triageEnded ? (
          <View style={styles.footer}>
            <TouchableOpacity style={styles.finishButton} onPress={handleFinishTriage} disabled={isLoading}>
                {isLoading ? <ActivityIndicator color="#fff" /> : <Text style={styles.finishButtonText}>Ver Advogados Recomendados</Text>}
            </TouchableOpacity>
          </View>
        ) : (
          <View style={styles.inputContainer}>
            <TouchableOpacity style={styles.attachButton}>
              <Paperclip size={22} color="#6B7280" />
            </TouchableOpacity>
            <TextInput
              style={styles.input}
              value={input}
              onChangeText={setInput}
              placeholder="Digite sua mensagem..."
              editable={!isLoading}
              multiline
            />
            <TouchableOpacity style={styles.sendButton} onPress={handleSend} disabled={isLoading || !input.trim()}>
              <Send size={22} color="#fff" />
            </TouchableOpacity>
          </View>
        )}
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#F9FAFB',
    },
    header: {
        padding: 16,
        paddingTop: Platform.OS === 'android' ? 40 : 20,
        borderBottomWidth: 1,
        borderBottomColor: '#E5E7EB',
    },
    headerTitle: {
        fontSize: 22,
        fontWeight: '700',
        color: '#1F2937',
        textAlign: 'center',
    },
    headerSubtitle: {
        fontSize: 14,
        color: '#6B7280',
        textAlign: 'center',
        marginTop: 4,
    },
    messagesContainer: {
        padding: 16,
    },
    messageContainer: {
        marginVertical: 8,
        maxWidth: '80%',
    },
    userMessageContainer: {
        alignSelf: 'flex-end',
    },
    botMessageContainer: {
        alignSelf: 'flex-start',
    },
    messageBubble: {
        padding: 12,
        borderRadius: 18,
    },
    userBubble: {
        backgroundColor: '#007AFF',
        borderBottomRightRadius: 4,
    },
    botBubble: {
        backgroundColor: '#FFFFFF',
        borderWidth: 1,
        borderColor: '#E5E7EB',
        borderBottomLeftRadius: 4,
    },
    userText: {
        color: 'white',
        fontSize: 16,
    },
    botText: {
        color: '#1F2937',
        fontSize: 16,
    },
    typingIndicator: {
        alignSelf: 'flex-start',
        marginLeft: 10,
        marginTop: 10,
    },
    footer: {
        padding: 16,
        borderTopWidth: 1,
        borderTopColor: '#E5E7EB',
        backgroundColor: '#FFFFFF'
    },
    finishButton: {
        backgroundColor: '#16A34A',
        paddingVertical: 14,
        borderRadius: 12,
        alignItems: 'center',
        justifyContent: 'center',
    },
    finishButtonText: {
        color: 'white',
        fontSize: 16,
        fontWeight: '600',
    },
    inputContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        padding: 8,
        borderTopWidth: 1,
        borderTopColor: '#E5E7EB',
        backgroundColor: '#FFFFFF',
    },
    attachButton: {
        padding: 8,
    },
    input: {
        flex: 1,
        minHeight: 44,
        maxHeight: 120,
        paddingHorizontal: 16,
        backgroundColor: '#F3F4F6',
        borderRadius: 22,
        fontSize: 16,
        lineHeight: 20,
    },
    sendButton: {
        marginLeft: 8,
        width: 44,
        height: 44,
        borderRadius: 22,
        backgroundColor: '#007AFF',
        justifyContent: 'center',
        alignItems: 'center',
    },
});

export default ChatTriageScreen; 