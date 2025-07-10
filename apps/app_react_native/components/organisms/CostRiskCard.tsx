import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { TrendingUp, AlertTriangle } from 'lucide-react-native';
import MoneyTile from '../atoms/MoneyTile';
import ProgressBar from '../atoms/ProgressBar';
import Badge from '../atoms/Badge';

interface CostRiskCardProps {
  consultationCost: number;
  representationCost: number;
  riskLevel: 'low' | 'medium' | 'high';
  riskScore: number; // 0-10
  successProbability: number; // 0-100
}

export default function CostRiskCard({
  consultationCost,
  representationCost,
  riskLevel,
  riskScore,
  successProbability
}: CostRiskCardProps) {
  const getRiskBadgeIntent = () => {
    switch (riskLevel) {
      case 'low':
        return 'success';
      case 'medium':
        return 'warning';
      case 'high':
        return 'danger';
      default:
        return 'neutral';
    }
  };

  const getRiskText = () => {
    switch (riskLevel) {
      case 'low':
        return 'Risco Baixo';
      case 'medium':
        return 'Risco Médio';
      case 'high':
        return 'Risco Alto';
      default:
        return 'Risco Indefinido';
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Estimativa de Custos e Riscos</Text>
      
      {/* Cost Section */}
      <View style={styles.costsContainer}>
        <MoneyTile
          value={consultationCost}
          label="Consulta"
          size="medium"
          variant="primary"
        />
        <MoneyTile
          value={representationCost}
          label="Representação"
          size="medium"
          variant="secondary"
        />
      </View>

      {/* Risk Section */}
      <View style={styles.riskContainer}>
        <View style={styles.riskHeader}>
          <AlertTriangle size={20} color="#F5A623" />
          <Text style={styles.riskTitle}>Análise de Risco</Text>
          <Badge 
            label={getRiskText()}
            intent={getRiskBadgeIntent()}
            size="small"
          />
        </View>

        <View style={styles.riskMetrics}>
          <View style={styles.riskMetric}>
            <Text style={styles.metricLabel}>Nível de Risco</Text>
            <ProgressBar 
              value={riskScore} 
              maxValue={10} 
              height={8}
            />
            <Text style={styles.metricValue}>{riskScore}/10</Text>
          </View>

          <View style={styles.riskMetric}>
            <Text style={styles.metricLabel}>Probabilidade de Êxito</Text>
            <ProgressBar 
              value={successProbability} 
              maxValue={100} 
              height={8}
            />
            <Text style={styles.metricValue}>{successProbability}%</Text>
          </View>
        </View>

        <View style={styles.successContainer}>
          <TrendingUp size={16} color="#1DB57C" />
          <Text style={styles.successText}>
            Baseado em casos similares analisados
          </Text>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  title: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1F2937',
    marginBottom: 16,
  },
  costsContainer: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 20,
  },
  riskContainer: {
    gap: 16,
  },
  riskHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  riskTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#1F2937',
    flex: 1,
  },
  riskMetrics: {
    gap: 16,
  },
  riskMetric: {
    gap: 8,
  },
  metricLabel: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#374151',
  },
  metricValue: {
    fontFamily: 'Inter-Bold',
    fontSize: 14,
    color: '#1F2937',
    textAlign: 'right',
  },
  successContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: '#F0FDF4',
    padding: 12,
    borderRadius: 8,
  },
  successText: {
    fontFamily: 'Inter-Regular',
    fontSize: 13,
    color: '#166534',
    flex: 1,
  },
}); 