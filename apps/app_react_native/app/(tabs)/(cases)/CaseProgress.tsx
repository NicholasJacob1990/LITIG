import React from 'react';
import { View, Text, StyleSheet, ScrollView, ActivityIndicator, RefreshControl } from 'react-native';
import { useRoute, RouteProp } from '@react-navigation/native';
import { useQuery } from '@tanstack/react-query';
import { StatusBar } from 'expo-status-bar';

import { getProcessEvents, ProcessEventData } from '@/lib/services/processEvents';
import { CasesStackParamList } from '@/lib/types/cases';

import TopBar from '@/components/layout/TopBar';
import CaseTimeline from '@/components/molecules/CaseTimeline';
import { Alert } from 'react-native';

type CaseProgressRouteProp = RouteProp<CasesStackParamList, 'CaseProgress'>;

export default function CaseProgress() {
  const route = useRoute<CaseProgressRouteProp>();
  const { caseId } = route.params;

  const { 
    data: events, 
    isLoading, 
    isError,
    error,
    refetch,
    isRefetching
  } = useQuery<ProcessEventData[], Error>({
    queryKey: ['processEvents', caseId],
    queryFn: () => getProcessEvents(caseId),
    enabled: !!caseId,
  });

  if (isError) {
    console.error("Erro ao buscar andamento processual:", error);
    Alert.alert("Erro", "Não foi possível carregar o andamento processual.");
  }

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      <TopBar title="Andamento Processual" showBack />
      <ScrollView 
        contentContainerStyle={styles.content}
        refreshControl={
          <RefreshControl refreshing={isRefetching} onRefresh={refetch} />
        }
      >
        {isLoading && !isRefetching ? (
          <View style={styles.centered}>
            <ActivityIndicator size="large" color="#006CFF" />
            <Text style={styles.loadingText}>Carregando andamento...</Text>
          </View>
        ) : events && events.length > 0 ? (
          <CaseTimeline events={events} isLoading={isLoading} />
        ) : (
          <View style={styles.centered}>
            <Text style={styles.emptyText}>Nenhum andamento processual encontrado.</Text>
          </View>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  content: {
    flexGrow: 1,
    padding: 20,
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 10,
    fontSize: 16,
    color: '#6B7280',
    fontFamily: 'Inter-Regular'
  },
  emptyText: {
    fontSize: 16,
    color: '#6B7280',
    fontFamily: 'Inter-Regular'
  }
}); 