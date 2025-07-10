import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TextInput, TouchableOpacity, ScrollView, ActivityIndicator, Alert } from 'react-native';
import { getCaseById, updateCase } from '@/lib/services/cases';
import { getLawyerTier, getTierDefaultFees, LawyerTier, TierDefaultFees } from '@/lib/services/tiers';
import supabase from '@/lib/supabase';

export default function AdjustFeesScreen() {
  const { caseId } = useLocalSearchParams<{ caseId: string }>();
  const router = useRouter();

  const [consultationFee, setConsultationFee] = useState('');
  const [representationFee, setRepresentationFee] = useState('');
  const [hourlyRate, setHourlyRate] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [lawyerTier, setLawyerTier] = useState<LawyerTier | null>(null);
  const [tierDefaults, setTierDefaults] = useState<TierDefaultFees | null>(null);
  const [hasCustomValues, setHasCustomValues] = useState(false);

  useEffect(() => {
    loadCaseAndTierData();
  }, [caseId]);

  const loadCaseAndTierData = async () => {
    if (!caseId) return;

    try {
      setLoading(true);
      
      // Buscar dados do caso
      const caseData = await getCaseById(caseId);
      if (!caseData) {
        Alert.alert('Erro', 'Caso não encontrado.');
        router.back();
        return;
      }

      // Buscar dados do advogado e seu tier
      if (caseData.lawyer_id) {
        const tier = await getLawyerTier(caseData.lawyer_id);
        setLawyerTier(tier);

        if (tier) {
          // Buscar valores padrão do tier
          const defaults = await getTierDefaultFees(tier.id);
          setTierDefaults(defaults);

          // Se o caso já tem valores definidos, usar eles (valores customizados)
          if (caseData.consultation_fee && caseData.consultation_fee > 0) {
            setConsultationFee(String(caseData.consultation_fee));
            setHasCustomValues(true);
          } else if (defaults) {
            // Caso contrário, usar valores padrão do tier
            setConsultationFee(String(defaults.consultation_fee));
          }

          if (caseData.representation_fee && caseData.representation_fee > 0) {
            setRepresentationFee(String(caseData.representation_fee));
            setHasCustomValues(true);
          } else {
            // Para representação, usar um multiplicador do valor por hora (ex: 10x)
            setRepresentationFee(String((defaults?.hourly_rate || 0) * 10));
          }

          if (caseData.hourly_rate && caseData.hourly_rate > 0) {
            setHourlyRate(String(caseData.hourly_rate));
            setHasCustomValues(true);
          } else if (defaults) {
            setHourlyRate(String(defaults.hourly_rate));
          }
        }
      } else {
        // Caso não tenha advogado atribuído ainda, usar valores padrão
        setConsultationFee(String(caseData?.consultation_fee || ''));
        setRepresentationFee(String(caseData?.representation_fee || ''));
        setHourlyRate(String(caseData?.hourly_rate || ''));
      }
    } catch (error) {
      console.error('Error loading case and tier data:', error);
      Alert.alert('Erro', 'Falha ao carregar dados do caso.');
    } finally {
      setLoading(false);
    }
  };

  const resetToTierDefaults = () => {
    if (tierDefaults) {
      setConsultationFee(String(tierDefaults.consultation_fee));
      setHourlyRate(String(tierDefaults.hourly_rate));
      setRepresentationFee(String(tierDefaults.hourly_rate * 10));
      setHasCustomValues(false);
    }
  };

  const handleSave = async () => {
    if (!caseId) return;

    setSaving(true);
    try {
      const consultation_fee = parseFloat(consultationFee);
      const representation_fee = parseFloat(representationFee);
      const hourly_rate = parseFloat(hourlyRate);

      if (isNaN(consultation_fee) || isNaN(representation_fee) || isNaN(hourly_rate)) {
        Alert.alert('Erro', 'Por favor, insira valores numéricos válidos para os honorários.');
        setSaving(false);
        return;
      }

      await updateCase(caseId, { 
        consultation_fee,
        representation_fee,
        hourly_rate
      });
      
      Alert.alert('Sucesso', 'Os honorários foram atualizados.');
      router.back();
    } catch (error) {
      Alert.alert('Erro', 'Não foi possível atualizar os honorários.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color="#1E40AF" />
        <Text style={styles.loadingText}>Carregando dados do tier...</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Ajustar Honorários</Text>
      
      {lawyerTier && (
        <View style={styles.tierInfo}>
          <Text style={styles.tierTitle}>
            Tier: {lawyerTier.display_name}
          </Text>
          <Text style={styles.tierDescription}>
            {lawyerTier.description}
          </Text>
          {hasCustomValues && (
            <TouchableOpacity onPress={resetToTierDefaults} style={styles.resetButton}>
              <Text style={styles.resetButtonText}>
                Restaurar Valores Padrão do Tier
              </Text>
            </TouchableOpacity>
          )}
        </View>
      )}

      <Text style={styles.description}>
        {lawyerTier 
          ? `Os valores abaixo foram pré-preenchidos com base no tier "${lawyerTier.display_name}", mas você pode ajustá-los conforme necessário para este caso específico.`
          : 'Defina os valores cobrados para este caso específico.'
        }
      </Text>

      <Text style={styles.label}>
        Honorários de Consulta (R$)
        {tierDefaults && (
          <Text style={styles.defaultValue}>
            {' '}(Padrão do tier: R$ {tierDefaults.consultation_fee.toFixed(2)})
          </Text>
        )}
      </Text>
      <TextInput
        style={styles.input}
        value={consultationFee}
        onChangeText={(value) => {
          setConsultationFee(value);
          setHasCustomValues(true);
        }}
        keyboardType="numeric"
        placeholder="Ex: 350.00"
      />

      <Text style={styles.label}>
        Valor por Hora (R$)
        {tierDefaults && (
          <Text style={styles.defaultValue}>
            {' '}(Padrão do tier: R$ {tierDefaults.hourly_rate.toFixed(2)})
          </Text>
        )}
      </Text>
      <TextInput
        style={styles.input}
        value={hourlyRate}
        onChangeText={(value) => {
          setHourlyRate(value);
          setHasCustomValues(true);
        }}
        keyboardType="numeric"
        placeholder="Ex: 400.00"
      />

      <Text style={styles.label}>
        Honorários de Representação (R$)
        {tierDefaults && (
          <Text style={styles.defaultValue}>
            {' '}(Sugestão: R$ {(tierDefaults.hourly_rate * 10).toFixed(2)})
          </Text>
        )}
      </Text>
      <TextInput
        style={styles.input}
        value={representationFee}
        onChangeText={(value) => {
          setRepresentationFee(value);
          setHasCustomValues(true);
        }}
        keyboardType="numeric"
        placeholder="Ex: 2500.00"
      />

      <View style={styles.buttonContainer}>
        <TouchableOpacity 
          style={[styles.saveButton, saving && styles.saveButtonDisabled]} 
          onPress={handleSave} 
          disabled={saving}
        >
          <Text style={styles.saveButtonText}>
            {saving ? "Salvando..." : "Salvar Honorários"}
          </Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: '#fff',
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 10,
    fontSize: 16,
    color: '#374151',
    fontFamily: 'Inter-Regular',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 16,
    color: '#1F2937',
  },
  tierInfo: {
    backgroundColor: '#EBF4FF',
    padding: 16,
    borderRadius: 12,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#1E40AF',
  },
  tierTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1E40AF',
    marginBottom: 4,
  },
  tierDescription: {
    fontSize: 14,
    color: '#374151',
    marginBottom: 12,
  },
  resetButton: {
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    alignSelf: 'flex-start',
  },
  resetButtonText: {
    color: '#1E40AF',
    fontWeight: '600',
    fontSize: 14,
  },
  description: {
    fontSize: 14,
    color: '#666',
    marginBottom: 24,
    lineHeight: 20,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  defaultValue: {
    fontSize: 14,
    fontWeight: '400',
    color: '#6B7280',
  },
  input: {
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 12,
    fontSize: 16,
    marginBottom: 16,
    backgroundColor: '#F9FAFB'
  },
  buttonContainer: {
    marginTop: 16,
    marginBottom: 32,
  },
  saveButton: {
    backgroundColor: '#1E40AF',
    paddingVertical: 14,
    borderRadius: 8,
    alignItems: 'center',
  },
  saveButtonDisabled: {
    backgroundColor: '#9CA3AF',
  },
  saveButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
}); 