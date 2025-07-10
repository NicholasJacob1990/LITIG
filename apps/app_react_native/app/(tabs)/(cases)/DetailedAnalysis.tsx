import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  Alert,
  TouchableOpacity,
  RefreshControl
} from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import { StatusBar } from 'expo-status-bar';
import { 
  Brain,
  Scale,
  AlertTriangle,
  Clock,
  FileText,
  CheckCircle,
  XCircle,
  Calendar,
  Users,
  DollarSign,
  BookOpen,
  Target,
  ArrowRight,
  Share,
  Shield
} from 'lucide-react-native';
import TopBar from '@/components/layout/TopBar';
import { Badge } from '@/components/atoms/Badge';
import { ProgressBar } from '@/components/atoms/ProgressBar';
import { getDetailedAnalysis } from '@/lib/services/api';

interface DetailedAnalysis {
  classificacao: {
    area_principal: string;
    assunto_principal: string;
    subarea: string;
    natureza: string;
  };
  dados_extraidos: {
    partes: {
      nome: string;
      tipo: string;
      qualificacao: string;
    }[];
    fatos_principais: string[];
    pedidos: string[];
    valor_causa: string;
    documentos_mencionados: string[];
    cronologia: string;
  };
  analise_viabilidade: {
    classificacao: string;
    pontos_fortes: string[];
    pontos_fracos: string[];
    probabilidade_exito: string;
    justificativa: string;
    complexidade: string;
    custos_estimados: string;
  };
  urgencia: {
    nivel: string;
    motivo: string;
    prazo_limite: string;
    acoes_imediatas: string[];
  };
  aspectos_tecnicos: {
    legislacao_aplicavel: string[];
    jurisprudencia_relevante: string[];
    competencia: string;
    foro: string;
    alertas: string[];
  };
  recomendacoes: {
    estrategia_sugerida: string;
    proximos_passos: string[];
    documentos_necessarios: string[];
    observacoes: string;
  };
}

export default function DetailedAnalysis() {
  const route = useRoute<any>();
  const navigation = useNavigation();
  const { caseId } = route.params;

  const [analysis, setAnalysis] = useState<DetailedAnalysis | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchDetailedAnalysis = async () => {
    try {
      const data = await getDetailedAnalysis(caseId);
      setAnalysis(data.detailed_analysis);
    } catch (error) {
      console.error('Erro ao carregar análise detalhada:', error);
      Alert.alert('Erro', 'Não foi possível carregar a análise detalhada');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchDetailedAnalysis();
  }, [caseId]);

  const handleRefresh = () => {
    setRefreshing(true);
    fetchDetailedAnalysis();
  };

  const handleShare = async () => {
    if (!analysis) {
      Alert.alert('Erro', 'Não há análise para compartilhar');
      return;
    }

    try {
      const { sharingService } = await import('@/lib/services/sharing');
      const success = await sharingService.shareDetailedAnalysis(analysis);
      
      if (!success) {
        Alert.alert('Erro', 'Não foi possível compartilhar a análise');
      }
    } catch (error) {
      console.error('Erro ao compartilhar:', error);
      Alert.alert('Erro', 'Não foi possível compartilhar a análise');
    }
  };

  const getViabilityColor = (classificacao: string) => {
    switch (classificacao?.toLowerCase()) {
      case 'viável':
        return '#10B981';
      case 'parcialmente viável':
        return '#F59E0B';
      case 'inviável':
        return '#EF4444';
      default:
        return '#6B7280';
    }
  };

  const getUrgencyColor = (nivel: string) => {
    switch (nivel?.toLowerCase()) {
      case 'crítica':
        return '#EF4444';
      case 'alta':
        return '#F59E0B';
      case 'média':
        return '#3B82F6';
      case 'baixa':
        return '#10B981';
      default:
        return '#6B7280';
    }
  };

  const getProbabilityValue = (probabilidade: string) => {
    switch (probabilidade?.toLowerCase()) {
      case 'alta':
        return 85;
      case 'média':
        return 60;
      case 'baixa':
        return 30;
      default:
        return 50;
    }
  };

  if (loading) {
    return (
      <View style={styles.container}>
        <StatusBar style="light" />
        <TopBar title="Análise Detalhada" showBack />
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#006CFF" />
          <Text style={styles.loadingText}>Carregando análise...</Text>
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

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      
      <TopBar
        title="Análise Jurídica Detalhada"
        subtitle={analysis.classificacao.area_principal}
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
            <Brain size={24} color="#006CFF" />
          </View>
          <View style={styles.headerInfo}>
            <Text style={styles.headerTitle}>Análise LEX-9000</Text>
            <Text style={styles.headerSubtitle}>
              {analysis.classificacao.assunto_principal}
            </Text>
          </View>
          <Badge
            label={analysis.classificacao.natureza}
            intent={analysis.classificacao.natureza === 'Preventivo' ? 'info' : 'warning'}
            size="small"
          />
        </View>

        {/* Classificação */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Classificação</Text>
          <View style={styles.classificationGrid}>
            <View style={styles.classificationItem}>
              <Scale size={20} color="#006CFF" />
              <View style={styles.classificationInfo}>
                <Text style={styles.classificationLabel}>Área Principal</Text>
                <Text style={styles.classificationValue}>
                  {analysis.classificacao.area_principal}
                </Text>
              </View>
            </View>
            
            <View style={styles.classificationItem}>
              <FileText size={20} color="#6B7280" />
              <View style={styles.classificationInfo}>
                <Text style={styles.classificationLabel}>Subárea</Text>
                <Text style={styles.classificationValue}>
                  {analysis.classificacao.subarea}
                </Text>
              </View>
            </View>
          </View>
        </View>

        {/* Viabilidade */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Análise de Viabilidade</Text>
          
          <View style={styles.viabilityHeader}>
            <View style={[styles.viabilityBadge, { backgroundColor: getViabilityColor(analysis.analise_viabilidade.classificacao) + '20' }]}>
              <Text style={[styles.viabilityText, { color: getViabilityColor(analysis.analise_viabilidade.classificacao) }]}>
                {analysis.analise_viabilidade.classificacao}
              </Text>
            </View>
            <Badge label={`Complexidade ${analysis.analise_viabilidade.complexidade}`} intent={getComplexityColor(analysis.analise_viabilidade.complexidade)}/>
          </View>

          <View style={styles.probabilityContainer}>
            <Text style={styles.probabilityLabel}>Probabilidade de Êxito</Text>
            <ProgressBar
              progress={getProbabilityValue(analysis.analise_viabilidade.probabilidade_exito)}
              color={getViabilityColor(analysis.analise_viabilidade.classificacao)}
              height={8}
              showPercentage
            />
            <Text style={styles.probabilityValue}>
              {analysis.analise_viabilidade.probabilidade_exito}
            </Text>
          </View>

          <Text style={styles.justificativa}>
            {analysis.analise_viabilidade.justificativa}
          </Text>

          <View style={styles.pontosContainer}>
            <View style={styles.pontosSection}>
              <View style={styles.pontosHeader}>
                <CheckCircle size={16} color="#10B981" />
                <Text style={styles.pontosTitle}>Pontos Fortes</Text>
              </View>
              {analysis.analise_viabilidade.pontos_fortes.map((ponto, index) => (
                <Text key={index} style={styles.pontoItem}>• {ponto}</Text>
              ))}
            </View>

            <View style={styles.pontosSection}>
              <View style={styles.pontosHeader}>
                <XCircle size={16} color="#EF4444" />
                <Text style={styles.pontosTitle}>Pontos Fracos</Text>
              </View>
              {analysis.analise_viabilidade.pontos_fracos.map((ponto, index) => (
                <Text key={index} style={styles.pontoItem}>• {ponto}</Text>
              ))}
            </View>
          </View>
        </View>

        {/* Urgência */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Análise de Urgência</Text>
          
          <View style={styles.urgencyHeader}>
            <Badge label={analysis.urgencia.nivel} intent={getUrgencyColor(analysis.urgencia.nivel)} />
            {analysis.urgencia.prazo_limite !== 'N/A' && (
              <View style={styles.deadlineContainer}>
                <Clock size={16} color="#F59E0B" />
                <Text style={styles.deadlineText}>
                  Prazo limite: {analysis.urgencia.prazo_limite}
                </Text>
              </View>
            )}
          </View>

          <Text style={styles.urgencyMotivo}>
            {analysis.urgencia.motivo}
          </Text>

          <View style={styles.acoesContainer}>
            <Text style={styles.acoesTitle}>Ações Imediatas</Text>
            {analysis.urgencia.acoes_imediatas.map((acao, index) => (
              <View key={index} style={styles.acaoItem}>
                <ArrowRight size={16} color="#006CFF" />
                <Text style={styles.acaoText}>{acao}</Text>
              </View>
            ))}
          </View>
        </View>

        {/* Partes Envolvidas */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Partes Envolvidas</Text>
          {analysis.dados_extraidos.partes.map((parte, index) => (
            <View key={index} style={styles.parteItem}>
              <Users size={20} color="#6B7280" />
              <View style={styles.parteInfo}>
                <Text style={styles.parteNome}>{parte.nome}</Text>
                <Text style={styles.parteTipo}>{parte.tipo} - {parte.qualificacao}</Text>
              </View>
            </View>
          ))}
        </View>

        {/* Valor da Causa */}
        {analysis.dados_extraidos.valor_causa !== 'A ser estimado' && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Valor da Causa</Text>
            <View style={styles.valorContainer}>
              <DollarSign size={20} color="#10B981" />
              <Text style={styles.valorText}>
                {analysis.dados_extraidos.valor_causa}
              </Text>
            </View>
            <Text style={styles.custosText}>
              Custos estimados: {analysis.analise_viabilidade.custos_estimados}
            </Text>
          </View>
        )}

        {/* Aspectos Técnicos */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Aspectos Técnicos</Text>
          
          <View style={styles.aspectoSection}>
            <View style={styles.aspectoHeader}>
              <BookOpen size={16} color="#6B7280" />
              <Text style={styles.aspectoTitle}>Legislação Aplicável</Text>
            </View>
            {analysis.aspectos_tecnicos.legislacao_aplicavel.map((lei, index) => (
              <Text key={index} style={styles.aspectoItem}>• {lei}</Text>
            ))}
          </View>

          <View style={styles.aspectoSection}>
            <View style={styles.aspectoHeader}>
              <Scale size={16} color="#6B7280" />
              <Text style={styles.aspectoTitle}>Jurisprudência</Text>
            </View>
            {analysis.aspectos_tecnicos.jurisprudencia_relevante.map((juris, index) => (
              <Text key={index} style={styles.aspectoItem}>• {juris}</Text>
            ))}
          </View>

          <View style={styles.competenciaContainer}>
            <Text style={styles.competenciaLabel}>Competência:</Text>
            <Text style={styles.competenciaValue}>
              {analysis.aspectos_tecnicos.competencia} - {analysis.aspectos_tecnicos.foro}
            </Text>
          </View>

          {analysis.aspectos_tecnicos.alertas.length > 0 && (
            <View style={styles.alertasContainer}>
              <View style={styles.alertasHeader}>
                <AlertTriangle size={16} color="#F59E0B" />
                <Text style={styles.alertasTitle}>Alertas Importantes</Text>
              </View>
              {analysis.aspectos_tecnicos.alertas.map((alerta, index) => (
                <Text key={index} style={styles.alertaItem}>⚠️ {alerta}</Text>
              ))}
            </View>
          )}
        </View>

        {/* Recomendações */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Recomendações Estratégicas</Text>
          
          <View style={styles.estrategiaContainer}>
            <Target size={20} color="#10B981" />
            <View style={styles.estrategiaInfo}>
              <Text style={styles.estrategiaLabel}>Estratégia Sugerida</Text>
              <Text style={styles.estrategiaValue}>
                {analysis.recomendacoes.estrategia_sugerida}
              </Text>
            </View>
          </View>

          <View style={styles.passosContainer}>
            <Text style={styles.passosTitle}>Próximos Passos</Text>
            {analysis.recomendacoes.proximos_passos.map((passo, index) => (
              <View key={index} style={styles.passoItem}>
                <Text style={styles.passoNumber}>{index + 1}</Text>
                <Text style={styles.passoText}>{passo}</Text>
              </View>
            ))}
          </View>

          <View style={styles.documentosContainer}>
            <Text style={styles.documentosTitle}>Documentos Necessários</Text>
            {analysis.recomendacoes.documentos_necessarios.map((doc, index) => (
              <Text key={index} style={styles.documentoItem}>📄 {doc}</Text>
            ))}
          </View>

          <View style={styles.observacoesContainer}>
            <Text style={styles.observacoesTitle}>Observações</Text>
            <Text style={styles.observacoesText}>
              {analysis.recomendacoes.observacoes}
            </Text>
          </View>
        </View>

        {/* Disclaimer */}
        <View style={styles.disclaimer}>
          <AlertTriangle size={16} color="#F59E0B" />
          <Text style={styles.disclaimerText}>
            Esta análise é gerada por inteligência artificial e tem caráter orientativo. 
            Para decisões jurídicas importantes, consulte sempre um advogado especializado.
          </Text>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#6B7280',
  },
  emptyState: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
  },
  emptyStateTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#1F2937',
    marginTop: 16,
    textAlign: 'center',
  },
  emptyStateDescription: {
    fontSize: 16,
    color: '#6B7280',
    marginTop: 8,
    textAlign: 'center',
    lineHeight: 24,
  },
  content: {
    flex: 1,
  },
  headerCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    margin: 16,
    padding: 16,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  headerIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#EBF4FF',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  headerInfo: {
    flex: 1,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1F2937',
  },
  headerSubtitle: {
    fontSize: 14,
    color: '#6B7280',
    marginTop: 2,
  },
  card: {
    backgroundColor: '#FFFFFF',
    marginHorizontal: 16,
    marginBottom: 16,
    padding: 16,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 16,
  },
  classificationGrid: {
    gap: 12,
  },
  classificationItem: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  classificationInfo: {
    marginLeft: 12,
    flex: 1,
  },
  classificationLabel: {
    fontSize: 14,
    color: '#6B7280',
  },
  classificationValue: {
    fontSize: 16,
    fontWeight: '500',
    color: '#1F2937',
    marginTop: 2,
  },
  viabilityHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  viabilityBadge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
  },
  viabilityText: {
    fontSize: 14,
    fontWeight: '600',
  },
  probabilityContainer: {
    marginBottom: 16,
  },
  probabilityLabel: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 8,
  },
  probabilityValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    marginTop: 8,
  },
  justificativa: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
    marginBottom: 16,
  },
  pontosContainer: {
    gap: 16,
  },
  pontosSection: {
    gap: 8,
  },
  pontosHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  pontosTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
  },
  pontoItem: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
  },
  urgencyHeader: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  urgencyInfo: {
    marginLeft: 12,
    flex: 1,
  },
  urgencyLevel: {
    fontSize: 16,
    fontWeight: '600',
  },
  urgencyMotivo: {
    fontSize: 14,
    color: '#6B7280',
    marginTop: 2,
  },
  prazoContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FEF3C7',
    padding: 12,
    borderRadius: 8,
    marginBottom: 16,
  },
  prazoText: {
    fontSize: 14,
    color: '#D97706',
    marginLeft: 8,
    fontWeight: '500',
  },
  acoesContainer: {
    gap: 8,
  },
  acoesTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 8,
  },
  acaoItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  acaoText: {
    fontSize: 14,
    color: '#4B5563',
    flex: 1,
  },
  parteItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  parteInfo: {
    marginLeft: 12,
    flex: 1,
  },
  parteNome: {
    fontSize: 16,
    fontWeight: '500',
    color: '#1F2937',
  },
  parteTipo: {
    fontSize: 14,
    color: '#6B7280',
    marginTop: 2,
  },
  valorContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  valorText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#10B981',
    marginLeft: 8,
  },
  custosText: {
    fontSize: 14,
    color: '#6B7280',
  },
  aspectoSection: {
    marginBottom: 16,
  },
  aspectoHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 8,
  },
  aspectoTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
  },
  aspectoItem: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
  },
  competenciaContainer: {
    backgroundColor: '#F3F4F6',
    padding: 12,
    borderRadius: 8,
    marginBottom: 16,
  },
  competenciaLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
  },
  competenciaValue: {
    fontSize: 14,
    color: '#4B5563',
    marginTop: 4,
  },
  alertasContainer: {
    backgroundColor: '#FEF3C7',
    padding: 12,
    borderRadius: 8,
  },
  alertasHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 8,
  },
  alertasTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#D97706',
  },
  alertaItem: {
    fontSize: 14,
    color: '#D97706',
    lineHeight: 20,
  },
  estrategiaContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  estrategiaInfo: {
    marginLeft: 12,
    flex: 1,
  },
  estrategiaLabel: {
    fontSize: 14,
    color: '#6B7280',
  },
  estrategiaValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#10B981',
    marginTop: 2,
  },
  passosContainer: {
    marginBottom: 16,
  },
  passosTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 8,
  },
  passoItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 8,
  },
  passoNumber: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#006CFF',
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '600',
    textAlign: 'center',
    lineHeight: 24,
    marginRight: 12,
  },
  passoText: {
    fontSize: 14,
    color: '#4B5563',
    flex: 1,
    lineHeight: 20,
  },
  documentosContainer: {
    marginBottom: 16,
  },
  documentosTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 8,
  },
  documentoItem: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
  },
  observacoesContainer: {
    backgroundColor: '#F9FAFB',
    padding: 12,
    borderRadius: 8,
  },
  observacoesTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 8,
  },
  observacoesText: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
  },
  disclaimer: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: '#FEF3C7',
    margin: 16,
    padding: 16,
    borderRadius: 12,
    gap: 12,
  },
  disclaimerText: {
    fontSize: 14,
    color: '#D97706',
    lineHeight: 20,
    flex: 1,
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
}); 