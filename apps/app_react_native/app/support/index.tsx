import React, { useState, useMemo, useEffect } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity, RefreshControl, ActivityIndicator, Alert, TextInput, Modal } from 'react-native';
import { useRouter, Link, useFocusEffect } from 'expo-router';
import { useSupport } from '@/lib/contexts/SupportContext';
import { SupportTicket } from '@/lib/services/support';
import Badge from '@/components/atoms/Badge';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { Plus, MessageSquareWarning, ChevronRight, ArrowLeft, Search, Filter, RefreshCw, X } from 'lucide-react-native';

export default function SupportScreen() {
  const router = useRouter();
  const { tickets, isLoading, error, refetchTickets } = useSupport();

  const [isRefreshing, setIsRefreshing] = useState(false);
  const [searchText, setSearchText] = useState('');
  const [selectedStatus, setSelectedStatus] = useState<string>('all');
  const [selectedPriority, setSelectedPriority] = useState<string>('all');
  const [showFilters, setShowFilters] = useState(false);

  // UseFocusEffect para atualizar os dados sempre que a tela for focada
  useFocusEffect(
    React.useCallback(() => {
      refetchTickets();
    }, [refetchTickets])
  );

  // Filtros e busca
  const filteredTickets = useMemo(() => {
    let filtered = tickets;

    // Filtro por texto
    if (searchText.trim()) {
      filtered = filtered.filter(ticket => 
        ticket.subject.toLowerCase().includes(searchText.toLowerCase()) ||
        (ticket.description && ticket.description.toLowerCase().includes(searchText.toLowerCase()))
      );
    }

    // Filtro por status
    if (selectedStatus !== 'all') {
      filtered = filtered.filter(ticket => ticket.status === selectedStatus);
    }

    // Filtro por prioridade
    if (selectedPriority !== 'all') {
      filtered = filtered.filter(ticket => ticket.priority === selectedPriority);
    }

    return filtered;
  }, [tickets, searchText, selectedStatus, selectedPriority]);

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      await refetchTickets();
    } catch (error) {
      Alert.alert('Erro', 'Não foi possível atualizar a lista de tickets.');
    } finally {
      setIsRefreshing(false);
    }
  };

  const clearFilters = () => {
    setSearchText('');
    setSelectedStatus('all');
    setSelectedPriority('all');
    setShowFilters(false);
  };

  const getStatusColor = (status?: string) => {
    switch (status) {
      case 'open': return '#10B981';
      case 'in_progress': return '#F59E0B';
      case 'closed': return '#6B7280';
      case 'on_hold': return '#EF4444';
      default: return '#10B981';
    }
  };

  const getPriorityColor = (priority?: string) => {
    switch (priority) {
      case 'low': return '#10B981';
      case 'medium': return '#F59E0B';
      case 'high': return '#EF4444';
      case 'critical': return '#DC2626';
      default: return '#F59E0B';
    }
  };

  const getStatusText = (status?: string) => {
    switch (status) {
      case 'open': return 'Aberto';
      case 'in_progress': return 'Em Andamento';
      case 'closed': return 'Fechado';
      case 'on_hold': return 'Em Espera';
      default: return 'Aberto';
    }
  };

  const getPriorityText = (priority?: string) => {
    switch (priority) {
      case 'low': return 'Baixa';
      case 'medium': return 'Média';
      case 'high': return 'Alta';
      case 'critical': return 'Crítica';
      default: return 'Média';
    }
  };

  const renderTicket = (item: SupportTicket) => {
    const hasUnread = !item.last_viewed_at || 
                     (item.updated_at && item.last_viewed_at && new Date(item.updated_at) > new Date(item.last_viewed_at));

    return (
      <Link href={`/support/${item.id}`} asChild key={item.id}>
        <TouchableOpacity
          style={[styles.ticketCard, hasUnread && styles.unreadTicket]}
        >
        <View style={styles.ticketHeader}>
            <Text style={styles.ticketTitle} numberOfLines={2}>{item.subject}</Text>
            {hasUnread && <View style={styles.unreadIndicator} />}
          </View>
          <Text style={styles.ticketDescription} numberOfLines={2}>
            {item.description || 'Sem descrição'}
          </Text>
          <View style={styles.ticketFooter}>
            <View style={styles.badges}>
              <View style={[styles.badge, { backgroundColor: getStatusColor(item.status) }]}>
                <Text style={styles.badgeText}>{getStatusText(item.status)}</Text>
              </View>
              <View style={[styles.badge, { backgroundColor: getPriorityColor(item.priority) }]}>
                <Text style={styles.badgeText}>{getPriorityText(item.priority)}</Text>
              </View>
            </View>
            <Text style={styles.ticketDate}>
              #{item.id} - Criado em {item.created_at ? format(new Date(item.created_at), 'dd/MM/yyyy', { locale: ptBR }) : 'Data não disponível'}
            </Text>
        </View>
      </TouchableOpacity>
    </Link>
  );
  };

  const hasActiveFilters = selectedStatus !== 'all' || selectedPriority !== 'all' || searchText.trim();

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity
          style={styles.backButton}
          onPress={() => router.back()}
        >
          <ArrowLeft size={24} color="#111827" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Central de Suporte</Text>
        <View style={styles.headerActions}>
          <TouchableOpacity 
            style={styles.headerButton}
            onPress={handleRefresh}
            disabled={isRefreshing}
          >
            <RefreshCw size={20} color={isRefreshing ? "#A5B4FC" : "#4F46E5"} />
          </TouchableOpacity>
          <TouchableOpacity 
            style={styles.headerButton}
            onPress={() => setShowFilters(true)}
          >
            <Filter size={20} color={hasActiveFilters ? "#EF4444" : "#4F46E5"} />
          </TouchableOpacity>
        </View>
      </View>

      <View style={styles.searchContainer}>
        <Search size={20} color="#9CA3AF" />
        <TextInput
          style={styles.searchInput}
          placeholder="Buscar tickets..."
          value={searchText}
          onChangeText={setSearchText}
        />
        {searchText.length > 0 && (
          <TouchableOpacity onPress={() => setSearchText('')}>
            <X size={20} color="#9CA3AF" />
          </TouchableOpacity>
        )}
      </View>

      {hasActiveFilters && (
        <View style={styles.activeFilters}>
          <Text style={styles.activeFiltersText}>
            {filteredTickets.length} de {tickets.length} tickets
          </Text>
          <TouchableOpacity onPress={clearFilters}>
            <Text style={styles.clearFiltersText}>Limpar filtros</Text>
          </TouchableOpacity>
        </View>
      )}

      {isLoading ? (
        <View style={styles.centered}>
          <ActivityIndicator size="large" color="#4F46E5" />
          <Text style={styles.loadingText}>Carregando tickets...</Text>
        </View>
      ) : filteredTickets.length === 0 ? (
        <View style={styles.centered}>
          <Text style={styles.emptyText}>
            {hasActiveFilters ? 'Nenhum ticket encontrado com os filtros aplicados' : 'Você ainda não tem tickets de suporte'}
          </Text>
          {!hasActiveFilters && (
            <TouchableOpacity 
              style={styles.createFirstButton}
              onPress={() => router.push('/support/new')}
            >
              <Text style={styles.createFirstButtonText}>Criar primeiro ticket</Text>
            </TouchableOpacity>
          )}
        </View>
      ) : (
        <FlatList
          data={filteredTickets}
          renderItem={({ item }) => renderTicket(item)}
          keyExtractor={(item) => item.id!}
          contentContainerStyle={styles.listContainer}
          showsVerticalScrollIndicator={false}
          onRefresh={handleRefresh}
          refreshing={isRefreshing}
        />
      )}

      <TouchableOpacity
        style={styles.fab}
        onPress={() => router.push('/support/new')}
      >
        <Plus size={24} color="#FFF" />
      </TouchableOpacity>

      <Modal
        visible={showFilters}
        transparent
        animationType="slide"
        onRequestClose={() => setShowFilters(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Filtros</Text>
              <TouchableOpacity onPress={() => setShowFilters(false)}>
                <X size={24} color="#111827" />
              </TouchableOpacity>
            </View>

            <Text style={styles.filterTitle}>Status</Text>
            <View style={styles.filterOptions}>
              {[
                { label: 'Todos', value: 'all' },
                { label: 'Aberto', value: 'open' },
                { label: 'Em Andamento', value: 'in_progress' },
                { label: 'Fechado', value: 'closed' },
                { label: 'Em Espera', value: 'on_hold' },
              ].map((option) => (
                <TouchableOpacity
                  key={option.value}
                  style={[
                    styles.filterOption,
                    selectedStatus === option.value && styles.filterOptionActive
                  ]}
                  onPress={() => setSelectedStatus(option.value)}
                >
                  <Text style={[
                    styles.filterOptionText,
                    selectedStatus === option.value && styles.filterOptionTextActive
                  ]}>
                    {option.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <Text style={styles.filterTitle}>Prioridade</Text>
            <View style={styles.filterOptions}>
              {[
                { label: 'Todas', value: 'all' },
                { label: 'Baixa', value: 'low' },
                { label: 'Média', value: 'medium' },
                { label: 'Alta', value: 'high' },
                { label: 'Crítica', value: 'critical' },
              ].map((option) => (
                <TouchableOpacity
                  key={option.value}
                  style={[
                    styles.filterOption,
                    selectedPriority === option.value && styles.filterOptionActive
                  ]}
                  onPress={() => setSelectedPriority(option.value)}
                >
                  <Text style={[
                    styles.filterOptionText,
                    selectedPriority === option.value && styles.filterOptionTextActive
                  ]}>
                    {option.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <View style={styles.modalActions}>
              <TouchableOpacity 
                style={styles.clearButton}
                onPress={clearFilters}
              >
                <Text style={styles.clearButtonText}>Limpar</Text>
              </TouchableOpacity>
              <TouchableOpacity 
                style={styles.applyButton}
                onPress={() => setShowFilters(false)}
              >
                <Text style={styles.applyButtonText}>Aplicar</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F3F4F6',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF',
    paddingHorizontal: 20,
    paddingTop: 50,
    paddingBottom: 15,
    borderBottomWidth: 1,
    borderColor: '#E5E7EB',
  },
  backButton: {
    padding: 8,
    marginLeft: -8,
  },
  headerTitle: {
    flex: 1,
    fontSize: 20,
    fontWeight: 'bold',
    color: '#111827',
    textAlign: 'center',
  },
  headerActions: {
    flexDirection: 'row',
    gap: 8,
  },
  headerButton: {
    padding: 8,
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF',
    marginHorizontal: 20,
    marginTop: 15,
    marginBottom: 10,
    paddingHorizontal: 15,
    paddingVertical: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    gap: 10,
  },
  searchInput: {
    flex: 1,
    fontSize: 16,
    color: '#111827',
  },
  activeFilters: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginHorizontal: 20,
    marginBottom: 10,
  },
  activeFiltersText: {
    fontSize: 14,
    color: '#6B7280',
  },
  clearFiltersText: {
    fontSize: 14,
    color: '#EF4444',
    fontWeight: '600',
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 40,
  },
  loadingText: {
    marginTop: 10,
    fontSize: 16,
    color: '#6B7280',
  },
  emptyText: {
    fontSize: 16,
    color: '#6B7280',
    textAlign: 'center',
    marginBottom: 20,
  },
  createFirstButton: {
    backgroundColor: '#4F46E5',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 8,
  },
  createFirstButtonText: {
    color: '#FFF',
    fontSize: 16,
    fontWeight: '600',
  },
  listContainer: {
    paddingHorizontal: 15,
    paddingTop: 15,
  },
  ticketCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  unreadTicket: {
    borderColor: '#4F46E5',
    borderWidth: 2,
  },
  ticketHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  ticketTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    flex: 1,
    marginRight: 12,
  },
  unreadIndicator: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#4F46E5',
    marginLeft: 8,
  },
  ticketDescription: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 12,
    lineHeight: 20,
  },
  ticketFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 8,
  },
  badges: {
    flexDirection: 'row',
    gap: 6,
    alignItems: 'flex-end',
  },
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  badgeText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#FFF',
  },
  ticketDate: {
    fontSize: 12,
    color: '#6B7280',
  },
  fab: {
    position: 'absolute',
    bottom: 30,
    right: 30,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#4F46E5',
    justifyContent: 'center',
    alignItems: 'center',
    elevation: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 8,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: '#FFF',
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    padding: 20,
    maxHeight: '80%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#111827',
  },
  filterTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#374151',
    marginTop: 20,
    marginBottom: 12,
  },
  filterOptions: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  filterOption: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#F3F4F6',
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  filterOptionActive: {
    backgroundColor: '#4F46E5',
    borderColor: '#4F46E5',
  },
  filterOptionText: {
    fontSize: 14,
    color: '#374151',
  },
  filterOptionTextActive: {
    color: '#FFF',
  },
  modalActions: {
    flexDirection: 'row',
    gap: 12,
    marginTop: 30,
  },
  clearButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    alignItems: 'center',
  },
  clearButtonText: {
    fontSize: 16,
    color: '#374151',
    fontWeight: '600',
  },
  applyButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    backgroundColor: '#4F46E5',
    alignItems: 'center',
  },
  applyButtonText: {
    fontSize: 16,
    color: '#FFF',
    fontWeight: '600',
  },
}); 