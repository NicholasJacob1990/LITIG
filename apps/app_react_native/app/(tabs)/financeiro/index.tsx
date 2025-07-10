import React from 'react';
import { View, Text, StyleSheet, SafeAreaView, ScrollView } from 'react-native';
import { CreditCard, FileText, TrendingUp, DollarSign, Calendar, PieChart } from 'lucide-react-native';
import { useAuth } from '@/lib/contexts/AuthContext';

const ClientFinancialDashboard = () => {
  return (
    <SafeAreaView style={styles.container}>
      <ScrollView>
        <View style={styles.header}>
          <Text style={styles.title}>Minhas Finanças</Text>
          <Text style={styles.subtitle}>Acompanhe suas faturas e pagamentos</Text>
        </View>

        <View style={styles.kpiContainer}>
          <View style={styles.kpiCard}>
            <Text style={styles.kpiLabel}>Saldo Devedor</Text>
            <Text style={styles.kpiValue}>R$ 1.250,00</Text>
          </View>
          <View style={styles.kpiCard}>
            <Text style={styles.kpiLabel}>Próximo Vencimento</Text>
            <Text style={styles.kpiValue}>15/08/2025</Text>
          </View>
        </View>

        <View style={styles.actionsContainer}>
          <View style={styles.actionCard}>
            <FileText size={24} color="#1E40AF" />
            <Text style={styles.actionText}>Ver Faturas</Text>
          </View>
          <View style={styles.actionCard}>
            <CreditCard size={24} color="#059669" />
            <Text style={styles.actionText}>Métodos de Pag.</Text>
          </View>
          <View style={styles.actionCard}>
            <TrendingUp size={24} color="#7C3AED" />
            <Text style={styles.actionText}>Histórico</Text>
          </View>
        </View>

        <View style={styles.placeholder}>
          <Text style={styles.placeholderText}>
            Gráficos de gastos jurídicos e outras informações aparecerão aqui em breve.
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const LawyerFinancialDashboard = () => {
  return (
    <SafeAreaView style={styles.container}>
      <ScrollView>
        <View style={[styles.header, { backgroundColor: '#059669' }]}>
          <Text style={styles.title}>Meus Honorários</Text>
          <Text style={styles.subtitle}>Acompanhe seus ganhos e repasses</Text>
        </View>

        <View style={styles.kpiContainer}>
          <View style={styles.kpiCard}>
            <Text style={styles.kpiLabel}>Faturado (Mês)</Text>
            <Text style={[styles.kpiValue, { color: '#059669' }]}>R$ 8.750,00</Text>
          </View>
          <View style={styles.kpiCard}>
            <Text style={styles.kpiLabel}>Próximo Repasse</Text>
            <Text style={styles.kpiValue}>22/08/2025</Text>
          </View>
        </View>

        <View style={styles.actionsContainer}>
          <View style={styles.actionCard}>
            <DollarSign size={24} color="#059669" />
            <Text style={styles.actionText}>Honorários</Text>
          </View>
          <View style={styles.actionCard}>
            <Calendar size={24} color="#1E40AF" />
            <Text style={styles.actionText}>Repasses</Text>
          </View>
          <View style={styles.actionCard}>
            <PieChart size={24} color="#7C3AED" />
            <Text style={styles.actionText}>Relatórios</Text>
          </View>
        </View>

        <View style={styles.placeholder}>
          <Text style={styles.placeholderText}>
            Métricas de performance financeira e gráficos de honorários aparecerão aqui em breve.
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const FinancialDashboardScreen = () => {
  const { role } = useAuth();

  if (role === 'lawyer') {
    return <LawyerFinancialDashboard />;
  }

  return <ClientFinancialDashboard />;
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F3F4F6',
  },
  header: {
    padding: 24,
    backgroundColor: '#1E3A8A',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  subtitle: {
    fontSize: 16,
    color: '#D1D5DB',
    marginTop: 4,
  },
  kpiContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingVertical: 20,
    backgroundColor: '#FFFFFF',
    marginHorizontal: 16,
    borderRadius: 12,
    marginTop: -30,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 5,
  },
  kpiCard: {
    alignItems: 'center',
  },
  kpiLabel: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 4,
  },
  kpiValue: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1F2937',
  },
  actionsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: 16,
    marginTop: 16,
  },
  actionCard: {
    alignItems: 'center',
    padding: 16,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    width: '30%',
  },
  actionText: {
    marginTop: 8,
    fontSize: 12,
    fontWeight: '600',
    color: '#374151',
  },
  placeholder: {
    margin: 16,
    padding: 24,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    alignItems: 'center',
  },
  placeholderText: {
    color: '#6B7280',
    textAlign: 'center',
  },
});

export default FinancialDashboardScreen; 