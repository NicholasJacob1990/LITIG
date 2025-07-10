import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, Switch, ActivityIndicator, Alert, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Bell } from 'lucide-react-native';

import api from '@/lib/services/api';
import TopBar from '@/components/layout/TopBar';

const PRIMARY_COLOR = '#0D47A1';
const GREY_COLOR = '#64748B';
const SUCCESS_COLOR = '#16A34A';
const BUSY_COLOR = '#F97316';
const INACTIVE_COLOR = '#4B5563';

type AvailabilityStatus = 'available' | 'busy' | 'vacation' | 'inactive';

interface AvailabilitySettings {
  availability_status: AvailabilityStatus;
  max_concurrent_cases?: number;
  vacation_start?: string;
  vacation_end?: string;
}

const fetchAvailability = async (): Promise<AvailabilitySettings> => {
  return api.get('/lawyers/availability');
};

const updateAvailability = async (settings: Partial<AvailabilitySettings>): Promise<void> => {
  await api.patch('/lawyers/availability', settings);
};

export default function AvailabilitySettingsScreen() {
  const queryClient = useQueryClient();
  const [status, setStatus] = useState<AvailabilityStatus>('available');

  const { data, isLoading, isError } = useQuery<AvailabilitySettings, Error>({
    queryKey: ['availabilitySettings'],
    queryFn: fetchAvailability,
  });

  useEffect(() => {
    if (data) {
      setStatus(data.availability_status);
    }
  }, [data]);

  const mutation = useMutation({
    mutationFn: updateAvailability,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['availabilitySettings'] });
    },
    onError: (error) => {
      Alert.alert('Erro ao Atualizar', `Não foi possível salvar as alterações: ${error.message}`);
      if (data) setStatus(data.availability_status);
    },
  });

  const handleStatusChange = (isNowEnabled: boolean) => {
    const newStatus: AvailabilityStatus = isNowEnabled ? 'available' : 'busy';
    setStatus(newStatus);
    mutation.mutate({ availability_status: newStatus });
  };

  const isAvailable = status === 'available';

  const getStatusColor = () => {
    switch (status) {
      case 'available': return SUCCESS_COLOR;
      case 'busy': return BUSY_COLOR;
      case 'vacation': return INACTIVE_COLOR;
      case 'inactive': return INACTIVE_COLOR;
    }
  };

  const getStatusText = () => {
    switch (status) {
      case 'available': return 'Disponível para receber ofertas';
      case 'busy': return 'Indisponível para novas ofertas';
      case 'vacation': return 'De férias (Indisponível)';
      case 'inactive': return 'Status inativo';
    }
  }

  if (isLoading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={PRIMARY_COLOR} />
        <Text style={{ marginTop: 10 }}>Carregando configurações...</Text>
      </View>
    );
  }

  if (isError) {
    return (
      <SafeAreaView style={styles.container} edges={['top']}>
        <TopBar title="Gestão de Disponibilidade" showBack />
        <View style={styles.centered}>
          <Text>Ocorreu um erro ao buscar suas configurações.</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <TopBar title="Gestão de Disponibilidade" showBack />
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Status Atual</Text>
          <Text style={styles.sectionSubtitle}>
            Indique se você está aceitando novos casos no momento.
          </Text>
          <View style={styles.statusContainer}>
            <View style={[styles.statusIndicator, { backgroundColor: getStatusColor() }]} />
            <Text style={styles.statusText}>{getStatusText()}</Text>
          </View>
          <View style={styles.switchContainer}>
            <Text style={[styles.switchLabel, { color: BUSY_COLOR }]}>Indisponível</Text>
            <Switch
              trackColor={{ false: BUSY_COLOR, true: SUCCESS_COLOR }}
              thumbColor="#FFFFFF"
              onValueChange={handleStatusChange}
              value={isAvailable}
              disabled={mutation.isPending || status === 'vacation' || status === 'inactive'}
            />
            <Text style={[styles.switchLabel, { color: SUCCESS_COLOR }]}>Disponível</Text>
          </View>
          {mutation.isPending && <ActivityIndicator style={{ marginTop: 10 }} color={PRIMARY_COLOR} />}
        </View>

        <View style={styles.infoBox}>
          <Bell size={20} color={PRIMARY_COLOR} />
          <Text style={styles.infoText}>
            Quando estiver indisponível, seu perfil não aparecerá nas recomendações para novos casos. Você continuará trabalhando normalmente nos seus casos atuais.
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  scrollContent: {
    padding: 20,
    flexGrow: 1,
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  section: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 20,
    marginBottom: 24,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1E293B',
    marginBottom: 4,
  },
  sectionSubtitle: {
    fontSize: 14,
    color: GREY_COLOR,
    marginBottom: 20,
  },
  statusContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    borderRadius: 8,
    backgroundColor: '#F1F5F9',
    marginBottom: 20,
  },
  statusIndicator: {
    width: 12,
    height: 12,
    borderRadius: 6,
    marginRight: 12,
  },
  statusText: {
    fontSize: 16,
    fontWeight: '500',
    color: '#334155',
  },
  switchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  switchLabel: {
    fontSize: 16,
    fontWeight: '500',
    marginHorizontal: 16,
  },
  infoBox: {
    flexDirection: 'row',
    backgroundColor: '#EFF6FF',
    padding: 16,
    borderRadius: 8,
    marginTop: 'auto',
  },
  infoText: {
    flex: 1,
    marginLeft: 12,
    color: '#1E40AF',
    lineHeight: 20,
    fontSize: 13,
  },
}); 