import React, { useState } from 'react';
import { View, Text, Modal, StyleSheet, TextInput, Button, TouchableOpacity, Alert } from 'react-native';
import { createSupportTicket, SupportTicket } from '@/lib/services/support';
import { useSupport } from '@/lib/contexts/SupportContext';
import { useAuth } from '@/lib/contexts/AuthContext';
import { X } from 'lucide-react-native';

interface SupportTicketFormProps {
  isVisible: boolean;
  onClose: () => void;
}

export default function SupportTicketForm({ isVisible, onClose }: SupportTicketFormProps) {
  const { user } = useAuth();
  const { refetchTickets } = useSupport();
  const [subject, setSubject] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async () => {
    if (subject.trim().length === 0) {
      setError('O assunto não pode estar em branco.');
      return;
    }
    if (subject.trim().length < 10) {
      setError('O assunto deve ter pelo menos 10 caracteres.');
      return;
    }
    if (!user) {
        setError('Usuário não autenticado. Por favor, reinicie o aplicativo.');
        return;
    }

    setError(null);
    setIsSubmitting(true);

    const newTicket: SupportTicket = {
      subject: subject.trim(),
      creator_id: user.id,
      status: 'open',
      priority: 'medium', // Prioridade padrão
    };

    try {
      await createSupportTicket(newTicket);
      await refetchTickets();
      onClose();
      setSubject('');
    } catch (err) {
      console.error('Failed to create support ticket:', err);
      Alert.alert(
        'Erro Inesperado', 
        'Não foi possível criar o ticket de suporte. Por favor, tente novamente mais tarde.'
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    setSubject('');
    setError(null);
    onClose();
  }

  return (
    <Modal
      animationType="slide"
      transparent={true}
      visible={isVisible}
      onRequestClose={handleClose}
    >
      <View style={styles.modalContainer}>
        <View style={styles.modalContent}>
          <View style={styles.header}>
            <Text style={styles.headerTitle}>Novo Ticket de Suporte</Text>
            <TouchableOpacity onPress={handleClose}>
              <X size={24} color="#64748B" />
            </TouchableOpacity>
          </View>
          
          <Text style={styles.label}>Assunto</Text>
          <TextInput
            style={[styles.input, error && styles.inputError]}
            value={subject}
            onChangeText={(text) => {
              setSubject(text);
              if(error) setError(null);
            }}
            placeholder="Ex: Dúvida sobre o caso XPTO"
            maxLength={150}
          />
          <View style={styles.fieldHelper}>
            {error ? (
              <Text style={styles.errorText}>{error}</Text>
            ) : (
              <Text style={styles.helperText}>Descreva o problema de forma resumida.</Text>
            )}
            <Text style={styles.charCounter}>{subject.length}/150</Text>
          </View>
          
          <View style={styles.buttonContainer}>
            <Button
              title={isSubmitting ? 'Abrindo...' : 'Abrir Ticket'}
              onPress={handleSubmit}
              disabled={isSubmitting || !!error}
            />
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
    modalContainer: {
        flex: 1,
        justifyContent: 'flex-end',
        backgroundColor: 'rgba(0, 0, 0, 0.5)',
    },
    modalContent: {
        backgroundColor: 'white',
        padding: 20,
        borderTopLeftRadius: 20,
        borderTopRightRadius: 20,
    },
    header: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 20,
    },
    headerTitle: {
        fontSize: 22,
        fontWeight: 'bold',
        color: '#1E293B',
    },
    label: {
        fontSize: 16,
        color: '#475569',
        marginBottom: 8,
        marginTop: 10,
    },
    input: {
        backgroundColor: '#F8FAFC',
        borderWidth: 1,
        borderColor: '#E2E8F0',
        borderRadius: 8,
        padding: 12,
        fontSize: 16,
        color: '#1E293B',
    },
    inputError: {
      borderColor: '#EF4444',
    },
    fieldHelper: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      marginTop: 6,
      paddingHorizontal: 4,
    },
    helperText: {
      fontSize: 12,
      color: '#64748B',
    },
    errorText: {
      fontSize: 12,
      color: '#EF4444',
      flex: 1,
    },
    charCounter: {
      fontSize: 12,
      color: '#64748B',
    },
    buttonContainer: {
      marginTop: 30,
    }
}); 