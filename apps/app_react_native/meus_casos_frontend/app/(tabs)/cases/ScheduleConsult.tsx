import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import TopBar from '@/components/layout/TopBar';

export default function ScheduleConsultScreen() {
  return (
    <View style={styles.container}>
      <TopBar title="Agendar Consulta" showBack />
      <View style={styles.content}>
        <Text style={styles.title}>Página de Agendamento</Text>
        <Text style={styles.subtitle}>
          Esta funcionalidade está em desenvolvimento.
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  title: {
    fontFamily: 'Inter-Bold',
    fontSize: 24,
    color: '#1E293B',
    marginBottom: 16,
  },
  subtitle: {
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#64748B',
    textAlign: 'center',
  },
}); 