import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { Share2, FileText, AlertTriangle, ArrowRight, DollarSign, Edit3, CheckCircle } from 'lucide-react-native';
import Badge from '../atoms/Badge';
import ProgressBar from '../atoms/ProgressBar';

interface CostProps {
  label: string;
  value: string;
}

const CostItem: React.FC<CostProps> = ({ label, value }) => (
  <View style={styles.costItem}>
    <View style={styles.costIcon}>
      <DollarSign size={20} color="#059669" />
    </View>
    <View>
      <Text style={styles.costLabel}>{label}</Text>
      <Text style={styles.costValue}>{value}</Text>
    </View>
  </View>
);

interface UnifiedAnalysisCardProps {
  priority: 'high' | 'medium' | 'low';
  area: string;
  analysisText: string;
  requiredDocuments: string[];
  consultationFee: number;
  representationFee: number;
  riskLevel: 'low' | 'medium' | 'high';
  riskDescription: string;
  urgencyLevel: number;
  isLawyer?: boolean;
  onViewFullAnalysis: () => void;
  onValidateAndEdit?: () => void;
  onShare: () => void;
}

const UnifiedAnalysisCard: React.FC<UnifiedAnalysisCardProps> = ({
  priority,
  area,
  analysisText,
  requiredDocuments,
  consultationFee,
  representationFee,
  riskLevel,
  riskDescription,
  urgencyLevel,
  isLawyer = false,
  onViewFullAnalysis,
  onValidateAndEdit,
  onShare
}) => {
  const formatCurrency = (value: number) => 
    new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value);

  const getRiskBadgeIntent = (level: typeof riskLevel) => {
    if (level === 'high') return 'danger';
    if (level === 'medium') return 'warning';
    return 'success';
  };
  
  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Badge label={priority} intent={priority === 'high' ? 'highlight' : 'warning'} size="medium" />
        <TouchableOpacity onPress={onShare}>
          <Share2 size={22} color="#64748B" />
        </TouchableOpacity>
      </View>
      
      <Text style={styles.areaTitle}>{area}</Text>
      
      <View style={styles.aiChip}>
        <Text style={styles.aiChipText}>Análise Preliminar por IA</Text>
        <Text style={styles.aiChipSubtext}>Sujeita a conferência humana</Text>
      </View>

      {/* Botão de Validação para Advogados */}
      {isLawyer && onValidateAndEdit && (
        <TouchableOpacity style={styles.validateButton} onPress={onValidateAndEdit}>
          <CheckCircle size={18} color="#059669" />
          <Text style={styles.validateButtonText}>Validar e Editar Análise</Text>
          <Edit3 size={16} color="#059669" />
        </TouchableOpacity>
      )}

      <View style={styles.urgencyContainer}>
        <Text style={styles.sectionTitle}>Nível de Urgência</Text>
        <Text style={styles.urgencyLabel}>{urgencyLevel}/10</Text>
      </View>
      <ProgressBar value={urgencyLevel} />

      <Text style={styles.sectionTitle}>Análise Preliminar</Text>
      <Text style={styles.descriptionText}>{analysisText}</Text>
      
      <Text style={styles.sectionTitle}>Documentos Necessários</Text>
      <View style={styles.documentList}>
        {requiredDocuments.slice(0, 3).map((doc, index) => (
          <View key={index} style={styles.documentItem}>
            <FileText size={18} color="#475569" />
            <Text style={styles.documentText}>{doc}</Text>
          </View>
        ))}
        {requiredDocuments.length > 3 && (
           <Text style={styles.moreDocumentsText}>+ {requiredDocuments.length - 3} documentos adicionais</Text>
        )}
      </View>

      <Text style={styles.sectionTitle}>Estimativa de Custos</Text>
      <View style={styles.costContainer}>
        <CostItem label="Consulta" value={formatCurrency(consultationFee)} />
        <CostItem label="Representação" value={formatCurrency(representationFee)} />
      </View>

      <Text style={styles.sectionTitle}>Avaliação de Risco</Text>
      <View style={styles.riskContainer}>
        <Badge label={`Risco ${riskLevel}`} intent={getRiskBadgeIntent(riskLevel)} variant="subtle" size="large"/>
        <Text style={styles.descriptionText}>{riskDescription}</Text>
      </View>
      
      <TouchableOpacity style={styles.fullAnalysisButton} onPress={onViewFullAnalysis}>
        <Text style={styles.fullAnalysisButtonText}>Ver Análise Completa</Text>
        <ArrowRight size={16} color="#3B82F6" />
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    marginHorizontal: 16,
    marginTop: 24,
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    shadowColor: '#9FB0C2',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 12,
    elevation: 4,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  areaTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: '#1E293B',
    marginBottom: 12,
  },
  aiChip: {
    backgroundColor: '#6D28D9',
    borderRadius: 12,
    paddingVertical: 12,
    paddingHorizontal: 16,
    alignItems: 'center',
    marginBottom: 20,
  },
  aiChipText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  aiChipSubtext: {
    color: '#EDE9FE',
    fontSize: 12,
    marginTop: 2,
  },
  validateButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#F0FDF4',
    borderWidth: 1,
    borderColor: '#BBF7D0',
    borderRadius: 12,
    paddingVertical: 12,
    paddingHorizontal: 16,
    marginBottom: 20,
    gap: 8,
  },
  validateButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#059669',
    flex: 1,
    textAlign: 'center',
  },
  urgencyContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 16,
    marginBottom: 8,
  },
  urgencyLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#334155',
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#334155',
    marginBottom: 12,
    marginTop: 16,
  },
  descriptionText: {
    fontSize: 14,
    color: '#475569',
    lineHeight: 20,
  },
  documentList: {
    gap: 12,
  },
  documentItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  documentText: {
    fontSize: 14,
    color: '#334155',
  },
  moreDocumentsText: {
    fontSize: 13,
    color: '#64748B',
    fontStyle: 'italic',
    marginTop: 4,
  },
  costContainer: {
    flexDirection: 'row',
    gap: 16,
  },
  costItem: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F0FDF4',
    borderRadius: 12,
    padding: 12,
    gap: 10,
  },
  costIcon: {
    backgroundColor: '#D1FAE5',
    borderRadius: 20,
    width: 40,
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
  },
  costLabel: {
    fontSize: 13,
    color: '#065F46',
  },
  costValue: {
    fontSize: 16,
    fontWeight: '700',
    color: '#047857',
  },
  riskContainer: {
    backgroundColor: '#F8FAFC',
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    gap: 12,
  },
  fullAnalysisButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    marginTop: 24,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  fullAnalysisButtonText: {
    color: '#3B82F6',
    fontSize: 14,
    fontWeight: '600',
    marginRight: 6,
  },
});

export default UnifiedAnalysisCard; 