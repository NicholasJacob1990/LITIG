import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, Alert, ActivityIndicator } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { contractsService, Contract, DocuSignStatus } from '@/lib/services/contracts';

interface DocuSignStatusProps {
  contract: Contract;
  onUpdate?: (updatedContract: Contract) => void;
}

export default function DocuSignStatusComponent({ contract, onUpdate }: DocuSignStatusProps) {
  const [status, setStatus] = useState<DocuSignStatus | null>(null);
  const [loading, setLoading] = useState(false);
  const [syncing, setSyncing] = useState(false);

  useEffect(() => {
    if (contractsService.isDocuSignContract(contract)) {
      loadDocuSignStatus();
    }
  }, [contract.id]);

  const loadDocuSignStatus = async () => {
    try {
      setLoading(true);
      const docuSignStatus = await contractsService.getDocuSignStatus(contract.id);
      setStatus(docuSignStatus);
    } catch (error: any) {
      console.error('Erro ao carregar status DocuSign:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSyncStatus = async () => {
    try {
      setSyncing(true);
      const updatedContract = await contractsService.syncDocuSignStatus(contract.id);
      onUpdate?.(updatedContract);
      await loadDocuSignStatus();
      Alert.alert('Sucesso', 'Status sincronizado com DocuSign');
    } catch (error: any) {
      Alert.alert('Erro', error.message || 'Erro ao sincronizar status');
    } finally {
      setSyncing(false);
    }
  };

  const handleDownloadSigned = async () => {
    try {
      if (!contractsService.isFullySigned(contract)) {
        Alert.alert('Aviso', 'Contrato ainda não foi totalmente assinado');
        return;
      }

      setLoading(true);
      const blob = await contractsService.downloadDocuSignDocument(contract.id);
      
      // Aqui você pode implementar o download do blob
      // Para React Native, você pode usar expo-sharing ou expo-file-system
      Alert.alert('Sucesso', 'Documento baixado com sucesso');
    } catch (error: any) {
      Alert.alert('Erro', error.message || 'Erro ao baixar documento');
    } finally {
      setLoading(false);
    }
  };

  if (!contractsService.isDocuSignContract(contract)) {
    return null;
  }

  return (
    <View className="bg-white p-4 rounded-lg shadow-sm border border-gray-200 mb-4">
      <View className="flex-row items-center justify-between mb-3">
        <View className="flex-row items-center">
          <Ionicons name="document-text" size={20} color="#3b82f6" />
          <Text className="ml-2 text-lg font-semibold text-gray-900">
            DocuSign
          </Text>
        </View>
        
        <TouchableOpacity
          onPress={handleSyncStatus}
          disabled={syncing}
          className="flex-row items-center px-3 py-1 bg-blue-50 rounded-full"
        >
          {syncing ? (
            <ActivityIndicator size="small" color="#3b82f6" />
          ) : (
            <Ionicons name="refresh" size={16} color="#3b82f6" />
          )}
          <Text className="ml-1 text-sm text-blue-600">
            {syncing ? 'Sincronizando...' : 'Sincronizar'}
          </Text>
        </TouchableOpacity>
      </View>

      {loading && !status ? (
        <View className="flex-row items-center justify-center py-4">
          <ActivityIndicator size="small" color="#6b7280" />
          <Text className="ml-2 text-gray-600">Carregando status...</Text>
        </View>
      ) : status ? (
        <View>
          {/* Status Geral */}
          <View className="mb-3">
            <Text className="text-sm text-gray-600 mb-1">Status do Envelope</Text>
            <View className="flex-row items-center">
              <View 
                className={`w-2 h-2 rounded-full mr-2 ${
                  status.status === 'completed' ? 'bg-green-500' :
                  status.status === 'sent' ? 'bg-blue-500' :
                  status.status === 'delivered' ? 'bg-yellow-500' :
                  'bg-gray-400'
                }`}
              />
              <Text className="text-gray-900 font-medium">
                {contractsService.formatDocuSignStatus(status.status)}
              </Text>
            </View>
          </View>

          {/* Datas */}
          <View className="mb-3">
            <Text className="text-sm text-gray-600">
              Criado: {new Date(status.created_date).toLocaleDateString('pt-BR')}
            </Text>
            {status.completed_date && (
              <Text className="text-sm text-gray-600">
                Concluído: {new Date(status.completed_date).toLocaleDateString('pt-BR')}
              </Text>
            )}
          </View>

          {/* Status dos Signatários */}
          {status.recipients && status.recipients.length > 0 && (
            <View className="mb-3">
              <Text className="text-sm text-gray-600 mb-2">Signatários</Text>
              {status.recipients.map((recipient, index) => (
                <View key={index} className="flex-row items-center justify-between py-1">
                  <View className="flex-1">
                    <Text className="text-sm font-medium text-gray-900">
                      {recipient.name}
                    </Text>
                    <Text className="text-xs text-gray-600">
                      {recipient.email}
                    </Text>
                  </View>
                  <View className="flex-row items-center">
                    <View 
                      className={`w-2 h-2 rounded-full mr-2 ${
                        recipient.status === 'completed' ? 'bg-green-500' :
                        recipient.status === 'sent' ? 'bg-blue-500' :
                        'bg-gray-400'
                      }`}
                    />
                    <Text className="text-xs text-gray-600">
                      {recipient.status === 'completed' ? 'Assinado' :
                       recipient.status === 'sent' ? 'Enviado' :
                       'Pendente'}
                    </Text>
                  </View>
                </View>
              ))}
            </View>
          )}

          {/* Ações */}
          {status.status === 'completed' && (
            <TouchableOpacity
              onPress={handleDownloadSigned}
              disabled={loading}
              className="flex-row items-center justify-center bg-green-500 py-2 px-4 rounded-lg"
            >
              {loading ? (
                <ActivityIndicator size="small" color="white" />
              ) : (
                <Ionicons name="download" size={16} color="white" />
              )}
              <Text className="ml-2 text-white font-medium">
                {loading ? 'Baixando...' : 'Baixar Documento Assinado'}
              </Text>
            </TouchableOpacity>
          )}
        </View>
      ) : (
        <Text className="text-gray-600 text-center py-4">
          Não foi possível carregar o status do DocuSign
        </Text>
      )}
    </View>
  );
} 