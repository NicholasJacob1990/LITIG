import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Image, Switch } from 'react-native';
import { useState } from 'react';
import { User, Settings, Bell, Shield, CreditCard, Star, FileText, LogOut, ChevronRight, Edit3 as EditIcon, Building2, Scale, BarChart2, CheckSquare, Power } from 'lucide-react-native';
import { StatusBar } from 'expo-status-bar';
import { LinearGradient } from 'expo-linear-gradient';
import { useRouter } from 'expo-router';
import { useAuth } from '@/lib/contexts/AuthContext';

// Componente Unificado de Perfil
export default function ProfileScreen() {
  const { user, signOut, role } = useAuth();
  const router = useRouter();
  const [notificationsEnabled, setNotificationsEnabled] = useState(true);

  // Define os menus com base no 'role'
  const lawyerMenuItems = [
    { id: 'availability', title: 'Gestão de Disponibilidade', subtitle: 'Defina se está aceitando novos casos', icon: Power, color: '#16A34A', onPress: () => router.push('/(tabs)/profile/availability-settings')},
    { id: 'performance', title: 'Minha Performance', subtitle: 'Visualize suas métricas e KPIs', icon: BarChart2, color: '#1E40AF', onPress: () => router.push('/(tabs)/profile/performance') },
    { id: 'my-reviews', title: 'Minhas Avaliações', subtitle: 'Veja os feedbacks recebidos', icon: Star, color: '#F59E0B', onPress: () => router.push('/(tabs)/profile/my-reviews') },
    { id: 'profile-settings', title: 'Configurações de Perfil', subtitle: 'Edite seu perfil público e dados', icon: EditIcon, color: '#7C3AED', onPress: () => router.push('/(tabs)/profile/profile-settings') },
  ];

  const clientMenuItems = [
    { id: 'edit-profile', title: 'Editar Perfil', subtitle: 'Atualize suas informações', icon: EditIcon, color: '#1E40AF', onPress: () => router.push('/(tabs)/profile/profile-settings')},
    { id: 'contracts', title: 'Meus Contratos', subtitle: 'Visualize e gerencie seus contratos', icon: CheckSquare, color: '#059669', onPress: () => router.push('/(tabs)/contract') },
    { id: 'my-reviews', title: 'Minhas Avaliações', subtitle: 'Avaliações de atendimentos', icon: Star, color: '#F59E0B', onPress: () => router.push('/(tabs)/profile/my-reviews')},
    { id: 'privacy', title: 'Privacidade e Segurança', subtitle: 'Configurações de dados e LGPD', icon: Shield, color: '#EF4444', onPress: () => router.push('/(tabs)/profile/equity-settings')},
    { id: 'settings', title: 'Configurações Gerais', subtitle: 'Preferências do aplicativo', icon: Settings, color: '#6B7280', onPress: () => router.push('/(tabs)/_internal/settings')},
  ];

  // Renderiza a tela de advogado
  if (role === 'lawyer') {
    return (
      <View style={styles.container}>
        <LinearGradient colors={['#1F2937', '#4B5563']} style={styles.header}>
          <View style={styles.profileSection}>
            <Image source={{ uri: user?.user_metadata?.avatar_url || 'https://avatar.vercel.sh/lawyer.png' }} style={styles.avatar} />
            <View style={styles.userInfo}>
              <Text style={styles.userName}>{user?.user_metadata?.full_name || 'Advogado(a)'}</Text>
              <Text style={styles.userEmail}>{user?.email}</Text>
            </View>
          </View>
        </LinearGradient>
        <ScrollView style={styles.menuScroll}>
          {lawyerMenuItems.map((item) => (
            <TouchableOpacity key={item.id} style={styles.menuItem} onPress={item.onPress}>
              <View style={[styles.menuIcon, { backgroundColor: `${item.color}15` }]}><item.icon size={20} color={item.color} /></View>
              <View style={styles.menuContent}><Text style={styles.menuTitle}>{item.title}</Text><Text style={styles.menuSubtitle}>{item.subtitle}</Text></View>
              <ChevronRight size={20} color="#9CA3AF" />
            </TouchableOpacity>
          ))}
          <TouchableOpacity style={styles.logoutButton} onPress={signOut}><LogOut size={20} color="#EF4444" /><Text style={styles.logoutText}>Sair</Text></TouchableOpacity>
        </ScrollView>
      </View>
    );
  }

  // Renderiza a tela de cliente (padrão)
  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      <LinearGradient colors={['#1E40AF', '#3B82F6']} style={styles.clientHeader}>
         <Image source={{ uri: 'https://avatar.vercel.sh/client.png' }} style={styles.avatar} />
         <Text style={styles.userName}>Maria Silva Santos</Text>
         <Text style={styles.userEmail}>maria.silva@email.com</Text>
      </LinearGradient>
      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Configurações</Text>
          {clientMenuItems.map((item) => (
            <TouchableOpacity key={item.id} style={styles.menuItem} onPress={item.onPress}>
              <View style={[styles.menuIcon, { backgroundColor: `${item.color}15` }]}><item.icon size={20} color={item.color} /></View>
              <View style={styles.menuContent}><Text style={styles.menuTitle}>{item.title}</Text><Text style={styles.menuSubtitle}>{item.subtitle}</Text></View>
              <ChevronRight size={20} color="#9CA3AF" />
            </TouchableOpacity>
          ))}
        </View>
         <TouchableOpacity style={styles.logoutButton} onPress={signOut}><LogOut size={20} color="#EF4444" /><Text style={styles.logoutText}>Sair da Conta</Text></TouchableOpacity>
      </ScrollView>
    </View>
  );
}

// Estilos (unificados e simplificados)
const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F8FAFC' },
  // Estilos de Advogado
  header: { padding: 20, paddingTop: 60, borderBottomLeftRadius: 20, borderBottomRightRadius: 20 },
  profileSection: { flexDirection: 'row', alignItems: 'center' },
  avatar: { width: 64, height: 64, borderRadius: 32, borderWidth: 2, borderColor: '#FFFFFF' },
  userInfo: { marginLeft: 16 },
  userName: { fontFamily: 'Inter-Bold', fontSize: 20, color: '#FFFFFF' },
  userEmail: { fontFamily: 'Inter-Regular', fontSize: 14, color: '#E5E7EB' },
  menuScroll: { padding: 16 },
  menuItem: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#FFFFFF', padding: 16, borderRadius: 12, marginBottom: 12, shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 8, elevation: 2 },
  menuIcon: { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center', marginRight: 16 },
  menuContent: { flex: 1 },
  menuTitle: { fontFamily: 'Inter-SemiBold', fontSize: 16, color: '#1F2937' },
  menuSubtitle: { fontFamily: 'Inter-Regular', fontSize: 14, color: '#6B7280', marginTop: 2 },
  logoutButton: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', padding: 16, marginTop: 16, borderRadius: 12, backgroundColor: '#FEF2F2' },
  logoutText: { marginLeft: 8, color: '#EF4444', fontFamily: 'Inter-Bold' },
  // Estilos de Cliente
  clientHeader: { alignItems: 'center', padding: 20, paddingTop: 60, paddingBottom: 40, borderBottomLeftRadius: 24, borderBottomRightRadius: 24 },
  content: { flex: 1, marginTop: -20, borderTopLeftRadius: 20, borderTopRightRadius: 20, backgroundColor: '#F8FAFC', paddingHorizontal: 24 },
  section: { marginTop: 32 },
  sectionTitle: { fontFamily: 'Inter-SemiBold', fontSize: 18, color: '#1F2937', marginBottom: 16 },
});