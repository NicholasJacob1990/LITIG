import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { FileText, Tag, Clock, BarChart2 } from 'lucide-react-native';

interface MyCaseCardProps {
    caseData: {
        id: string;
        created_at: string;
        ai_analysis: any; // Idealmente, tipar a estrutura da análise
    };
}

const MyCaseCard = ({ caseData }: MyCaseCardProps) => {
  const { ai_analysis, created_at } = caseData;
  
  // Adiciona verificação de segurança para os dados da análise
  const classificacao = ai_analysis?.classificacao;
  const analiseExito = ai_analysis?.analise_exito;
  const urgencia = ai_analysis?.urgencia;
  
  const assuntoPrincipal = classificacao?.assunto_principal ?? 'Caso não especificado';
  const areaPrincipal = classificacao?.area_principal ?? 'Área não identificada';
  const subarea = classificacao?.subarea ?? '';
  const probabilidade = analiseExito?.classificacao ?? 'Não avaliada';
  const complexidade = analiseExito?.complexidade ?? 'Não avaliada';
  const nivelUrgencia = urgencia?.nivel ?? 'Baixa';

  const getProbabilityColor = (probability: string) => {
    switch (probability?.toLowerCase()) {
      case 'alta':
        return '#10B981'; // Verde
      case 'média':
        return '#F59E0B'; // Amarelo
      case 'baixa':
        return '#EF4444'; // Vermelho
      default:
        return '#6B7280'; // Cinza
    }
  };

  const getUrgencyColor = (urgency: string) => {
    switch (urgency?.toLowerCase()) {
      case 'crítica':
        return '#DC2626'; // Vermelho escuro
      case 'alta':
        return '#EF4444'; // Vermelho
      case 'média':
        return '#F59E0B'; // Amarelo
      case 'baixa':
        return '#10B981'; // Verde
      default:
        return '#6B7280'; // Cinza
    }
  };

  return (
    <TouchableOpacity style={styles.card}>
      <View style={styles.header}>
        <FileText size={24} color="#4B5563" />
        <Text style={styles.title} numberOfLines={2}>
          {assuntoPrincipal}
        </Text>
        {nivelUrgencia !== 'Baixa' && nivelUrgencia !== 'Não avaliada' && (
          <View style={[styles.urgencyBadge, { backgroundColor: getUrgencyColor(nivelUrgencia) }]}>
            <Text style={styles.urgencyText}>{nivelUrgencia}</Text>
          </View>
        )}
      </View>
      <View style={styles.tagContainer}>
        <View style={styles.tag}>
          <Tag size={14} color="#1D4ED8" />
          <Text style={styles.tagText}>
            {areaPrincipal}{subarea ? ` - ${subarea}` : ''}
          </Text>
        </View>
        <View style={styles.tag}>
          <Clock size={14} color="#6B7280" />
          <Text style={styles.tagText}>
            {new Date(created_at).toLocaleDateString('pt-BR')}
          </Text>
        </View>
        {complexidade !== 'Não avaliada' && (
          <View style={styles.tag}>
            <BarChart2 size={14} color="#6B7280" />
            <Text style={styles.tagText}>Complexidade: {complexidade}</Text>
          </View>
        )}
      </View>
      <View style={styles.footer}>
        <Text style={styles.footerLabel}>Chance de Êxito:</Text>
        <View style={styles.probabilityContainer}>
            <BarChart2 size={16} color={getProbabilityColor(probabilidade)} />
            <Text style={[styles.probabilityText, { color: getProbabilityColor(probabilidade) }]}>
                {probabilidade}
            </Text>
        </View>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    marginVertical: 8,
    marginHorizontal: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  title: {
    fontFamily: 'Inter-Bold',
    fontSize: 18,
    color: '#1F2937',
    marginLeft: 12,
    flex: 1,
  },
  tagContainer: {
    flexDirection: 'row',
    gap: 16,
    marginBottom: 16,
    flexWrap: 'wrap',
  },
  tag: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F3F4F6',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
  },
  tagText: {
    fontFamily: 'Inter-Medium',
    fontSize: 12,
    color: '#4B5563',
    marginLeft: 6,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
    paddingTop: 12,
  },
  footerLabel: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
  },
  probabilityContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6
  },
  probabilityText: {
    fontFamily: 'Inter-Bold',
    fontSize: 14,
  },
  urgencyBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
    marginLeft: 8,
  },
  urgencyText: {
    fontFamily: 'Inter-Medium',
    fontSize: 12,
    color: '#FFFFFF',
  },
});

export default MyCaseCard; 