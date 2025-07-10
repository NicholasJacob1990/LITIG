import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { Briefcase, AlertTriangle, FileText, DollarSign, Shield, ArrowRight } from 'lucide-react-native';
import Badge from '../atoms/Badge';
import ProgressBar from '../atoms/ProgressBar';

type PreAnalysisCardProps = {
  area: string;
  priority: 'high' | 'medium' | 'low';
  urgencyLevel: number;
  summary: string;
  requiredDocuments: string[];
  consultationCost: number;
  representationCost: number;
  riskAssessment: string;
  onViewFull: () => void;
};

const PreAnalysisCard: React.FC<PreAnalysisCardProps> = ({
  area,
  priority,
  urgencyLevel,
  summary,
  requiredDocuments,
  consultationCost,
  representationCost,
  riskAssessment,
  onViewFull,
}) => {
  const urgencyColor = urgencyLevel > 7 ? '#EF4444' : urgencyLevel > 4 ? '#F59E0B' : '#10B981';

  return (
      <View style={styles.card}>
      {/* Header */}
        <View style={styles.header}>
        <View style={styles.headerTitleContainer}>
          <Badge label={priority.toUpperCase()} intent={priority === 'high' ? 'danger' : priority === 'medium' ? 'warning' : 'success'} outline />
          <Text style={styles.areaText}>{area}</Text>
        </View>
        <TouchableOpacity style={styles.aiButton}>
          <Text style={styles.aiButtonText}>Análise Preliminar por IA</Text>
          <Text style={styles.aiButtonSubtitle}>Sujeita a conferência humana</Text>
        </TouchableOpacity>
      </View>

      {/* Metrics */}
      <View style={styles.metricsContainer}>
        <View style={styles.metricItem}>
          <Text style={styles.metricLabel}>Nível de Urgência</Text>
          <ProgressBar value={urgencyLevel} color={urgencyColor} />
        </View>
      </View>

      {/* Preliminary Analysis */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Análise Preliminar</Text>
        <Text style={styles.sectionText}>{summary}</Text>
      </View>

      {/* Required Documents */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Documentos Necessários</Text>
        {requiredDocuments.map((doc, index) => (
          <View key={index} style={styles.documentItem}>
            <FileText size={16} color="#475569" />
            <Text style={styles.documentText}>{doc}</Text>
          </View>
        ))}
      </View>

      {/* Cost Estimation */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Estimativa de Custos</Text>
        <View style={styles.costContainer}>
          <View style={styles.costItem}>
            <DollarSign size={20} color="#34D399" />
            <View>
              <Text style={styles.costLabel}>Consulta</Text>
              <Text style={styles.costValue}>R$ {consultationCost.toFixed(2)}</Text>
            </View>
          </View>
          <View style={styles.costItem}>
            <Briefcase size={20} color="#60A5FA" />
            <View>
              <Text style={styles.costLabel}>Representação</Text>
              <Text style={styles.costValue}>R$ {representationCost.toFixed(2)}</Text>
            </View>
          </View>
        </View>
      </View>

      {/* Risk Assessment */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Avaliação de Risco</Text>
        <View style={styles.riskContainer}>
          <Shield size={16} color="#475569" />
          <Text style={styles.sectionText}>{riskAssessment}</Text>
        </View>
      </View>

      {/* View Full Analysis Button */}
      <TouchableOpacity style={styles.viewFullButton} onPress={onViewFull}>
        <Text style={styles.viewFullButtonText}>Ver Análise Completa</Text>
        <ArrowRight size={16} color="#3B82F6" />
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  header: {
    marginBottom: 20,
  },
  headerTitleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 12,
  },
  areaText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1E293B',
  },
  aiButton: {
    backgroundColor: '#6366F1',
    borderRadius: 12,
    padding: 12,
    alignItems: 'center',
  },
  aiButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#FFFFFF',
  },
  aiButtonSubtitle: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
    marginTop: 2,
  },
  metricsContainer: {
    marginBottom: 20,
    gap: 16,
  },
  metricItem: {},
  metricLabel: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#475569',
    marginBottom: 8,
  },
  section: {
    marginBottom: 20,
  },
  sectionTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#334155',
    marginBottom: 12,
  },
  sectionText: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#475569',
    lineHeight: 20,
  },
  documentItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 4,
  },
  documentText: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#475569',
  },
  costContainer: {
    flexDirection: 'row',
    gap: 16,
  },
  costItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    flex: 1,
  },
  costLabel: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#64748B',
  },
  costValue: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#1E293B',
  },
  riskContainer: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 8,
  },
  viewFullButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 12,
    borderTopWidth: 1,
    borderTopColor: '#E2E8F0',
    marginTop: 12,
  },
  viewFullButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
    color: '#3B82F6',
    marginRight: 8,
  },
});

export default PreAnalysisCard; 