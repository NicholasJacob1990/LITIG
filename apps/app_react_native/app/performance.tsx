import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, StyleSheet, SafeAreaView, ScrollView, TouchableOpacity, ActivityIndicator, RefreshControl } from 'react-native';
import { useRouter } from 'expo-router';
import { ArrowLeft, BarChart, Star, BrainCircuit } from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { getLawyerPerformance, LawyerKPIs } from '@/lib/services/api';
import EmptyState from '@/components/atoms/EmptyState';

const PerformanceDashboard = () => {
  const router = useRouter();
  const [performanceData, setPerformanceData] = useState<LawyerKPIs | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPerformanceData = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await getLawyerPerformance();
      setPerformanceData(data);
    } catch (e) {
      setError('Falha ao carregar dados de desempenho.');
      console.error(e);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchPerformanceData();
  }, [fetchPerformanceData]);

  if (isLoading) {
    return (
      <View style={[styles.container, styles.centered]}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  if (error || !performanceData) {
    return (
        <EmptyState
            icon={BarChart}
            title="Erro ao Carregar"
            description={error || "Não foi possível carregar seus dados de desempenho."}
            actionText="Tentar novamente"
            onAction={fetchPerformanceData}
        />
    );
  }

  const successRates = Object.entries(performanceData.kpi_subarea || {}).map(([area, rate]) => ({
    area,
    rate,
  })).sort((a, b) => b.rate - a.rate);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <ArrowLeft size={24} color="#1F2937" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Meu Desempenho</Text>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView 
        contentContainerStyle={styles.content}
        refreshControl={<RefreshControl refreshing={isLoading} onRefresh={fetchPerformanceData} />}
      >
        <Text style={styles.sectionTitle}>Resumo Geral</Text>
        <View style={styles.summaryGrid}>
          <LinearGradient colors={['#FACC15', '#F59E0B']} style={styles.kpiCard}>
            <Star size={24} color="white" />
            <Text style={styles.kpiValue}>{performanceData.kpi.avaliacao_media?.toFixed(1) || 'N/A'}</Text>
            <Text style={styles.kpiLabel}>Avaliação Média</Text>
          </LinearGradient>
          <LinearGradient colors={['#EC4899', '#DB2777']} style={styles.kpiCard}>
            <BrainCircuit size={24} color="white" />
            <Text style={styles.kpiValue}>{(performanceData.kpi_softskill * 100).toFixed(0)}%</Text>
            <Text style={styles.kpiLabel}>Soft Skills</Text>
          </LinearGradient>
          <LinearGradient colors={['#3B82F6', '#1D4ED8']} style={styles.kpiCard}>
            <BarChart size={24} color="white" />
            <Text style={styles.kpiValue}>{(performanceData.kpi.cv_score * 100).toFixed(0)}%</Text>
            <Text style={styles.kpiLabel}>Score do CV</Text>
          </LinearGradient>
        </View>

        <Text style={styles.sectionTitle}>Taxa de Sucesso por Subárea</Text>
        <View style={styles.ratesContainer}>
          {successRates.length > 0 ? successRates.map((item, index) => (
            <View key={index} style={styles.rateItem}>
              <Text style={styles.rateArea}>{item.area}</Text>
              <View style={styles.rateBarContainer}>
                <View style={[styles.rateBar, { width: `${item.rate * 100}%` }]} />
              </View>
              <Text style={styles.rateValue}>{(item.rate * 100).toFixed(0)}%</Text>
            </View>
          )) : (
            <Text style={styles.noDataText}>Nenhum dado de subárea disponível.</Text>
          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#F9FAFB',
    },
    header: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 16,
        paddingVertical: 12,
        borderBottomWidth: 1,
        borderBottomColor: '#E5E7EB',
        backgroundColor: 'white',
    },
    backButton: {
        padding: 8,
    },
    headerTitle: {
        fontSize: 20,
        fontWeight: 'bold',
        color: '#1F2937',
    },
    content: {
        padding: 20,
    },
    sectionTitle: {
        fontSize: 18,
        fontWeight: '600',
        color: '#111827',
        marginBottom: 16,
        marginTop: 12,
    },
    summaryGrid: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        marginBottom: 20,
    },
    kpiCard: {
        flex: 1,
        padding: 16,
        borderRadius: 12,
        alignItems: 'center',
        marginHorizontal: 4,
    },
    kpiValue: {
        fontSize: 24,
        fontWeight: 'bold',
        color: 'white',
        marginTop: 8,
    },
    kpiLabel: {
        fontSize: 12,
        color: 'rgba(255, 255, 255, 0.8)',
        marginTop: 4,
    },
    ratesContainer: {
        backgroundColor: 'white',
        borderRadius: 12,
        padding: 16,
    },
    rateItem: {
        flexDirection: 'row',
        alignItems: 'center',
        marginBottom: 12,
    },
    rateArea: {
        width: '40%',
        fontSize: 14,
        color: '#374151',
    },
    rateBarContainer: {
        flex: 1,
        height: 8,
        backgroundColor: '#E5E7EB',
        borderRadius: 4,
        marginHorizontal: 8,
    },
    rateBar: {
        height: 8,
        backgroundColor: '#3B82F6',
        borderRadius: 4,
    },
    rateValue: {
        width: '15%',
        textAlign: 'right',
        fontSize: 14,
        fontWeight: '600',
        color: '#111827',
    },
    noDataText: {
        textAlign: 'center',
        color: '#6B7280',
        marginTop: 16,
    },
    centered: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
    },
});

export default PerformanceDashboard; 