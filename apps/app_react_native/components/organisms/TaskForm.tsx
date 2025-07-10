import React, { useState, useEffect } from 'react';
import { View, Text, Modal, StyleSheet, TextInput, Button, TouchableOpacity, Platform } from 'react-native';
import { createTask, updateTask, Task } from '@/lib/services/tasks';
import { useTasks } from '@/lib/contexts/TasksContext';
import { useAuth } from '@/lib/contexts/AuthContext';
import { X } from 'lucide-react-native';
import { getUserCases } from '@/lib/services/cases';
import { Picker } from '@react-native-picker/picker';

interface TaskFormProps {
  isVisible: boolean;
  onClose: () => void;
  taskToEdit?: Task | null; // Nova prop para edição
}

export default function TaskForm({ isVisible, onClose, taskToEdit }: TaskFormProps) {
  const { user } = useAuth();
  const { refetchTasks } = useTasks();
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [priority, setPriority] = useState(5);
  const [dueDate, setDueDate] = useState('');
  const [status, setStatus] = useState<Task['status']>('pending');
  const [selectedCase, setSelectedCase] = useState<string | null>(null);
  const [userCases, setUserCases] = useState<{ id: string, description: string }[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Preencher formulário quando editando
  useEffect(() => {
    if (taskToEdit) {
      setTitle(taskToEdit.title || '');
      setDescription(taskToEdit.description || '');
      setPriority(taskToEdit.priority || 5);
      setDueDate(taskToEdit.due_date ? taskToEdit.due_date.split('T')[0] : '');
      setStatus(taskToEdit.status || 'pending');
      setSelectedCase(taskToEdit.case_id || null);
    } else {
      // Resetar formulário para nova tarefa
      setTitle('');
      setDescription('');
      setPriority(5);
      setDueDate('');
      setStatus('pending');
      setSelectedCase(null);
    }
  }, [taskToEdit, isVisible]);

  useEffect(() => {
    if (isVisible && user) {
      getUserCases(user.id).then(cases => {
        if (cases) {
          setUserCases(cases);
        }
      });
    }
  }, [isVisible, user]);

  const handleSubmit = async () => {
    if (!title.trim() || !user) return;

    setIsSubmitting(true);
    const taskData: Task = {
      title: title.trim(),
      description: description.trim(),
      priority,
      due_date: dueDate ? new Date(dueDate).toISOString() : undefined,
      status,
      case_id: selectedCase || undefined,
      created_by: user.id,
    };

    try {
      if (taskToEdit?.id) {
        // Editar tarefa existente
        await updateTask(taskToEdit.id, taskData);
      } else {
        // Criar nova tarefa
        await createTask(taskData);
      }
      
      await refetchTasks();
      onClose();
    } catch (error) {
      console.error('Failed to save task:', error);
      alert('Erro ao salvar tarefa. Tente novamente.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const isEditing = !!taskToEdit;

  return (
    <Modal
      animationType="slide"
      transparent={true}
      visible={isVisible}
      onRequestClose={onClose}
    >
      <View style={styles.modalContainer}>
        <View style={styles.modalContent}>
          <View style={styles.header}>
            <Text style={styles.headerTitle}>
              {isEditing ? 'Editar Tarefa' : 'Nova Tarefa'}
            </Text>
            <TouchableOpacity onPress={onClose}>
              <X size={24} color="#64748B" />
            </TouchableOpacity>
          </View>
          
          <Text style={styles.label}>Título</Text>
          <TextInput
            style={styles.input}
            value={title}
            onChangeText={setTitle}
            placeholder="Ex: Preparar petição inicial"
          />

          <Text style={styles.label}>Associar ao Caso (Opcional)</Text>
          <View style={styles.pickerContainer}>
            <Picker
              selectedValue={selectedCase}
              onValueChange={(itemValue) => setSelectedCase(itemValue)}
            >
              <Picker.Item label="Nenhum (Tarefa Geral)" value={null} />
              {userCases.map(c => (
                <Picker.Item key={c.id} label={c.description} value={c.id} />
              ))}
            </Picker>
          </View>

          <Text style={styles.label}>Descrição (Opcional)</Text>
          <TextInput
            style={[styles.input, styles.textArea]}
            value={description}
            onChangeText={setDescription}
            placeholder="Detalhes sobre a tarefa..."
            multiline
          />

          <Text style={styles.label}>Prazo (Opcional)</Text>
          <TextInput
            style={styles.input}
            value={dueDate}
            onChangeText={setDueDate}
            placeholder="YYYY-MM-DD"
            keyboardType="default"
          />

          {isEditing && (
            <>
              <Text style={styles.label}>Status</Text>
              <View style={styles.pickerContainer}>
                <Picker
                  selectedValue={status}
                  onValueChange={(itemValue) => setStatus(itemValue)}
                >
                  <Picker.Item label="Pendente" value="pending" />
                  <Picker.Item label="Em Progresso" value="in_progress" />
                  <Picker.Item label="Concluída" value="completed" />
                  <Picker.Item label="Atrasada" value="overdue" />
                </Picker>
              </View>
            </>
          )}

          <Text style={styles.label}>Prioridade: {priority}</Text>
          <View style={styles.prioritySelector}>
             {[1, 5, 8].map(p => (
                <TouchableOpacity 
                  key={p} 
                  onPress={() => setPriority(p)} 
                  style={[styles.priorityButton, priority === p && styles.priorityButtonSelected]}
                >
                    <Text style={[styles.priorityButtonText, priority === p && styles.priorityButtonTextSelected]}>
                      {p}
                    </Text>
                </TouchableOpacity>
             ))}
          </View>

          <Button
            title={isSubmitting ? 'Salvando...' : (isEditing ? 'Atualizar Tarefa' : 'Salvar Tarefa')}
            onPress={handleSubmit}
            disabled={isSubmitting || !title.trim()}
          />
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
    prioritySelector: {
        flexDirection: 'row',
        justifyContent: 'space-around',
        marginVertical: 20,
    },
    priorityButton: {
        paddingVertical: 10,
        paddingHorizontal: 20,
        borderRadius: 20,
        borderWidth: 1,
        borderColor: '#CBD5E1',
    },
    priorityButtonSelected: {
        backgroundColor: '#0F172A',
        borderColor: '#0F172A',
    },
    priorityButtonText: {
        color: '#0F172A',
        fontWeight: 'bold',
    },
    priorityButtonTextSelected: {
        color: 'white',
    },
    pickerContainer: {
        borderWidth: 1,
        borderColor: '#E2E8F0',
        borderRadius: 8,
        backgroundColor: '#F8FAFC',
        marginBottom: 10,
    },
}); 