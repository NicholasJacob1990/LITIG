import React, { useState, useEffect } from 'react';
import { View, Text, Modal, StyleSheet, TextInput, Button, TouchableOpacity, Alert, ScrollView } from 'react-native';
import { createProcessEvent, updateProcessEvent, ProcessEvent } from '@/lib/services/processEvents';
import { useAuth } from '@/lib/contexts/AuthContext';
import { X } from 'lucide-react-native';
import { Picker } from '@react-native-picker/picker';

interface ProcessEventFormProps {
  isVisible: boolean;
  onClose: () => void;
  eventToEdit?: ProcessEvent | null;
  caseId?: string;
}

export default function ProcessEventForm({ isVisible, onClose, eventToEdit, caseId }: ProcessEventFormProps) {
  const { user } = useAuth();
  const [eventDate, setEventDate] = useState('');
  const [eventTime, setEventTime] = useState('');
  const [eventType, setEventType] = useState<'peticao' | 'decisao' | 'audiencia' | 'despacho' | 'sentenca' | 'recurso' | 'outro'>('peticao');
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [documentUrl, setDocumentUrl] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Preencher formulário quando editando
  useEffect(() => {
    if (eventToEdit) {
      const date = new Date(eventToEdit.event_date);
      setEventDate(date.toISOString().split('T')[0]);
      setEventTime(date.toTimeString().slice(0, 5));
      setEventType(eventToEdit.event_type || 'peticao');
      setTitle(eventToEdit.title || '');
      setDescription(eventToEdit.description || '');
      setDocumentUrl(eventToEdit.document_url || '');
    } else {
      // Resetar formulário para novo evento
      setEventDate('');
      setEventTime('');
      setEventType('peticao');
      setTitle('');
      setDescription('');
      setDocumentUrl('');
    }
  }, [eventToEdit, isVisible]);

  const handleSubmit = async () => {
    if (!eventDate || !title.trim() || !user) {
      Alert.alert('Erro', 'Por favor, preencha data e título do evento.');
      return;
    }

    setIsSubmitting(true);
    
    // Combinar data e hora
    const eventDateTime = eventTime 
      ? new Date(`${eventDate}T${eventTime}:00`)
      : new Date(`${eventDate}T12:00:00`);
    
    const eventData: Partial<ProcessEvent> = {
      case_id: caseId || eventToEdit?.case_id,
      event_date: eventDateTime.toISOString(),
      event_type: eventType,
      title: title.trim(),
      description: description.trim() || undefined,
      document_url: documentUrl.trim() || undefined,
      created_by: user.id,
    };

    try {
      if (eventToEdit?.id) {
        await updateProcessEvent(eventToEdit.id, eventData);
      } else {
        await createProcessEvent(eventData as ProcessEvent);
      }
      
      Alert.alert('Sucesso', 'Evento processual salvo com sucesso!');
      onClose();
    } catch (error) {
      console.error('Failed to save process event:', error);
      Alert.alert('Erro', 'Erro ao salvar evento. Tente novamente.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const isEditing = !!eventToEdit;

  return (
    <Modal
      animationType="slide"
      transparent={true}
      visible={isVisible}
      onRequestClose={onClose}
    >
      <View style={styles.modalContainer}>
        <View style={styles.modalContent}>
          <ScrollView showsVerticalScrollIndicator={false}>
            <View style={styles.header}>
              <Text style={styles.headerTitle}>
                {isEditing ? 'Editar Evento' : 'Novo Evento Processual'}
              </Text>
              <TouchableOpacity onPress={onClose}>
                <X size={24} color="#64748B" />
              </TouchableOpacity>
            </View>
            
            <Text style={styles.label}>Data do Evento</Text>
            <TextInput
              style={styles.input}
              value={eventDate}
              onChangeText={setEventDate}
              placeholder="YYYY-MM-DD"
              keyboardType="default"
            />

            <Text style={styles.label}>Horário (Opcional)</Text>
            <TextInput
              style={styles.input}
              value={eventTime}
              onChangeText={setEventTime}
              placeholder="HH:MM"
              keyboardType="default"
            />

            <Text style={styles.label}>Tipo de Evento</Text>
            <View style={styles.pickerContainer}>
              <Picker
                selectedValue={eventType}
                onValueChange={(itemValue) => setEventType(itemValue)}
              >
                <Picker.Item label="Petição" value="peticao" />
                <Picker.Item label="Decisão" value="decisao" />
                <Picker.Item label="Audiência" value="audiencia" />
                <Picker.Item label="Despacho" value="despacho" />
                <Picker.Item label="Sentença" value="sentenca" />
                <Picker.Item label="Recurso" value="recurso" />
                <Picker.Item label="Outro" value="outro" />
              </Picker>
            </View>

            <Text style={styles.label}>Título</Text>
            <TextInput
              style={styles.input}
              value={title}
              onChangeText={setTitle}
              placeholder="Ex: Petição inicial protocolada"
            />

            <Text style={styles.label}>Descrição</Text>
            <TextInput
              style={[styles.input, styles.textArea]}
              value={description}
              onChangeText={setDescription}
              placeholder="Detalhes sobre o evento processual..."
              multiline
            />

            <Text style={styles.label}>URL do Documento (Opcional)</Text>
            <TextInput
              style={styles.input}
              value={documentUrl}
              onChangeText={setDocumentUrl}
              placeholder="https://..."
              keyboardType="url"
            />

            <View style={styles.buttonContainer}>
              <Button
                title={isSubmitting ? 'Salvando...' : (isEditing ? 'Atualizar Evento' : 'Salvar Evento')}
                onPress={handleSubmit}
                disabled={isSubmitting || !eventDate || !title.trim()}
              />
            </View>
          </ScrollView>
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
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -2 },
    shadowOpacity: 0.1,
    shadowRadius: 10,
    elevation: 10,
    maxHeight: '90%',
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
  textArea: {
    height: 100,
    textAlignVertical: 'top',
  },
  pickerContainer: {
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 8,
    backgroundColor: '#F8FAFC',
    marginBottom: 10,
  },
  buttonContainer: {
    marginTop: 20,
    marginBottom: 10,
  },
}); 