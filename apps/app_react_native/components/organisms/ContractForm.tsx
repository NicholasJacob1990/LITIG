/**
 * Formulário para criar contratos
 */
import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  Modal,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import { Picker } from '@react-native-picker/picker';
import { Ionicons } from '@expo/vector-icons';

import { contractsService, FeeModel, CreateContractData } from '../../lib/services/contracts';
import { useAuth } from '../../lib/contexts/AuthContext';

interface ContractFormProps {
  visible: boolean;
  onClose: () => void;
  caseId: string;
  lawyerId: string;
  lawyerName: string;
  caseTitle: string;
  onContractCreated: (contractId: string) => void;
}

export default function ContractForm({
  visible,
  onClose,
  caseId,
  lawyerId,
  lawyerName,
  caseTitle,
  onContractCreated,
}: ContractFormProps) {
  const { user } = useAuth();
  const [loading, setLoading] = useState(false);
  const [feeModel, setFeeModel] = useState<FeeModel>({
    type: 'success',
    percent: 20,
  });

  const handleSubmit = async () => {
    if (!user) {
      Alert.alert('Erro', 'Você precisa estar logado para criar um contrato.');
      return;
    }
    
    try {
      // Validar modelo de honorários
      const validationError = contractsService.validateFeeModel(feeModel);
      if (validationError) {
        Alert.alert('Erro de Validação', validationError);
        return;
      }

      setLoading(true);

      const contractData: CreateContractData = {
        case_id: caseId,
        lawyer_id: lawyerId,
        fee_model: feeModel,
      };

      const contract = await contractsService.createContract(contractData);

      Alert.alert(
        'Contrato Criado',
        'O contrato foi criado com sucesso. Agora você pode assiná-lo.',
        [
          {
            text: 'OK',
            onPress: () => {
              onContractCreated(contract.id);
              onClose();
            },
          },
        ]
      );
    } catch (error: any) {
      Alert.alert('Erro', error.message);
    } finally {
      setLoading(false);
    }
  };

  const renderFeeModelForm = () => {
    switch (feeModel.type) {
      case 'success':
        return (
          <View style={styles.feeModelForm}>
            <Text style={styles.label}>Percentual de Êxito (%)</Text>
            <TextInput
              style={styles.input}
              value={feeModel.percent?.toString() || ''}
              onChangeText={(text) => {
                const percent = parseFloat(text) || 0;
                setFeeModel({ ...feeModel, percent });
              }}
              keyboardType="numeric"
              placeholder="Ex: 20"
            />
            <Text style={styles.helpText}>
              Percentual sobre o valor obtido em caso de êxito
            </Text>
          </View>
        );

      case 'fixed':
        return (
          <View style={styles.feeModelForm}>
            <Text style={styles.label}>Valor Fixo (R$)</Text>
            <TextInput
              style={styles.input}
              value={feeModel.value?.toString() || ''}
              onChangeText={(text) => {
                const value = parseFloat(text) || 0;
                setFeeModel({ ...feeModel, value });
              }}
              keyboardType="numeric"
              placeholder="Ex: 5000"
            />
            <Text style={styles.helpText}>
              Valor fixo independente do resultado
            </Text>
          </View>
        );

      case 'hourly':
        return (
          <View style={styles.feeModelForm}>
            <Text style={styles.label}>Taxa por Hora (R$)</Text>
            <TextInput
              style={styles.input}
              value={feeModel.rate?.toString() || ''}
              onChangeText={(text) => {
                const rate = parseFloat(text) || 0;
                setFeeModel({ ...feeModel, rate });
              }}
              keyboardType="numeric"
              placeholder="Ex: 300"
            />
            <Text style={styles.helpText}>
              Valor cobrado por hora trabalhada
            </Text>
          </View>
        );

      default:
        return null;
    }
  };

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
      <View style={styles.container}>
        <View style={styles.header}>
          <Text style={styles.title}>Criar Contrato</Text>
          <TouchableOpacity onPress={onClose} style={styles.closeButton}>
            <Ionicons name="close" size={24} color="#666" />
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.content}>
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Informações do Caso</Text>
            <View style={styles.infoBox}>
              <Text style={styles.infoLabel}>Caso:</Text>
              <Text style={styles.infoValue}>{caseTitle}</Text>
            </View>
            <View style={styles.infoBox}>
              <Text style={styles.infoLabel}>Advogado:</Text>
              <Text style={styles.infoValue}>{lawyerName}</Text>
            </View>
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Modelo de Honorários</Text>
            
            <Text style={styles.label}>Tipo de Honorário</Text>
            <View style={styles.pickerContainer}>
              <Picker
                selectedValue={feeModel.type}
                onValueChange={(value) => {
                  setFeeModel({
                    type: value as FeeModel['type'],
                    percent: value === 'success' ? 20 : undefined,
                    value: value === 'fixed' ? 5000 : undefined,
                    rate: value === 'hourly' ? 300 : undefined,
                  });
                }}
                style={styles.picker}
              >
                <Picker.Item label="Honorários de Êxito" value="success" />
                <Picker.Item label="Honorários Fixos" value="fixed" />
                <Picker.Item label="Honorários por Hora" value="hourly" />
              </Picker>
            </View>

            {renderFeeModelForm()}

            <View style={styles.previewBox}>
              <Text style={styles.previewLabel}>Resumo:</Text>
              <Text style={styles.previewValue}>
                {contractsService.formatFeeModel(feeModel)}
              </Text>
            </View>
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Informações Importantes</Text>
            <View style={styles.infoBox}>
              <Text style={styles.warningText}>
                • Este contrato será enviado para assinatura digital de ambas as partes
              </Text>
              <Text style={styles.warningText}>
                • O contrato só será válido após assinatura de cliente e advogado
              </Text>
              <Text style={styles.warningText}>
                • Você receberá uma notificação quando o advogado assinar
              </Text>
            </View>
          </View>
        </ScrollView>

        <View style={styles.footer}>
          <TouchableOpacity
            style={[styles.button, styles.cancelButton]}
            onPress={onClose}
            disabled={loading}
          >
            <Text style={styles.cancelButtonText}>Cancelar</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.button, styles.submitButton]}
            onPress={handleSubmit}
            disabled={loading}
          >
            {loading ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.submitButtonText}>Criar Contrato</Text>
            )}
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 15,
    borderBottomWidth: 1,
    borderBottomColor: '#e5e5e5',
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
  },
  closeButton: {
    padding: 5,
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
  },
  section: {
    marginVertical: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 15,
  },
  infoBox: {
    backgroundColor: '#f8f9fa',
    padding: 15,
    borderRadius: 8,
    marginBottom: 10,
  },
  infoLabel: {
    fontSize: 14,
    color: '#666',
    marginBottom: 5,
  },
  infoValue: {
    fontSize: 16,
    color: '#333',
    fontWeight: '500',
  },
  label: {
    fontSize: 16,
    fontWeight: '500',
    color: '#333',
    marginBottom: 8,
  },
  pickerContainer: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    marginBottom: 15,
  },
  picker: {
    height: 50,
  },
  feeModelForm: {
    marginBottom: 15,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    marginBottom: 8,
  },
  helpText: {
    fontSize: 14,
    color: '#666',
    fontStyle: 'italic',
  },
  previewBox: {
    backgroundColor: '#e3f2fd',
    padding: 15,
    borderRadius: 8,
    borderLeftWidth: 4,
    borderLeftColor: '#2196f3',
  },
  previewLabel: {
    fontSize: 14,
    color: '#1976d2',
    fontWeight: '500',
    marginBottom: 5,
  },
  previewValue: {
    fontSize: 16,
    color: '#1976d2',
    fontWeight: 'bold',
  },
  warningText: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8,
    lineHeight: 20,
  },
  footer: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    paddingVertical: 20,
    borderTopWidth: 1,
    borderTopColor: '#e5e5e5',
  },
  button: {
    flex: 1,
    paddingVertical: 15,
    borderRadius: 8,
    alignItems: 'center',
    marginHorizontal: 5,
  },
  cancelButton: {
    backgroundColor: '#f5f5f5',
    borderWidth: 1,
    borderColor: '#ddd',
  },
  cancelButtonText: {
    fontSize: 16,
    color: '#666',
    fontWeight: '500',
  },
  submitButton: {
    backgroundColor: '#007bff',
  },
  submitButtonText: {
    fontSize: 16,
    color: '#fff',
    fontWeight: 'bold',
  },
}); 