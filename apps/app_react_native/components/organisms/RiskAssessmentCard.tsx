import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { ShieldCheck, AlertTriangle, ShieldAlert } from 'lucide-react-native';
import Badge from '../atoms/Badge';

interface RiskAssessmentCardProps {
  riskLevel: 'low' | 'medium' | 'high';
  details: string;
}

const RiskAssessmentCard: React.FC<RiskAssessmentCardProps> = ({ riskLevel, details }) => {
  const getRiskInfo = () => {
    switch (riskLevel) {
      case 'low':
        return {
          icon: <ShieldCheck size={24} color="#10B981" />,
          title: 'Risco Baixo',
          color: '#10B981',
          backgroundColor: '#D1FAE5',
        };
      case 'medium':
        return {
          icon: <AlertTriangle size={24} color="#F59E0B" />,
          title: 'Risco Médio',
          color: '#D97706',
          backgroundColor: '#FEF3C7',
        };
      case 'high':
        return {
          icon: <ShieldAlert size={24} color="#EF4444" />,
          title: 'Risco Alto',
          color: '#DC2626',
          backgroundColor: '#FEE2E2',
        };
    }
  };

  const riskInfo = getRiskInfo();

  return (
    <View style={styles.container}>
      <Text style={styles.sectionTitle}>Avaliação de Risco</Text>
      <View style={[styles.card, { borderLeftColor: riskInfo.color }]}>
        <View style={styles.header}>
          {riskInfo.icon}
          <Text style={[styles.title, { color: riskInfo.color }]}>{riskInfo.title}</Text>
        </View>
        <Text style={styles.details}>{details}</Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 16,
    paddingTop: 24,
    paddingBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1E293B',
    marginBottom: 12,
  },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    borderLeftWidth: 4,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 8,
  },
  title: {
    fontSize: 16,
    fontWeight: '700',
  },
  details: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
  },
});

export default RiskAssessmentCard; 