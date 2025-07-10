import React, { useState, useEffect, useCallback } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  ScrollView, 
  TouchableOpacity, 
  Alert, 
  ActivityIndicator,
  RefreshControl
} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { StatusBar } from 'expo-status-bar';
import { Plus, FileText, Download, Trash2, Eye } from 'lucide-react-native';
import { useAuth } from '@/lib/contexts/AuthContext';
import { 
  getCaseDocuments, 
  uploadDocument, 
  deleteDocument, 
  downloadDocument, 
  pickDocument,
  formatFileSize,
  isValidFileType,
  DocumentData,
} from '@/lib/services/documents';
import TopBar from '@/components/layout/TopBar';
import Badge from '@/components/atoms/Badge';
import Avatar from '@/components/atoms/Avatar';

export default function CaseDocuments() {
  const route = useRoute<any>();
  const { user } = useAuth();
  const { caseId } = route.params;

  const [documents, setDocuments] = useState<DocumentData[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [uploading, setUploading] = useState(false);

  const loadDocuments = useCallback(async () => {
    if (!caseId) return;
    try {
      setLoading(true);
      const docs = await getCaseDocuments(caseId);
      setDocuments(docs);
    } catch (error) {
      console.error('Error loading documents:', error);
      Alert.alert('Erro', 'Não foi possível carregar os documentos');
    } finally {
      setLoading(false);
    }
  }, [caseId]);

  useEffect(() => {
    loadDocuments();
  }, [loadDocuments]);

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadDocuments();
    setRefreshing(false);
  };

  const handleUploadDocument = async () => {
    try {
      const result = await pickDocument();
      if (result.canceled) return;

      const doc = result.assets?.[0];
      if (!doc) {
        Alert.alert('Erro', 'Nenhum arquivo selecionado');
        return;
      }

      const fileExtension = doc.name.split('.').pop()?.toLowerCase() || '';
      if (!isValidFileType(fileExtension)) {
        Alert.alert('Tipo de arquivo não suportado', 'Por favor, selecione um arquivo válido (PDF, DOCX, PNG, JPG, etc.).');
        return;
      }

      if (doc.size && doc.size > 10 * 1024 * 1024) {
        Alert.alert('Arquivo muito grande', 'O arquivo deve ter no máximo 10MB.');
        return;
      }

      setUploading(true);
      
      const uploadedDoc = await uploadDocument(caseId, user?.id || '', {
        uri: doc.uri,
        name: doc.name,
        type: doc.mimeType || 'application/octet-stream',
        size: doc.size,
      });
      
      setDocuments((prev: DocumentData[]) => [uploadedDoc, ...prev]);
      Alert.alert('Sucesso', 'Documento enviado com sucesso!');
    } catch (error) {
      console.error('Error uploading document:', error);
      Alert.alert('Erro', 'Não foi possível enviar o documento');
    } finally {
      setUploading(false);
    }
  };

  const handleDeleteDocument = (documentId: string, documentName: string) => {
    Alert.alert(
      'Confirmar exclusão',
      `Tem certeza que deseja excluir "${documentName}"?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Excluir',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteDocument(documentId);
              setDocuments((prev: DocumentData[]) => prev.filter(doc => doc.id !== documentId));
              Alert.alert('Sucesso', 'Documento excluído com sucesso!');
            } catch (error) {
              console.error('Error deleting document:', error);
              Alert.alert('Erro', 'Não foi possível excluir o documento');
            }
          }
        }
      ]
    );
  };

  const handleDownloadDocument = async (documentId: string) => {
    try {
      const success = await downloadDocument(documentId);
      if (success) {
        Alert.alert('Sucesso', 'Documento salvo em seus Downloads.');
      } else {
        Alert.alert('Erro', 'Não foi possível baixar o documento.');
      }
    } catch (error) {
      console.error('Error downloading document:', error);
      Alert.alert('Erro', 'Não foi possível baixar o documento');
    }
  };

  const renderDocument = (doc: DocumentData) => (
    <View key={doc.id} style={styles.documentCard}>
      <View style={styles.documentHeader}>
        <View style={styles.documentInfo}>
          <View style={styles.documentIcon}>
            <FileText size={20} color="#006CFF" />
          </View>
          <View style={styles.documentDetails}>
            <Text style={styles.documentName} numberOfLines={1}>{doc.name}</Text>
            <View style={styles.documentMeta}>
              <Text style={styles.documentSize}>{formatFileSize(doc.file_size || 0)}</Text>
              <Text style={styles.documentSeparator}>•</Text>
              <Text style={styles.documentDate}>
                {new Date(doc.uploaded_at).toLocaleDateString('pt-BR')}
              </Text>
            </View>
            {doc.uploader && (
              <View style={styles.uploaderInfo}>
                <Avatar 
                  src={(doc.uploader as any).avatar_url} 
                  name={(doc.uploader as any).full_name} 
                  size="xsmall" 
                />
                <Text style={styles.uploaderName}>
                  {(doc.uploader as any).full_name}
                </Text>
              </View>
            )}
          </View>
        </View>
      </View>

      <View style={styles.documentActions}>
        <TouchableOpacity 
          style={styles.actionButton}
          onPress={() => handleDownloadDocument(doc.id)}
        >
          <Download size={16} color="#006CFF" />
          <Text style={styles.actionButtonText}>Baixar</Text>
        </TouchableOpacity>
        
        <TouchableOpacity style={styles.actionButton}>
          <Eye size={16} color="#006CFF" />
          <Text style={styles.actionButtonText}>Visualizar</Text>
        </TouchableOpacity>
        
        {doc.uploaded_by === user?.id && (
          <TouchableOpacity 
            style={[styles.actionButton, styles.deleteButton]}
            onPress={() => handleDeleteDocument(doc.id, doc.name)}
          >
            <Trash2 size={16} color="#E44C2E" />
            <Text style={[styles.actionButtonText, styles.deleteButtonText]}>Excluir</Text>
          </TouchableOpacity>
        )}
      </View>
    </View>
  );

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      <TopBar title="Documentos" showBack />
      <ScrollView 
        style={styles.content}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
        }
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.uploadSection}>
          <TouchableOpacity 
            style={[styles.uploadButton, uploading && styles.uploadButtonDisabled]}
            onPress={handleUploadDocument}
            disabled={uploading}
          >
            {uploading ? <ActivityIndicator size="small" color="#FFFFFF" /> : <Plus size={20} color="#FFFFFF" />}
            <Text style={styles.uploadButtonText}>
              {uploading ? 'Enviando...' : 'Adicionar Documento'}
            </Text>
          </TouchableOpacity>
        </View>

        <View style={styles.documentsSection}>
          {loading ? (
             <ActivityIndicator size="large" color="#006CFF" style={{marginTop: 40}}/>
          ): documents.length === 0 ? (
            <View style={styles.emptyState}>
              <FileText size={48} color="#9CA3AF" />
              <Text style={styles.emptyStateTitle}>Nenhum documento</Text>
              <Text style={styles.emptyStateDescription}>
                Adicione documentos relacionados ao seu caso para facilitar o atendimento.
              </Text>
            </View>
          ) : (
            documents.map(renderDocument)
          )}
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  loadingText: {
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#6B7280',
    marginTop: 16,
  },
  uploadSection: {
    marginVertical: 20,
  },
  uploadButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#006CFF',
    paddingVertical: 16,
    paddingHorizontal: 24,
    borderRadius: 12,
    gap: 8,
  },
  uploadButtonDisabled: {
    backgroundColor: '#9CA3AF',
  },
  uploadButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#FFFFFF',
  },
  documentsSection: {
    marginBottom: 24,
  },
  documentCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  documentHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  documentInfo: {
    flexDirection: 'row',
    flex: 1,
  },
  documentIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#F0F9FF',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  documentDetails: {
    flex: 1,
  },
  documentName: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#1F2937',
    marginBottom: 4,
  },
  documentMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  documentSize: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: '#6B7280',
  },
  documentSeparator: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: '#6B7280',
    marginHorizontal: 8,
  },
  documentDate: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: '#6B7280',
  },
  uploaderInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginTop: 4,
  },
  uploaderName: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: '#6B7280',
  },
  documentActions: {
    flexDirection: 'row',
    gap: 8,
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
    paddingTop: 12,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 8,
    backgroundColor: '#F0F9FF',
    gap: 4,
    flex: 1,
  },
  actionButtonText: {
    fontFamily: 'Inter-Medium',
    fontSize: 12,
    color: '#006CFF',
  },
  deleteButton: {
    backgroundColor: '#FEF2F2',
  },
  deleteButtonText: {
    color: '#E44C2E',
  },
  emptyState: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 48,
  },
  emptyStateTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1F2937',
    marginTop: 16,
    marginBottom: 8,
  },
  emptyStateDescription: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
    lineHeight: 20,
    paddingHorizontal: 32,
  },
}); 