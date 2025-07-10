import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TextInput, Button, ScrollView, ActivityIndicator, Alert } from 'react-native';
import { getCaseById, CaseData } from '@/lib/services/cases';
import { updateCase } from '@/lib/services/cases'; // Assumindo que essa função será criada

export default function EditAnalysisScreen() {
  const { caseId } = useLocalSearchParams<{ caseId: string }>();
  const router = useRouter();
  
  const [caseData, setCaseData] = useState<CaseData | null>(null);
  const [formData, setFormData] = useState<Partial<CaseData>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (caseId) {
      getCaseById(caseId).then(data => {
        setCaseData(data);
        setFormData({
          description: data?.description,
          risk_level: data?.risk_level,
          urgency_hours: data?.urgency_hours,
          consultation_fee: data?.consultation_fee,
          representation_fee: data?.representation_fee,
          ai_analysis: {
            risk_description: data?.ai_analysis?.risk_description,
            required_documents: data?.ai_analysis?.required_documents || [],
          }
        });
        setLoading(false);
      });
    }
  }, [caseId]);

  const handleInputChange = (field: keyof CaseData, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };
  
  const handleAIInputChange = (field: string, value: any) => {
    setFormData(prev => ({ 
      ...prev, 
      ai_analysis: { ...prev.ai_analysis, [field]: value }
    }));
  };

  const handleSave = async () => {
    if (!caseId) return;
    
    setSaving(true);
    try {
      // Esta função agora existe e será chamada
      await updateCase(caseId, formData); 
      Alert.alert('Sucesso', 'As alterações foram salvas.');
      router.back();
    } catch (error) {
      Alert.alert('Erro', 'Não foi possível salvar as alterações.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <ActivityIndicator style={styles.centered} size="large" />;
  }

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Validar e Editar Análise</Text>
      
      <Text style={styles.label}>Análise Preliminar</Text>
      <TextInput
        style={[styles.input, styles.textArea]}
        multiline
        value={formData.description}
        onChangeText={(text) => handleInputChange('description', text)}
        placeholder="Descreva a análise preliminar do caso"
      />

      <Text style={styles.label}>Descrição do Risco</Text>
      <TextInput
        style={[styles.input, styles.textArea]}
        multiline
        value={formData.ai_analysis?.risk_description}
        onChangeText={(text) => handleAIInputChange('risk_description', text)}
        placeholder="Descreva os riscos associados"
      />

      <Text style={styles.label}>Nível de Risco</Text>
      <TextInput
        style={styles.input}
        value={formData.risk_level}
        onChangeText={(text) => handleInputChange('risk_level', text)}
        placeholder="low, medium, high"
      />

      <Text style={styles.label}>Nível de Urgência (em horas)</Text>
      <TextInput
        style={styles.input}
        value={String(formData.urgency_hours || '')}
        onChangeText={(text) => handleInputChange('urgency_hours', Number(text))}
        keyboardType="numeric"
        placeholder="Ex: 72"
      />

      <Text style={styles.label}>Documentos Necessários (separados por vírgula)</Text>
      <TextInput
        style={styles.input}
        value={formData.ai_analysis?.required_documents?.join(', ')}
        onChangeText={(text) => handleAIInputChange('required_documents', text.split(',').map(s => s.trim()))}
        placeholder="Contrato de trabalho, Carta de demissão"
      />
      
      <Text style={styles.label}>Honorários de Consulta (R$)</Text>
      <TextInput
        style={styles.input}
        value={String(formData.consultation_fee || '')}
        onChangeText={(text) => handleInputChange('consultation_fee', Number(text))}
        keyboardType="numeric"
        placeholder="Ex: 350"
      />

      <Text style={styles.label}>Honorários de Representação (R$)</Text>
      <TextInput
        style={styles.input}
        value={String(formData.representation_fee || '')}
        onChangeText={(text) => handleInputChange('representation_fee', Number(text))}
        keyboardType="numeric"
        placeholder="Ex: 2500"
      />
      
      <View style={styles.buttonContainer}>
        <Button title={saving ? "Salvando..." : "Salvar Alterações"} onPress={handleSave} disabled={saving} />
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
    marginBottom: 24,
    textAlign: 'center',
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
    height: 100,
    textAlignVertical: 'top',
  },
  buttonContainer: {
    marginTop: 16,
    marginBottom: 32,
  }
}); 