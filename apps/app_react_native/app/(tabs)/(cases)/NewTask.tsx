import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useState } from 'react';
import { View, Text, StyleSheet, TextInput, Button, ScrollView, Alert, TouchableOpacity, Platform } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { Picker } from '@react-native-picker/picker';
import { createTask } from '@/lib/services/tasks';

export default function NewTaskScreen() {
  const { caseId } = useLocalSearchParams<{ caseId: string }>();
  const router = useRouter();

  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [dueDate, setDueDate] = useState<Date>(new Date());
  const [priority, setPriority] = useState<'low' | 'medium' | 'high'>('medium');
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [saving, setSaving] = useState(false);

  const handleDateChange = (event: any, selectedDate?: Date) => {
    setShowDatePicker(Platform.OS === 'ios');
    if (selectedDate) {
      setDueDate(selectedDate);
    }
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  const getPriorityLabel = (priority: string) => {
    switch (priority) {
      case 'low': return 'Baixa';
      case 'medium': return 'Média';
      case 'high': return 'Alta';
      default: return 'Média';
    }
  };

  const getPriorityNumber = (priority: string) => {
    switch (priority) {
      case 'low': return 1;
      case 'medium': return 2;
      case 'high': return 3;
      default: return 2;
    }
  };

  const handleSave = async () => {
    if (!caseId || !title.trim()) {
      Alert.alert('Erro', 'O título da tarefa é obrigatório.');
      return;
    }

    setSaving(true);
    try {
      await createTask({
        case_id: caseId,
        title: title.trim(),
        description: description.trim() || undefined,
        due_date: dueDate.toISOString(),
        priority: getPriorityNumber(priority),
        status: 'pending',
      });
      Alert.alert('Sucesso', 'A nova tarefa foi adicionada ao caso.');
      router.back();
    } catch (error) {
      console.error('Error creating task:', error);
      Alert.alert('Erro', 'Não foi possível criar a tarefa.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Adicionar Nova Tarefa</Text>
      <Text style={styles.description}>
        Crie uma nova etapa ou pendência para o andamento deste caso. Ela ficará visível para o cliente.
      </Text>

      <Text style={styles.label}>Título da Tarefa *</Text>
      <TextInput
        style={styles.input}
        value={title}
        onChangeText={setTitle}
        placeholder="Ex: Enviar documentos comprobatórios"
      />

      <Text style={styles.label}>Descrição</Text>
      <TextInput
        style={[styles.input, styles.textArea]}
        multiline
        value={description}
        onChangeText={setDescription}
        placeholder="Detalhes sobre a tarefa, instruções, etc."
      />

      <Text style={styles.label}>Prazo</Text>
      <TouchableOpacity 
        style={styles.dateButton} 
        onPress={() => setShowDatePicker(true)}
      >
        <Text style={styles.dateButtonText}>{formatDate(dueDate)}</Text>
      </TouchableOpacity>

      {showDatePicker && (
        <DateTimePicker
          value={dueDate}
          mode="date"
          display={Platform.OS === 'ios' ? 'spinner' : 'default'}
          onChange={handleDateChange}
          minimumDate={new Date()}
        />
      )}

      <Text style={styles.label}>Prioridade</Text>
      <View style={styles.pickerContainer}>
        <Picker
          selectedValue={priority}
          onValueChange={(itemValue) => setPriority(itemValue)}
          style={styles.picker}
        >
          <Picker.Item label="Baixa" value="low" />
          <Picker.Item label="Média" value="medium" />
          <Picker.Item label="Alta" value="high" />
        </Picker>
      </View>

      <View style={styles.summaryContainer}>
        <Text style={styles.summaryTitle}>Resumo da Tarefa:</Text>
        <Text style={styles.summaryText}>• Título: {title || 'Não definido'}</Text>
        <Text style={styles.summaryText}>• Prazo: {formatDate(dueDate)}</Text>
        <Text style={styles.summaryText}>• Prioridade: {getPriorityLabel(priority)}</Text>
      </View>

      <View style={styles.buttonContainer}>
        <Button 
          title={saving ? "Criando..." : "Criar Tarefa"} 
          onPress={handleSave} 
          disabled={saving || !title.trim()} 
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
    height: 120,
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