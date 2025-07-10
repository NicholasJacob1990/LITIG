import React, { useState, useEffect, useRef } from 'react';
import { View, Text, StyleSheet, TextInput, TouchableOpacity, ScrollView, ActivityIndicator, Alert, KeyboardAvoidingView, Platform, Modal } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useAuth } from '@/lib/contexts/AuthContext';
import { getSupportMessages, sendSupportMessage, SupportMessage, SupportTicket, updateTicketStatus, updateTicketPriority, markTicketRead, uploadAttachment } from '@/lib/services/support';
import { useSupport } from '@/lib/contexts/SupportContext';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { Send, ArrowLeft, MoreVertical, X, Star, Paperclip } from 'lucide-react-native';
import SupportRatingModal from '@/components/organisms/SupportRatingModal';
import AttachmentItem from '@/components/molecules/AttachmentItem';
import supabase from '@/lib/supabase';
import * as DocumentPicker from 'expo-document-picker';
import * as FileSystem from 'expo-file-system';

export default function TicketDetailScreen() {
  const { ticketId } = useLocalSearchParams();
  const { user } = useAuth();
  const router = useRouter();
  const { tickets, refetchTickets } = useSupport();

  const [messages, setMessages] = useState<SupportMessage[]>([]);
  const [ticket, setTicket] = useState<SupportTicket | null>(null);
  const [newMessage, setNewMessage] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isSending, setIsSending] = useState(false);
  const [showActionsModal, setShowActionsModal] = useState(false);
  const [showRatingModal, setShowRatingModal] = useState(false);
  const [isUpdating, setIsUpdating] = useState(false);
  const [isUploadingFile, setIsUploadingFile] = useState(false);
  
  const scrollViewRef = useRef<ScrollView>(null);

  useEffect(() => {
    // Encontra o ticket correspondente na lista do contexto
    const currentTicket = tickets.find(t => t.id === ticketId);
    if (currentTicket) {
      setTicket(currentTicket);
      // Marcar como lido quando abrir o ticket
      if (typeof ticketId === 'string') {
        markTicketRead(ticketId).catch(console.error);
      }
    } else {
      console.warn("Ticket não encontrado no contexto");
    }

    // Carrega as mensagens iniciais
    fetchMessages();

    // Configura a inscrição em tempo real para novas mensagens
    const channel = supabase
      .channel(`support-ticket-${ticketId}`)
      .on<SupportMessage>(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'support_messages',
          filter: `ticket_id=eq.${ticketId}`,
        },
        (payload) => {
          // Adiciona a nova mensagem ao estado, evitando duplicatas
          setMessages((prevMessages) => {
            if (prevMessages.some(msg => msg.id === payload.new.id)) {
              return prevMessages;
            }
            return [...prevMessages, payload.new];
          });
          
          // Rola para o final
          setTimeout(() => scrollViewRef.current?.scrollToEnd({ animated: true }), 100);
          
          // Se a mensagem não for do usuário atual, marcar como lido
          if (payload.new.sender_id !== user?.id) {
             if (typeof ticketId === 'string') {
                markTicketRead(ticketId).catch(console.error);
             }
          }
        }
      )
      .subscribe();

    // Limpa a inscrição ao desmontar o componente
    return () => {
      supabase.removeChannel(channel);
    };
  }, [ticketId, tickets]);

  const fetchMessages = async () => {
    if (typeof ticketId !== 'string') return;
    try {
      setIsLoading(true);
      const fetchedMessages = await getSupportMessages(ticketId);
      setMessages(fetchedMessages || []);
    } catch (error) {
      Alert.alert("Erro", "Não foi possível carregar as mensagens.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleSendMessage = async (attachmentData?: { url: string; name: string; type: string }) => {
    if ((!newMessage.trim() && !attachmentData) || !user || typeof ticketId !== 'string') return;

    setIsSending(true);
    try {
      const messageData: SupportMessage = {
        ticket_id: ticketId,
        sender_id: user.id,
        content: newMessage.trim() || (attachmentData ? `Arquivo enviado: ${attachmentData.name}` : ''),
        attachment_url: attachmentData?.url,
        attachment_name: attachmentData?.name,
        attachment_mime_type: attachmentData?.type,
      };

      const sentMessage = await sendSupportMessage(messageData);
      setMessages(prev => [...prev, sentMessage]);
      setNewMessage('');
      setTimeout(() => scrollViewRef.current?.scrollToEnd({ animated: true }), 100);
    } catch (error) {
      Alert.alert("Erro", "Não foi possível enviar a mensagem.");
    } finally {
      setIsSending(false);
    }
  };

  const handleAttachFile = async () => {
    try {
      setIsUploadingFile(true);
      
      // Selecionar arquivo
      const result = await DocumentPicker.getDocumentAsync({
        type: '*/*',
        copyToCacheDirectory: true,
      });

      if (result.canceled || !result.assets?.[0]) {
        setIsUploadingFile(false);
        return;
      }

      const file = result.assets[0];
      
      // Verificar tamanho do arquivo (máximo 10MB)
      if (file.size && file.size > 10 * 1024 * 1024) {
        Alert.alert('Arquivo muito grande', 'O arquivo deve ter no máximo 10MB.');
        setIsUploadingFile(false);
        return;
      }

      // Converter para File para upload
      const fileInfo = await FileSystem.getInfoAsync(file.uri);
      if (!fileInfo.exists) {
        throw new Error('Arquivo não encontrado');
      }

      // Criar objeto File
      const fileBlob = await fetch(file.uri).then(r => r.blob());
      const uploadFile = new File([fileBlob], file.name, { type: file.mimeType || 'application/octet-stream' });

      // Upload do arquivo
      const uploadResult = await uploadAttachment({
        file: uploadFile,
        ticketId: ticketId as string,
        userId: user!.id,
      });

      // Enviar mensagem com anexo
      await handleSendMessage({
        url: uploadResult.url,
        name: uploadResult.name,
        type: uploadResult.type,
      });

    } catch (error) {
      console.error('Error attaching file:', error);
      Alert.alert('Erro', 'Não foi possível anexar o arquivo.');
    } finally {
      setIsUploadingFile(false);
    }
  };

  const handleUpdateStatus = async (newStatus: 'open' | 'in_progress' | 'closed' | 'on_hold') => {
    if (!ticket?.id) return;
    
    setIsUpdating(true);
    try {
      await updateTicketStatus(ticket.id, newStatus);
      await refetchTickets(); // Atualiza a lista
      setShowActionsModal(false);
      
      // Se o ticket foi fechado, oferecer avaliação
      if (newStatus === 'closed') {
        Alert.alert(
          "Ticket Fechado", 
          "Ticket fechado com sucesso! Gostaria de avaliar o atendimento?",
          [
            { text: "Agora não", style: "cancel" },
            { text: "Avaliar", onPress: () => setShowRatingModal(true) }
          ]
        );
      } else {
        Alert.alert("Sucesso", "Ticket atualizado com sucesso!");
      }
    } catch (error) {
      Alert.alert("Erro", "Não foi possível atualizar o status do ticket.");
    } finally {
      setIsUpdating(false);
    }
  };

  const handleUpdatePriority = async (newPriority: 'low' | 'medium' | 'high' | 'critical') => {
    if (!ticket?.id) return;
    
    setIsUpdating(true);
    try {
      await updateTicketPriority(ticket.id, newPriority);
      await refetchTickets();
      setShowActionsModal(false);
      Alert.alert("Sucesso", "Prioridade atualizada com sucesso!");
    } catch (error) {
      Alert.alert("Erro", "Não foi possível atualizar a prioridade do ticket.");
    } finally {
      setIsUpdating(false);
    }
  };

  const handleRatingSubmitted = () => {
    // Atualizar a lista de tickets após a avaliação
    refetchTickets();
  };
  
  const renderMessage = (msg: SupportMessage) => {
    const isUserMessage = msg.sender_id === user?.id;
    return (
      <View
        key={msg.id}
        style={[
          styles.messageBubble,
          isUserMessage ? styles.userMessage : styles.supportMessage,
        ]}
      >
        <Text style={[styles.messageText, isUserMessage && styles.userMessageText]}>{msg.content}</Text>
        
        {/* Renderizar anexo se existir */}
        {msg.attachment_url && msg.attachment_name && (
          <AttachmentItem
            url={msg.attachment_url}
            name={msg.attachment_name}
            mimeType={msg.attachment_mime_type}
          />
        )}
        
        <Text style={styles.messageDate}>
          {msg.created_at ? format(new Date(msg.created_at), 'HH:mm') : '--:--'}
        </Text>
      </View>
    );
  };

  const getStatusText = (status?: string) => {
    switch (status) {
      case 'open': return 'Aberto';
      case 'in_progress': return 'Em Andamento';
      case 'closed': return 'Fechado';
      case 'on_hold': return 'Em Espera';
      default: return 'Aberto';
    }
  };

  if (isLoading) {
    return <View style={styles.centered}><ActivityIndicator size="large" /></View>;
  }

  if (!ticket) {
    return <View style={styles.centered}><Text>Ticket não encontrado.</Text></View>;
  }

  const isTicketClosed = ticket.status === 'closed';

  return (
    <KeyboardAvoidingView 
      style={styles.container}
      behavior={Platform.OS === "ios" ? "padding" : "height"}
      keyboardVerticalOffset={Platform.OS === "ios" ? 100 : 0}
    >
      {/* Header com botão voltar e menu de ações */}
      <View style={styles.header}>
        <TouchableOpacity 
          style={styles.backButton}
          onPress={() => router.back()}
        >
          <ArrowLeft size={24} color="#111827" />
        </TouchableOpacity>
        <View style={styles.headerContent}>
          <Text style={styles.headerTitle} numberOfLines={1}>{ticket.subject}</Text>
          <Text style={styles.headerSubtitle}>#{ticket.id} • {getStatusText(ticket.status)}</Text>
        </View>
        <TouchableOpacity 
          style={styles.actionsButton}
          onPress={() => setShowActionsModal(true)}
        >
          <MoreVertical size={24} color="#111827" />
        </TouchableOpacity>
      </View>

      {/* Botão de avaliação para tickets fechados */}
      {isTicketClosed && (
        <View style={styles.ratingBanner}>
          <Text style={styles.ratingBannerText}>Ticket fechado</Text>
          <TouchableOpacity
            style={styles.ratingButton}
            onPress={() => setShowRatingModal(true)}
          >
            <Star size={16} color="#F59E0B" />
            <Text style={styles.ratingButtonText}>Avaliar Atendimento</Text>
          </TouchableOpacity>
        </View>
      )}

      <ScrollView 
        ref={scrollViewRef}
        style={styles.messagesContainer}
        contentContainerStyle={{ paddingVertical: 10 }}
        onContentSizeChange={() => scrollViewRef.current?.scrollToEnd({ animated: true })}
      >
        {messages.map(renderMessage)}
      </ScrollView>

      {/* Input de mensagem (desabilitado para tickets fechados) */}
      <View style={[styles.inputContainer, isTicketClosed && styles.inputContainerDisabled]}>
        <TouchableOpacity 
          style={[styles.attachButton, (isUploadingFile || isTicketClosed) && styles.attachButtonDisabled]}
          onPress={handleAttachFile}
          disabled={isUploadingFile || isTicketClosed}
        >
          {isUploadingFile ? (
            <ActivityIndicator size="small" color="#6B7280" />
          ) : (
            <Paperclip size={20} color={isTicketClosed ? "#9CA3AF" : "#6B7280"} />
          )}
        </TouchableOpacity>
        
        <TextInput
          style={[styles.input, isTicketClosed && styles.inputDisabled]}
          value={newMessage}
          onChangeText={setNewMessage}
          placeholder={isTicketClosed ? "Ticket fechado - não é possível enviar mensagens" : "Digite sua mensagem..."}
          multiline
          editable={!isTicketClosed}
        />
        
        <TouchableOpacity 
          style={[styles.sendButton, (isSending || isTicketClosed) && styles.sendButtonDisabled]} 
          onPress={() => handleSendMessage()}
          disabled={isSending || isTicketClosed}
        >
          {isSending ? <ActivityIndicator size="small" color="#FFF" /> : <Send size={20} color="#FFF" />}
        </TouchableOpacity>
      </View>

      {/* Modal de ações */}
      <Modal
        visible={showActionsModal}
        transparent
        animationType="slide"
        onRequestClose={() => setShowActionsModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Ações do Ticket</Text>
              <TouchableOpacity onPress={() => setShowActionsModal(false)}>
                <X size={24} color="#111827" />
              </TouchableOpacity>
            </View>

            <Text style={styles.sectionTitle}>Status</Text>
            <View style={styles.actionButtons}>
              {ticket.status !== 'open' && (
                <TouchableOpacity 
                  style={styles.actionButton}
                  onPress={() => handleUpdateStatus('open')}
                  disabled={isUpdating}
                >
                  <Text style={styles.actionButtonText}>Reabrir</Text>
                </TouchableOpacity>
              )}
              {ticket.status !== 'closed' && (
                <TouchableOpacity 
                  style={[styles.actionButton, styles.closeButton]}
                  onPress={() => handleUpdateStatus('closed')}
                  disabled={isUpdating}
                >
                  <Text style={[styles.actionButtonText, styles.closeButtonText]}>Fechar</Text>
                </TouchableOpacity>
              )}
            </View>

            <Text style={styles.sectionTitle}>Prioridade</Text>
            <View style={styles.actionButtons}>
              {(['low', 'medium', 'high', 'critical'] as const).map((priority) => (
                <TouchableOpacity 
                  key={priority}
                  style={[
                    styles.priorityButton,
                    ticket.priority === priority && styles.priorityButtonActive
                  ]}
                  onPress={() => handleUpdatePriority(priority)}
                  disabled={isUpdating || ticket.priority === priority}
                >
                  <Text style={[
                    styles.priorityButtonText,
                    ticket.priority === priority && styles.priorityButtonActiveText
                  ]}>
                    {priority === 'low' ? 'Baixa' : 
                     priority === 'medium' ? 'Média' : 
                     priority === 'high' ? 'Alta' : 'Crítica'}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            {isUpdating && (
              <View style={styles.loadingOverlay}>
                <ActivityIndicator size="large" color="#4F46E5" />
              </View>
            )}
          </View>
        </View>
      </Modal>

      {/* Modal de avaliação */}
      {showRatingModal && ticket?.id && (
        <SupportRatingModal
          visible={showRatingModal}
          onClose={() => setShowRatingModal(false)}
          ticketId={ticket.id}
          ticketSubject={ticket.subject}
          onRatingSubmitted={handleRatingSubmitted}
        />
      )}
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F3F4F6',
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF',
    paddingHorizontal: 20,
    paddingTop: 50,
    paddingBottom: 15,
    borderBottomWidth: 1,
    borderColor: '#E5E7EB',
  },
  backButton: {
    padding: 8,
    marginLeft: -8,
  },
  headerContent: {
    flex: 1,
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#111827',
  },
  headerSubtitle: {
    fontSize: 14,
    color: '#6B7280',
    marginTop: 2,
  },
  actionsButton: {
    padding: 8,
    marginRight: -8,
  },
  ratingBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#FEF3C7',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderColor: '#FDE68A',
  },
  ratingBannerText: {
    fontSize: 14,
    color: '#92400E',
    fontWeight: '600',
  },
  ratingButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F59E0B',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    gap: 4,
  },
  ratingButtonText: {
    fontSize: 12,
    color: '#FFF',
    fontWeight: '600',
  },
  messagesContainer: {
    flex: 1,
    paddingHorizontal: 10,
  },
  messageBubble: {
    padding: 12,
    borderRadius: 18,
    marginVertical: 5,
    maxWidth: '80%',
  },
  userMessage: {
    backgroundColor: '#4F46E5',
    alignSelf: 'flex-end',
  },
  supportMessage: {
    backgroundColor: '#FFFFFF',
    alignSelf: 'flex-start',
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  messageText: {
    fontSize: 16,
    color: '#111827',
  },
  userMessageText: {
    color: '#FFFFFF',
  },
  messageDate: {
    fontSize: 10,
    color: '#9CA3AF',
    alignSelf: 'flex-end',
    marginTop: 4,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 10,
    backgroundColor: '#FFF',
    borderTopWidth: 1,
    borderColor: '#E5E7EB',
  },
  inputContainerDisabled: {
    backgroundColor: '#F9FAFB',
  },
  attachButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#F3F4F6',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 10,
  },
  attachButtonDisabled: {
    backgroundColor: '#E5E7EB',
  },
  input: {
    flex: 1,
    backgroundColor: '#F3F4F6',
    borderRadius: 20,
    paddingVertical: 10,
    paddingHorizontal: 15,
    marginRight: 10,
    fontSize: 16,
    maxHeight: 100,
  },
  inputDisabled: {
    backgroundColor: '#E5E7EB',
    color: '#9CA3AF',
  },
  sendButton: {
    backgroundColor: '#4F46E5',
    borderRadius: 22,
    width: 44,
    height: 44,
    justifyContent: 'center',
    alignItems: 'center',
  },
  sendButtonDisabled: {
    backgroundColor: '#A5B4FC',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: '#FFF',
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    padding: 20,
    minHeight: 300,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#111827',
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#374151',
    marginTop: 20,
    marginBottom: 10,
  },
  actionButtons: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 10,
  },
  actionButton: {
    flex: 1,
    backgroundColor: '#F3F4F6',
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  closeButton: {
    backgroundColor: '#FEE2E2',
  },
  actionButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#374151',
  },
  closeButtonText: {
    color: '#DC2626',
  },
  priorityButton: {
    flex: 1,
    backgroundColor: '#F3F4F6',
    padding: 8,
    borderRadius: 6,
    alignItems: 'center',
    marginHorizontal: 2,
  },
  priorityButtonActive: {
    backgroundColor: '#4F46E5',
  },
  priorityButtonText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#374151',
  },
  priorityButtonActiveText: {
    color: '#FFFFFF',
  },
  loadingOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(255, 255, 255, 0.8)',
    justifyContent: 'center',
    alignItems: 'center',
  },
}); 