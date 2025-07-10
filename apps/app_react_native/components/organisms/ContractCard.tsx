/**
 * Cartão de contrato para exibição em listas
 */
import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Alert,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';

import { Contract, contractsService } from '../../lib/services/contracts';
import { useAuth } from '../../lib/contexts/AuthContext';

interface ContractCardProps {
  contract: Contract;
  onPress: () => void;
  onSign?: () => void;
  onCancel?: () => void;
}

export default function ContractCard({
  contract,
  onPress,
  onSign,
  onCancel,
}: ContractCardProps) {
  const { user } = useAuth();

  const formatDate = (dateString: string) => {
    return format(new Date(dateString), 'dd/MM/yyyy', { locale: ptBR });
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return '#10b981';
      case 'pending-signature':
        return '#f59e0b';
      case 'cancelled':
        return '#ef4444';
      default:
        return '#6b7280';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'active':
        return 'Ativo';
      case 'pending-signature':
        return 'Pendente';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconhecido';
    }
  };

  const canSign = user && contractsService.canBeSigned(contract);
  const statusColor = getStatusColor(contract.status);
  const statusText = getStatusText(contract.status);

  const handleSignPress = () => {
    if (onSign) {
      onSign();
    }
  };

  const handleCancelPress = () => {
    Alert.alert(
      'Cancelar Contrato',
      'Tem certeza que deseja cancelar este contrato?',
      [
        { text: 'Não', style: 'cancel' },
        {
          text: 'Sim',
          style: 'destructive',
          onPress: () => onCancel?.(),
        },
      ]
    );
  };

  const renderStatusBadge = () => (
    <View style={[styles.statusBadge, { backgroundColor: statusColor }]}>
      <Text style={styles.statusText}>{statusText}</Text>
    </View>
  );

  const renderSignatureStatus = () => {
    if (contract.status === 'pending-signature') {
      return (
        <View style={styles.signatureStatus}>
          <View style={styles.signatureItem}>
            <Ionicons
              name={contract.signed_client ? 'checkmark-circle' : 'time-outline'}
              size={16}
              color={contract.signed_client ? '#10b981' : '#f59e0b'}
            />
            <Text style={styles.signatureText}>
              Cliente: {contract.signed_client ? 'Assinado' : 'Pendente'}
            </Text>
          </View>
          <View style={styles.signatureItem}>
            <Ionicons
              name={contract.signed_lawyer ? 'checkmark-circle' : 'time-outline'}
              size={16}
              color={contract.signed_lawyer ? '#10b981' : '#f59e0b'}
            />
            <Text style={styles.signatureText}>
              Advogado: {contract.signed_lawyer ? 'Assinado' : 'Pendente'}
            </Text>
          </View>
        </View>
      );
    }

    if (contractsService.isFullySigned(contract)) {
      return (
        <View style={styles.signatureStatus}>
          <Ionicons name="checkmark-circle" size={16} color="#10b981" />
          <Text style={[styles.signatureText, { color: '#10b981' }]}>
            Contrato assinado por ambas as partes
          </Text>
        </View>
      );
    }

    return null;
  };

  const renderActions = () => {
    if (contract.status === 'pending-signature') {
      return (
        <View style={styles.actions}>
          {canSign && (
            <TouchableOpacity
              style={[styles.actionButton, styles.signButton]}
              onPress={handleSignPress}
            >
              <Ionicons name="create-outline" size={16} color="#fff" />
              <Text style={styles.signButtonText}>Assinar</Text>
            </TouchableOpacity>
          )}
          <TouchableOpacity
            style={[styles.actionButton, styles.cancelButton]}
            onPress={handleCancelPress}
          >
            <Ionicons name="close-outline" size={16} color="#ef4444" />
            <Text style={styles.cancelButtonText}>Cancelar</Text>
          </TouchableOpacity>
        </View>
      );
    }

    return null;
  };

  return (
    <TouchableOpacity style={styles.card} onPress={onPress}>
      <View style={styles.header}>
        <View style={styles.titleContainer}>
          <Text style={styles.title} numberOfLines={2}>
            {contract.case_title || 'Caso Jurídico'}
          </Text>
          <Text style={styles.subtitle}>
            {contract.case_area} • {contract.lawyer_name || 'Advogado'}
          </Text>
        </View>
        {renderStatusBadge()}
      </View>

      <View style={styles.content}>
        <View style={styles.infoRow}>
          <View style={styles.infoItem}>
            <Text style={styles.infoLabel}>Honorários</Text>
            <Text style={styles.infoValue}>
              {contractsService.formatFeeModel(contract.fee_model)}
            </Text>
          </View>
        </View>

        <View style={styles.infoRow}>
          <View style={styles.infoItem}>
            <Text style={styles.infoLabel}>Criado em</Text>
            <Text style={styles.infoValue}>
              {formatDate(contract.created_at)}
            </Text>
          </View>
          {contract.status === 'active' && (
            <View style={styles.infoItem}>
              <Text style={styles.infoLabel}>Ativo desde</Text>
              <Text style={styles.infoValue}>
                {contract.signed_client && contract.signed_lawyer
                  ? formatDate(
                      contract.signed_client > contract.signed_lawyer
                        ? contract.signed_client
                        : contract.signed_lawyer
                    )
                  : '-'}
              </Text>
            </View>
          )}
        </View>

        {renderSignatureStatus()}
      </View>

      {renderActions()}

      <View style={styles.footer}>
        <TouchableOpacity style={styles.viewButton} onPress={onPress}>
          <Ionicons name="document-text-outline" size={16} color="#007bff" />
          <Text style={styles.viewButtonText}>Ver Contrato</Text>
        </TouchableOpacity>
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  titleContainer: {
    flex: 1,
    marginRight: 12,
  },
  title: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 14,
    color: '#666',
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  statusText: {
    fontSize: 12,
    color: '#fff',
    fontWeight: '500',
  },
  content: {
    marginBottom: 12,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  infoItem: {
    flex: 1,
  },
  infoLabel: {
    fontSize: 12,
    color: '#666',
    marginBottom: 2,
  },
  infoValue: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
  },
  signatureStatus: {
    marginTop: 8,
    padding: 8,
    backgroundColor: '#f8f9fa',
    borderRadius: 6,
  },
  signatureItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  signatureText: {
    fontSize: 12,
    color: '#666',
    marginLeft: 6,
  },
  actions: {
    flexDirection: 'row',
    marginBottom: 12,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 6,
    marginRight: 8,
  },
  signButton: {
    backgroundColor: '#10b981',
  },
  signButtonText: {
    fontSize: 14,
    color: '#fff',
    fontWeight: '500',
    marginLeft: 4,
  },
  cancelButton: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#ef4444',
  },
  cancelButtonText: {
    fontSize: 14,
    color: '#ef4444',
    fontWeight: '500',
    marginLeft: 4,
  },
  footer: {
    borderTopWidth: 1,
    borderTopColor: '#e5e5e5',
    paddingTop: 12,
  },
  viewButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 8,
  },
  viewButtonText: {
    fontSize: 14,
    color: '#007bff',
    fontWeight: '500',
    marginLeft: 4,
  },
}); 
