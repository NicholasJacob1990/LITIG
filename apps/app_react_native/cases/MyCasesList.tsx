import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Animated, Alert, ActivityIndicator, RefreshControl } from 'react-native';
import { useState, useRef, useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';
import { useNavigation } from '@react-navigation/native';
import { useAuth } from '@/lib/contexts/AuthContext';
import { getUserCases, getCaseStats, CaseData } from '@/lib/services/cases';
import { getUnreadMessagesCount } from '@/lib/services/chat';
import CaseCard from '@/components/organisms/CaseCard';
import PreAnalysisCard from '@/components/organisms/PreAnalysisCard';
import CaseHeader from '@/components/organisms/CaseHeader';
import Badge from '@/components/atoms/Badge';
import FabNewCase from '@/components/layout/FabNewCase';

// Sample data with proper typing
const mockCases = [
  {
    id: '001',
    title: 'Rescisão Trabalhista',
    description: 'Demissão sem justa causa - Cálculo de verbas rescisórias',
    status: 'active' as const,
    priority: 'high' as const,
    clientType: 'PF' as const,
    createdAt: '2024-01-15',
    nextStep: 'Aguardando documentos adicionais do cliente',
    hasAiSummary: true,
    summarySharedAt: '2024-01-15T10:30:00Z',
    unreadMessages: 12,
    lawyer: {
      name: 'Dr. Carlos Mendes',
      avatar: 'https://images.pexels.com/photos/2182970/pexels-photo-2182970.jpeg?auto=compress&cs=tinysrgb&w=400',
      specialty: 'Direito Trabalhista'
    },
  },
  {
    id: '002',
    title: 'Contrato Empresarial',
    description: 'Revisão de contrato de prestação de serviços B2B',
    status: 'completed' as const,
    priority: 'medium' as const,
    clientType: 'PJ' as const,
    createdAt: '2024-01-10',
    nextStep: 'Caso finalizado com sucesso',
    hasAiSummary: true,
    summarySharedAt: '2024-01-10T14:20:00Z',
    unreadMessages: 0,
    lawyer: {
      name: 'Dra. Ana Paula Santos',
      avatar: 'https://images.pexels.com/photos/3760263/pexels-photo-3760263.jpeg?auto=compress&cs=tinysrgb&w=400',
      specialty: 'Direito Empresarial'
    },
  },
  {
    id: '003',
    title: 'Reclamação Consumidor',
    description: 'Produto com defeito - Reembolso e danos morais',
    status: 'pending' as const,
    priority: 'low' as const,
    clientType: 'PF' as const,
    createdAt: '2024-01-19',
    nextStep: 'Aguardando atribuição de advogado especializado',
    hasAiSummary: true,
    summarySharedAt: '2024-01-19T09:15:00Z',
    unreadMessages: 0,
  },
  {
    id: '004',
    title: 'Compliance Empresarial',
    description: 'Adequação LGPD - Implementação de políticas de privacidade',
    status: 'summary_generated' as const,
    priority: 'medium' as const,
    clientType: 'PJ' as const,
    createdAt: '2024-01-20',
    nextStep: 'Pré-análise concluída - Aguardando atribuição',
    hasAiSummary: true,
    summarySharedAt: '2024-01-20T11:45:00Z',
    unreadMessages: 0,
  },
  {
    id: '005',
    title: 'Questão Previdenciária',
    description: 'Revisão de benefício INSS - Aposentadoria por tempo de contribuição',
    status: 'summary_generated' as const,
    priority: 'medium' as const,
    clientType: 'PF' as const,
    createdAt: '2024-01-20',
    nextStep: 'Análise IA disponível para revisão',
    hasAiSummary: true,
    summarySharedAt: '2024-01-20T11:45:00Z',
    unreadMessages: 0,
  },
];

// Sample pre-analysis data
const mockPreAnalysis = {
  caseTitle: 'Questão Previdenciária',
  analysisDate: '2024-01-20T11:45:00Z',
  confidence: 87,
  estimatedCost: 2500,
  riskLevel: 'medium' as const,
  keyPoints: [
    'Documentação completa e válida para aposentadoria',
    'Tempo de contribuição suficiente conforme legislação',
    'Possibilidade de revisão do valor do benefício',
    'Recomendação de acompanhamento jurídico especializado',
    'Prazo legal para contestação ainda válido'
  ]
};

// Sample detailed data
export const mockDetailedData = {
  '001': {
    preAnalysis: {
      caseTitle: 'Rescisão Trabalhista',
      analysisDate: '2024-01-15T10:30:00Z',
      confidence: 92,
      estimatedCost: 3500,
      riskLevel: 'medium' as const,
      keyPoints: [
        'Demissão sem justa causa comprovada',
        'Direito a todas as verbas rescisórias',
        'Possível indenização adicional por danos morais',
        'Documentação trabalhista completa',
        'Prazo para ação ainda válido'
      ]
    },
    consultInfo: {
      scheduledDate: '2024-01-22T14:00:00Z',
      duration: '45 minutos',
      type: 'Consulta Presencial',
      plan: 'Premium'
    },
    steps: [
      {
        title: 'Análise de Documentos',
        description: 'Revisão completa da documentação trabalhista',
        status: 'completed' as const,
        priority: 8,
        dueDate: '2024-01-16'
      },
      {
        title: 'Cálculo de Verbas',
        description: 'Cálculo detalhado das verbas rescisórias devidas',
        status: 'active' as const,
        priority: 9,
        dueDate: '2024-01-20'
      },
      {
        title: 'Notificação Extrajudicial',
        description: 'Envio de notificação para tentativa de acordo',
        status: 'pending' as const,
        priority: 7,
        dueDate: '2024-01-25'
      }
    ],
    documents: [
      { 
        id: 'doc1', 
        name: 'Carteira de Trabalho.pdf', 
        size: 2048576, 
        uploadedAt: '2024-01-15T10:30:00Z' 
      },
      { 
        id: 'doc2', 
        name: 'Contrato de Trabalho.pdf', 
        size: 1536000, 
        uploadedAt: '2024-01-15T11:45:00Z' 
      },
      { 
        id: 'doc3', 
        name: 'Comprovantes de Pagamento.pdf', 
        size: 3072000, 
        uploadedAt: '2024-01-16T09:20:00Z' 
      },
      { 
        id: 'doc4', 
        name: 'Termo de Rescisão.pdf', 
        size: 1024000, 
        uploadedAt: '2024-01-16T14:10:00Z' 
      }
    ],
    costs: {
      consultationFee: 300,
      legalFees: 2500,
      courtCosts: 450,
      totalEstimate: 3250
    }
  }
};

const HEADER_HEIGHT = 220; // Approximate height of CaseHeader + Filters

export default function MyCasesList() {
  const navigation = useNavigation<any>();
  const { user } = useAuth();
  const [activeFilter, setActiveFilter] = useState('all');
  const [cases, setCases] = useState<CaseData[]>([]);
  const [caseStats, setCaseStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const scrollY = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (user?.id) {
      loadCases();
    }
  }, [user?.id]);

  const loadCases = async () => {
    try {
      setLoading(true);
      const [casesData, statsData] = await Promise.all([
        getUserCases(user?.id || ''),
        getCaseStats(user?.id || '')
      ]);

      // Enriquecer casos com contagem de mensagens não lidas
      const enrichedCases = await Promise.all(
        casesData.map(async (caseItem) => {
          try {
            const unreadCount = await getUnreadMessagesCount(caseItem.id, user?.id || '');
            return {
              ...caseItem,
              unread_messages: unreadCount,
              // Mapear status do backend para os esperados pela interface
              status: mapBackendStatus(caseItem.status),
              // Extrair informações da análise IA se disponível
              title: caseItem.ai_analysis?.title || 'Caso sem título',
              description: caseItem.ai_analysis?.description || 'Descrição não disponível',
              priority: caseItem.ai_analysis?.priority || 'medium',
              client_type: caseItem.ai_analysis?.client_type || 'PF'
            };
          } catch (error) {
            console.warn('Error getting unread count for case:', caseItem.id, error);
            return caseItem;
          }
        })
      );

      setCases(enrichedCases);
      setCaseStats(statsData);
    } catch (error) {
      console.error('Error loading cases:', error);
      Alert.alert('Erro', 'Não foi possível carregar os casos');
      // Fallback para dados mock em caso de erro
      setCases(mockCases);
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadCases();
    setRefreshing(false);
  };

  const mapBackendStatus = (status: string) => {
    const statusMap: Record<string, string> = {
      'pending_assignment': 'pending',
      'assigned': 'active',
      'in_progress': 'active',
      'closed': 'completed',
      'cancelled': 'completed'
    };
    return statusMap[status] || status;
  };

  const headerTranslateY = scrollY.interpolate({
    inputRange: [0, HEADER_HEIGHT],
    outputRange: [0, -HEADER_HEIGHT],
    extrapolate: 'clamp',
  });

  const headerOpacity = scrollY.interpolate({
    inputRange: [0, HEADER_HEIGHT / 2, HEADER_HEIGHT],
    outputRange: [1, 1, 0],
    extrapolate: 'clamp',
  });

  const filters = [
    { id: 'all', label: 'Todos', count: cases.length },
    { id: 'active', label: 'Ativos', count: cases.filter(c => c.status === 'active').length },
    { id: 'pending', label: 'Pendentes', count: cases.filter(c => c.status === 'pending').length },
    { id: 'summary_generated', label: 'Pré-análise', count: cases.filter(c => c.status === 'summary_generated').length },
    { id: 'completed', label: 'Concluídos', count: cases.filter(c => c.status === 'completed').length },
  ];

  const filteredCases = activeFilter === 'all' 
    ? cases 
    : cases.filter(case_ => case_.status === activeFilter);

  // Calculate case statistics for the header
  const headerStats = caseStats ? [
    { key: 'triagem', label: 'Em Triagem', count: caseStats.pending_assignment },
    { key: 'atribuido', label: 'Atribuído', count: caseStats.assigned },
    { key: 'pagamento', label: 'Pagamento', count: 0 },
    { key: 'atendimento', label: 'Atendimento', count: caseStats.in_progress },
    { key: 'finalizado', label: 'Finalizado', count: caseStats.closed },
  ] : [
    { key: 'triagem', label: 'Em Triagem', count: cases.filter(c => c.status === 'summary_generated').length },
    { key: 'atribuido', label: 'Atribuído', count: cases.filter(c => c.status === 'active').length },
    { key: 'pagamento', label: 'Pagamento', count: 0 },
    { key: 'atendimento', label: 'Atendimento', count: cases.filter(c => c.status === 'pending').length },
    { key: 'finalizado', label: 'Finalizado', count: cases.filter(c => c.status === 'completed').length },
  ];

  const handleCasePress = (caseId: string) => {
    navigation.navigate('CaseDetail', { caseId });
  };

  const handleViewSummary = (caseId: string) => {
    navigation.navigate('AISummary', { caseId });
  };

  const handleChat = (caseId: string) => {
    navigation.navigate('CaseChat', { caseId });
  };

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      
      {loading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#006CFF" />
          <Text style={styles.loadingText}>Carregando casos...</Text>
        </View>
      ) : (
        <>
          <Animated.View style={[styles.header, { transform: [{ translateY: headerTranslateY }], opacity: headerOpacity }]}>
            {/* Enhanced Header */}
            <CaseHeader caseStats={headerStats} totalCases={cases.length} />

        {/* Filters */}
        <View style={styles.filtersWrapper}>
          <ScrollView 
            horizontal 
            showsHorizontalScrollIndicator={false}
            style={styles.filtersContainer}
            contentContainerStyle={styles.filtersContent}
          >
          {filters.map((filter) => (
            <TouchableOpacity
              key={filter.id}
              style={[
                styles.filterButton,
                activeFilter === filter.id && styles.filterButtonActive
              ]}
              onPress={() => setActiveFilter(filter.id)}
            >
              <Text style={[
                styles.filterButtonText,
                activeFilter === filter.id && styles.filterButtonTextActive
              ]}>
                {filter.label}
              </Text>
              <Badge
                label={filter.count.toString()}
                intent={activeFilter === filter.id ? 'primary' : 'neutral'}
                size="small"
              />
            </TouchableOpacity>
          ))}
          </ScrollView>
        </View>
      </Animated.View>

          {/* Cases List */}
          <Animated.ScrollView 
            style={styles.content}
            onScroll={Animated.event(
              [{ nativeEvent: { contentOffset: { y: scrollY } } }],
              { useNativeDriver: true }
            )}
            scrollEventThrottle={16}
            showsVerticalScrollIndicator={false}
            refreshControl={
              <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
            }
            contentContainerStyle={{ paddingTop: HEADER_HEIGHT + 24 }} // Adjust paddingTop to account for absolute header
          >
        {/* AI Pre-Analysis Card (if any case has summary_generated status) */}
        {activeFilter === 'summary_generated' && (
          <PreAnalysisCard
            {...mockPreAnalysis}
            onViewFull={() => console.log('View full analysis')}
            onScheduleConsult={() => console.log('Schedule consultation')}
          />
        )}

        {/* Case Cards */}
        {filteredCases.map((case_) => (
          <CaseCard
            key={case_.id}
            {...case_}
            onPress={() => handleCasePress(case_.id)}
            onViewSummary={() => handleViewSummary(case_.id)}
            onChat={() => handleChat(case_.id)}
          />
        ))}

            {/* Empty State */}
            {filteredCases.length === 0 && (
              <View style={styles.emptyState}>
                <Text style={styles.emptyStateTitle}>Nenhum caso encontrado</Text>
                <Text style={styles.emptyStateDescription}>
                  {activeFilter === 'all' 
                    ? 'Você ainda não possui casos. Inicie uma nova consulta jurídica!' 
                    : `Não há casos com status "${filters.find(f => f.id === activeFilter)?.label}".`}
                </Text>
              </View>
            )}
          </Animated.ScrollView>
          <FabNewCase />
        </>
      )}
    </View>
  );
}

// Export mockCases for use in other components
export { mockCases };

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
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#6B7280',
    marginTop: 16,
  },
  header: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 10,
    backgroundColor: '#F8FAFC', // Match container background
  },
  filtersWrapper: {
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  filtersContainer: {
    flexGrow: 0,
  },
  filtersContent: {
    paddingHorizontal: 24,
    paddingVertical: 16,
  },
  filterButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#F3F4F6',
    marginRight: 12,
    gap: 8,
  },
  filterButtonActive: {
    backgroundColor: '#006CFF',
  },
  filterButtonText: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#4B5563',
  },
  filterButtonTextActive: {
    color: '#FFFFFF',
  },
  content: {
    flex: 1,
    paddingHorizontal: 24,
  },
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 64,
  },
  emptyStateTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 20,
    color: '#1F2937',
    marginBottom: 8,
  },
  emptyStateDescription: {
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#6B7280',
    textAlign: 'center',
    lineHeight: 24,
    paddingHorizontal: 32,
  },
}); 