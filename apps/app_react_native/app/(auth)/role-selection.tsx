import { View, Text, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Building, User, ChevronRight } from 'lucide-react-native';

export default function RoleSelection() {
  const router = useRouter();

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <View style={styles.content}>
        <Text style={styles.title}>Como você usará o LITGO?</Text>
        <Text style={styles.subtitle}>
          Escolha seu perfil para personalizarmos sua experiência.
        </Text>

        <TouchableOpacity style={styles.optionButton} onPress={() => router.push({ pathname: '/register-client' })}>
          <View style={styles.iconContainer}>
            <User size={24} color="#1E40AF" />
          </View>
          <View style={styles.textContainer}>
            <Text style={styles.optionTitle}>Sou um Cliente</Text>
            <Text style={styles.optionDescription}>
              Preciso de assessoria jurídica para um caso pessoal ou da minha empresa.
            </Text>
          </View>
          <ChevronRight size={24} color="#9CA3AF" />
        </TouchableOpacity>

        <TouchableOpacity style={styles.optionButton} onPress={() => router.push({ pathname: '/register-lawyer' })}>
          <View style={styles.iconContainer}>
            <Building size={24} color="#1E40AF" />
          </View>
          <View style={styles.textContainer}>
            <Text style={styles.optionTitle}>Sou Advogado</Text>
            <Text style={styles.optionDescription}>
              Quero me juntar à plataforma para atender clientes.
            </Text>
          </View>
          <ChevronRight size={24} color="#9CA3AF" />
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  content: {
    flex: 1,
    padding: 24,
    justifyContent: 'center',
  },
  title: {
    fontSize: 28,
    fontFamily: 'Inter-Bold',
    color: '#1F2937',
    textAlign: 'center',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    fontFamily: 'Inter-Regular',
    color: '#6B7280',
    textAlign: 'center',
    marginBottom: 40,
  },
  optionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    padding: 20,
    borderRadius: 16,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  iconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#DBEAFE',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 16,
  },
  textContainer: {
    flex: 1,
  },
  optionTitle: {
    fontSize: 18,
    fontFamily: 'Inter-Bold',
    color: '#1F2937',
  },
  optionDescription: {
    fontSize: 14,
    fontFamily: 'Inter-Regular',
    color: '#6B7280',
    marginTop: 4,
  },
}); 