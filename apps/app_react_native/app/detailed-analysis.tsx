import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  RefreshControl,
} from 'react-native';
import {
  Brain,
  Scale,
  AlertTriangle,
  CheckCircle,
  XCircle,
  TrendingUp,
  TrendingDown,
  Clock,
  DollarSign,
  FileText,
  Users,
  Gavel,
} from 'lucide-react-native';
import { StatusBar } from 'expo-status-bar';
import { useLocalSearchParams, useRouter } from 'expo-router';
import TopBar from '@/components/layout/TopBar';

interface DetailedAnalysis {
  id: string;
  case_id: string;
  generated_at: string;
  confidence: number;
  classificacao: {
    area_principal: string;
    sub_areas: string[];
    complexidade: 'baixa' | 'media' | 'alta';
    urgencia: 'baixa' | 'media' | 'alta';
  };
  analise_viabilidade: {
    classificacao: 'viavel' | 'parcialmente_viavel' | 'inviavel';
    probabilidade_sucesso: number;
    riscos_identificados: string[];
    pontos_fortes: string[];
  };
  analise_juridica: {
    fundamentos_legais: string[];
    precedentes_relevantes: string[];
    estrategias_sugeridas: string[];
    documentos_necessarios: string[];
  };
  analise_financeira: {
    custo_estimado_min: number;
    custo_estimado_max: number;
    tempo_estimado_meses: number;
    valor_causa_estimado?: number;
  };
  recomendacoes: {
    proximos_passos: string[];
    prazo_urgencia?: string;
    especialista_recomendado?: string;
  };
}

export default function DetailedAnalysis() {
  const router = useRouter();
  const params = useLocalSearchParams<{ caseId?: string }>();
  const caseId = params?.caseId;

  const [analysis, setAnalysis] = useState<DetailedAnalysis | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  // Mock data - em produção, buscar do backend
  const mockAnalysis: DetailedAnalysis = {
    id: 'analysis-1',
    case_id: caseId || '',
    generated_at: '2025-01-04T10:30:00Z',
    confidence: 87,
    classificacao: {
      area_principal: 'Direito Trabalhista',
      sub_areas: ['Rescisão Contratual', 'Verbas Rescisórias'],
      complexidade: 'media',
      urgencia: 'alta',
    },
    analise_viabilidade: {
      classificacao: 'viavel',
      probabilidade_sucesso: 78,
      riscos_identificados: [
        'Possível contestação do empregador sobre justa causa',
        'Necessidade de comprovação documental das horas extras',
        'Prazo de prescrição próximo ao limite',
      ],
      pontos_fortes: [
        'Documentação trabalhista bem preservada',
        'Testemunhas disponíveis para depor',
        'Jurisprudência favorável na região',
      ],
    },
    analise_juridica: {
      fundamentos_legais: [
        'Art. 477 da CLT - Rescisão do contrato de trabalho',
        'Art. 59 da CLT - Horas extraordinárias',
        'Súmula 331 do TST - Contrato de prestação de serviços',
      ],
      precedentes_relevantes: [
        'TST-RR-123456-78.2023.5.02.0001',
        'TRT-2 RO-987654-32.2023.5.02.0010',
      ],
      estrategias_sugeridas: [
        'Requerer tutela de urgência para pagamento das verbas rescisórias',
        'Solicitar perícia contábil para apuração das horas extras',
        'Arrolar testemunhas para comprovar jornada de trabalho',
      ],
      documentos_necessarios: [
        'Carteira de trabalho',
        'Contracheques dos últimos 12 meses',
        'Comprovante de rescisão ou comunicado de demissão',
        'Controle de ponto (se houver)',
      ],
    },
    analise_financeira: {
      custo_estimado_min: 2500,
      custo_estimado_max: 8000,
      tempo_estimado_meses: 18,
      valor_causa_estimado: 45000,
    },
    recomendacoes: {
      proximos_passos: [
        'Reunir toda a documentação trabalhista',
        'Agendar consulta com advogado especialista',
        'Protocolar reclamação trabalhista em até 30 dias',
      ],
      prazo_urgencia: '30 dias',
      especialista_recomendado: 'Advogado com especialização em Direito do Trabalho',
    },
  };

  useEffect(() => {
    if (caseId) {
      loadAnalysis();
    }
  }, [caseId]);

  const loadAnalysis = async () => {
    try {
      setLoading(true);
      // Simular carregamento - em produção, chamar API
      await new Promise(resolve => setTimeout(resolve, 1500));
      setAnalysis(mockAnalysis);
    } catch (error) {
      console.error('Error loading detailed analysis:', error);
      Alert.alert('Erro', 'Não foi possível carregar a análise detalhada');
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadAnalysis();
    setRefreshing(false);
  };

  const getComplexityColor = (complexity: string) => {
    switch (complexity) {
      case 'baixa': return '#10B981';
      case 'media': return '#F59E0B';
      case 'alta': return '#EF4444';
      default: return '#6B7280';
    }
  };

  const getViabilityIcon = (classification: string) => {
    switch (classification) {
      case 'viavel': return CheckCircle;
      case 'parcialmente_viavel': return AlertTriangle;
      case 'inviavel': return XCircle;
      default: return AlertTriangle;
    }
  };

  const getViabilityColor = (classification: string) => {
    switch (classification) {
      case 'viavel': return '#10B981';
      case 'parcialmente_viavel': return '#F59E0B';
      case 'inviavel': return '#EF4444';
      default: return '#6B7280';
    }
  };

  if (!caseId) {
    return (
      <View style={styles.container}>
        <StatusBar style="light" />
        <TopBar title="Análise Detalhada" showBack />
        <View style={styles.emptyState}>
          <Brain size={48} color="#9CA3AF" />
          <Text style={styles.emptyStateTitle}>Caso não encontrado</Text>
          <Text style={styles.emptyStateDescription}>
            O ID do caso não foi fornecido.
          </Text>
        </View>
      </View>
    );
  }

  if (loading) {
    return (
      <View style={styles.container}>
        <StatusBar style="light" />
        <TopBar title="Análise Detalhada" showBack />
        <View style={styles.loadingState}>
          <Brain size={48} color="#006CFF" />
          <Text style={styles.loadingText}>Gerando análise detalhada...</Text>
          <Text style={styles.loadingSubtext}>
            Nossa IA está analisando todos os aspectos do seu caso
          </Text>
        </View>
      </View>
    );
  }

  if (!analysis) {
    return (
      <View style={styles.container}>
        <StatusBar style="light" />
        <TopBar title="Análise Detalhada" showBack />
        <View style={styles.emptyState}>
          <Brain size={48} color="#9CA3AF" />
          <Text style={styles.emptyStateTitle}>Análise não disponível</Text>
          <Text style={styles.emptyStateDescription}>
            A análise detalhada ainda não foi gerada para este caso.
          </Text>
        </View>
      </View>
    );
  }

  const ViabilityIcon = getViabilityIcon(analysis.analise_viabilidade.classificacao);

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      
      <TopBar
        title="Análise Detalhada"
        subtitle={`Caso #${caseId.slice(-6)}`}
        showBack
      />

      <ScrollView
        style={styles.content}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
        }
        showsVerticalScrollIndicator={false}
      >
        {/* Header Card */}
        <View style={styles.headerCard}>
          <View style={styles.headerIcon}>
            <Brain size={24} color="#006CFF" />
          </View>
          <View style={styles.headerInfo}>
            <Text style={styles.headerTitle}>Análise Jurídica Completa</Text>
            <Text style={styles.headerSubtitle}>
              Confiança: {analysis.confidence}% • {new Date(analysis.generated_at).toLocaleDateString('pt-BR')}
            </Text>
          </View>
        </View>

        {/* Classification */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Classificação</Text>
          <View style={styles.card}>
            <View style={styles.classificationGrid}>
              <View style={styles.classificationItem}>
                <Scale size={20} color="#006CFF" />
                <Text style={styles.classificationLabel}>Área Principal</Text>
                <Text style={styles.classificationValue}>
                  {analysis.classificacao.area_principal}
                </Text>
              </View>
              
              <View style={styles.classificationItem}>
                <TrendingUp 
                  size={20} 
                  color={getComplexityColor(analysis.classificacao.complexidade)} 
                />
                <Text style={styles.classificationLabel}>Complexidade</Text>
                <Text style={[
                  styles.classificationValue,
                  { color: getComplexityColor(analysis.classificacao.complexidade) }
                ]}>
                  {analysis.classificacao.complexidade.charAt(0).toUpperCase() + 
                   analysis.classificacao.complexidade.slice(1)}
                </Text>
              </View>
            </View>

            {analysis.classificacao.sub_areas.length > 0 && (
              <View style={styles.subAreas}>
                <Text style={styles.subAreasTitle}>Sub-áreas:</Text>
                {analysis.classificacao.sub_areas.map((subArea, index) => (
                  <View key={index} style={styles.subAreaTag}>
                    <Text style={styles.subAreaText}>{subArea}</Text>
                  </View>
                ))}
              </View>
            )}
          </View>
        </View>

        {/* Viability Analysis */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Análise de Viabilidade</Text>
          <View style={styles.card}>
            <View style={styles.viabilityHeader}>
              <ViabilityIcon 
                size={24} 
                color={getViabilityColor(analysis.analise_viabilidade.classificacao)} 
              />
              <View style={styles.viabilityInfo}>
                <Text style={styles.viabilityStatus}>
                  {analysis.analise_viabilidade.classificacao === 'viavel' ? 'Viável' :
                   analysis.analise_viabilidade.classificacao === 'parcialmente_viavel' ? 'Parcialmente Viável' :
                   'Inviável'}
                </Text>
                <Text style={styles.viabilityProbability}>
                  {analysis.analise_viabilidade.probabilidade_sucesso}% de chance de sucesso
                </Text>
              </View>
            </View>

            <View style={styles.viabilityDetails}>
              <View style={styles.viabilityColumn}>
                <Text style={styles.viabilityColumnTitle}>Pontos Fortes</Text>
                {analysis.analise_viabilidade.pontos_fortes.map((ponto, index) => (
                  <View key={index} style={styles.viabilityItem}>
                    <CheckCircle size={14} color="#10B981" />
                    <Text style={styles.viabilityItemText}>{ponto}</Text>
                  </View>
                ))}
              </View>

              <View style={styles.viabilityColumn}>
                <Text style={styles.viabilityColumnTitle}>Riscos</Text>
                {analysis.analise_viabilidade.riscos_identificados.map((risco, index) => (
                  <View key={index} style={styles.viabilityItem}>
                    <AlertTriangle size={14} color="#F59E0B" />
                    <Text style={styles.viabilityItemText}>{risco}</Text>
                  </View>
                ))}
              </View>
            </View>
          </View>
        </View>

        {/* Financial Analysis */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Análise Financeira</Text>
          <View style={styles.card}>
            <View style={styles.financialGrid}>
              <View style={styles.financialItem}>
                <DollarSign size={20} color="#10B981" />
                <Text style={styles.financialLabel}>Custo Estimado</Text>
                <Text style={styles.financialValue}>
                  R$ {analysis.analise_financeira.custo_estimado_min.toLocaleString('pt-BR')} - 
                  R$ {analysis.analise_financeira.custo_estimado_max.toLocaleString('pt-BR')}
                </Text>
              </View>

              <View style={styles.financialItem}>
                <Clock size={20} color="#F59E0B" />
                <Text style={styles.financialLabel}>Tempo Estimado</Text>
                <Text style={styles.financialValue}>
                  {analysis.analise_financeira.tempo_estimado_meses} meses
                </Text>
              </View>

              {analysis.analise_financeira.valor_causa_estimado && (
                <View style={styles.financialItem}>
                  <TrendingUp size={20} color="#3B82F6" />
                  <Text style={styles.financialLabel}>Valor da Causa</Text>
                  <Text style={styles.financialValue}>
                    R$ {analysis.analise_financeira.valor_causa_estimado.toLocaleString('pt-BR')}
                  </Text>
                </View>
              )}
            </View>
          </View>
        </View>

        {/* Legal Analysis */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Fundamentos Jurídicos</Text>
          <View style={styles.card}>
            <View style={styles.legalSection}>
              <Text style={styles.legalSectionTitle}>Fundamentos Legais</Text>
              {analysis.analise_juridica.fundamentos_legais.map((fundamento, index) => (
                <View key={index} style={styles.legalItem}>
                  <Gavel size={14} color="#6B7280" />
                  <Text style={styles.legalItemText}>{fundamento}</Text>
                </View>
              ))}
            </View>

            <View style={styles.legalSection}>
              <Text style={styles.legalSectionTitle}>Estratégias Sugeridas</Text>
              {analysis.analise_juridica.estrategias_sugeridas.map((estrategia, index) => (
                <View key={index} style={styles.legalItem}>
                  <CheckCircle size={14} color="#10B981" />
                  <Text style={styles.legalItemText}>{estrategia}</Text>
                </View>
              ))}
            </View>
          </View>
        </View>

        {/* Recommendations */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Recomendações</Text>
          <View style={styles.card}>
            <View style={styles.recommendationsHeader}>
              <AlertTriangle size={20} color="#F59E0B" />
              <Text style={styles.recommendationsTitle}>Próximos Passos</Text>
              {analysis.recomendacoes.prazo_urgencia && (
                <Text style={styles.urgencyText}>
                  Prazo: {analysis.recomendacoes.prazo_urgencia}
                </Text>
              )}
            </View>

            {analysis.recomendacoes.proximos_passos.map((passo, index) => (
              <View key={index} style={styles.recommendationItem}>
                <View style={styles.stepNumber}>
                  <Text style={styles.stepNumberText}>{index + 1}</Text>
                </View>
                <Text style={styles.recommendationText}>{passo}</Text>
              </View>
            ))}

            {analysis.recomendacoes.especialista_recomendado && (
              <View style={styles.specialistRecommendation}>
                <Users size={16} color="#3B82F6" />
                <Text style={styles.specialistText}>
                  {analysis.recomendacoes.especialista_recomendado}
                </Text>
              </View>
            )}
          </View>
        </View>
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
  loadingState: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
  },
  loadingText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1F2937',
    marginTop: 16,
    marginBottom: 8,
  },
  loadingSubtext: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
  },
  emptyState: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
  },
  emptyStateTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1F2937',
    marginTop: 16,
    marginBottom: 8,
  },
  emptyStateDescription: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
    lineHeight: 20,
  },
  headerCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    marginVertical: 12,
    flexDirection: 'row',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  headerIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#F0F9FF',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 16,
  },
  headerInfo: {
    flex: 1,
  },
  headerTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1F2937',
    marginBottom: 4,
  },
  headerSubtitle: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
  },
  section: {
    marginVertical: 12,
  },
  sectionTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1F2937',
    marginBottom: 12,
  },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  classificationGrid: {
    flexDirection: 'row',
    gap: 20,
  },
  classificationItem: {
    flex: 1,
    alignItems: 'center',
    gap: 8,
  },
  classificationLabel: {
    fontFamily: 'Inter-Medium',
    fontSize: 12,
    color: '#6B7280',
    textAlign: 'center',
  },
  classificationValue: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
    color: '#1F2937',
    textAlign: 'center',
  },
  subAreas: {
    marginTop: 16,
    paddingTop: 16,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
  },
  subAreasTitle: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#374151',
    marginBottom: 8,
  },
  subAreaTag: {
    backgroundColor: '#F3F4F6',
    borderRadius: 6,
    paddingHorizontal: 8,
    paddingVertical: 4,
    marginRight: 8,
    marginBottom: 4,
    alignSelf: 'flex-start',
  },
  subAreaText: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: '#6B7280',
  },
  viabilityHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
    gap: 12,
  },
  viabilityInfo: {
    flex: 1,
  },
  viabilityStatus: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#1F2937',
    marginBottom: 4,
  },
  viabilityProbability: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
  },
  viabilityDetails: {
    gap: 16,
  },
  viabilityColumn: {
    gap: 8,
  },
  viabilityColumnTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
    color: '#374151',
    marginBottom: 8,
  },
  viabilityItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 8,
  },
  viabilityItemText: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#1F2937',
    flex: 1,
    lineHeight: 20,
  },
  financialGrid: {
    gap: 16,
  },
  financialItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  financialLabel: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#6B7280',
    flex: 1,
  },
  financialValue: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
    color: '#1F2937',
  },
  legalSection: {
    marginBottom: 20,
  },
  legalSectionTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#1F2937',
    marginBottom: 12,
  },
  legalItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 8,
    marginBottom: 8,
  },
  legalItemText: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#374151',
    flex: 1,
    lineHeight: 20,
  },
  recommendationsHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
    gap: 8,
  },
  recommendationsTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#1F2937',
    flex: 1,
  },
  urgencyText: {
    fontFamily: 'Inter-Medium',
    fontSize: 12,
    color: '#F59E0B',
    backgroundColor: '#FEF3C7',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 4,
  },
  recommendationItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
    marginBottom: 12,
  },
  stepNumber: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#006CFF',
    alignItems: 'center',
    justifyContent: 'center',
  },
  stepNumberText: {
    fontFamily: 'Inter-Bold',
    fontSize: 12,
    color: '#FFFFFF',
  },
  recommendationText: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#1F2937',
    flex: 1,
    lineHeight: 20,
  },
  specialistRecommendation: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
  },
  specialistText: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#3B82F6',
  },
}); 