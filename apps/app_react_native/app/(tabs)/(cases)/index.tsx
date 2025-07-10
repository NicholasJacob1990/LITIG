import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Animated, Alert, ActivityIndicator, RefreshControl } from 'react-native';
import { useState, useRef, useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';
import { useNavigation } from '@react-navigation/native';
import { useAuth } from '@/lib/contexts/AuthContext';
import { getUserCases, getCaseStats, CaseData } from '@/lib/services/cases';
import { getUnreadMessagesCount } from '@/lib/services/chat';
import CaseCard from '@/components/organisms/CaseCard';
import CaseHeader from '@/components/organisms/CaseHeader';
import Badge from '@/components/atoms/Badge';
import FabNewCase from '@/components/layout/FabNewCase';

const statusLabelMap: Record<string, string> = {
  pending_assignment: 'Aguardando Atribuição',
  assigned: 'Advogado Atribuído',
  in_progress: 'Em Andamento',
  summary_generated: 'Pré-análise Pronta',
  closed: 'Concluído',
  cancelled: 'Cancelado',
  active: 'Em Andamento',
  pending: 'Pendente'
};

const HEADER_HEIGHT = 220;

export default function MyCasesList() {
  const navigation = useNavigation<any>();
  const { user } = useAuth();
  const [activeFilter, setActiveFilter] = useState('all');
  const [cases, setCases] = useState<any[]>([]);
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
        getCaseStats(user?.id || ''),
      ]);

      const enrichedCases = await Promise.all(
        casesData.map(async (caseItem: any) => {
          try {
            const unreadCount = await getUnreadMessagesCount(caseItem.id, user?.id || '');
            return {
              id: caseItem.id,
              title: caseItem.ai_analysis?.title || 'Caso sem título',
              description: caseItem.ai_analysis?.description || 'Descrição não disponível',
              status: caseItem.status,
              statusLabel: statusLabelMap[caseItem.status as keyof typeof statusLabelMap] || caseItem.status,
              clientType: caseItem.ai_analysis?.client_type || 'PF',
              createdAt: caseItem.created_at,
              nextStep: caseItem.next_step || 'Verificar detalhes do caso',
              hasAiSummary: caseItem.has_ai_summary,
              summarySharedAt: caseItem.ai_analysis?.generated_at,
              unreadMessages: unreadCount,
              priority: caseItem.ai_analysis?.priority || 'medium',
              lawyer: caseItem.lawyer
                ? {
                    name: caseItem.lawyer.name,
                    avatar: caseItem.lawyer.avatar_url,
                    specialty: caseItem.lawyer.specialty,
                  }
                : undefined,
            };
          } catch (error) {
            console.warn(`Error enriching case ${caseItem.id}:`, error);
            return { ...caseItem, unreadMessages: 0 };
          }
        })
      );

      setCases(enrichedCases);
      setCaseStats(statsData);
    } catch (error) {
      console.error('Error loading cases:', error);
      Alert.alert('Erro', 'Não foi possível carregar os casos.');
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadCases();
    setRefreshing(false);
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

  const getCaseCount = (status: string) => {
    if (status === 'all') return cases.length;
    if (status === 'active') return cases.filter(c => ['assigned', 'in_progress'].includes(c.status)).length;
    return cases.filter(c => c.status === status).length;
  }

  const filters = [
    { id: 'all', label: 'Todos' },
    { id: 'active', label: 'Ativos' },
    { id: 'pending_assignment', label: 'Pendentes' },
    { id: 'summary_generated', label: 'Pré-análise' },
    { id: 'closed', label: 'Concluídos' },
  ];

  const filteredCases = cases.filter(case_ => {
    if (activeFilter === 'all') return true;
    if (activeFilter === 'active') return ['assigned', 'in_progress'].includes(case_.status);
    return case_.status === activeFilter;
  });

  const headerStats = caseStats ? [
    { key: 'triagem', label: 'Em Triagem', count: caseStats.pending_assignment || 0 },
    { key: 'atribuido', label: 'Atribuído', count: caseStats.assigned || 0 },
    { key: 'pagamento', label: 'Pagamento', count: 0 },
    { key: 'atendimento', label: 'Atendimento', count: caseStats.in_progress || 0 },
    { key: 'finalizado', label: 'Finalizado', count: caseStats.closed || 0 },
  ] : [];

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
            <CaseHeader caseStats={headerStats} totalCases={cases.length} />
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
                    label={getCaseCount(filter.id).toString()}
                intent={activeFilter === filter.id ? 'primary' : 'neutral'}
                size="small"
              />
            </TouchableOpacity>
          ))}
          </ScrollView>
        </View>
      </Animated.View>

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
            contentContainerStyle={{ paddingTop: HEADER_HEIGHT + 24 }}
          >
        {filteredCases.map((case_) => (
          <View key={case_.id} style={styles.caseCardContainer}>
            <CaseCard
              {...case_}
              status={case_.status as any}
              onPress={() => handleCasePress(case_.id)}
              onViewSummary={() => handleViewSummary(case_.id)}
              onChat={() => handleChat(case_.id)}
            />
          </View>
        ))}

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
  caseCardContainer: {
    marginBottom: 16,
  },
}); 