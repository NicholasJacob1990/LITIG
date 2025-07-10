import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  RefreshControl,
} from 'react-native';
import {
  FileText,
  Download,
  Upload,
  Eye,
  Trash2,
  Calendar,
  User,
  FileIcon,
  Image as ImageIcon,
  Video,
} from 'lucide-react-native';
import { StatusBar } from 'expo-status-bar';
import { useLocalSearchParams, useRouter } from 'expo-router';
import TopBar from '@/components/layout/TopBar';
import * as DocumentPicker from 'expo-document-picker';
import { useAuth } from '@/lib/contexts/AuthContext';

interface Document {
  id: string;
  file_name: string;
  file_size: number;
  file_type: string;
  file_url: string;
  uploaded_by: string;
  created_at: string;
  uploader_name?: string;
}

export default function CaseDocuments() {
  const router = useRouter();
  const { user } = useAuth();
  const params = useLocalSearchParams<{ caseId?: string }>();
  const caseId = params?.caseId;

  const [documents, setDocuments] = useState<Document[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [uploading, setUploading] = useState(false);

  // Mock data - em produção, buscar do backend
  const mockDocuments: Document[] = [
    {
      id: '1',
      file_name: 'contrato_trabalho.pdf',
      file_size: 2048576, // 2MB
      file_type: 'application/pdf',
      file_url: '#',
      uploaded_by: user?.id || '',
      created_at: '2025-01-03T10:30:00Z',
      uploader_name: 'João Silva',
    },
    {
      id: '2',
      file_name: 'carteira_trabalho.jpg',
      file_size: 1024000, // 1MB
      file_type: 'image/jpeg',
      file_url: '#',
      uploaded_by: user?.id || '',
      created_at: '2025-01-02T14:15:00Z',
      uploader_name: 'João Silva',
    },
    {
      id: '3',
      file_name: 'rescisao_anterior.pdf',
      file_size: 512000, // 512KB
      file_type: 'application/pdf',
      file_url: '#',
      uploaded_by: 'lawyer-id',
      created_at: '2025-01-01T09:00:00Z',
      uploader_name: 'Dr. Carlos Mendes',
    },
  ];

  useEffect(() => {
    if (caseId) {
      loadDocuments();
    }
  }, [caseId]);

  const loadDocuments = async () => {
    try {
      setLoading(true);
      // Simular carregamento - em produção, chamar API
      await new Promise(resolve => setTimeout(resolve, 1000));
      setDocuments(mockDocuments);
    } catch (error) {
      console.error('Error loading documents:', error);
      Alert.alert('Erro', 'Não foi possível carregar os documentos');
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadDocuments();
    setRefreshing(false);
  };

  const handleUpload = async () => {
    try {
      const result = await DocumentPicker.getDocumentAsync({
        type: '*/*',
        copyToCacheDirectory: true,
      });

      if (!result.canceled && result.assets[0]) {
        setUploading(true);
        const file = result.assets[0];
        
        // Simular upload - em produção, fazer upload real
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        const newDocument: Document = {
          id: Date.now().toString(),
          file_name: file.name,
          file_size: file.size || 0,
          file_type: file.mimeType || 'application/octet-stream',
          file_url: file.uri,
          uploaded_by: user?.id || '',
          created_at: new Date().toISOString(),
          uploader_name: user?.user_metadata?.full_name || 'Você',
        };

        setDocuments(prev => [newDocument, ...prev]);
        Alert.alert('Sucesso', 'Documento enviado com sucesso!');
      }
    } catch (error) {
      Alert.alert('Erro', 'Não foi possível enviar o documento');
    } finally {
      setUploading(false);
    }
  };

  const handleDelete = (documentId: string) => {
    Alert.alert(
      'Excluir Documento',
      'Tem certeza que deseja excluir este documento?',
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Excluir',
          style: 'destructive',
          onPress: () => {
            setDocuments(prev => prev.filter(doc => doc.id !== documentId));
          },
        },
      ]
    );
  };

  const getFileIcon = (fileType: string) => {
    if (fileType.startsWith('image/')) return ImageIcon;
    if (fileType.startsWith('video/')) return Video;
    if (fileType === 'application/pdf') return FileText;
    return FileIcon;
  };

  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    return date.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (!caseId) {
    return (
      <View style={styles.container}>
        <StatusBar style="light" />
        <TopBar title="Documentos" showBack />
        <View style={styles.emptyState}>
          <FileText size={48} color="#9CA3AF" />
          <Text style={styles.emptyStateTitle}>Caso não encontrado</Text>
          <Text style={styles.emptyStateDescription}>
            O ID do caso não foi fornecido.
          </Text>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      
      <TopBar
        title="Documentos"
        subtitle={`Caso #${caseId.slice(-6)}`}
        showBack
      />

      <ScrollView
        style={styles.content}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
        }
        showsVerticalScrollIndicator={false}
      >
        {/* Upload Button */}
        <TouchableOpacity
          style={[styles.uploadButton, uploading && styles.uploadButtonDisabled]}
          onPress={handleUpload}
          disabled={uploading}
        >
          <Upload size={20} color="#FFFFFF" />
          <Text style={styles.uploadButtonText}>
            {uploading ? 'Enviando...' : 'Enviar Documento'}
          </Text>
        </TouchableOpacity>

        {/* Documents List */}
        {loading ? (
          <View style={styles.loadingState}>
            <Text style={styles.loadingText}>Carregando documentos...</Text>
          </View>
        ) : documents.length === 0 ? (
          <View style={styles.emptyState}>
            <FileText size={48} color="#9CA3AF" />
            <Text style={styles.emptyStateTitle}>Nenhum documento</Text>
            <Text style={styles.emptyStateDescription}>
              Ainda não há documentos anexados a este caso.
            </Text>
          </View>
        ) : (
          <View style={styles.documentsList}>
            {documents.map((document) => {
              const FileIconComponent = getFileIcon(document.file_type);
              const isOwner = document.uploaded_by === user?.id;
              
              return (
                <View key={document.id} style={styles.documentCard}>
                  <View style={styles.documentHeader}>
                    <View style={styles.documentIcon}>
                      <FileIconComponent size={24} color="#6B7280" />
                    </View>
                    <View style={styles.documentInfo}>
                      <Text style={styles.documentName} numberOfLines={1}>
                        {document.file_name}
                      </Text>
                      <Text style={styles.documentMeta}>
                        {formatFileSize(document.file_size)} • {formatDate(document.created_at)}
                      </Text>
                      <View style={styles.uploaderInfo}>
                        <User size={12} color="#9CA3AF" />
                        <Text style={styles.uploaderName}>
                          {document.uploader_name}
                        </Text>
                      </View>
                    </View>
                  </View>

                  <View style={styles.documentActions}>
                    <TouchableOpacity style={styles.actionButton}>
                      <Eye size={18} color="#6B7280" />
                    </TouchableOpacity>
                    <TouchableOpacity style={styles.actionButton}>
                      <Download size={18} color="#6B7280" />
                    </TouchableOpacity>
                    {isOwner && (
                      <TouchableOpacity
                        style={[styles.actionButton, styles.deleteButton]}
                        onPress={() => handleDelete(document.id)}
                      >
                        <Trash2 size={18} color="#EF4444" />
                      </TouchableOpacity>
                    )}
                  </View>
                </View>
              );
            })}
          </View>
        )}
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
  uploadButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#006CFF',
    borderRadius: 12,
    paddingVertical: 16,
    marginVertical: 16,
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
  loadingState: {
    alignItems: 'center',
    paddingVertical: 40,
  },
  loadingText: {
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#6B7280',
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: 60,
    paddingHorizontal: 32,
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
  },
  documentsList: {
    gap: 12,
    paddingBottom: 20,
  },
  documentCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 2,
  },
  documentHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
    gap: 12,
  },
  documentIcon: {
    width: 40,
    height: 40,
    borderRadius: 8,
    backgroundColor: '#F3F4F6',
    alignItems: 'center',
    justifyContent: 'center',
  },
  documentInfo: {
    flex: 1,
  },
  documentName: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#1F2937',
    marginBottom: 4,
  },
  documentMeta: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: '#6B7280',
    marginBottom: 4,
  },
  uploaderInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  uploaderName: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: '#9CA3AF',
  },
  documentActions: {
    flexDirection: 'row',
    gap: 8,
  },
  actionButton: {
    width: 36,
    height: 36,
    borderRadius: 8,
    backgroundColor: '#F9FAFB',
    alignItems: 'center',
    justifyContent: 'center',
  },
  deleteButton: {
    backgroundColor: '#FEF2F2',
  },
}); 