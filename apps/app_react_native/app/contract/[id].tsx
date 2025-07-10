/**
 * Tela de detalhes do contrato
 */
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
  Linking,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';

import { Contract, contractsService } from '../../lib/services/contracts';
import { useAuth } from '../../lib/contexts/AuthContext';

export default function ContractDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { user } = useAuth();
  const router = useRouter();
  const [contract, setContract] = useState<Contract | null>(null);
  const [loading, setLoading] = useState(true);
  const [signing, setSigning] = useState(false);

  useEffect(() => {
    if (id) {
      loadContract();
    }
  }, [id]);

  const loadContract = async () => {
    try {
      const data = await contractsService.getContract(id!);
      setContract(data);
    } catch (error: any) {
      Alert.alert('Erro', error.message);
      router.back();
    } finally {
      setLoading(false);
    }
  };

  const handleSign = async () => {
    if (!contract || !user) return;

    const role = contract.client_id === user.id ? 'client' : 'lawyer';

    Alert.alert(
      'Assinar Contrato',
      'Ao assinar este contrato, você concorda com todos os termos e condições estabelecidos. Esta ação não pode ser desfeita.',
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Assinar',
          onPress: async () => {
            try {
              setSigning(true);
              const updatedContract = await contractsService.signContract(contract.id, { role });
              setContract(updatedContract);
              Alert.alert('Sucesso', 'Contrato assinado com sucesso!');
            } catch (error: any) {
              Alert.alert('Erro', error.message);
            } finally {
              setSigning(false);
            }
          },
        },
      ]
    );
  };

  const handleCancel = async () => {
    if (!contract) return;

    Alert.alert(
      'Cancelar Contrato',
      'Tem certeza que deseja cancelar este contrato? Esta ação não pode ser desfeita.',
      [
        { text: 'Não', style: 'cancel' },
        {
          text: 'Sim',
          style: 'destructive',
          onPress: async () => {
            try {
              const updatedContract = await contractsService.cancelContract(contract.id);
              setContract(updatedContract);
              Alert.alert('Sucesso', 'Contrato cancelado com sucesso!');
            } catch (error: any) {
              Alert.alert('Erro', error.message);
            }
          },
        },
      ]
    );
  };

  const handleDownloadPdf = async () => {
    if (!contract) return;

    try {
      const pdfUrl = await contractsService.getContractPdf(contract.id);
      await Linking.openURL(pdfUrl);
    } catch (error: any) {
      Alert.alert('Erro', error.message);
    }
  };

  const formatDate = (dateString: string) => {
    return format(new Date(dateString), "dd 'de' MMMM 'de' yyyy 'às' HH:mm", {
      locale: ptBR,
    });
  };

  const canSign = user && contract && contractsService.canBeSignedBy(contract, user.id);

  if (loading) {
    return (
      <View style={[styles.container, styles.centered]}>
        <ActivityIndicator size="large" color="#007bff" />
        <Text style={styles.loadingText}>Carregando contrato...</Text>
      </View>
    );
  }

  if (!contract) {
    return (
      <View style={[styles.container, styles.centered]}>
        <Text>Contrato não encontrado</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <Ionicons name="arrow-back" size={24} color="#333" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Contrato</Text>
        <TouchableOpacity onPress={handleDownloadPdf} style={styles.downloadButton}>
          <Ionicons name="download-outline" size={24} color="#007bff" />
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.content}>
        <View style={styles.statusSection}>
          <View
            style={[
              styles.statusBadge,
              { backgroundColor: contractsService.getStatusColor(contract.status) },
            ]}
          >
            <Text style={styles.statusText}>
              {contractsService.getStatusText(contract.status)}
            </Text>
          </View>
          <Text style={styles.statusDescription}>
            {contractsService.getSignatureStatus(contract)}
          </Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Informações do Caso</Text>
          <View style={styles.infoCard}>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Título:</Text>
              <Text style={styles.infoValue}>{contract.case_title || 'Caso Jurídico'}</Text>
            </View>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Área:</Text>
              <Text style={styles.infoValue}>{contract.case_area || 'Não especificada'}</Text>
            </View>
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Partes Envolvidas</Text>
          <View style={styles.infoCard}>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Cliente:</Text>
              <Text style={styles.infoValue}>{contract.client_name || 'Nome não informado'}</Text>
            </View>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Advogado:</Text>
              <Text style={styles.infoValue}>{contract.lawyer_name || 'Nome não informado'}</Text>
            </View>
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Honorários</Text>
          <View style={styles.feeCard}>
            <Text style={styles.feeValue}>
              {contractsService.formatFeeModel(contract.fee_model)}
            </Text>
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Histórico de Assinaturas</Text>
          <View style={styles.infoCard}>
            <View style={styles.signatureItem}>
              <Ionicons
                name={contract.signed_client ? 'checkmark-circle' : 'time-outline'}
                size={20}
                color={contract.signed_client ? '#10b981' : '#f59e0b'}
              />
              <View style={styles.signatureInfo}>
                <Text style={styles.signatureRole}>Cliente</Text>
                <Text style={styles.signatureDate}>
                  {contract.signed_client
                    ? `Assinado em ${formatDate(contract.signed_client)}`
                    : 'Aguardando assinatura'}
                </Text>
              </View>
            </View>

            <View style={styles.signatureItem}>
              <Ionicons
                name={contract.signed_lawyer ? 'checkmark-circle' : 'time-outline'}
                size={20}
                color={contract.signed_lawyer ? '#10b981' : '#f59e0b'}
              />
              <View style={styles.signatureInfo}>
                <Text style={styles.signatureRole}>Advogado</Text>
                <Text style={styles.signatureDate}>
                  {contract.signed_lawyer
                    ? `Assinado em ${formatDate(contract.signed_lawyer)}`
                    : 'Aguardando assinatura'}
                </Text>
              </View>
            </View>
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Informações do Contrato</Text>
          <View style={styles.infoCard}>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>ID do Contrato:</Text>
              <Text style={styles.infoValue}>{contract.id}</Text>
            </View>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Criado em:</Text>
              <Text style={styles.infoValue}>{formatDate(contract.created_at)}</Text>
            </View>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Última atualização:</Text>
              <Text style={styles.infoValue}>{formatDate(contract.updated_at)}</Text>
            </View>
          </View>
        </View>
      </ScrollView>

      {contract.status === 'pending-signature' && (
        <View style={styles.footer}>
          {canSign && (
            <TouchableOpacity
              style={[styles.button, styles.signButton]}
              onPress={handleSign}
              disabled={signing}
            >
              {signing ? (
                <ActivityIndicator color="#fff" />
              ) : (
                <>
                  <Ionicons name="create-outline" size={20} color="#fff" />
                  <Text style={styles.signButtonText}>Assinar Contrato</Text>
                </>
              )}
            </TouchableOpacity>
          )}

          <TouchableOpacity
            style={[styles.button, styles.cancelButton]}
            onPress={handleCancel}
          >
            <Ionicons name="close-outline" size={20} color="#ef4444" />
            <Text style={styles.cancelButtonText}>Cancelar</Text>
          </TouchableOpacity>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  centered: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#666',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 15,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e5e5e5',
  },
  backButton: {
    padding: 5,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
  },
  downloadButton: {
    padding: 5,
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
  },
  statusSection: {
    alignItems: 'center',
    paddingVertical: 20,
  },
  statusBadge: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    marginBottom: 8,
  },
  statusText: {
    fontSize: 14,
    color: '#fff',
    fontWeight: 'bold',
  },
  statusDescription: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 12,
  },
  infoCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  infoLabel: {
    fontSize: 14,
    color: '#666',
    flex: 1,
  },
  infoValue: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
    flex: 2,
    textAlign: 'right',
  },
  feeCard: {
    backgroundColor: '#e3f2fd',
    borderRadius: 12,
    padding: 16,
    borderLeftWidth: 4,
    borderLeftColor: '#2196f3',
  },
  feeValue: {
    fontSize: 16,
    color: '#1976d2',
    fontWeight: 'bold',
    textAlign: 'center',
  },
  signatureItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  signatureInfo: {
    marginLeft: 12,
    flex: 1,
  },
  signatureRole: {
    fontSize: 16,
    fontWeight: '500',
    color: '#333',
    marginBottom: 2,
  },
  signatureDate: {
    fontSize: 14,
    color: '#666',
  },
  footer: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    paddingVertical: 20,
    backgroundColor: '#fff',
    borderTopWidth: 1,
    borderTopColor: '#e5e5e5',
  },
  button: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 15,
    borderRadius: 8,
    marginHorizontal: 5,
  },
  signButton: {
    backgroundColor: '#10b981',
  },
  signButtonText: {
    fontSize: 16,
    color: '#fff',
    fontWeight: 'bold',
    marginLeft: 8,
  },
  cancelButton: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#ef4444',
  },
  cancelButtonText: {
    fontSize: 16,
    color: '#ef4444',
    fontWeight: '500',
    marginLeft: 8,
  },
});
