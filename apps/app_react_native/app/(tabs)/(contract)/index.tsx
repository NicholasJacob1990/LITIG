import React, { useState } from 'react';
import { View, Text, StyleSheet, SafeAreaView, FlatList, TouchableOpacity, ActivityIndicator } from 'react-native';
import { useQuery } from '@tanstack/react-query';
import { useRouter } from 'expo-router';
import { FileText, CheckCircle, Clock, XCircle, LucideIcon } from 'lucide-react-native';
import { contractsService, Contract } from '@/lib/services/contracts';

const statusConfig: Record<Contract['status'], { label: string; icon: LucideIcon; color: string; }> = {
  'pending-signature': { label: 'Aguardando Assinaturas', icon: Clock, color: '#F59E0B' },
  'active': { label: 'Ativo', icon: CheckCircle, color: '#10B981' },
  'closed': { label: 'Concluído', icon: CheckCircle, color: '#6B7280' },
  'canceled': { label: 'Cancelado', icon: XCircle, color: '#EF4444' },
};

interface ContractCardProps {
  contract: Contract;
  onPress: () => void;
}

const ContractCard = ({ contract, onPress }: ContractCardProps) => {
  const config = statusConfig[contract.status] || { label: contract.status, icon: FileText, color: '#6B7280' };
  const Icon = config.icon;

  return (
    <TouchableOpacity style={styles.card} onPress={onPress}>
      <View style={styles.iconContainer}>
        <Icon size={24} color={config.color} />
      </View>
      <View style={styles.cardContent}>
        <Text style={styles.cardTitle}>Contrato do Caso #{contract.case_id.substring(0, 8)}</Text>
        <Text style={styles.cardDate}>Criado em: {new Date(contract.created_at).toLocaleDateString('pt-BR')}</Text>
      </View>
      <View style={[styles.statusBadge, { backgroundColor: `${config.color}20` }]}>
        <Text style={[styles.statusText, { color: config.color }]}>{config.label}</Text>
      </View>
    </TouchableOpacity>
  );
};

const ContractsListScreen = () => {
  const router = useRouter();
  const { data: contracts, isLoading, error } = useQuery({
    queryKey: ['contracts'],
    queryFn: () => contractsService.getContracts(),
  });

  const renderContent = () => {
    if (isLoading) {
      return <ActivityIndicator style={{ marginTop: 50 }} size="large" color="#1E40AF" />;
    }
    if (error) {
      return <Text style={styles.errorText}>Erro ao carregar contratos: {error.message}</Text>;
    }
    return (
      <FlatList
        data={contracts}
        renderItem={({ item }) => (
          <ContractCard
            contract={item}
            onPress={() => router.push(`/contract/${item.id}` as any)}
          />
        )}
        keyExtractor={item => item.id}
        contentContainerStyle={styles.listContent}
        ListEmptyComponent={<Text style={styles.emptyText}>Nenhum contrato encontrado.</Text>}
      />
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Meus Contratos</Text>
      </View>
      {renderContent()}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F3F4F6' },
  header: { padding: 24, backgroundColor: '#1E3A8A' },
  title: { fontSize: 28, fontWeight: 'bold', color: '#FFFFFF' },
  listContent: { padding: 16 },
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
  },
  iconContainer: {
    marginRight: 16,
  },
  cardContent: {
    flex: 1,
  },
  cardTitle: { fontSize: 16, fontWeight: '600', color: '#1F2937' },
  cardDate: { fontSize: 12, color: '#6B7280', marginTop: 4 },
  statusBadge: { paddingHorizontal: 8, paddingVertical: 4, borderRadius: 12 },
  statusText: { fontSize: 12, fontWeight: '500' },
  errorText: { textAlign: 'center', marginTop: 20, color: '#EF4444' },
  emptyText: { textAlign: 'center', marginTop: 20, color: '#6B7280' },
});

export default ContractsListScreen; 