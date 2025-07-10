import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
  RefreshControl
} from 'react-native';
import { useLocalSearchParams, useNavigation } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { 
  Brain, 
  CheckCircle, 
  AlertTriangle, 
  Calendar, 
  DollarSign, 
  Scale, 
  FileText, 
  Share,
  TrendingUp,
  Clock,
  Users,
  Shield
} from 'lucide-react-native';
import { getCaseById } from '@/lib/services/cases';
import { getDetailedAnalysis } from '@/lib/services/cases';
import TopBar from '@/components/layout/TopBar';
import Badge from '@/components/atoms/Badge';
import ProgressBar from '@/components/atoms/ProgressBar';

export default function DetailedAnalysis() {
  const navigation = useNavigation();
  const { caseId } = useLocalSearchParams<{ caseId: string }>();

  const [caseData, setCaseData] = useState<any>(null);
  const [detailedAnalysis, setDetailedAnalysis] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    if (caseId) {
      loadData();
    }
  }, [caseId]);

  const loadData = async () => {
    try {
      setLoading(true);
      const [caseResult, analysisResult] = await Promise.all([
        getCaseById(caseId),
        getDetailedAnalysis(caseId)
      ]);
      
      setCaseData(caseResult);
      setDetailedAnalysis(analysisResult);
    } catch (error) {
      console.error('Error loading detailed analysis:', error);
      Alert.alert('Erro', 'Não foi possível carregar a análise detalhada');
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  };

  const handleShare = () => {
    Alert.alert('Compartilhar', 'Funcionalidade de compartilhamento em desenvolvimento');
  };

  const getViabilityColor = (viability: string) => {
    switch (viability?.toLowerCase()) {
      case 'viável':
        return 'success';
      case 'parcialmente viável':
        return 'warning';
      case 'inviável':
        return 'danger';
      default:
        return 'info';
    }
  };

  const getUrgencyColor = (urgency: string) => {
    switch (urgency?.toLowerCase()) {
      case 'crítica':
        return 'danger';
      case 'alta':
        return 'warning';
      case 'média':
        return 'info';
      case 'baixa':
        return 'success';
      default:
        return 'info';
    }
  };

  const getComplexityColor = (complexity: string) => {
    switch (complexity?.toLowerCase()) {
      case 'alta':
        return 'danger';
      case 'média':
        return 'warning';
      case 'baixa':
        return 'success';
      default:
        return 'info';
    }
  };

  if (loading) {
    return (
      <View style={styles.container}>
        <StatusBar style="light" />
        <TopBar title="Análise Detalhada" showBack />
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#3B82F6" />
          <Text style={styles.loadingText}>Carregando análise detalhada...</Text>
        </View>
      </View>
    );
  }

  if (!detailedAnalysis) {
    return (
      <View style={styles.container}>
        <StatusBar style="light" />
        <TopBar title="Análise Detalhada" showBack />
        <View style={styles.emptyState}>
          <Brain size={48} color="#9CA3AF" />
          <Text style={styles.emptyStateTitle}>Análise detalhada não disponível</Text>
          <Text style={styles.emptyStateDescription}>
            A análise detalhada ainda não foi gerada para este caso.
          </Text>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      
      <TopBar
        title="Análise Detalhada"
        subtitle={detailedAnalysis.classificacao?.area_principal || 'Análise Jurídica'}
        showBack
        showShare
        onShare={handleShare}
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
            <Brain size={24} color="#3B82F6" />
          </View>
          <View style={styles.headerInfo}>
            <Text style={styles.headerTitle}>Análise Jurídica Completa</Text>
            <Text style={styles.headerSubtitle}>
              Gerada pela IA LEX-9000 • {new Date().toLocaleDateString('pt-BR')}
            </Text>
          </View>
          <Badge intent="primary">
            IA
          </Badge>
        </View>

        {/* Classificação Principal */}
        {detailedAnalysis.classificacao && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Classificação do Caso</Text>
            <View style={styles.classificationGrid}>
              <View style={styles.classificationItem}>
                <Scale size={20} color="#3B82F6" />
                <View style={styles.classificationInfo}>
                  <Text style={styles.classificationLabel}>Área Principal</Text>
                  <Text style={styles.classificationValue}>
                    {detailedAnalysis.classificacao.area_principal}
                  </Text>
                </View>
              </View>
              
              <View style={styles.classificationItem}>
                <FileText size={20} color="#6B7280" />
                <View style={styles.classificationInfo}>
                  <Text style={styles.classificationLabel}>Assunto</Text>
                  <Text style={styles.classificationValue}>
                    {detailedAnalysis.classificacao.assunto_principal}
                  </Text>
                </View>
              </View>

              <View style={styles.classificationItem}>
                <Shield size={20} color="#10B981" />
                <View style={styles.classificationInfo}>
                  <Text style={styles.classificationLabel}>Natureza</Text>
                  <Badge intent={detailedAnalysis.classificacao.natureza === 'Contencioso' ? 'danger' : 'success'}>
                    {detailedAnalysis.classificacao.natureza}
                  </Badge>
                </View>
              </View>
            </View>
          </View>
        )}

        {/* Análise de Viabilidade */}
        {detailedAnalysis.analise_viabilidade && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Análise de Viabilidade</Text>
            
            <View style={styles.viabilityHeader}>
              <Badge intent={getViabilityColor(detailedAnalysis.analise_viabilidade.classificacao)} outline>
                {detailedAnalysis.analise_viabilidade.classificacao}
              </Badge>
              <Badge intent={getComplexityColor(detailedAnalysis.analise_viabilidade.complexidade)}>
                Complexidade {detailedAnalysis.analise_viabilidade.complexidade}
              </Badge>
            </View>

            <View style={styles.probabilityContainer}>
              <Text style={styles.probabilityLabel}>Probabilidade de Êxito</Text>
              <View style={styles.probabilityBar}>
                <Text style={styles.probabilityText}>
                  {detailedAnalysis.analise_viabilidade.probabilidade_exito}
                </Text>
                <ProgressBar 
                  value={detailedAnalysis.analise_viabilidade.probabilidade_exito === 'Alta' ? 8 : 
                        detailedAnalysis.analise_viabilidade.probabilidade_exito === 'Média' ? 5 : 2} 
                />
              </View>
            </View>

            <Text style={styles.justificativa}>
              {detailedAnalysis.analise_viabilidade.justificativa}
            </Text>

            {/* Pontos Fortes */}
            {detailedAnalysis.analise_viabilidade.pontos_fortes?.length > 0 && (
              <View style={styles.pointsSection}>
                <Text style={styles.pointsTitle}>Pontos Fortes</Text>
                {detailedAnalysis.analise_viabilidade.pontos_fortes.map((point: string, index: number) => (
                  <View key={index} style={styles.pointItem}>
                    <CheckCircle size={16} color="#10B981" />
                    <Text style={styles.pointText}>{point}</Text>
                  </View>
                ))}
              </View>
            )}

            {/* Pontos Fracos */}
            {detailedAnalysis.analise_viabilidade.pontos_fracos?.length > 0 && (
              <View style={styles.pointsSection}>
                <Text style={styles.pointsTitle}>Pontos de Atenção</Text>
                {detailedAnalysis.analise_viabilidade.pontos_fracos.map((point: string, index: number) => (
                  <View key={index} style={styles.pointItem}>
                    <AlertTriangle size={16} color="#F59E0B" />
                    <Text style={styles.pointText}>{point}</Text>
                  </View>
                ))}
              </View>
            )}
          </View>
        )}

        {/* Urgência */}
        {detailedAnalysis.urgencia && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Análise de Urgência</Text>
            
            <View style={styles.urgencyHeader}>
              <Badge intent={getUrgencyColor(detailedAnalysis.urgencia.nivel)} outline>
                {detailedAnalysis.urgencia.nivel}
              </Badge>
              {detailedAnalysis.urgencia.prazo_limite && detailedAnalysis.urgencia.prazo_limite !== 'N/A' && (
                <View style={styles.deadlineContainer}>
                  <Clock size={16} color="#F59E0B" />
                  <Text style={styles.deadlineText}>
                    Prazo: {detailedAnalysis.urgencia.prazo_limite}
                  </Text>
                </View>
              )}
            </View>

            <Text style={styles.urgencyMotivo}>
              {detailedAnalysis.urgencia.motivo}
            </Text>

            {/* Ações Imediatas */}
            {detailedAnalysis.urgencia.acoes_imediatas?.length > 0 && (
              <View style={styles.actionsSection}>
                <Text style={styles.actionsTitle}>Ações Imediatas Recomendadas</Text>
                {detailedAnalysis.urgencia.acoes_imediatas.map((action: string, index: number) => (
                  <View key={index} style={styles.actionItem}>
                    <View style={styles.actionNumber}>
                      <Text style={styles.actionNumberText}>{index + 1}</Text>
                    </View>
                    <Text style={styles.actionText}>{action}</Text>
                  </View>
                ))}
              </View>
            )}
          </View>
        )}

        {/* Aspectos Técnicos */}
        {detailedAnalysis.aspectos_tecnicos && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Aspectos Técnicos</Text>
            
            <View style={styles.technicalGrid}>
              <View style={styles.technicalItem}>
                <Text style={styles.technicalLabel}>Competência</Text>
                <Text style={styles.technicalValue}>
                  {detailedAnalysis.aspectos_tecnicos.competencia}
                </Text>
              </View>
              
              {detailedAnalysis.aspectos_tecnicos.foro && (
                <View style={styles.technicalItem}>
                  <Text style={styles.technicalLabel}>Foro</Text>
                  <Text style={styles.technicalValue}>
                    {detailedAnalysis.aspectos_tecnicos.foro}
                  </Text>
                </View>
              )}
            </View>

            {/* Legislação Aplicável */}
            {detailedAnalysis.aspectos_tecnicos.legislacao_aplicavel?.length > 0 && (
              <View style={styles.legislationSection}>
                <Text style={styles.legislationTitle}>Legislação Aplicável</Text>
                {detailedAnalysis.aspectos_tecnicos.legislacao_aplicavel.map((lei: string, index: number) => (
                  <View key={index} style={styles.legislationItem}>
                    <Text style={styles.legislationText}>{lei}</Text>
                  </View>
                ))}
              </View>
            )}

            {/* Alertas */}
            {detailedAnalysis.aspectos_tecnicos.alertas?.length > 0 && (
              <View style={styles.alertsSection}>
                <Text style={styles.alertsTitle}>Alertas Importantes</Text>
                {detailedAnalysis.aspectos_tecnicos.alertas.map((alert: string, index: number) => (
                  <View key={index} style={styles.alertItem}>
                    <AlertTriangle size={16} color="#EF4444" />
                    <Text style={styles.alertText}>{alert}</Text>
                  </View>
                ))}
              </View>
            )}
          </View>
        )}

        {/* Recomendações */}
        {detailedAnalysis.recomendacoes && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Recomendações Estratégicas</Text>
            
            <View style={styles.strategyContainer}>
              <Badge intent="primary" outline>
                {detailedAnalysis.recomendacoes.estrategia_sugerida}
              </Badge>
            </View>

            {/* Próximos Passos */}
            {detailedAnalysis.recomendacoes.proximos_passos?.length > 0 && (
              <View style={styles.stepsSection}>
                <Text style={styles.stepsTitle}>Próximos Passos</Text>
                {detailedAnalysis.recomendacoes.proximos_passos.map((step: string, index: number) => (
                  <View key={index} style={styles.stepItem}>
                    <View style={styles.stepNumber}>
                      <Text style={styles.stepNumberText}>{index + 1}</Text>
                    </View>
                    <Text style={styles.stepText}>{step}</Text>
                  </View>
                ))}
              </View>
            )}

            {/* Documentos Necessários */}
            {detailedAnalysis.recomendacoes.documentos_necessarios?.length > 0 && (
              <View style={styles.documentsSection}>
                <Text style={styles.documentsTitle}>Documentos Necessários</Text>
                {detailedAnalysis.recomendacoes.documentos_necessarios.map((doc: string, index: number) => (
                  <View key={index} style={styles.documentItem}>
                    <FileText size={16} color="#6B7280" />
                    <Text style={styles.documentText}>{doc}</Text>
                  </View>
                ))}
              </View>
            )}

            {/* Observações */}
            {detailedAnalysis.recomendacoes.observacoes && (
              <View style={styles.observationsSection}>
                <Text style={styles.observationsTitle}>Observações do Especialista</Text>
                <Text style={styles.observationsText}>
                  {detailedAnalysis.recomendacoes.observacoes}
                </Text>
              </View>
            )}
          </View>
        )}

        {/* Disclaimer */}
        <View style={styles.disclaimer}>
          <Text style={styles.disclaimerText}>
            ⚠️ Esta análise é gerada por inteligência artificial e tem caráter orientativo. 
            Recomenda-se sempre a consulta com um advogado especializado para validação e estratégia detalhada.
          </Text>
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
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  loadingText: {
    fontSize: 16,
    color: '#6B7280',
    marginTop: 16,
  },
  emptyState: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  emptyStateTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#1F2937',
    marginTop: 16,
    marginBottom: 8,
  },
  emptyStateDescription: {
    fontSize: 16,
    color: '#6B7280',
    textAlign: 'center',
    lineHeight: 24,
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
  },
  headerCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    padding: 20,
    borderRadius: 16,
    marginVertical: 16,
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
    backgroundColor: '#EEF2FF',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  headerInfo: {
    flex: 1,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1F2937',
  },
  headerSubtitle: {
    fontSize: 14,
    color: '#6B7280',
    marginTop: 2,
  },
  card: {
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
  cardTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1F2937',
    marginBottom: 16,
  },
  classificationGrid: {
    gap: 16,
  },
  classificationItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#F3F4F6',
  },
  classificationInfo: {
    marginLeft: 12,
    flex: 1,
  },
  classificationLabel: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 4,
  },
  classificationValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
  },
  viabilityHeader: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 16,
  },
  probabilityContainer: {
    marginBottom: 16,
  },
  probabilityLabel: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 8,
  },
  probabilityBar: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  probabilityText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    minWidth: 60,
  },
  justificativa: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
    marginBottom: 16,
    fontStyle: 'italic',
  },
  pointsSection: {
    marginBottom: 16,
  },
  pointsTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 12,
  },
  pointItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 8,
    gap: 8,
  },
  pointText: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
    flex: 1,
  },
  urgencyHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  deadlineContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  deadlineText: {
    fontSize: 14,
    color: '#F59E0B',
    fontWeight: '600',
  },
  urgencyMotivo: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
    marginBottom: 16,
  },
  actionsSection: {
    marginTop: 16,
  },
  actionsTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 12,
  },
  actionItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 12,
    gap: 12,
  },
  actionNumber: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#3B82F6',
    justifyContent: 'center',
    alignItems: 'center',
  },
  actionNumberText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  actionText: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
    flex: 1,
  },
  technicalGrid: {
    gap: 16,
    marginBottom: 16,
  },
  technicalItem: {
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F3F4F6',
  },
  technicalLabel: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 4,
  },
  technicalValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
  },
  legislationSection: {
    marginBottom: 16,
  },
  legislationTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 12,
  },
  legislationItem: {
    backgroundColor: '#F9FAFB',
    padding: 12,
    borderRadius: 8,
    marginBottom: 8,
  },
  legislationText: {
    fontSize: 14,
    color: '#4B5563',
  },
  alertsSection: {
    marginTop: 16,
  },
  alertsTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#EF4444',
    marginBottom: 12,
  },
  alertItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: '#FEF2F2',
    padding: 12,
    borderRadius: 8,
    marginBottom: 8,
    gap: 8,
  },
  alertText: {
    fontSize: 14,
    color: '#DC2626',
    lineHeight: 20,
    flex: 1,
  },
  strategyContainer: {
    marginBottom: 16,
  },
  stepsSection: {
    marginBottom: 16,
  },
  stepsTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 12,
  },
  stepItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 12,
    gap: 12,
  },
  stepNumber: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#10B981',
    justifyContent: 'center',
    alignItems: 'center',
  },
  stepNumberText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  stepText: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
    flex: 1,
  },
  documentsSection: {
    marginBottom: 16,
  },
  documentsTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 12,
  },
  documentItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F9FAFB',
    padding: 12,
    borderRadius: 8,
    marginBottom: 8,
    gap: 8,
  },
  documentText: {
    fontSize: 14,
    color: '#4B5563',
    flex: 1,
  },
  observationsSection: {
    marginTop: 16,
    padding: 16,
    backgroundColor: '#EEF2FF',
    borderRadius: 12,
  },
  observationsTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1E3A8A',
    marginBottom: 8,
  },
  observationsText: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
    fontStyle: 'italic',
  },
  disclaimer: {
    backgroundColor: '#FEF3C7',
    padding: 16,
    borderRadius: 12,
    marginBottom: 20,
  },
  disclaimerText: {
    fontSize: 12,
    color: '#92400E',
    lineHeight: 18,
    textAlign: 'center',
  },
}); 