import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TextInput, Button, ScrollView, Alert, ActivityIndicator, TouchableOpacity, Platform } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { Picker } from '@react-native-picker/picker';
import { createConsultation } from '@/lib/services/consultations';
import { getCaseById, CaseData } from '@/lib/services/cases';

export default function ScheduleConsultScreen() {
  const { caseId } = useLocalSearchParams<{ caseId: string }>();
  const router = useRouter();

  const [caseData, setCaseData] = useState<CaseData | null>(null);
  const [consultationDate, setConsultationDate] = useState<Date>(new Date());
  const [duration, setDuration] = useState('45'); // Em minutos
  const [modality, setModality] = useState<'presencial' | 'videochamada' | 'telefone'>('videochamada');
  const [notes, setNotes] = useState('');
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (caseId) {
      getCaseById(caseId).then(data => {
        setCaseData(data);
        setLoading(false);
      });
    }
  }, [caseId]);

  const handleDateChange = (event: any, selectedDate?: Date) => {
    setShowDatePicker(Platform.OS === 'ios');
    if (selectedDate) {
      const newDate = new Date(consultationDate);
      newDate.setFullYear(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate());
      setConsultationDate(newDate);
    }
  };

  const handleTimeChange = (event: any, selectedTime?: Date) => {
    setShowTimePicker(Platform.OS === 'ios');
    if (selectedTime) {
      const newDate = new Date(consultationDate);
      newDate.setHours(selectedTime.getHours(), selectedTime.getMinutes());
      setConsultationDate(newDate);
    }
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString('pt-BR', {
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getModalityLabel = (modality: string) => {
    switch (modality) {
      case 'videochamada': return 'Videochamada';
      case 'presencial': return 'Presencial';
      case 'telefone': return 'Telefone';
      default: return 'Videochamada';
    }
  };

  const handleSave = async () => {
    if (!caseId || !caseData?.client_id || !caseData?.lawyer_id) {
      Alert.alert('Erro', 'Dados do caso incompletos para agendar a consulta.');
      return;
    }
    if (!duration || parseInt(duration) <= 0) {
      Alert.alert('Erro', 'Duração deve ser um número válido maior que zero.');
      return;
    }

    // Verificar se a data não é no passado
    if (consultationDate < new Date()) {
      Alert.alert('Erro', 'A data da consulta não pode ser no passado.');
      return;
    }

    setSaving(true);
    try {
      await createConsultation({
        case_id: caseId,
        lawyer_id: caseData.lawyer_id,
        client_id: caseData.client_id,
        scheduled_date: consultationDate.toISOString(),
        duration: parseInt(duration, 10),
        modality: modality,
        plan: 'premium', // Valor padrão, pode ser alterado
        status: 'agendada',
        notes: notes.trim() || undefined,
      });
      Alert.alert('Sucesso', 'A consulta foi agendada com sucesso.');
      router.back();
    } catch (error) {
      console.error('Error creating consultation:', error);
      Alert.alert('Erro', 'Não foi possível agendar a consulta.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <ActivityIndicator style={styles.centered} size="large" />;
  }

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Agendar Nova Consulta</Text>
      <Text style={styles.description}>
        Marque uma nova conversa com o cliente para discutir o andamento do caso.
      </Text>

      <Text style={styles.label}>Data da Consulta</Text>
      <TouchableOpacity 
        style={styles.dateButton} 
        onPress={() => setShowDatePicker(true)}
      >
        <Text style={styles.dateButtonText}>{formatDate(consultationDate)}</Text>
      </TouchableOpacity>

      {showDatePicker && (
        <DateTimePicker
          value={consultationDate}
          mode="date"
          display={Platform.OS === 'ios' ? 'spinner' : 'default'}
          onChange={handleDateChange}
          minimumDate={new Date()}
        />
      )}

      <Text style={styles.label}>Horário da Consulta</Text>
      <TouchableOpacity 
        style={styles.dateButton} 
        onPress={() => setShowTimePicker(true)}
      >
        <Text style={styles.dateButtonText}>{formatTime(consultationDate)}</Text>
      </TouchableOpacity>

      {showTimePicker && (
        <DateTimePicker
          value={consultationDate}
          mode="time"
          display={Platform.OS === 'ios' ? 'spinner' : 'default'}
          onChange={handleTimeChange}
        />
      )}

      <Text style={styles.label}>Duração (em minutos)</Text>
      <View style={styles.pickerContainer}>
        <Picker
          selectedValue={duration}
          onValueChange={(itemValue) => setDuration(itemValue)}
          style={styles.picker}
        >
          <Picker.Item label="30 minutos" value="30" />
          <Picker.Item label="45 minutos" value="45" />
          <Picker.Item label="60 minutos" value="60" />
          <Picker.Item label="90 minutos" value="90" />
          <Picker.Item label="120 minutos" value="120" />
        </Picker>
      </View>

      <Text style={styles.label}>Modalidade</Text>
      <View style={styles.pickerContainer}>
        <Picker
          selectedValue={modality}
          onValueChange={(itemValue) => setModality(itemValue)}
          style={styles.picker}
        >
          <Picker.Item label="Videochamada" value="videochamada" />
          <Picker.Item label="Presencial" value="presencial" />
          <Picker.Item label="Telefone" value="telefone" />
        </Picker>
      </View>

      <Text style={styles.label}>Observações</Text>
      <TextInput
        style={[styles.input, styles.textArea]}
        multiline
        value={notes}
        onChangeText={setNotes}
        placeholder="Observações adicionais sobre a consulta..."
      />

      <View style={styles.summaryContainer}>
        <Text style={styles.summaryTitle}>Resumo da Consulta:</Text>
        <Text style={styles.summaryText}>• Data: {formatDate(consultationDate)}</Text>
        <Text style={styles.summaryText}>• Horário: {formatTime(consultationDate)}</Text>
        <Text style={styles.summaryText}>• Duração: {duration} minutos</Text>
        <Text style={styles.summaryText}>• Modalidade: {getModalityLabel(modality)}</Text>
        {caseData?.client_name && (
          <Text style={styles.summaryText}>• Cliente: {caseData.client_name}</Text>
        )}
      </View>

      <View style={styles.buttonContainer}>
        <Button 
          title={saving ? "Agendando..." : "Agendar Consulta"} 
          onPress={handleSave} 
          disabled={saving} 
        />
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: '#fff',
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 12,
  },
  description: {
    fontSize: 14,
    color: '#666',
    marginBottom: 24,
    lineHeight: 20,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 16,
    marginBottom: 16,
    backgroundColor: '#f8f8f8'
  },
  textArea: {
    height: 80,
    textAlignVertical: 'top',
  },
  dateButton: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 12,
    marginBottom: 16,
    backgroundColor: '#f8f8f8',
  },
  dateButtonText: {
    fontSize: 16,
    color: '#333',
  },
  pickerContainer: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    marginBottom: 16,
    backgroundColor: '#f8f8f8',
    overflow: 'hidden',
  },
  picker: {
    height: 50,
  },
  summaryContainer: {
    backgroundColor: '#f0f9ff',
    padding: 16,
    borderRadius: 8,
    marginBottom: 24,
    borderWidth: 1,
    borderColor: '#e0f2fe',
  },
  summaryTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#0369a1',
    marginBottom: 8,
  },
  summaryText: {
    fontSize: 14,
    color: '#0c4a6e',
    marginBottom: 4,
  },
  buttonContainer: {
    marginTop: 16,
    marginBottom: 32,
  }
}); 