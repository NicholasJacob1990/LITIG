import React from 'react';
import { View, Text, StyleSheet, ScrollView, ActivityIndicator, RefreshControl } from 'react-native';
import { useQuery } from '@tanstack/react-query';
import { Sliders, Zap } from 'lucide-react-native';

import { providerService } from '@/lib/services/provider';
import { WeakPoint, Suggestion } from '@/lib/services/types';
import ProfileStrength from './components/ProfileStrength';
import DiagnosticCard from './components/DiagnosticCard';

const PerformanceScreen = () => {
  const { data: insights, isLoading, error, refetch } = useQuery({
    queryKey: ['performanceInsights'],
    queryFn: () => providerService.getPerformanceInsights(),
  });

  const renderContent = () => {
    if (isLoading) {
      return <ActivityIndicator size="large" style={styles.loader} color="#1E40AF" />;
    }
    if (error) {
      return <Text style={styles.errorText}>Erro ao carregar dados: {error.message}</Text>;
    }
    if (!insights) {
      return <Text style={styles.errorText}>Nenhum dado de performance encontrado.</Text>;
    }

    // Assumindo que a API retorna os pontos fracos e sugestões na mesma ordem.
    const diagnosticItems = insights.weak_points.map((wp: WeakPoint, index: number) => ({
      weakPoint: wp,
      suggestion: insights.improvement_suggestions[index],
    }));

    return (
      <ScrollView
        contentContainerStyle={styles.contentContainer}
        refreshControl={<RefreshControl refreshing={isLoading} onRefresh={refetch} />}
      >
        <ProfileStrength
          score={insights.overall_score}
          grade={insights.grade}
          trend={insights.trend}
        />

        <View style={styles.sectionHeader}>
          <Sliders size={20} color="#1E40AF" />
          <Text style={styles.sectionTitle}>Diagnóstico e Oportunidades</Text>
        </View>
        
        {diagnosticItems.map((item: { weakPoint: WeakPoint; suggestion: Suggestion }, index: number) => (
          item.suggestion && (
            <DiagnosticCard
              key={index}
              weakPoint={item.weakPoint}
              suggestion={item.suggestion}
            />
          )
        ))}

        {diagnosticItems.length === 0 && (
          <View style={styles.allGoodContainer}>
            <Zap size={24} color="#10B981" />
            <Text style={styles.allGoodTitle}>Tudo Certo por Aqui!</Text>
            <Text style={styles.allGoodText}>
              Seu perfil está com uma ótima performance. Continue assim!
            </Text>
          </View>
        )}
      </ScrollView>
    );
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Minha Performance</Text>
        <Text style={styles.subtitle}>Insights para otimizar seu perfil e resultados</Text>
      </View>
      {renderContent()}
    </View>
  );
};

const styles = StyleSheet.create({
  container: { 
    flex: 1, 
    backgroundColor: '#F3F4F6' 
  },
  header: { 
    backgroundColor: '#1E40AF',
    padding: 24,
    paddingTop: 48,
    borderBottomLeftRadius: 24,
    borderBottomRightRadius: 24,
  },
  title: { 
    fontSize: 26, 
    fontWeight: 'bold', 
    color: '#FFFFFF',
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    color: '#D1D5DB',
    textAlign: 'center',
    marginTop: 4,
  },
  contentContainer: {
    paddingBottom: 24,
  },
  loader: { 
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorText: { 
    textAlign: 'center', 
    marginTop: 40, 
    color: '#EF4444',
    padding: 16,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 24,
    marginTop: 16,
    marginBottom: 8,
  },
  sectionTitle: { 
    fontSize: 20, 
    fontWeight: 'bold',
    color: '#1F2937',
    marginLeft: 8,
  },
  allGoodContainer: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    margin: 16,
    padding: 24,
    alignItems: 'center',
  },
  allGoodTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#10B981',
    marginTop: 8,
  },
  allGoodText: {
    fontSize: 14,
    color: '#4B5563',
    textAlign: 'center',
    marginTop: 4,
  }
});

export default PerformanceScreen; 