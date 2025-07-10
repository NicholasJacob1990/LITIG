import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { DollarSign, Clock, TrendingUp, FileText } from 'lucide-react-native';
import MoneyTile from '../atoms/MoneyTile';

interface CostEstimateProps {
  consultationFee: number;
  representationFee: number;
  feeType: 'fixed' | 'success' | 'hourly' | 'plan' | 'mixed';
  successPercentage?: number;
  hourlyRate?: number;
  planType?: string;
  paymentTerms?: string;
}

export default function CostEstimate({
  consultationFee,
  representationFee,
  feeType,
  successPercentage,
  hourlyRate,
  planType,
  paymentTerms
}: CostEstimateProps) {

  const renderConsultationFee = () => {
    if (consultationFee <= 0) return null;
    
    return (
      <MoneyTile
        value={consultationFee}
        label="Consulta"
        size="medium"
        variant="secondary"
      />
    );
  };

  const renderRepresentationFee = () => {
    switch (feeType) {
      case 'fixed':
      case 'mixed':
        if (representationFee <= 0) return null;
        return (
          <MoneyTile
            value={representationFee}
            label="Representação"
            size="medium"
            variant="primary"
          />
        );

      case 'success':
        return (
          <View style={styles.successFeeContainer}>
            <View style={styles.successHeader}>
              <TrendingUp size={16} color="#F59E0B" />
              <Text style={styles.successLabel}>Honorários por Êxito</Text>
            </View>
            <Text style={styles.successPercentage}>
              {successPercentage || 20}% do valor obtido
            </Text>
            <Text style={styles.successNote}>
              Só paga se ganhar o caso
            </Text>
          </View>
        );

      case 'hourly':
        return (
          <View style={styles.hourlyFeeContainer}>
            <View style={styles.hourlyHeader}>
              <Clock size={16} color="#8B5CF6" />
              <Text style={styles.hourlyLabel}>Cobrança por Hora</Text>
            </View>
            <Text style={styles.hourlyRate}>
              R$ {hourlyRate?.toFixed(2) || '200,00'}/hora
            </Text>
            <Text style={styles.hourlyNote}>
              Valor final depende do tempo gasto
            </Text>
          </View>
        );

      case 'plan':
        return (
          <View style={styles.planFeeContainer}>
            <View style={styles.planHeader}>
              <FileText size={16} color="#EF4444" />
              <Text style={styles.planLabel}>Plano {planType || 'Mensal'}</Text>
            </View>
            <Text style={styles.planValue}>
              R$ {representationFee?.toFixed(2) || '500,00'}
            </Text>
            <Text style={styles.planNote}>
              Inclui consultoria jurídica
            </Text>
          </View>
        );

      default:
        return null;
    }
  };

  const getTotalEstimate = () => {
    if (feeType === 'success') {
      return consultationFee; // Só a consulta é fixa
    }
    if (feeType === 'hourly') {
      return consultationFee; // Representação é variável
    }
    return consultationFee + representationFee;
  };

  const shouldShowTotal = () => {
    return feeType === 'fixed' || feeType === 'mixed' || feeType === 'plan';
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Estimativa de Custos</Text>
      
      <View style={styles.feesContainer}>
        {renderConsultationFee()}
        {renderRepresentationFee()}
      </View>

      {shouldShowTotal() && (
        <View style={styles.totalContainer}>
                     <MoneyTile
             value={getTotalEstimate()}
             label="Total Estimado"
             size="large"
             variant="primary"
           />
        </View>
      )}

      {paymentTerms && (
        <View style={styles.termsContainer}>
          <Text style={styles.termsTitle}>Condições de Pagamento</Text>
          <Text style={styles.termsText}>{paymentTerms}</Text>
        </View>
      )}

      {(feeType === 'success' || feeType === 'hourly') && (
        <View style={styles.disclaimerContainer}>
          <Text style={styles.disclaimerText}>
            {feeType === 'success' 
              ? '* Honorários de êxito só são cobrados em caso de resultado positivo'
              : '* Valor final será calculado com base no tempo efetivamente trabalhado'
            }
          </Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#F8FAFC',
    borderRadius: 12,
    padding: 16,
    marginVertical: 8,
  },
  title: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1F2937',
    marginBottom: 16,
  },
  feesContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
    marginBottom: 16,
  },
  successFeeContainer: {
    flex: 1,
    backgroundColor: '#FEF3C7',
    borderRadius: 8,
    padding: 12,
    alignItems: 'center',
  },
  successHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 8,
  },
  successLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#92400E',
  },
  successPercentage: {
    fontSize: 20,
    fontWeight: '700',
    color: '#92400E',
    marginBottom: 4,
  },
  successNote: {
    fontSize: 12,
    color: '#78350F',
    textAlign: 'center',
  },
  hourlyFeeContainer: {
    flex: 1,
    backgroundColor: '#EDE9FE',
    borderRadius: 8,
    padding: 12,
    alignItems: 'center',
  },
  hourlyHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 8,
  },
  hourlyLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#5B21B6',
  },
  hourlyRate: {
    fontSize: 18,
    fontWeight: '700',
    color: '#5B21B6',
    marginBottom: 4,
  },
  hourlyNote: {
    fontSize: 12,
    color: '#4C1D95',
    textAlign: 'center',
  },
  planFeeContainer: {
    flex: 1,
    backgroundColor: '#FEE2E2',
    borderRadius: 8,
    padding: 12,
    alignItems: 'center',
  },
  planHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 8,
  },
  planLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#B91C1C',
  },
  planValue: {
    fontSize: 18,
    fontWeight: '700',
    color: '#B91C1C',
    marginBottom: 4,
  },
  planNote: {
    fontSize: 12,
    color: '#991B1B',
    textAlign: 'center',
  },
  totalContainer: {
    alignItems: 'center',
    marginVertical: 12,
  },
  termsContainer: {
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    padding: 12,
    marginTop: 12,
    borderLeftWidth: 4,
    borderLeftColor: '#3B82F6',
  },
  termsTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 6,
  },
  termsText: {
    fontSize: 13,
    color: '#4B5563',
    lineHeight: 18,
  },
  disclaimerContainer: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
  },
  disclaimerText: {
    fontSize: 12,
    color: '#6B7280',
    fontStyle: 'italic',
    textAlign: 'center',
  },
}); 