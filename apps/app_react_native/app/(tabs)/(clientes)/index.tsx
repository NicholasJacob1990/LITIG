import React, { useState, useMemo } from 'react';
import { View, Text, FlatList, ActivityIndicator, StyleSheet, RefreshControl, SafeAreaView, TouchableOpacity } from 'react-native';
import { useQuery } from '@tanstack/react-query';
import { User, Briefcase, Calendar, Info } from 'lucide-react-native';
import api from '@/lib/services/api'; // Corrigido o caminho da API

const PRIMARY_COLOR = '#0D47A1';
const GREY_COLOR = '#64748B';
const ERROR_COLOR = '#B91C1C';

// A interface do contrato precisa ser definida aqui, pois não temos o hook
export interface Contract {
  id: string;
  client_id: string;
  client_name: string;
  created_at: string;
  // Adicione outros campos do contrato se necessário
}

// Interface para representar um cliente agregado
interface AggregatedClient {
  id: string;
  name: string;
  casesCount: number;
  firstContact: Date;
  avatarUrl?: string;
}

// Função para buscar os contratos via API
const fetchContracts = async (): Promise<Contract[]> => {
  const { data } = await api.get('/contracts', {
    params: {
      status_filter: 'active', // Usando o filtro que a API espera
      limit: 100, // Pegar um número grande para agregar todos os clientes
    },
  });
  return data;
};

// Componente de Card para o Cliente
const ClientCard = ({ item }: { item: AggregatedClient }) => (
  <TouchableOpacity style={styles.card}>
    <View style={styles.cardHeader}>
      <View style={styles.avatarPlaceholder}>
        <User color={PRIMARY_COLOR} size={22} />
      </View>
      <Text style={styles.clientName}>{item.name}</Text>
    </View>
    <View style={styles.cardBody}>
      <View style={styles.infoRow}>
        <Briefcase color={GREY_COLOR} size={16} />
        <Text style={styles.infoText}>{item.casesCount} caso(s) ativo(s)</Text>
      </View>
      <View style={styles.infoRow}>
        <Calendar color={GREY_COLOR} size={16} />
        <Text style={styles.infoText}>Cliente desde: {new Date(item.firstContact).toLocaleDateString()}</Text>
      </View>
    </View>
  </TouchableOpacity>
);

// Componente simples para exibir erros
const ErrorDisplay = ({ message }: { message: string }) => (
  <View style={styles.centered}>
    <Info size={40} color={ERROR_COLOR} />
    <Text style={styles.errorText}>Ocorreu um erro</Text>
    <Text style={styles.errorSubText}>{message}</Text>
  </View>
);

export default function ClientesScreen() {
  const [isRefreshing, setIsRefreshing] = useState(false);

  const { data: contracts, isLoading, error, refetch } = useQuery<Contract[], Error>({
    queryKey: ['lawyer-clients'], // Chave de query única
    queryFn: fetchContracts,
  });

  const onRefresh = async () => {
    setIsRefreshing(true);
    await refetch();
    setIsRefreshing(false);
  };

  const aggregatedClients = useMemo(() => {
    if (!contracts) return [];
    const clientsMap = new Map<string, AggregatedClient>();
    contracts.forEach(contract => {
      if (!contract.client_id || !contract.client_name) return;
      if (clientsMap.has(contract.client_id)) {
        const existing = clientsMap.get(contract.client_id)!;
        existing.casesCount++;
        if (new Date(contract.created_at) < existing.firstContact) {
          existing.firstContact = new Date(contract.created_at);
        }
      } else {
        clientsMap.set(contract.client_id, {
          id: contract.client_id,
          name: contract.client_name,
          casesCount: 1,
          firstContact: new Date(contract.created_at),
        });
      }
    });
    return Array.from(clientsMap.values()).sort((a, b) => a.name.localeCompare(b.name));
  }, [contracts]);

  if (isLoading && !isRefreshing) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={PRIMARY_COLOR} />
        <Text style={{marginTop: 10, color: GREY_COLOR}}>Carregando clientes...</Text>
      </View>
    );
  }

  if (error) {
    return <ErrorDisplay message={error.message || 'Não foi possível buscar seus clientes.'} />;
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Meus Clientes</Text>
        <Text style={styles.headerSubtitle}>
          {aggregatedClients.length} cliente(s) com contratos ativos.
        </Text>
      </View>
      <FlatList
        data={aggregatedClients}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => <ClientCard item={item} />}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl refreshing={isRefreshing} onRefresh={onRefresh} colors={[PRIMARY_COLOR]} />
        }
        ListEmptyComponent={() => (
          <View style={styles.centered}>
             <Text style={styles.emptyText}>Nenhum cliente ativo encontrado.</Text>
             <Text style={styles.emptySubText}>Quando você tiver um contrato ativo, o cliente aparecerá aqui.</Text>
          </View>
        )}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
    marginTop: -50, // Puxa um pouco para cima
  },
  header: {
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 16,
    backgroundColor: '#FFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1E293B',
    fontFamily: 'Inter-Bold',
  },
  headerSubtitle: {
    fontSize: 14,
    color: GREY_COLOR,
    marginTop: 4,
    fontFamily: 'Inter-Regular',
  },
  listContent: {
    padding: 16,
    flexGrow: 1,
  },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 20,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#1E293B',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  avatarPlaceholder: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#E0E8F9',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  clientName: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1E293B',
    fontFamily: 'Inter-SemiBold',
  },
  cardBody: {
    paddingLeft: 56, // Alinha com o nome do cliente
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
  },
  infoText: {
    marginLeft: 12,
    fontSize: 14,
    color: '#334155',
    fontFamily: 'Inter-Medium',
  },
  emptyText: {
    fontSize: 16,
    color: GREY_COLOR,
    fontWeight: '600',
    textAlign: 'center',
    marginBottom: 8,
    fontFamily: 'Inter-SemiBold',
  },
  emptySubText: {
    fontSize: 14,
    color: GREY_COLOR,
    textAlign: 'center',
    fontFamily: 'Inter-Regular',
  },
  errorText: {
    fontSize: 18,
    color: ERROR_COLOR,
    fontWeight: 'bold',
    marginTop: 16,
    marginBottom: 8,
  },
  errorSubText: {
    fontSize: 14,
    color: GREY_COLOR,
    textAlign: 'center',
    paddingHorizontal: 20,
  }
}); 