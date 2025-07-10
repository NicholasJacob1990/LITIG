import React, { useState, useEffect } from 'react';
import { View, Text, Modal, StyleSheet, TextInput, Button, TouchableOpacity, Alert, ScrollView } from 'react-native';
import { createConsultation, updateConsultation, Consultation } from '@/lib/services/consultations';
import { useAuth } from '@/lib/contexts/AuthContext';
import { X } from 'lucide-react-native';
import { Picker } from '@react-native-picker/picker';

interface ConsultationFormProps {
  isVisible: boolean;
  onClose: () => void;
  consultationToEdit?: Consultation | null;
  caseId?: string;
}

export default function ConsultationForm({ isVisible, onClose, consultationToEdit, caseId }: ConsultationFormProps) {
  const { user } = useAuth();
  const [scheduledDate, setScheduledDate] = useState('');
  const [scheduledTime, setScheduledTime] = useState('');
  const [duration, setDuration] = useState(60);
  const [modality, setModality] = useState<'presencial' | 'videochamada' | 'telefone'>('videochamada');
  const [plan, setPlan] = useState<'gratuita' | 'premium' | 'corporativa'>('gratuita');
  const [notes, setNotes] = useState('');
  const [status, setStatus] = useState<'agendada' | 'confirmada' | 'concluida' | 'cancelada'>('agendada');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Preencher formulário quando editando
  useEffect(() => {
    if (consultationToEdit) {
      const date = new Date(consultationToEdit.scheduled_date);
      setScheduledDate(date.toISOString().split('T')[0]);
      setScheduledTime(date.toTimeString().slice(0, 5));
      setDuration(consultationToEdit.duration || 60);
      setModality(consultationToEdit.modality || 'videochamada');
      setPlan(consultationToEdit.plan || 'gratuita');
      setNotes(consultationToEdit.notes || '');
      setStatus(consultationToEdit.status || 'agendada');
    } else {
      // Resetar formulário para nova consulta
      setScheduledDate('');
      setScheduledTime('');
      setDuration(60);
      setModality('videochamada');
      setPlan('gratuita');
      setNotes('');
      setStatus('agendada');
    }
  }, [consultationToEdit, isVisible]);

  const handleSubmit = async () => {
    if (!scheduledDate || !scheduledTime || !user) {
      Alert.alert('Erro', 'Por favor, preencha data e horário.');
      return;
    }

    setIsSubmitting(true);
    
    // Combinar data e hora
    const scheduledDateTime = new Date(`${scheduledDate}T${scheduledTime}:00`);
    
    const consultationData: Partial<Consultation> = {
      case_id: caseId || consultationToEdit?.case_id,
      lawyer_id: user.id,
      scheduled_date: scheduledDateTime.toISOString(),
      duration,
      modality,
      plan,
      notes: notes.trim() || undefined,
      status,
    };

    try {
      if (consultationToEdit?.id) {
        await updateConsultation(consultationToEdit.id, consultationData);
      } else {
        await createConsultation(consultationData as Consultation);
      }
      
      Alert.alert('Sucesso', 'Consulta salva com sucesso!');
      onClose();
    } catch (error) {
      console.error('Failed to save consultation:', error);
      Alert.alert('Erro', 'Erro ao salvar consulta. Tente novamente.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const isEditing = !!consultationToEdit;

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
                {isEditing ? 'Editar Consulta' : 'Nova Consulta'}
              </Text>
              <TouchableOpacity onPress={onClose}>
                <X size={24} color="#64748B" />
              </TouchableOpacity>
            </View>
            
            <Text style={styles.label}>Data</Text>
            <TextInput
              style={styles.input}
              value={scheduledDate}
              onChangeText={setScheduledDate}
              placeholder="YYYY-MM-DD"
              keyboardType="default"
            />

            <Text style={styles.label}>Horário</Text>
            <TextInput
              style={styles.input}
              value={scheduledTime}
              onChangeText={setScheduledTime}
              placeholder="HH:MM"
              keyboardType="default"
            />

            <Text style={styles.label}>Duração (minutos)</Text>
            <View style={styles.pickerContainer}>
              <Picker
                selectedValue={duration}
                onValueChange={(itemValue) => setDuration(itemValue)}
              >
                <Picker.Item label="30 minutos" value={30} />
                <Picker.Item label="60 minutos" value={60} />
                <Picker.Item label="90 minutos" value={90} />
                <Picker.Item label="120 minutos" value={120} />
              </Picker>
            </View>

            <Text style={styles.label}>Modalidade</Text>
            <View style={styles.pickerContainer}>
              <Picker
                selectedValue={modality}
                onValueChange={(itemValue) => setModality(itemValue)}
              >
                <Picker.Item label="Videochamada" value="videochamada" />
                <Picker.Item label="Presencial" value="presencial" />
                <Picker.Item label="Telefone" value="telefone" />
              </Picker>
            </View>

            <Text style={styles.label}>Plano</Text>
            <View style={styles.pickerContainer}>
              <Picker
                selectedValue={plan}
                onValueChange={(itemValue) => setPlan(itemValue)}
              >
                <Picker.Item label="Gratuita" value="gratuita" />
                <Picker.Item label="Premium" value="premium" />
                <Picker.Item label="Corporativa" value="corporativa" />
              </Picker>
            </View>

            {isEditing && (
              <>
                <Text style={styles.label}>Status</Text>
                <View style={styles.pickerContainer}>
                  <Picker
                    selectedValue={status}
                    onValueChange={(itemValue) => setStatus(itemValue)}
                  >
                    <Picker.Item label="Agendada" value="agendada" />
                    <Picker.Item label="Confirmada" value="confirmada" />
                    <Picker.Item label="Concluída" value="concluida" />
                    <Picker.Item label="Cancelada" value="cancelada" />
                  </Picker>
                </View>
              </>
            )}

            <Text style={styles.label}>Observações (Opcional)</Text>
            <TextInput
              style={[styles.input, styles.textArea]}
              value={notes}
              onChangeText={setNotes}
              placeholder="Anotações sobre a consulta..."
              multiline
            />

            <View style={styles.buttonContainer}>
              <Button
                title={isSubmitting ? 'Salvando...' : (isEditing ? 'Atualizar Consulta' : 'Agendar Consulta')}
                onPress={handleSubmit}
                disabled={isSubmitting || !scheduledDate || !scheduledTime}
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