import React, { useState, useEffect } from 'react';
import { View, Text, Modal, StyleSheet, TextInput, Button, TouchableOpacity, Alert, ScrollView } from 'react-native';
import { updateServiceScope } from '@/lib/services/serviceScope';
import { useAuth } from '@/lib/contexts/AuthContext';
import { X } from 'lucide-react-native';

interface ServiceScopeFormProps {
  isVisible: boolean;
  onClose: () => void;
  caseId: string;
  currentScope?: string;
  onSave?: (scope: string) => void;
}

export default function ServiceScopeForm({ 
  isVisible, 
  onClose, 
  caseId, 
  currentScope, 
  onSave 
}: ServiceScopeFormProps) {
  const { user } = useAuth();
  const [serviceScope, setServiceScope] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Preencher formulário com escopo atual quando editando
  useEffect(() => {
    if (isVisible) {
      setServiceScope(currentScope || '');
    }
  }, [currentScope, isVisible]);

  const handleSubmit = async () => {
    if (!serviceScope.trim() || !user) {
      Alert.alert('Erro', 'Por favor, descreva o escopo do serviço.');
      return;
    }

    if (serviceScope.trim().length < 50) {
      Alert.alert('Erro', 'O escopo deve ter pelo menos 50 caracteres para ser detalhado.');
      return;
    }

    setIsSubmitting(true);

    try {
      await updateServiceScope(caseId, serviceScope.trim(), user.id);
      
      Alert.alert('Sucesso', 'Escopo do serviço definido com sucesso!');
      
      // Callback para atualizar a tela pai
      if (onSave) {
        onSave(serviceScope.trim());
      }
      
      onClose();
    } catch (error) {
      console.error('Failed to save service scope:', error);
      Alert.alert('Erro', 'Erro ao salvar escopo do serviço. Tente novamente.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    if (!isSubmitting) {
      onClose();
    }
  };

  const isEditing = !!(currentScope && currentScope.trim().length > 0);
  const characterCount = serviceScope.length;
  const minCharacters = 50;
  const maxCharacters = 2000;

  return (
    <Modal
      animationType="slide"
      transparent={true}
      visible={isVisible}
      onRequestClose={handleClose}
    >
      <View style={styles.modalContainer}>
        <View style={styles.modalContent}>
          <ScrollView showsVerticalScrollIndicator={false}>
            <View style={styles.header}>
              <Text style={styles.headerTitle}>
                {isEditing ? 'Editar Escopo do Serviço' : 'Definir Escopo do Serviço'}
              </Text>
              <TouchableOpacity onPress={handleClose} disabled={isSubmitting}>
                <X size={24} color="#64748B" />
              </TouchableOpacity>
            </View>

            <View style={styles.infoBox}>
              <Text style={styles.infoTitle}>📋 Instruções</Text>
              <Text style={styles.infoText}>
                Descreva detalhadamente o escopo do serviço que será prestado ao cliente. 
                Inclua as atividades, prazos, entregas e limitações do trabalho.
              </Text>
            </View>
            
            <Text style={styles.label}>Descrição Detalhada do Serviço</Text>
            <TextInput
              style={[styles.textArea]}
              value={serviceScope}
              onChangeText={setServiceScope}
              placeholder="Ex: O serviço compreenderá a análise completa da documentação trabalhista, elaboração e protocolo de reclamação trabalhista perante a Vara do Trabalho competente, incluindo:

• Análise de todos os documentos fornecidos pelo cliente
• Cálculo das verbas rescisórias devidas
• Elaboração da petição inicial
• Protocolo da ação trabalhista
• Acompanhamento processual até a audiência inicial
• Tentativa de acordo extrajudicial

Prazo estimado: 30 dias úteis para protocolo da ação
Não inclui: custas processuais e honorários periciais"
              multiline
              numberOfLines={15}
              maxLength={maxCharacters}
              textAlignVertical="top"
            />

            <View style={styles.characterCounter}>
              <Text style={[
                styles.counterText, 
                characterCount < minCharacters ? styles.counterError : 
                characterCount > maxCharacters * 0.9 ? styles.counterWarning : 
                styles.counterNormal
              ]}>
                {characterCount}/{maxCharacters} caracteres
                {characterCount < minCharacters && ` (mínimo: ${minCharacters})`}
              </Text>
            </View>

            <View style={styles.tipsBox}>
              <Text style={styles.tipsTitle}>💡 Dicas para um bom escopo:</Text>
              <Text style={styles.tipsText}>
                • Seja específico sobre as atividades incluídas{'\n'}
                • Defina prazos realistas{'\n'}
                • Mencione o que NÃO está incluído{'\n'}
                • Inclua custos adicionais se houver{'\n'}
                • Use linguagem clara e objetiva
              </Text>
            </View>

            <View style={styles.buttonContainer}>
              <Button
                title={isSubmitting ? 'Salvando...' : (isEditing ? 'Atualizar Escopo' : 'Definir Escopo')}
                onPress={handleSubmit}
                disabled={isSubmitting || serviceScope.trim().length < minCharacters}
              />
            </View>
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  modalContainer: {
    flex: 1,
    justifyContent: 'flex-end',
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  modalContent: {
    backgroundColor: 'white',
    padding: 20,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -2 },
    shadowOpacity: 0.1,
    shadowRadius: 10,
    elevation: 10,
    maxHeight: '95%',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1E293B',
    flex: 1,
  },
  infoBox: {
    backgroundColor: '#EFF6FF',
    padding: 12,
    borderRadius: 8,
    marginBottom: 20,
    borderLeftWidth: 4,
    borderLeftColor: '#3B82F6',
  },
  infoTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1E40AF',
    marginBottom: 4,
  },
  infoText: {
    fontSize: 13,
    color: '#1E40AF',
    lineHeight: 18,
  },
  label: {
    fontSize: 16,
    color: '#475569',
    marginBottom: 8,
    fontWeight: '600',
  },
  textArea: {
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 8,
    padding: 12,
    fontSize: 14,
    color: '#1E293B',
    minHeight: 200,
    textAlignVertical: 'top',
  },
  characterCounter: {
    alignItems: 'flex-end',
    marginTop: 8,
    marginBottom: 16,
  },
  counterText: {
    fontSize: 12,
    fontWeight: '500',
  },
  counterNormal: {
    color: '#6B7280',
  },
  counterWarning: {
    color: '#F59E0B',
  },
  counterError: {
    color: '#EF4444',
  },
  tipsBox: {
    backgroundColor: '#F0FDF4',
    padding: 12,
    borderRadius: 8,
    marginBottom: 20,
    borderLeftWidth: 4,
    borderLeftColor: '#10B981',
  },
  tipsTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#047857',
    marginBottom: 6,
  },
  tipsText: {
    fontSize: 12,
    color: '#047857',
    lineHeight: 16,
  },
  buttonContainer: {
    marginTop: 10,
    marginBottom: 10,
  },
}); 