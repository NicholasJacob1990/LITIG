import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { Briefcase, Users, Bell, MessageSquare, LogOut, Calendar } from 'lucide-react-native';
import { router } from 'expo-router';
import { useAuth } from '@/lib/contexts/AuthContext';
import { StatusBar } from 'expo-status-bar';

const StatCard = ({ icon, label, value }: { icon: React.ReactNode, label: string, value: string }) => (
  <View style={styles.statCard}>
    {icon}
    <Text style={styles.statValue}>{value}</Text>
    <Text style={styles.statLabel}>{label}</Text>
  </View>
);

const ActionButton = ({ icon, label, screen }: { icon: React.ReactNode, label: string, screen: string }) => (
  <TouchableOpacity style={styles.actionButton} onPress={() => router.push(screen as any)}>
    {icon}
    <Text style={styles.actionLabel}>{label}</Text>
  </TouchableOpacity>
);

export default function LawyerDashboard() {
  const { user, signOut } = useAuth();

  const displayName = user?.user_metadata?.full_name || user?.email;

  return (
    <ScrollView style={styles.container}>
      <StatusBar style="light" />
      <View style={styles.header}>
        <View>
          <Text style={styles.welcomeText}>Bem-vindo(a),</Text>
          {displayName && <Text style={styles.userName}>{displayName}</Text>}
        </View>
        <TouchableOpacity onPress={signOut} style={styles.logoutButton}>
          <LogOut size={24} color="#FFFFFF" />
        </TouchableOpacity>
      </View>

      <View style={styles.statsContainer}>
        <StatCard icon={<Briefcase size={28} color="#FFFFFF" />} label="Casos Ativos" value="12" />
        <StatCard icon={<Users size={28} color="#FFFFFF" />} label="Novos Leads" value="3" />
        <StatCard icon={<Bell size={28} color="#FFFFFF" />} label="Alertas" value="5" />
      </View>

      <View style={styles.actionsGrid}>
        <ActionButton icon={<Briefcase size={32} color="#FFFFFF" />} label="Meus Casos" screen="/cases" />
        <ActionButton icon={<MessageSquare size={32} color="#FFFFFF" />} label="Mensagens" screen="/chat" />
        <ActionButton icon={<Calendar size={32} color="#FFFFFF" />} label="Agenda" screen="/agenda-real" />
        <ActionButton icon={<Bell size={32} color="#FFFFFF" />} label="Notificações" screen="/notifications" />
      </View>

      <View style={styles.quickAccess}>
        <Text style={styles.quickAccessTitle}>Acesso Rápido</Text>
        <TouchableOpacity style={styles.quickAccessItem} onPress={() => router.push('/profile')}>
            <Text style={styles.quickAccessText}>Editar Perfil Público</Text>
        </TouchableOpacity>
         <TouchableOpacity style={styles.quickAccessItem} onPress={() => router.push('/profile/performance')}>
            <Text style={styles.quickAccessText}>Análise de Performance</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    width: '100%',
  },
  header: {
    paddingTop: 60,
    paddingHorizontal: 24,
    paddingBottom: 24,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  welcomeText: {
    color: 'rgba(255, 255, 255, 0.8)',
    fontSize: 16,
  },
  userName: {
    color: '#FFFFFF',
    fontSize: 24,
    fontWeight: 'bold',
  },
  logoutButton: {
    padding: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 50,
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingHorizontal: 16,
    marginBottom: 24,
  },
  statCard: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 16,
    padding: 16,
    alignItems: 'center',
    width: '30%',
  },
  statValue: {
    color: '#FFFFFF',
    fontSize: 28,
    fontWeight: 'bold',
    marginTop: 8,
  },
  statLabel: {
    color: 'rgba(255, 255, 255, 0.7)',
    fontSize: 14,
    marginTop: 4,
  },
  actionsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-around',
    paddingHorizontal: 16,
    marginBottom: 24,
  },
  actionButton: {
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 16,
    width: '45%',
    aspectRatio: 1,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  actionLabel: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: 'bold',
    marginTop: 12,
  },
  quickAccess: {
      paddingHorizontal: 24,
  },
  quickAccessTitle: {
      color: '#FFFFFF',
      fontSize: 20,
      fontWeight: 'bold',
      marginBottom: 16,
  },
  quickAccessItem: {
      backgroundColor: 'rgba(255, 255, 255, 0.1)',
      borderRadius: 12,
      padding: 16,
      marginBottom: 12,
  },
  quickAccessText: {
      color: '#FFFFFF',
      fontSize: 16,
      fontWeight: '600',
  }
}); 