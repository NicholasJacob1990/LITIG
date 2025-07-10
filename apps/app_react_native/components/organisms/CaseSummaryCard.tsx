import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { TriangleAlert as AlertTriangle, ShieldCheck, Share2, CircleCheck as CircleCheck2, BadgePercent, Eye } from 'lucide-react-native';

// Updated interface to match Gemini API response
interface CaseSummary {
  case_summary: string;
  case_category: string;
  suggested_action: string;
  is_litigious: boolean;
  success_probability?: string; // Optional field
  generatedAt: string; // Keep this for the timestamp
}

interface CaseSummaryCardProps {
  summary: CaseSummary;
  onViewDetails: () => void;
  onShare: () => void;
}

export default function CaseSummaryCard({ 
  summary, 
  onViewDetails, 
  onShare,
}: CaseSummaryCardProps) {

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.headerLeft}>
           <View style={[styles.priorityBadge, { backgroundColor: summary.is_litigious ? '#DC2626' : '#059669' }]}>
            {summary.is_litigious ? <AlertTriangle size={16} color="#FFFFFF" /> : <ShieldCheck size={16} color="#FFFFFF" />}
            <Text style={styles.priorityText}>
              {summary.is_litigious ? 'Contencioso' : 'Não Contencioso'}
            </Text>
          </View>
          <Text style={styles.legalArea}>{summary.case_category}</Text>
        </View>
        <TouchableOpacity onPress={onShare} style={styles.shareButton}>
          <Share2 size={20} color="#6B7280" />
        </TouchableOpacity>
      </View>

      {/* AI Analysis Badge */}
      <View style={styles.aiBadge}>
        <View style={styles.aiGradient}>
          <Text style={styles.aiText}>Análise Preliminar por IA</Text>
          <Text style={styles.aiDisclaimer}>Sujeita a conferência humana</Text>
        </View>
      </View>

      {/* Preliminary Analysis */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Resumo do Caso</Text>
        <Text style={styles.analysisText}>
          {summary.case_summary}
        </Text>
      </View>

      {/* Suggested Action */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Ação Sugerida</Text>
         <View style={styles.documentItem}>
            <CircleCheck2 size={14} color="#059669" />
            <Text style={styles.documentText}>{summary.suggested_action}</Text>
        </View>
      </View>
      
      {/* Success Probability */}
      {summary.is_litigious && summary.success_probability && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Estimativa de Êxito</Text>
          <View style={styles.costItem}>
            <BadgePercent size={16} color="#1E40AF" />
            <Text style={styles.costLabel}>Probabilidade</Text>
            <Text style={styles.costValue}>
              {summary.success_probability}
            </Text>
          </View>
        </View>
      )}

      {/* Actions */}
      <View style={styles.actions}>
        <TouchableOpacity style={styles.viewButton} onPress={onViewDetails}>
          <Eye size={16} color="#1E40AF" />
          <Text style={styles.viewButtonText}>Ver Análise Completa</Text>
        </TouchableOpacity>
      </View>

      {/* Generation Timestamp */}
      <Text style={styles.timestamp}>
        Gerado em {new Date(summary.generatedAt).toLocaleString('pt-BR')}
      </Text>
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
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 12,
    elevation: 6,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 16,
  },
  headerLeft: {
    flex: 1,
  },
  priorityBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
    marginBottom: 8,
    alignSelf: 'flex-start',
  },
  priorityText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 12,
    color: '#FFFFFF',
    marginLeft: 4,
  },
  legalArea: {
    fontFamily: 'Inter-Bold',
    fontSize: 18,
    color: '#1F2937',
  },
  shareButton: {
    padding: 8,
  },
  aiBadge: {
    marginBottom: 16,
    borderRadius: 12,
    overflow: 'hidden',
  },
  aiGradient: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 12,
    backgroundColor: '#7C3AED',
  },
  aiText: {
    fontFamily: 'Inter-Bold',
    fontSize: 14,
    color: '#FFFFFF',
    textAlign: 'center',
  },
  aiDisclaimer: {
    fontFamily: 'Inter-Regular',
    fontSize: 10,
    color: '#E9D5FF',
    textAlign: 'center',
    marginTop: 2,
  },
  section: {
    marginBottom: 16,
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
    paddingTop: 16,
  },
  sectionTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#374151',
    marginBottom: 8,
  },
  analysisText: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
  },
  documentItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F0FDF4',
    padding: 10,
    borderRadius: 8,
    marginBottom: 4,
  },
  documentText: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#14532D',
    marginLeft: 8,
  },
  costItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#EFF6FF',
    padding: 12,
    borderRadius: 8,
  },
  costLabel: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#1E3A8A',
    marginLeft: 8,
    flex: 1,
  },
  costValue: {
    fontFamily: 'Inter-Bold',
    fontSize: 16,
    color: '#1E40AF',
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginTop: 8,
  },
  viewButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#DBEAFE',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 8,
  },
  viewButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
    color: '#1E40AF',
    marginLeft: 8,
  },
  timestamp: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: '#6B7280',
    textAlign: 'center',
    marginTop: 16,
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
    paddingTop: 12,
  },
}); 