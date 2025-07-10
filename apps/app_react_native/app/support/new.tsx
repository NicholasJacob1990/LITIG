import React, { useState } from 'react';
import { View, Text, StyleSheet, TextInput, TouchableOpacity, ScrollView, Alert, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { useAuth } from '@/lib/contexts/AuthContext';
import { useSupport } from '@/lib/contexts/SupportContext';
import { createSupportTicket } from '@/lib/services/support';
import { ArrowLeft, Paperclip, X } from 'lucide-react-native';
import * as DocumentPicker from 'expo-document-picker';

type Priority = 'low' | 'medium' | 'high' | 'critical';

interface SelectedFile {
  uri: string;
  name: string;
  type: string;
  size: number;
}

export default function NewSupportTicketScreen() {
  const router = useRouter();
  const { user } = useAuth();
  const { refetchTickets } = useSupport();

  const [subject, setSubject] = useState('');
  const [description, setDescription] = useState('');
  const [priority, setPriority] = useState<Priority>('medium');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [selectedFiles, setSelectedFiles] = useState<SelectedFile[]>([]);

  const handleSelectFile = async () => {
    try {
      const result = await DocumentPicker.getDocumentAsync({
        type: '*/*',
        copyToCacheDirectory: true,
        multiple: false, // Por enquanto, um arquivo por vez
      });

      if (result.canceled || !result.assets?.[0]) {
        return;
      }

      const file = result.assets[0];
      
      // Verificar tamanho do arquivo (máximo 10MB)
      if (file.size && file.size > 10 * 1024 * 1024) {
        Alert.alert('Arquivo muito grande', 'O arquivo deve ter no máximo 10MB.');
        return;
      }

      // Verificar se já não foi selecionado
      if (selectedFiles.some(f => f.name === file.name)) {
        Alert.alert('Arquivo já selecionado', 'Este arquivo já foi adicionado.');
        return;
      }

      const newFile: SelectedFile = {
        uri: file.uri,
        name: file.name,
        type: file.mimeType || 'application/octet-stream',
        size: file.size || 0,
      };

      setSelectedFiles(prev => [...prev, newFile]);
    } catch (error) {
      console.error('Error selecting file:', error);
      Alert.alert('Erro', 'Não foi possível selecionar o arquivo.');
    }
  };

  const handleRemoveFile = (fileName: string) => {
    setSelectedFiles(prev => prev.filter(file => file.name !== fileName));
  };

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
  };

  const handleCreateTicket = async () => {
    if (!subject.trim() || !description.trim()) {
      Alert.alert('Campos obrigatórios', 'Por favor, preencha o assunto e a descrição.');
      return;
    }
    if (!user) {
      Alert.alert('Erro', 'Você precisa estar logado para criar um ticket.');
      return;
    }

    setIsSubmitting(true);
    try {
      let ticketDescription = description;
      
      // Se há arquivos selecionados, adicionar na descrição
      if (selectedFiles.length > 0) {
        ticketDescription += '\n\nArquivos anexados:\n';
        selectedFiles.forEach(file => {
          ticketDescription += `• ${file.name} (${formatFileSize(file.size)})\n`;
        });
        ticketDescription += '\nNota: Os arquivos serão enviados na primeira mensagem do ticket.';
      }

      await createSupportTicket({
        creator_id: user.id,
        subject,
        description: ticketDescription,
        priority,
      });

      await refetchTickets(); // Atualiza a lista na tela anterior
      
      if (selectedFiles.length > 0) {
        Alert.alert(
          'Ticket criado!', 
          'Seu ticket foi criado. Envie os arquivos anexados na conversa do ticket.',
          [{ text: 'OK', onPress: () => router.back() }]
        );
      } else {
        Alert.alert('Sucesso!', 'Seu ticket de suporte foi aberto.');
        router.back(); // Volta para a tela anterior
      }
    } catch (error) {
      console.error('Failed to create support ticket:', error);
      Alert.alert('Erro', 'Não foi possível criar o ticket. Tente novamente mais tarde.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const priorityOptions: { label: string; value: Priority }[] = [
    { label: 'Baixa', value: 'low' },
    { label: 'Média', value: 'medium' },
    { label: 'Alta', value: 'high' },
    { label: 'Crítica', value: 'critical' },
  ];

  return (
    <View style={styles.container}>
      {/* Header com botão voltar */}
      <View style={styles.header}>
        <TouchableOpacity 
          style={styles.backButton}
          onPress={() => router.back()}
        >
          <ArrowLeft size={24} color="#111827" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Abrir Novo Ticket</Text>
        <View style={styles.headerSpacer} />
      </View>

      <ScrollView style={styles.content} contentContainerStyle={styles.contentContainer}>
        <Text style={styles.label}>Assunto</Text>
        <TextInput
          style={styles.input}
          value={subject}
          onChangeText={setSubject}
          placeholder="Ex: Problema ao sincronizar calendário"
        />

        <Text style={styles.label}>Prioridade</Text>
        <View style={styles.prioritySelector}>
          {priorityOptions.map((option) => (
            <TouchableOpacity
              key={option.value}
              style={[styles.priorityButton, priority === option.value && styles.priorityButtonSelected]}
              onPress={() => setPriority(option.value)}
            >
              <Text style={[styles.priorityButtonText, priority === option.value && styles.priorityButtonTextSelected]}>
                {option.label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
        
        <Text style={styles.label}>Descrição do Problema</Text>
        <TextInput
          style={[styles.input, styles.textArea]}
          value={description}
          onChangeText={setDescription}
          placeholder="Descreva em detalhes o que está acontecendo..."
          multiline
        />

        {/* Seção de anexos */}
        <View style={styles.attachmentSection}>
          <Text style={styles.label}>Anexos</Text>
          <TouchableOpacity style={styles.attachmentButton} onPress={handleSelectFile}>
            <Paperclip size={20} color="#4F46E5" />
            <Text style={styles.attachmentButtonText}>Adicionar arquivo</Text>
          </TouchableOpacity>
          
          {/* Lista de arquivos selecionados */}
          {selectedFiles.map((file, index) => (
            <View key={index} style={styles.selectedFile}>
              <View style={styles.fileInfo}>
                <Text style={styles.fileName} numberOfLines={1}>{file.name}</Text>
                <Text style={styles.fileSize}>{formatFileSize(file.size)}</Text>
              </View>
              <TouchableOpacity 
                style={styles.removeFileButton}
                onPress={() => handleRemoveFile(file.name)}
              >
                <X size={16} color="#EF4444" />
              </TouchableOpacity>
            </View>
          ))}
        </View>
        
        <TouchableOpacity
          style={[styles.submitButton, isSubmitting && styles.submitButtonDisabled]}
          onPress={handleCreateTicket}
          disabled={isSubmitting}
        >
          {isSubmitting ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.submitButtonText}>Enviar Ticket</Text>
          )}
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingTop: 50,
    paddingBottom: 15,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  backButton: {
    padding: 8,
    marginLeft: -8,
  },
  headerSpacer: {
    width: 40, // Mesmo tamanho do botão voltar para centralizar o título
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#111827',
  },
  content: {
    flex: 1,
  },
  contentContainer: {
    padding: 20,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: '#374151',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#F3F4F6',
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 8,
    padding: 14,
    fontSize: 16,
    marginBottom: 20,
    color: '#111827',
  },
  textArea: {
    height: 120,
    textAlignVertical: 'top',
  },
  prioritySelector: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 20,
  },
  priorityButton: {
    flex: 1,
    paddingVertical: 12,
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 8,
    alignItems: 'center',
    marginHorizontal: 4,
  },
  priorityButtonSelected: {
    backgroundColor: '#4F46E5',
    borderColor: '#4F46E5',
  },
  priorityButtonText: {
    fontWeight: '600',
    color: '#374151',
    fontSize: 14,
  },
  priorityButtonTextSelected: {
    color: '#FFFFFF',
  },
  attachmentSection: {
    marginBottom: 20,
  },
  attachmentButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F9FAFB',
    borderWidth: 1,
    borderColor: '#4F46E5',
    borderRadius: 8,
    padding: 14,
    gap: 10,
    marginBottom: 10,
  },
  attachmentButtonText: {
    color: '#4F46E5',
    fontSize: 14,
    fontWeight: '600',
  },
  selectedFile: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F3F4F6',
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 8,
    padding: 12,
    marginBottom: 8,
  },
  fileInfo: {
    flex: 1,
  },
  fileName: {
    fontSize: 14,
    fontWeight: '600',
    color: '#111827',
    marginBottom: 2,
  },
  fileSize: {
    fontSize: 12,
    color: '#6B7280',
  },
  removeFileButton: {
    padding: 4,
  },
  submitButton: {
    backgroundColor: '#4F46E5',
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 10,
  },
  submitButtonDisabled: {
    backgroundColor: '#A5B4FC',
  },
  submitButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: 'bold',
  },
}); 