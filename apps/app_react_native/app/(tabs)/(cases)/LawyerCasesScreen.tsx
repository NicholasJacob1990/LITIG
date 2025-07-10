import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, ActivityIndicator } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Briefcase, CheckCircle, Clock, DollarSign, User, Search, Filter } from 'lucide-react-native';
import { StatusBar } from 'expo-status-bar';
import { useAuth } from '@/lib/contexts/AuthContext';
import supabase from '@/lib/supabase';
import ImprovedCaseList from '@/components/organisms/ImprovedCaseList';
import { getLawyerCases, getCaseStats, CaseData } from '@/lib/services/cases';

const LawyerDashboard = () => (
  <View style={styles.dashboard}>
    <View style={styles.kpi}>
      <Briefcase size={24} color="#3B82F6" />
      <Text style={styles.kpiValue}>12</Text>
      <Text style={styles.kpiLabel}>Casos Ativos</Text>
    </View>
    <View style={styles.kpi}>
      <Clock size={24} color="#F59E0B" />
      <Text style={styles.kpiValue}>3</Text>
      <Text style={styles.kpiLabel}>Aguardando</Text>
    </View>
    <View style={styles.kpi}>
      <DollarSign size={24} color="#10B981" />
      <Text style={styles.kpiValue}>R$ 7.5k</Text>
      <Text style={styles.kpiLabel}>Faturado</Text>
    </View>
  </View>
);

const CaseCard = ({ caseData }: { caseData: any }) => {
  const statusStyles = {
    pending_assignment: { backgroundColor: '#FEF3C7', color: '#B45309', text: 'Aguardando Atribuição' },
    assigned: { backgroundColor: '#DBEAFE', color: '#1E40AF', text: 'Atribuído' },
    in_progress: { backgroundColor: '#EBF8FF', color: '#0369A1', text: 'Em Andamento' },
    completed: { backgroundColor: '#D1FAE5', color: '#065F46', text: 'Concluído' },
    cancelled: { backgroundColor: '#FEE2E2', color: '#DC2626', text: 'Cancelado' },
  };

  return (
    <TouchableOpacity style={styles.card}>
      <View style={styles.cardHeader}>
        <View style={styles.clientInfo}>
          <User size={16} color="#4B5563" />
          <Text style={styles.clientName}>{caseData.client_name}</Text>
        </View>
        <View style={[styles.statusBadge, { backgroundColor: statusStyles[caseData.status as keyof typeof statusStyles]?.backgroundColor || '#F3F4F6' }]}>
          <Text style={[styles.statusText, { color: statusStyles[caseData.status as keyof typeof statusStyles]?.color || '#6B7280' }]}>
            {statusStyles[caseData.status as keyof typeof statusStyles]?.text || caseData.status}
          </Text>
        </View>
      </View>
      <Text style={styles.caseArea}>
        {caseData.ai_analysis?.classificacao?.area_principal || 'Área não definida'}
      </Text>
      <View style={styles.cardFooter}>
        <View style={styles.feeContainer}>
          <Text style={styles.feeLabel}>Honorários:</Text>
          <Text style={styles.feeValue}>R$ {caseData.fee?.toFixed(2) || 'N/A'}</Text>
        </View>
        {caseData.unread_messages > 0 && (
          <View style={styles.unreadBadge}>
            <Text style={styles.unreadText}>{caseData.unread_messages}</Text>
          </View>
        )}
      </View>
    </TouchableOpacity>
  );
};

export default function LawyerCasesScreen() {
  const { user } = useAuth();
  const [cases, setCases] = useState<CaseData[]>([]);
  const [caseStats, setCaseStats] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadCases = useCallback(async () => {
    if (!user) return;
    setIsLoading(true);
    setError(null);
    try {
      const [casesData, statsData] = await Promise.all([
        getLawyerCases(user.id), 
        getCaseStats(user.id)
      ]);
      setCases(casesData);
      setCaseStats(statsData);
    } catch (e) {
      setError('Falha ao carregar seus casos.');
      console.error(e);
    } finally {
      setIsLoading(false);
    }
  }, [user]);

  useEffect(() => {
    loadCases();
  }, [loadCases]);

  return (
    <ImprovedCaseList
      cases={cases}
      caseStats={caseStats}
      isLoading={isLoading}
      error={error}
      onRefresh={loadCases}
      headerComponent={<LawyerDashboard />}
    />
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F3F4F6' },
  header: {
    backgroundColor: '#1E293B',
    paddingTop: 60,
    paddingBottom: 70,
    paddingHorizontal: 20,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerTitle: { fontSize: 24, fontWeight: 'bold', color: '#FFFFFF' },
  headerActions: { flexDirection: 'row', gap: 16 },
  dashboard: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: 16,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    marginHorizontal: 16,
    marginTop: -40,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 5,
  },
  kpi: { alignItems: 'center', gap: 4 },
  kpiValue: { fontSize: 18, fontWeight: 'bold', color: '#1F2937' },
  kpiLabel: { fontSize: 12, color: '#6B7280' },
  listContainer: {
    paddingHorizontal: 16,
    marginTop: 16,
  },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  clientInfo: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  clientName: { fontWeight: '600', color: '#1F2937' },
  statusBadge: { paddingHorizontal: 8, paddingVertical: 4, borderRadius: 12 },
  statusText: { fontSize: 12, fontWeight: '500' },
  caseArea: { fontSize: 16, fontWeight: 'bold', color: '#111827', marginBottom: 16 },
  cardFooter: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  feeContainer: {},
  feeLabel: { fontSize: 12, color: '#6B7280' },
  feeValue: { fontWeight: 'bold', color: '#10B981' },
  unreadBadge: {
    backgroundColor: '#EF4444',
    borderRadius: 12,
    width: 24,
    height: 24,
    justifyContent: 'center',
    alignItems: 'center',
  },
  unreadText: { color: '#FFFFFF', fontWeight: 'bold', fontSize: 12 },
}); 