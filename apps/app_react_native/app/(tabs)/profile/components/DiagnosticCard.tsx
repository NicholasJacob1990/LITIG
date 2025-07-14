import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { AlertTriangle, ChevronDown, ChevronUp, Target } from 'lucide-react-native';
import { WeakPoint, Suggestion } from '@/lib/services/types';

interface DiagnosticCardProps {
  weakPoint: WeakPoint;
  suggestion: Suggestion;
}

const DiagnosticCard: React.FC<DiagnosticCardProps> = ({ weakPoint, suggestion }) => {
  const [isExpanded, setIsExpanded] = useState(false);
  
  const getImpactColor = () => {
    if (weakPoint.improvement_potential === 'Alto') return '#EF4444';
    if (weakPoint.improvement_potential === 'Médio') return '#F59E0B';
    return '#10B981';
  }

  return (
    <View style={styles.container}>
      <TouchableOpacity style={styles.header} onPress={() => setIsExpanded(!isExpanded)}>
        <View style={styles.headerLeft}>
          <AlertTriangle color={getImpactColor()} size={24} />
          <View style={styles.headerTextContainer}>
            <Text style={styles.title}>{weakPoint.feature_label}</Text>
            <Text style={[styles.impact, { color: getImpactColor() }]}>
              Potencial de Melhoria: {weakPoint.improvement_potential}
            </Text>
          </View>
        </View>
        {isExpanded ? <ChevronUp color="#6B7280" /> : <ChevronDown color="#6B7280" />}
      </TouchableOpacity>
      
      {isExpanded && (
        <View style={styles.content}>
          <Text style={styles.sectionTitle}>Diagnóstico</Text>
          <Text style={styles.description}>
            Sua performance em "{weakPoint.feature_label}" está abaixo da média do mercado, 
            o que pode estar impactando negativamente seu ranking de compatibilidade.
          </Text>
          <View style={styles.metricsRow}>
            <View style={styles.metric}>
              <Text style={styles.metricValue}>{weakPoint.current_value.toFixed(1)}</Text>
              <Text style={styles.metricLabel}>Sua Métrica</Text>
            </View>
            <View style={styles.metric}>
              <Text style={styles.metricValue}>{weakPoint.benchmark_p50.toFixed(1)}</Text>
              <Text style={styles.metricLabel}>Média Mercado</Text>
            </View>
          </View>

          <View style={styles.separator} />
          
          <Text style={styles.sectionTitle}>Plano de Ação</Text>
          <View style={styles.suggestionHeader}>
             <Target color="#3B82F6" size={20} />
             <Text style={styles.suggestionTitle}>{suggestion.title}</Text>
          </View>
          <Text style={styles.suggestionDescription}>{suggestion.description}</Text>
          <View>
            {suggestion.action_items.map((item, index) => (
              <Text key={index} style={styles.actionItem}>• {item}</Text>
            ))}
          </View>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    marginHorizontal: 16,
    marginBottom: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerTextContainer: {
    marginLeft: 12,
  },
  title: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
  },
  impact: {
    fontSize: 13,
    fontWeight: '500',
  },
  content: {
    marginTop: 16,
  },
  sectionTitle: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#374151',
    marginBottom: 8,
  },
  description: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
    marginBottom: 12,
  },
  metricsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    backgroundColor: '#F9FAFB',
    borderRadius: 8,
    padding: 12,
    marginBottom: 16,
  },
  metric: {
    alignItems: 'center',
  },
  metricValue: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1E40AF',
  },
  metricLabel: {
    fontSize: 12,
    color: '#6B7280',
    marginTop: 4,
  },
  separator: {
    height: 1,
    backgroundColor: '#E5E7EB',
    marginVertical: 16,
  },
  suggestionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  suggestionTitle: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#3B82F6',
    marginLeft: 8,
  },
  suggestionDescription: {
    fontSize: 14,
    color: '#4B5563',
    marginBottom: 12,
  },
  actionItem: {
    fontSize: 14,
    color: '#4B5563',
    marginBottom: 4,
    lineHeight: 20,
  }
});

export default DiagnosticCard; 