import { View, StyleSheet, ActivityIndicator } from 'react-native';
import { useAuth } from '@/lib/contexts/AuthContext';
import ClientDashboard from '@/components/organisms/ClientDashboard';
import LawyerDashboard from '@/components/organisms/LawyerDashboard';
import { LinearGradient } from 'expo-linear-gradient';

export default function HomeScreen() {
  const { role, isLoading } = useAuth();

  if (isLoading) {
    return (
      <View style={styles.container}>
         <LinearGradient
            colors={['#0F172A', '#1E293B']}
            style={styles.background}
          />
        <ActivityIndicator size="large" color="#FFFFFF" />
      </View>
    );
  }

  return (
    <View style={styles.container}>
       <LinearGradient
        colors={['#0F172A', '#1E293B']}
        style={styles.background}
      />
      {role === 'client' ? <ClientDashboard /> : <LawyerDashboard />}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  background: {
    position: 'absolute',
    left: 0,
    right: 0,
    top: 0,
    height: '100%',
  },
});