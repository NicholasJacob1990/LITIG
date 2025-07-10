import React, { useState } from 'react';
import { View, Text, StyleSheet, TextInput, Switch, TouchableOpacity, Alert, ScrollView } from 'react-native';
import { ArrowLeft, Check, Shield } from 'lucide-react-native';
import { useRouter } from 'expo-router';
import { useAuth } from '@/lib/contexts/AuthContext';
import supabase from '@/lib/supabase'; // Importar supabase diretamente

export default function EquitySettingsScreen() {
  const router = useRouter();
  const { user } = useAuth();

  const [gender, setGender] = useState(user?.user_metadata?.gender || '');
  const [ethnicity, setEthnicity] = useState(user?.user_metadata?.ethnicity || '');
  const [pcd, setPcd] = useState(user?.user_metadata?.pcd || false);
  const [orientation, setOrientation] = useState(user?.user_metadata?.orientation || '');
  const [lgbtqia, setLgbtqia] = useState(user?.user_metadata?.lgbtqia || false);
  const [isLoading, setIsLoading] = useState(false);

  const handleSave = async () => {
    if (!user) {
      Alert.alert('Erro', 'Você não está autenticado.');
      return;
    }

    setIsLoading(true);
    try {
      const payload = {
        gender,
        ethnicity,
        pcd,
        orientation,
        lgbtqia,
      };

      // Usar updateUser para modificar user_metadata
      const { error } = await supabase.auth.updateUser({
        data: payload
      });

      if (error) throw error;

      Alert.alert('Sucesso', 'Seus dados foram atualizados com segurança.');
      router.back();

    } catch (error) {
      console.error('Erro ao salvar dados de equidade:', error);
      Alert.alert('Erro', 'Não foi possível salvar seus dados. Tente novamente.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <ArrowLeft size={24} color="#1F2937" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Dados de Diversidade</Text>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.disclaimer}>
          <Shield size={24} color="#1E40AF" />
          <Text style={styles.disclaimerText}>
            O fornecimento destas informações é **opcional**. Elas são usadas exclusivamente para promover uma distribuição mais justa de oportunidades em nosso sistema, sem identificar você. Seus dados são armazenados com segurança.
          </Text>
        </View>

        <Text style={styles.label}>Gênero</Text>
        <TextInput
          style={styles.input}
          placeholder="Ex: Mulher, Homem, Não-binário"
          value={gender}
          onChangeText={setGender}
        />

        <Text style={styles.label}>Etnia / Raça</Text>
        <TextInput
          style={styles.input}
          placeholder="Ex: Preta, Parda, Indígena, Branca"
          value={ethnicity}
          onChangeText={setEthnicity}
        />
        
        <Text style={styles.label}>Orientação Sexual</Text>
        <TextInput
          style={styles.input}
          placeholder="Ex: Lésbica, Gay, Bissexual, etc."
          value={orientation}
          onChangeText={setOrientation}
        />

        <View style={styles.switchContainer}>
          <Text style={styles.label}>Me identifico como Pessoa com Deficiência (PCD)</Text>
          <Switch
            value={pcd}
            onValueChange={setPcd}
            trackColor={{ false: '#D1D5DB', true: '#818CF8' }}
            thumbColor={pcd ? '#1E40AF' : '#f4f3f4'}
          />
        </View>

        <View style={styles.switchContainer}>
          <Text style={styles.label}>Faço parte da comunidade LGBTQIA+</Text>
          <Switch
            value={lgbtqia}
            onValueChange={setLgbtqia}
            trackColor={{ false: '#D1D5DB', true: '#818CF8' }}
            thumbColor={lgbtqia ? '#1E40AF' : '#f4f3f4'}
          />
        </View>

        <TouchableOpacity style={[styles.saveButton, isLoading && styles.saveButtonDisabled]} onPress={handleSave} disabled={isLoading}>
          {isLoading ? (
            <Text style={styles.saveButtonText}>Salvando...</Text>
          ) : (
            <>
              <Check size={20} color="#FFFFFF" />
              <Text style={styles.saveButtonText}>Salvar com Segurança</Text>
            </>
          )}
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F9FAFB' },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    paddingTop: 60,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  headerTitle: {
    fontSize: 20,
    fontFamily: 'Inter-Bold',
    marginLeft: 16,
  },
  scrollContent: {
    padding: 20,
  },
  disclaimer: {
    flexDirection: 'row',
    backgroundColor: '#EFF6FF',
    padding: 16,
    borderRadius: 12,
    marginBottom: 24,
    alignItems: 'center',
    gap: 12,
  },
  disclaimerText: {
    flex: 1,
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#1E3A8A',
    lineHeight: 20,
  },
  label: {
    fontSize: 16,
    fontFamily: 'Inter-SemiBold',
    color: '#374151',
    marginBottom: 8,
    marginTop: 16,
  },
  input: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    fontFamily: 'Inter-Regular',
  },
  switchContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 24,
  },
  saveButton: {
    marginTop: 32,
    backgroundColor: '#1E40AF',
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 8,
  },
  saveButtonDisabled: {
    backgroundColor: '#9CA3AF',
  },
  saveButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontFamily: 'Inter-Bold',
  },
}); 