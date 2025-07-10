import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Animated, RefreshControl } from 'react-native';
import { useState, useRef, useMemo } from 'react';
import { StatusBar } from 'expo-status-bar';
import { useRouter } from 'expo-router';
import { useMyCases, useCaseStats } from '@/lib/hooks/useCases';
import CaseCard from '@/components/organisms/CaseCard';
import CaseHeader from '@/components/organisms/CaseHeader';
import FabNewCase from '@/components/layout/FabNewCase';
import EmptyState from '@/components/atoms/EmptyState';
import ErrorState from '@/components/atoms/ErrorState';
import LoadingSpinner from '@/components/atoms/LoadingSpinner';
import SearchBar from '@/components/molecules/SearchBar';
import FilterModal from '@/components/molecules/FilterModal';
import { Briefcase, SortAsc, SortDesc } from 'lucide-react-native';

// Tipos para filtros
interface CaseFilters {
  status?: string[];
  priority?: string[];
  dateRange?: string;
  hasLawyer?: boolean;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

const HEADER_HEIGHT = 280;

export default function CaseListWithQuery() {
  const router = useRouter();
  
  // Hooks do TanStack Query
  const { data: cases = [], isLoading, error, refetch } = useMyCases();
  const { data: caseStats } = useCaseStats();
  
  const [searchQuery, setSearchQuery] = useState('');
  const [filters, setFilters] = useState<CaseFilters>({
    sortBy: 'updated_at',
    sortOrder: 'desc'
  });
  const [showFilterModal, setShowFilterModal] = useState(false);
  
  const scrollY = useRef(new Animated.Value(0)).current;

  // Configuração dos filtros
  const filterSections = [
    {
      id: 'status',
      title: 'Status',
      type: 'multiple' as const,
      options: [
        { id: 'pending_assignment', label: 'Aguardando Atribuição' },
        { id: 'assigned', label: 'Atribuído' },
        { id: 'in_progress', label: 'Em Andamento' },
        { id: 'closed', label: 'Finalizado' },
        { id: 'cancelled', label: 'Cancelado' }
      ]
    },
    {
      id: 'priority',
      title: 'Prioridade',
      type: 'multiple' as const,
      options: [
        { id: 'high', label: 'Alta' },
        { id: 'medium', label: 'Média' },
        { id: 'low', label: 'Baixa' }
      ]
    },
    {
      id: 'hasLawyer',
      title: 'Com Advogado Atribuído',
      type: 'toggle' as const
    },
    {
      id: 'sortBy',
      title: 'Ordenar Por',
      type: 'single' as const,
      options: [
        { id: 'updated_at', label: 'Última Atualização' },
        { id: 'created_at', label: 'Data de Criação' },
        { id: 'priority', label: 'Prioridade' },
        { id: 'title', label: 'Título' }
      ]
    }
  ];

  // Filtrar e ordenar casos
  const filteredAndSortedCases = useMemo(() => {
    let filtered = cases;

    // Aplicar busca por texto
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(case_ => 
        case_.title?.toLowerCase().includes(query) ||
        case_.description?.toLowerCase().includes(query) ||
        case_.area?.toLowerCase().includes(query)
      );
    }

    // Aplicar filtros
    if (filters.status?.length) {
      filtered = filtered.filter(case_ => filters.status!.includes(case_.status));
    }

    // Aplicar ordenação
    const sortBy = filters.sortBy || 'updated_at';
    const sortOrder = filters.sortOrder || 'desc';

    filtered.sort((a, b) => {
      let aValue: any, bValue: any;

      switch (sortBy) {
        case 'title':
          aValue = a.title || '';
          bValue = b.title || '';
          break;
        case 'created_at':
          aValue = new Date(a.created_at).getTime();
          bValue = new Date(b.created_at).getTime();
          break;
        default: // updated_at
          aValue = new Date(a.updated_at).getTime();
          bValue = new Date(b.updated_at).getTime();
      }

      if (sortOrder === 'asc') {
        return aValue > bValue ? 1 : -1;
      } else {
        return aValue < bValue ? 1 : -1;
      }
    });

    return filtered;
  }, [cases, searchQuery, filters]);

  // Estatísticas para o header
  const headerStats = useMemo(() => {
    if (caseStats) {
      return [
        { key: 'triagem', label: 'Em Triagem', count: caseStats.pending_assignment || 0 },
        { key: 'atribuido', label: 'Atribuído', count: caseStats.assigned || 0 },
        { key: 'andamento', label: 'Em Andamento', count: caseStats.in_progress || 0 },
        { key: 'finalizado', label: 'Finalizado', count: caseStats.closed || 0 },
      ];
    }
    return [
      { key: 'triagem', label: 'Em Triagem', count: cases.filter(c => c.status === 'pending_assignment').length },
      { key: 'atribuido', label: 'Atribuído', count: cases.filter(c => c.status === 'assigned').length },
      { key: 'andamento', label: 'Em Andamento', count: cases.filter(c => c.status === 'in_progress').length },
      { key: 'finalizado', label: 'Finalizado', count: cases.filter(c => c.status === 'closed').length },
    ];
  }, [cases, caseStats]);

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
    router.push({
      pathname: '/(tabs)/cases/CaseDetail',
      params: { caseId },
    });
  };

  const handleViewSummary = (caseId: string) => {
    router.push({
      pathname: '/(tabs)/cases/AISummary',
      params: { caseId },
    });
  };

  const handleChat = (caseId: string) => {
    router.push({
      pathname: '/(tabs)/cases/CaseChat',
      params: { caseId },
    });
  };

  const handleApplyFilters = (newFilters: Record<string, any>) => {
    setFilters(prev => ({ ...prev, ...newFilters }));
  };

  const handleClearFilters = () => {
    setFilters({
      sortBy: 'updated_at',
      sortOrder: 'desc'
    });
    setSearchQuery('');
  };

  const toggleSortOrder = () => {
    setFilters(prev => ({
      ...prev,
      sortOrder: prev.sortOrder === 'asc' ? 'desc' : 'asc'
    }));
  };

  // Estados de carregamento e erro
  if (isLoading && !cases.length) {
    return <LoadingSpinner size="large" text="Carregando casos..." fullScreen />;
  }

  if (error && !cases.length) {
    return (
      <ErrorState 
        title="Erro ao carregar casos" 
        description={error.message || 'Erro desconhecido'} 
        type="server" 
        onRetry={() => refetch()} 
      />
    );
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
        {/* Header com estatísticas */}
        <CaseHeader caseStats={headerStats} totalCases={cases.length} />

        {/* Barra de busca */}
        <View style={styles.searchContainer}>
          <SearchBar
            placeholder="Buscar casos, advogados..."
            value={searchQuery}
            onChangeText={setSearchQuery}
            onFilterPress={() => setShowFilterModal(true)}
            showFilter
            variant="rounded"
          />
        </View>

        {/* Controles de ordenação */}
        <View style={styles.sortContainer}>
          <Text style={styles.sortLabel}>
            {filteredAndSortedCases.length} caso(s) encontrado(s)
          </Text>
          <TouchableOpacity style={styles.sortButton} onPress={toggleSortOrder}>
            {filters.sortOrder === 'asc' ? (
              <SortAsc size={16} color="#006CFF" />
            ) : (
              <SortDesc size={16} color="#006CFF" />
            )}
            <Text style={styles.sortButtonText}>
              {filters.sortBy === 'title' ? 'A-Z' : 
               filters.sortBy === 'priority' ? 'Prioridade' : 'Data'}
            </Text>
          </TouchableOpacity>
        </View>
      </Animated.View>

      {/* Lista de casos */}
      <Animated.ScrollView 
        style={styles.content}
        onScroll={Animated.event(
          [{ nativeEvent: { contentOffset: { y: scrollY } } }],
          { useNativeDriver: true }
        )}
        scrollEventThrottle={16}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl refreshing={isLoading} onRefresh={() => refetch()} />
        }
        contentContainerStyle={{ paddingTop: HEADER_HEIGHT + 24 }}
      >
        {filteredAndSortedCases.length === 0 ? (
          <EmptyState
            icon={Briefcase}
            title={searchQuery || Object.keys(filters).length > 2 ? 
              "Nenhum caso encontrado" : 
              "Nenhum caso ainda"
            }
            description={searchQuery || Object.keys(filters).length > 2 ? 
              "Tente ajustar sua busca ou filtros." : 
              "Você ainda não possui casos. Inicie uma nova consulta jurídica!"
            }
            actionText={searchQuery || Object.keys(filters).length > 2 ? 
              "Limpar filtros" : 
              "Novo caso"
            }
            onAction={searchQuery || Object.keys(filters).length > 2 ? 
              handleClearFilters : 
              undefined
            }
          />
        ) : (
          filteredAndSortedCases.map((case_) => (
            <View key={case_.id} style={styles.caseCardContainer}>
              <CaseCard
                {...case_}
                title={case_.title || 'Caso sem título'}
                description={case_.description || 'Descrição não disponível'}
                status={case_.status as any}
                priority={'medium' as any}
                clientType={'PF' as any}
                createdAt={case_.created_at}
                nextStep="Próximo passo"
                hasAiSummary={true}
                summarySharedAt={case_.updated_at}
                unreadMessages={0}
                onPress={() => handleCasePress(case_.id)}
                onViewSummary={() => handleViewSummary(case_.id)}
                onChat={() => handleChat(case_.id)}
              />
            </View>
          ))
        )}
      </Animated.ScrollView>

      {/* Modal de filtros */}
      <FilterModal
        visible={showFilterModal}
        onClose={() => setShowFilterModal(false)}
        onApply={handleApplyFilters}
        onClear={handleClearFilters}
        sections={filterSections}
        title="Filtrar Casos"
      />

      <FabNewCase />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  header: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 10,
    backgroundColor: '#F8FAFC',
    paddingBottom: 16,
  },
  searchContainer: {
    paddingHorizontal: 20,
    paddingTop: 16,
  },
  sortContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 12,
  },
  sortLabel: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
  },
  sortButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: '#F0F9FF',
    borderRadius: 8,
  },
  sortButtonText: {
    fontFamily: 'Inter-Medium',
    fontSize: 12,
    color: '#006CFF',
  },
  content: {
    flex: 1,
  },
  caseCardContainer: {
    marginHorizontal: 20,
    marginBottom: 16,
  },
}); 