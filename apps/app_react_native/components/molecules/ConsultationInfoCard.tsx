import React from 'react';
import { View, Text, StyleSheet, ActivityIndicator, TouchableOpacity } from 'react-native';
import { Calendar, Clock, Video, FileText, Plus } from 'lucide-react-native';

interface InfoItemProps {
  icon: React.ComponentType<{ size: number; color: string }>;
  label: string;
  value: string;
}

const InfoItem: React.FC<InfoItemProps> = ({ icon: Icon, label, value }) => (
  <View style={styles.infoItem}>
    <View style={styles.labelContainer}>
      <Icon size={16} color="#6B7280" />
      <Text style={styles.label}>{label}:</Text>
    </View>
    <Text style={styles.value}>{value}</Text>
  </View>
);

interface ConsultationInfoCardProps {
  date: string;
  duration: string;
  modality: string;
  plan: string;
  loading?: boolean;
  onScheduleConsultation?: () => void;
}

const ConsultationInfoCard: React.FC<ConsultationInfoCardProps> = ({
  date,
  duration,
  modality,
  plan,
  loading = false,
  onScheduleConsultation,
}) => {
  if (loading) {
    return (
      <View style={styles.container}>
        <Text style={styles.sectionTitle}>Informações da Consulta</Text>
        <View style={styles.loadingCard}>
          <ActivityIndicator size="small" color="#3B82F6" />
          <Text style={styles.loadingText}>Carregando informações da consulta...</Text>
        </View>
      </View>
    );
  }

  const hasConsultation = date !== 'Aguardando agendamento';

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.sectionTitle}>Informações da Consulta</Text>
        {onScheduleConsultation && (
          <TouchableOpacity style={styles.scheduleButton} onPress={onScheduleConsultation}>
            <Plus size={16} color="#3B82F6" />
            <Text style={styles.scheduleButtonText}>
              {hasConsultation ? 'Nova' : 'Agendar'}
            </Text>
          </TouchableOpacity>
        )}
      </View>
      <View style={styles.card}>
        <InfoItem icon={Calendar} label="Data da Consulta" value={date} />
        <View style={styles.divider} />
        <InfoItem icon={Clock} label="Duração" value={duration} />
        <View style={styles.divider} />
        <InfoItem icon={Video} label="Modalidade" value={modality} />
        <View style={styles.divider} />
        <InfoItem icon={FileText} label="Plano" value={plan} />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 16,
    paddingTop: 24,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1E293B',
  },
  scheduleButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#EFF6FF',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
    gap: 4,
  },
  scheduleButtonText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#3B82F6',
  },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  loadingCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 24,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  loadingText: {
    fontSize: 14,
    color: '#6B7280',
    marginTop: 8,
  },
  infoItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 10,
  },
  labelContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  label: {
    fontSize: 14,
    color: '#4B5563',
  },
  value: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
  },
  divider: {
    height: 1,
    backgroundColor: '#F3F4F6',
    marginVertical: 4,
  },
});

export default ConsultationInfoCard; 