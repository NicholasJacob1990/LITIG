import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, StyleSheet, SafeAreaView, FlatList, TouchableOpacity, ActivityIndicator, RefreshControl } from 'react-native';
import { useRouter } from 'expo-router';
import { Briefcase, ChevronRight, LucideIcon } from 'lucide-react-native';
import { getCasesWithMatches } from '@/lib/services/api';
import { Case } from '@/lib/types/cases';
import EmptyState from '@/components/atoms/EmptyState';
import { useAuth } from '@/lib/contexts/AuthContext';

// Combinando o tipo Case com a contagem de matches
export type CaseWithMatches = Case & { match_count: number };

const RecommendationsScreen = () => {
  const router = useRouter();
  const { role, isLoading: authLoading } = useAuth();
  const [cases, setCases] = useState<CaseWithMatches[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchCases = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const fetchedCases: CaseWithMatches[] = await getCasesWithMatches();
      setCases(fetchedCases);
    } catch (e) {
      setError('Falha ao buscar suas recomendações. Tente novamente.');
      console.error(e);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    // Se ainda carregando info de auth, aguardar
    if (authLoading) return;
    // Se não for cliente, redirecionar para tela inicial
    if (role !== 'client') {
      router.replace('/');
      return;
    }
    fetchCases();
  }, [fetchCases, role, authLoading]);

  const handleCasePress = (caseId: string) => {
    router.push(`/MatchesPage?caseId=${caseId}&fromRecs=true`);
  };

  const renderCaseItem = ({ item }: { item: CaseWithMatches }) => (
    <TouchableOpacity style={styles.caseItem} onPress={() => handleCasePress(item.id)}>
      <View style={styles.caseIcon}>
        <Briefcase size={24} color="#1D4ED8" />
      </View>
      <View style={styles.caseInfo}>
        <Text style={styles.caseTitle} numberOfLines={1}>{item.title}</Text>
        <Text style={styles.caseSubtitle}>{item.match_count} advogados recomendados</Text>
      </View>
      <ChevronRight size={20} color="#9CA3AF" />
    </TouchableOpacity>
  );

  if (authLoading) {
    return (
      <View style={[styles.container, styles.centered]}>
        <ActivityIndicator size="large" color="#1F2937" />
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Suas Recomendações</Text>
      </View>
      <FlatList
        data={cases}
        keyExtractor={(item) => item.id}
        renderItem={renderCaseItem}
        contentContainerStyle={styles.listContent}
        refreshControl={<RefreshControl refreshing={isLoading} onRefresh={fetchCases} />}
        ListEmptyComponent={
          !isLoading ? (
            <EmptyState
              icon={Briefcase as unknown as React.ComponentType<{ size: number; color: string; }>}
              title="Nenhuma Recomendação"
              description="Quando você criar um caso e receber recomendações de advogados, elas aparecerão aqui."
            />
          ) : null
        }
      />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  header: {
    paddingHorizontal: 16,
    paddingVertical: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
    backgroundColor: 'white',
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1F2937',
  },
  listContent: {
    padding: 16,
  },
  caseItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'white',
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 2,
  },
  caseIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#DBEAFE',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  caseInfo: {
    flex: 1,
  },
  caseTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 4,
  },
  caseSubtitle: {
    fontSize: 14,
    color: '#6B7280',
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default RecommendationsScreen; 