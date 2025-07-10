import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  TextInput,
} from 'react-native';
import { Calendar, Clock, MapPin, User, Phone, Mail, CheckCircle } from 'lucide-react-native';
import { StatusBar } from 'expo-status-bar';
import { useLocalSearchParams, useRouter } from 'expo-router';
import TopBar from '@/components/layout/TopBar';

export default function ScheduleConsult() {
  const router = useRouter();
  const params = useLocalSearchParams<{ 
    caseId?: string; 
    lawyerId?: string;
    analysis?: string;
  }>();
  
  const [selectedDate, setSelectedDate] = useState<string>('');
  const [selectedTime, setSelectedTime] = useState<string>('');
  const [consultType, setConsultType] = useState<'video' | 'presencial' | 'telefone'>('video');
  const [notes, setNotes] = useState<string>('');
  const [isLoading, setIsLoading] = useState(false);

  // Mock data - em produção, buscar do backend
  const availableDates = [
    { date: '2025-01-06', label: 'Segunda, 06 Jan' },
    { date: '2025-01-07', label: 'Terça, 07 Jan' },
    { date: '2025-01-08', label: 'Quarta, 08 Jan' },
    { date: '2025-01-09', label: 'Quinta, 09 Jan' },
    { date: '2025-01-10', label: 'Sexta, 10 Jan' },
  ];

  const availableTimes = [
    '09:00', '10:00', '11:00', '14:00', '15:00', '16:00', '17:00'
  ];

  const consultTypes = [
    { 
      id: 'video', 
      label: 'Videochamada', 
      icon: Calendar, 
      description: 'Consulta online via plataforma segura' 
    },
    { 
      id: 'presencial', 
      label: 'Presencial', 
      icon: MapPin, 
      description: 'Reunião no escritório do advogado' 
    },
    { 
      id: 'telefone', 
      label: 'Telefone', 
      icon: Phone, 
      description: 'Consulta por chamada telefônica' 
    },
  ];

  const handleSchedule = async () => {
    if (!selectedDate || !selectedTime) {
      Alert.alert('Erro', 'Por favor, selecione data e horário para a consulta');
      return;
    }

    setIsLoading(true);

    try {
      // Simular agendamento - em produção, chamar API
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      Alert.alert(
        'Consulta Agendada!',
        `Sua consulta foi agendada para ${availableDates.find(d => d.date === selectedDate)?.label} às ${selectedTime}`,
        [
          {
            text: 'OK',
            onPress: () => router.back()
          }
        ]
      );
    } catch (error) {
      Alert.alert('Erro', 'Não foi possível agendar a consulta. Tente novamente.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      
      <TopBar
        title="Agendar Consulta"
        subtitle="Escolha data, horário e tipo de consulta"
        showBack
      />

      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Case Info */}
        {params.caseId && (
          <View style={styles.caseInfoCard}>
            <View style={styles.caseInfoHeader}>
              <CheckCircle size={20} color="#10B981" />
              <Text style={styles.caseInfoTitle}>Caso #{params.caseId.slice(-6)}</Text>
            </View>
            <Text style={styles.caseInfoDescription}>
              Consulta sobre análise de IA gerada para seu caso
            </Text>
          </View>
        )}

        {/* Consultation Type */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Tipo de Consulta</Text>
          <View style={styles.consultTypeGrid}>
            {consultTypes.map((type) => {
              const IconComponent = type.icon;
              return (
                <TouchableOpacity
                  key={type.id}
                  style={[
                    styles.consultTypeCard,
                    consultType === type.id && styles.consultTypeCardSelected
                  ]}
                  onPress={() => setConsultType(type.id as any)}
                >
                  <IconComponent 
                    size={24} 
                    color={consultType === type.id ? '#006CFF' : '#6B7280'} 
                  />
                  <Text style={[
                    styles.consultTypeLabel,
                    consultType === type.id && styles.consultTypeLabelSelected
                  ]}>
                    {type.label}
                  </Text>
                  <Text style={styles.consultTypeDescription}>
                    {type.description}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </View>

        {/* Date Selection */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Selecionar Data</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            <View style={styles.dateGrid}>
              {availableDates.map((date) => (
                <TouchableOpacity
                  key={date.date}
                  style={[
                    styles.dateCard,
                    selectedDate === date.date && styles.dateCardSelected
                  ]}
                  onPress={() => setSelectedDate(date.date)}
                >
                  <Text style={[
                    styles.dateLabel,
                    selectedDate === date.date && styles.dateLabelSelected
                  ]}>
                    {date.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </ScrollView>
        </View>

        {/* Time Selection */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Selecionar Horário</Text>
          <View style={styles.timeGrid}>
            {availableTimes.map((time) => (
              <TouchableOpacity
                key={time}
                style={[
                  styles.timeCard,
                  selectedTime === time && styles.timeCardSelected
                ]}
                onPress={() => setSelectedTime(time)}
              >
                <Clock 
                  size={16} 
                  color={selectedTime === time ? '#FFFFFF' : '#6B7280'} 
                />
                <Text style={[
                  styles.timeLabel,
                  selectedTime === time && styles.timeLabelSelected
                ]}>
                  {time}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Notes */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Observações (Opcional)</Text>
          <TextInput
            style={styles.notesInput}
            placeholder="Descreva pontos específicos que gostaria de abordar na consulta..."
            value={notes}
            onChangeText={setNotes}
            multiline
            numberOfLines={4}
            maxLength={500}
          />
          <Text style={styles.characterCount}>{notes.length}/500</Text>
        </View>

        {/* Summary */}
        {selectedDate && selectedTime && (
          <View style={styles.summaryCard}>
            <Text style={styles.summaryTitle}>Resumo da Consulta</Text>
            <View style={styles.summaryItem}>
              <Calendar size={16} color="#6B7280" />
              <Text style={styles.summaryText}>
                {availableDates.find(d => d.date === selectedDate)?.label}
              </Text>
            </View>
            <View style={styles.summaryItem}>
              <Clock size={16} color="#6B7280" />
              <Text style={styles.summaryText}>{selectedTime}</Text>
            </View>
            <View style={styles.summaryItem}>
              <User size={16} color="#6B7280" />
              <Text style={styles.summaryText}>
                {consultTypes.find(t => t.id === consultType)?.label}
              </Text>
            </View>
          </View>
        )}

        {/* Schedule Button */}
        <TouchableOpacity
          style={[
            styles.scheduleButton,
            (!selectedDate || !selectedTime || isLoading) && styles.scheduleButtonDisabled
          ]}
          onPress={handleSchedule}
          disabled={!selectedDate || !selectedTime || isLoading}
        >
          <Text style={styles.scheduleButtonText}>
            {isLoading ? 'Agendando...' : 'Confirmar Agendamento'}
          </Text>
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
  },
  caseInfoCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    marginVertical: 12,
    borderLeftWidth: 4,
    borderLeftColor: '#10B981',
  },
  caseInfoHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  caseInfoTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#1F2937',
    marginLeft: 8,
  },
  caseInfoDescription: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
  },
  section: {
    marginVertical: 16,
  },
  sectionTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1F2937',
    marginBottom: 12,
  },
  consultTypeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  consultTypeCard: {
    flex: 1,
    minWidth: '30%',
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#E5E7EB',
  },
  consultTypeCardSelected: {
    borderColor: '#006CFF',
    backgroundColor: '#F0F9FF',
  },
  consultTypeLabel: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#6B7280',
    marginTop: 8,
    marginBottom: 4,
  },
  consultTypeLabelSelected: {
    color: '#006CFF',
  },
  consultTypeDescription: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: '#9CA3AF',
    textAlign: 'center',
  },
  dateGrid: {
    flexDirection: 'row',
    gap: 12,
    paddingVertical: 8,
  },
  dateCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  dateCardSelected: {
    backgroundColor: '#006CFF',
    borderColor: '#006CFF',
  },
  dateLabel: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#6B7280',
  },
  dateLabelSelected: {
    color: '#FFFFFF',
  },
  timeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  timeCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    gap: 8,
  },
  timeCardSelected: {
    backgroundColor: '#006CFF',
    borderColor: '#006CFF',
  },
  timeLabel: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#6B7280',
  },
  timeLabelSelected: {
    color: '#FFFFFF',
  },
  notesInput: {
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#1F2937',
    textAlignVertical: 'top',
  },
  characterCount: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: '#9CA3AF',
    textAlign: 'right',
    marginTop: 4,
  },
  summaryCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    marginVertical: 16,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  summaryTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#1F2937',
    marginBottom: 12,
  },
  summaryItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
    gap: 8,
  },
  summaryText: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
  },
  scheduleButton: {
    backgroundColor: '#006CFF',
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
    marginVertical: 20,
    marginBottom: 40,
  },
  scheduleButtonDisabled: {
    backgroundColor: '#9CA3AF',
  },
  scheduleButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#FFFFFF',
  },
}); 