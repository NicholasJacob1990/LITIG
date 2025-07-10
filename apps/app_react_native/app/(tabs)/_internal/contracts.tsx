/**
 * Tela principal de contratos
 */
import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  RefreshControl,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { useQuery } from '@tanstack/react-query';

import ContractCard from '../../../components/organisms/ContractCard';
import { Contract, contractsService } from '../../../lib/services/contracts';
import { useAuth } from '../../../lib/contexts/AuthContext';

type FilterStatus = 'all' | 'pending-signature' | 'active' | 'closed' | 'canceled';

export default function ContractsScreen() {
  const { user } = useAuth();
  const router = useRouter();
  const [contracts, setContracts] = useState<Contract[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [filter, setFilter] = useState<FilterStatus>('all');

  const loadContracts = useCallback(async () => {
    if (!user) return;

    try {
      const statusParam = filter !== 'all' ? filter : undefined;
      const data = await contractsService.getContracts(statusParam);
      setContracts(data);
    } catch (error: any) {
      Alert.alert('Erro', error.message);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [user, filter]);

  useFocusEffect(
    useCallback(() => {
      loadContracts();
    }, [loadContracts])
  );

  const handleRefresh = () => {
    setRefreshing(true);
    loadContracts();
  };

  const handleContractPress = (contract: Contract) => {
    router.push({
      pathname: '/contract/[id]',
      params: { id: contract.id },
    });
  };

  const handleSignContract = async (contract: Contract) => {
    try {
      const role = contract.client_id === user?.id ? 'client' : 'lawyer';
      
      Alert.alert(
        'Assinar Contrato',
        'Ao assinar este contrato, você concorda com todos os termos e condições estabelecidos.',
        [
          { text: 'Cancelar', style: 'cancel' },
          {
            text: 'Assinar',
            onPress: async () => {
              try {
                await contractsService.signContract(contract.id, { role });
                Alert.alert('Sucesso', 'Contrato assinado com sucesso!');
                loadContracts();
              } catch (error: any) {
                Alert.alert('Erro', error.message);
              }
            },
          },
        ]
      );
    } catch (error: any) {
      Alert.alert('Erro', error.message);
    }
  };

  const handleCancelContract = async (contract: Contract) => {
    try {
      await contractsService.cancelContract(contract.id);
      Alert.alert('Sucesso', 'Contrato cancelado com sucesso!');
      loadContracts();
    } catch (error: any) {
      Alert.alert('Erro', error.message);
    }
  };

  const renderFilterButton = (status: FilterStatus, label: string) => (
    <TouchableOpacity
      key={status}
      style={[
        styles.filterButton,
        filter === status && styles.filterButtonActive,
      ]}
      onPress={() => setFilter(status)}
    >
      <Text
        style={[
          styles.filterButtonText,
          filter === status && styles.filterButtonTextActive,
        ]}
      >
        {label}
      </Text>
    </TouchableOpacity>
  );

  const renderEmptyState = () => (
    <View style={styles.emptyState}>
      <Ionicons name="document-text-outline" size={64} color="#ccc" />
      <Text style={styles.emptyStateTitle}>Nenhum contrato encontrado</Text>
      <Text style={styles.emptyStateSubtitle}>
        {filter === 'all'
          ? 'Você ainda não tem contratos criados.'
          : `Nenhum contrato com status "${getStatusText(filter)}".`}
      </Text>
    </View>
  );

  const renderContract = ({ item }: { item: Contract }) => (
    <ContractCard
      contract={item}
      onPress={() => handleContractPress(item)}
      onSign={() => handleSignContract(item)}
      onCancel={() => handleCancelContract(item)}
    />
  );

  const getStatusText = (status: FilterStatus) => {
    const map: Record<FilterStatus, string> = {
      'all': 'Todos',
      'pending-signature': 'Pendentes',
      'active': 'Ativos',
      'closed': 'Concluídos',
      'canceled': 'Cancelados',
    };
    return map[status] || status;
  };

  const getContractCounts = () => {
    return {
      all: contracts.length,
      'pending-signature': contracts.filter(c => c.status === 'pending-signature').length,
      active: contracts.filter(c => c.status === 'active').length,
      closed: contracts.filter(c => c.status === 'closed').length,
      canceled: contracts.filter(c => c.status === 'canceled').length,
    };
  };

  const counts = getContractCounts();

  if (loading) {
    return (
      <View style={[styles.container, styles.centered]}>
        <Text>Carregando contratos...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Meus Contratos</Text>
        <Text style={styles.subtitle}>
          {counts.all} contrato{counts.all !== 1 ? 's' : ''}
        </Text>
      </View>

      <View style={styles.filters}>
        {renderFilterButton('all', `Todos (${counts.all})`)}
        {renderFilterButton('pending-signature', `Pendentes (${counts['pending-signature']})`)}
        {renderFilterButton('active', `Ativos (${counts.active})`)}
        {renderFilterButton('closed', `Concluídos (${counts.closed})`)}
      </View>

      <FlatList
        data={contracts}
        renderItem={renderContract}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
        }
        ListEmptyComponent={renderEmptyState}
        showsVerticalScrollIndicator={false}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  centered: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  header: {
    backgroundColor: '#fff',
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 15,
    borderBottomWidth: 1,
    borderBottomColor: '#e5e5e5',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
  },
  filters: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    paddingVertical: 15,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e5e5e5',
  },
  filterButton: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 20,
    marginRight: 8,
    backgroundColor: '#f8f9fa',
  },
  filterButtonActive: {
    backgroundColor: '#007bff',
  },
  filterButtonText: {
    fontSize: 14,
    color: '#666',
    fontWeight: '500',
  },
  filterButtonTextActive: {
    color: '#fff',
  },
  listContent: {
    padding: 20,
    paddingBottom: 100,
  },
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 60,
  },
  emptyStateTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginTop: 16,
    marginBottom: 8,
  },
  emptyStateSubtitle: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
    lineHeight: 24,
  },
}); 