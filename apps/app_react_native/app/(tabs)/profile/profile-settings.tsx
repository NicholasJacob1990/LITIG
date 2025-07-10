import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { ChevronRight, Edit3, Shield } from 'lucide-react-native';
import { useRouter } from 'expo-router';

export default function ProfileSettingsScreen() {
  const router = useRouter();

  const settingsOptions = [
    {
      id: 'edit-public-profile',
      title: 'Editar Perfil Público',
      subtitle: 'Informações que os clientes veem',
      icon: Edit3,
      color: '#1E40AF',
      onPress: () => { /* Navegar para a tela de edição específica */ },
    },
    {
      id: 'equity-settings',
      title: 'Dados de Diversidade',
      subtitle: 'Informações confidenciais para equidade',
      icon: Shield,
      color: '#059669',
      onPress: () => router.push('/(tabs)/profile/equity-settings'),
    },
  ];

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Configurações do Perfil</Text>
      
      <View style={styles.optionsContainer}>
        {settingsOptions.map((item) => (
          <TouchableOpacity key={item.id} style={styles.menuItem} onPress={item.onPress}>
            <View style={[styles.menuIcon, { backgroundColor: `${item.color}15` }]}>
              <item.icon size={20} color={item.color} />
            </View>
            <View style={styles.menuContent}>
              <Text style={styles.menuTitle}>{item.title}</Text>
              <Text style={styles.menuSubtitle}>{item.subtitle}</Text>
            </View>
            <ChevronRight size={20} color="#9CA3AF" />
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: '#F8FAFC',
  },
  title: {
    fontSize: 28,
    fontFamily: 'Inter-Bold',
    color: '#1F2937',
    marginBottom: 24,
  },
  optionsContainer: {
    gap: 12,
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  menuIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 16,
  },
  menuContent: {
    flex: 1,
  },
  menuTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#1F2937',
  },
  menuSubtitle: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
    marginTop: 2,
  },
});