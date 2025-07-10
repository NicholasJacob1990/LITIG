import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Animated, Alert, RefreshControl, ActivityIndicator } from 'react-native';
import { useState, useRef, useEffect, useMemo } from 'react';
import { StatusBar } from 'expo-status-bar';
import { useRouter } from 'expo-router';
import { useAuth } from '@/lib/contexts/AuthContext';
import { getUserCases, getCaseStats, CaseData } from '@/lib/services/cases';
import { getUnreadMessagesCount } from '@/lib/services/chat';
import { getCaseTasks } from '@/lib/services/tasks';
import DetailedCaseCard from '@/components/organisms/DetailedCaseCard';
import PreAnalysisCard from '@/components/organisms/PreAnalysisCard';
import CaseHeader from '@/components/organisms/CaseHeader';
import Badge from '@/components/atoms/Badge';
import FabNewCase from '@/components/layout/FabNewCase';
import EmptyState from '@/components/atoms/EmptyState';
import ErrorState from '@/components/atoms/ErrorState';
import { Briefcase } from 'lucide-react-native';
import { mockDetailedCases } from '@/lib/services/mockCasesData';
import LawyerCaseCard from './LawyerCaseCard';

const HEADER_HEIGHT = 220; // Height for CaseHeader + Filters

interface CaseListProps {
  cases: CaseData[];
  caseStats: any;
  isLoading: boolean;
  error: string | null;
  onRefresh: () => void;
  headerComponent?: React.ReactNode;
}

// Mock pre-analysis data for demonstration
const mockPreAnalysis = {
  caseTitle: 'Questão Previdenciária',
  analysisDate: new Date().toISOString(),
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

export default function ImprovedCaseList({ 
  cases, 
  caseStats, 
  isLoading, 
  error, 
  onRefresh, 
  headerComponent 
}: CaseListProps) {
  const router = useRouter();
  const { user, role } = useAuth();
  const [activeFilter, setActiveFilter] = useState('all');
  const scrollY = useRef(new Animated.Value(0)).current;
  const [enrichedCases, setEnrichedCases] = useState<any[]>([]);

  useEffect(() => {
    enrichCases();
  }, [cases]);

  const enrichCases = async () => {
    try {
      // Se não há casos do banco, usar dados mock
      const casesToEnrich = cases.length > 0 ? cases : mockDetailedCases;
      
      const enriched = await Promise.all(
        casesToEnrich.map(async (caseItem) => {
          try {
            // Para casos reais do banco, buscar mensagens não lidas
            const unreadCount = cases.length > 0 
              ? await getUnreadMessagesCount(caseItem.id, user?.id || '')
              : caseItem.unread_messages || 0;
            
            const caseData = caseItem as any; // Type assertion para acessar todos os campos
            
            return {
              ...caseItem,
              unread_messages: unreadCount,
              // Map backend status for UI
              status: mapBackendStatus(caseItem.status),
              // Criar objeto lawyer para compatibilidade com DetailedCaseCard
              lawyer: caseItem.lawyer || (caseData.lawyer_name ? {
                id: caseData.lawyer_id || '',
                name: caseData.lawyer_name,
                avatar: caseData.lawyer_avatar,
                specialty: caseData.lawyer_specialty || 'Advogado',
                oab: caseData.lawyer_oab || '',
                rating: caseData.lawyer_rating || 0,
                experience_years: caseData.lawyer_experience_years || 0,
                success_rate: caseData.lawyer_success_rate || 0,
                phone: caseData.lawyer_phone,
                email: caseData.lawyer_email,
                location: caseData.lawyer_location
              } : undefined),
              // Garantir que os campos obrigatórios existam
              title: caseData.title || 'Caso sem título',
              description: caseData.description || 'Descrição não disponível',
              area: caseData.area || 'Área não definida',
              subarea: caseData.subarea || 'Geral',
              priority: caseData.priority || 'medium',
              urgencyHours: caseData.urgency_hours || 72,
              riskLevel: caseData.risk_level || 'medium',
              confidenceScore: caseData.confidence_score || 0,
              estimatedCost: caseData.estimated_cost || 0,
              nextStep: caseData.next_step || 'Aguardando análise',
              updatedAt: caseData.updated_at || caseData.created_at,
              createdAt: caseData.created_at,
              // Novos campos de honorários
              consultationFee: caseData.consultation_fee || 0,
              representationFee: caseData.representation_fee || 0,
              feeType: caseData.fee_type || 'fixed',
              successPercentage: caseData.success_percentage,
              hourlyRate: caseData.hourly_rate,
              planType: caseData.plan_type,
              paymentTerms: caseData.payment_terms
            };
          } catch (error) {
            console.warn('Error enriching case:', caseItem.id, error);
            return caseItem;
          }
        })
      );
      setEnrichedCases(enriched);
    } catch (error) {
      console.error('Error enriching cases:', error);
      setEnrichedCases(cases.length > 0 ? cases : mockDetailedCases);
    }
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

  const filters = [
    { id: 'all', label: 'Todos', count: enrichedCases.length },
    { id: 'active', label: 'Ativos', count: enrichedCases.filter(c => c.status === 'active').length },
    { id: 'pending', label: 'Pendentes', count: enrichedCases.filter(c => c.status === 'pending').length },
    { id: 'summary_generated', label: 'Pré-análise', count: enrichedCases.filter(c => c.status === 'summary_generated').length },
    { id: 'completed', label: 'Concluídos', count: enrichedCases.filter(c => c.status === 'completed').length },
  ];

  const filteredCases = activeFilter === 'all' 
    ? enrichedCases 
    : enrichedCases.filter(case_ => case_.status === activeFilter);

  // Calculate case statistics for the header
  const headerStats = caseStats ? [
    { key: 'triagem', label: 'Em Triagem', count: caseStats.pending_assignment || 0 },
    { key: 'atribuido', label: 'Atribuído', count: caseStats.assigned || 0 },
    { key: 'pagamento', label: 'Pagamento', count: 0 },
    { key: 'atendimento', label: 'Atendimento', count: caseStats.in_progress || 0 },
    { key: 'finalizado', label: 'Finalizado', count: caseStats.closed || 0 },
  ] : [
    { key: 'triagem', label: 'Em Triagem', count: enrichedCases.filter(c => c.status === 'pending').length },
    { key: 'atribuido', label: 'Atribuído', count: enrichedCases.filter(c => c.status === 'active').length },
    { key: 'pagamento', label: 'Pagamento', count: 0 },
    { key: 'atendimento', label: 'Atendimento', count: enrichedCases.filter(c => c.status === 'active').length },
    { key: 'finalizado', label: 'Finalizado', count: enrichedCases.filter(c => c.status === 'completed').length },
  ];

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

  const handleCasePress = (caseId: string) => {
    router.push(`/(tabs)/cases/CaseDetail?caseId=${caseId}` as any);
  };

  const handleViewSummary = (caseId: string) => {
    router.push(`/(tabs)/cases/AISummary?caseId=${caseId}` as any);
  };

  const handleChat = (caseId: string) => {
    router.push(`/(tabs)/cases/CaseChat?caseId=${caseId}` as any);
  };

  const handleScheduleConsult = () => {
    Alert.alert('Agendar Consulta', 'Funcionalidade em desenvolvimento');
  };

  const handleViewDocuments = (caseId: string) => {
    router.push({
      pathname: '/case-documents' as any,
      params: { caseId },
    });
  };

  const handleContactLawyer = (caseId: string) => {
    Alert.alert('Contatar Advogado', 'Funcionalidade em desenvolvimento');
  };

  if (isLoading && enrichedCases.length === 0) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#006CFF" />
        <Text style={styles.loadingText}>Carregando casos...</Text>
      </View>
    );
  }

  if (error && enrichedCases.length === 0) {
    return <ErrorState title="Erro ao carregar casos" description={error} type="server" onRetry={onRefresh} />;
  }

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      
      <Animated.View style={[
        styles.header, 
        { 
          transform: [{ translateY: headerTranslateY }], 
          opacity: headerOpacity 
        }
      ]}>
        {/* Enhanced Header */}
        <CaseHeader caseStats={headerStats} totalCases={enrichedCases.length} />

        {/* Visual Filters with Badges */}
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
                  intent={activeFilter === filter.id ? 'primary' : 'info'}
                  size="small"
                />
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>
      </Animated.View>

      {/* Cases List with Parallax Scrolling */}
      <Animated.ScrollView 
        style={styles.content}
        onScroll={Animated.event(
          [{ nativeEvent: { contentOffset: { y: scrollY } } }],
          { useNativeDriver: true }
        )}
        scrollEventThrottle={16}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={isLoading} onRefresh={onRefresh} />
        }
        contentContainerStyle={{ paddingTop: HEADER_HEIGHT + 24 }}
      >
        {/* AI Pre-Analysis Card (if any case has summary_generated status) */}
        {activeFilter === 'summary_generated' && filteredCases.length > 0 && (
          <View style={styles.preAnalysisContainer}>
            <PreAnalysisCard
              {...mockPreAnalysis}
              onViewFull={() => handleViewSummary(filteredCases[0].id)}
              onScheduleConsult={handleScheduleConsult}
            />
          </View>
        )}

        {/* Case Cards */}
        {filteredCases.map((case_) => (
          <View key={case_.id} style={styles.caseCardContainer}>
            <DetailedCaseCard
              id={case_.id}
              title={case_.title}
              description={case_.description}
              area={case_.area || 'Direito Civil'}
              subarea={case_.subarea || 'Geral'}
              status={case_.status}
              priority={case_.priority}
              urgencyHours={case_.urgency_hours || 48}
              riskLevel={case_.risk_level || 'medium'}
              confidenceScore={case_.confidence_score || 80}
              estimatedCost={case_.estimated_cost || 2500}
              createdAt={case_.created_at}
              updatedAt={case_.updated_at}
              nextStep={case_.nextStep || "Aguardando próxima ação"}
              consultationFee={case_.consultationFee || 0}
              representationFee={case_.representationFee || 0}
              feeType={case_.feeType || 'fixed'}
              successPercentage={case_.successPercentage}
              hourlyRate={case_.hourlyRate}
              planType={case_.planType}
              paymentTerms={case_.paymentTerms}
              lawyer={case_.lawyer}
              documents={case_.documents || []}
              unreadMessages={case_.unread_messages || 0}
              onPress={() => handleCasePress(case_.id)}
              onViewSummary={() => handleViewSummary(case_.id)}
              onChat={() => handleChat(case_.id)}
              onViewDocuments={() => handleViewDocuments(case_.id)}
              onContactLawyer={() => handleContactLawyer(case_.id)}
            />
          </View>
        ))}

        {/* Empty State */}
        {filteredCases.length === 0 && (
          <EmptyState
            icon={Briefcase}
            title={activeFilter === 'all' ? "Nenhum caso ainda" : "Nenhum caso encontrado"}
            description={
              activeFilter === 'all' 
                ? 'Você ainda não possui casos. Inicie uma nova consulta jurídica!' 
                : `Não há casos com status "${filters.find(f => f.id === activeFilter)?.label}".`
            }
            actionText={activeFilter === 'all' ? "Novo caso" : "Ver todos"}
            onAction={activeFilter === 'all' ? undefined : () => setActiveFilter('all')}
          />
        )}
      </Animated.ScrollView>

      <FabNewCase />
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
    backgroundColor: '#F8FAFC',
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
  },
  preAnalysisContainer: {
    paddingHorizontal: 24,
    marginBottom: 16,
  },
  caseCardContainer: {
    paddingHorizontal: 24,
    marginBottom: 16,
  },
});
