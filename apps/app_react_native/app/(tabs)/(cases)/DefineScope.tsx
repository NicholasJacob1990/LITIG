import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TextInput, Button, ScrollView, ActivityIndicator, Alert } from 'react-native';
import { getCaseById, CaseData, updateCase } from '@/lib/services/cases';

export default function DefineScopeScreen() {
  const { caseId } = useLocalSearchParams<{ caseId: string }>();
  const router = useRouter();

  const [scope, setScope] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (caseId) {
      getCaseById(caseId).then(data => {
        setScope(data?.service_scope || '');
        setLoading(false);
      });
    }
  }, [caseId]);

  const handleSave = async () => {
    if (!caseId) return;

    setSaving(true);
    try {
      await updateCase(caseId, { 
        service_scope: scope,
        service_scope_defined_at: new Date().toISOString()
      });
      Alert.alert('Sucesso', 'O escopo do serviço foi salvo.');
      router.back();
    } catch (error) {
      Alert.alert('Erro', 'Não foi possível salvar o escopo.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <ActivityIndicator style={styles.centered} size="large" />;
  }

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Definir Escopo do Serviço</Text>
      <Text style={styles.description}>
        Descreva detalhadamente os serviços que serão prestados, os entregáveis e os limites da sua atuação profissional neste caso.
      </Text>

      <Text style={styles.label}>Descrição do Escopo</Text>
      <TextInput
        style={[styles.input, styles.textArea]}
        multiline
        value={scope}
        onChangeText={setScope}
        placeholder="Ex: Elaboração da petição inicial, acompanhamento do processo em primeira instância, realização de audiências..."
      />

      <View style={styles.buttonContainer}>
        <Button title={saving ? "Salvando..." : "Salvar Escopo"} onPress={handleSave} disabled={saving} />
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
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 12,
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
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 16,
    marginBottom: 16,
    backgroundColor: '#f8f8f8'
  },
  textArea: {
    height: 200,
    textAlignVertical: 'top',
  },
  buttonContainer: {
    marginTop: 16,
    marginBottom: 32,
  }
}); 