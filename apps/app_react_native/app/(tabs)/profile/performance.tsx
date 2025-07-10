import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, ActivityIndicator, Dimensions } from 'react-native';
import { useQuery } from '@tanstack/react-query';
import { DollarSign, PieChart, TrendingUp, BarChart2 } from 'lucide-react-native';
import { BarChart } from 'react-native-gifted-charts';
import { financialReportsService } from '@/lib/services/financial';
import MetricCard from './components/MetricCard';

const screenWidth = Dimensions.get('window').width;

const PerformanceScreen = () => {
  const [activeTab, setActiveTab] = useState('overview');

  const { data: financials, isLoading, error } = useQuery({
    queryKey: ['lawyerFinancials'],
    queryFn: () => financialReportsService.getLawyerFinancials(),
  });

  const renderContent = () => {
    if (isLoading) {
      return <ActivityIndicator size="large" style={styles.loader} />;
    }
    if (error) {
      return <Text style={styles.errorText}>Erro ao carregar dados: {error.message}</Text>;
    }
    if (!financials) {
      return <Text style={styles.errorText}>Nenhum dado financeiro encontrado.</Text>;
    }

    const chartData = financials.monthly_billing.map(item => ({
      value: item.value,
      label: item.month.substring(5, 7),
      frontColor: '#177AD5',
    }));

    return (
      <View>
        <View style={styles.metricsGrid}>
          <MetricCard title="Faturamento Total" value={`R$ ${financials.total_billed.toFixed(2)}`} icon={DollarSign} color="#10B981" />
          <MetricCard title="Recebimento Total" value={`R$ ${financials.total_received.toFixed(2)}`} icon={PieChart} color="#3B82F6" />
          <MetricCard title="Contratos Ativos" value={financials.active_contracts.toString()} icon={TrendingUp} color="#7C3AED" />
          <MetricCard title="Ticket Médio" value={`R$ ${financials.avg_ticket.toFixed(2)}`} icon={BarChart2} color="#F59E0B" />
        </View>

        <View style={styles.chartContainer}>
          <Text style={styles.sectionTitle}>Faturamento Mensal (Últimos meses)</Text>
          <BarChart
            data={chartData}
            barWidth={30}
            spacing={20}
            roundedTop
            isAnimated
          />
        </View>
      </View>
    );
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Minha Performance</Text>
      </View>

      <View style={styles.tabContainer}>
        <TouchableOpacity onPress={() => setActiveTab('overview')} style={[styles.tab, activeTab === 'overview' && styles.activeTab]}>
          <Text style={[styles.tabText, activeTab === 'overview' && styles.activeTabText]}>Visão Geral</Text>
        </TouchableOpacity>
        <TouchableOpacity onPress={() => setActiveTab('reports')} style={[styles.tab, activeTab === 'reports' && styles.activeTab]}>
          <Text style={[styles.tabText, activeTab === 'reports' && styles.activeTabText]}>Relatórios</Text>
        </TouchableOpacity>
      </View>

      {renderContent()}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F8FAFC' },
  header: { padding: 24, backgroundColor: '#1E3A8A' },
  title: { fontSize: 28, fontWeight: 'bold', color: '#FFFFFF' },
  tabContainer: { flexDirection: 'row', padding: 16, justifyContent: 'center', backgroundColor: '#FFFFFF' },
  tab: { paddingVertical: 8, paddingHorizontal: 16, borderRadius: 20 },
  activeTab: { backgroundColor: '#1E40AF' },
  tabText: { color: '#374151', fontWeight: '600' },
  activeTabText: { color: '#FFFFFF' },
  metricsGrid: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-around', padding: 16 },
  chartContainer: { padding: 16, backgroundColor: '#FFFFFF', borderRadius: 12, margin: 16 },
  sectionTitle: { fontSize: 18, fontWeight: 'bold', marginBottom: 16 },
  loader: { marginTop: 50 },
  errorText: { textAlign: 'center', marginTop: 20, color: 'red' },
});

export default PerformanceScreen; 