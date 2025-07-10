/**
 * Componente para visualização prévia de documentos
 * Exibe documentos com preview, download e ações
 */
import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Alert,
  Dimensions,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import * as FileSystem from 'expo-file-system';
import * as Sharing from 'expo-sharing';

import type { Document, DocumentType } from '@/lib/types';

const { width: screenWidth } = Dimensions.get('window');

interface DocumentsPreviewCardProps {
  documents: Document[];
  onDocumentPress?: (document: Document) => void;
  onDocumentDelete?: (documentId: string) => void;
  onDocumentShare?: (document: Document) => void;
  maxVisible?: number;
  showActions?: boolean;
  compact?: boolean;
}

interface DocumentItemProps {
  document: Document;
  onPress?: () => void;
  onDelete?: () => void;
  onShare?: () => void;
  showActions?: boolean;
  compact?: boolean;
}

const DocumentItem: React.FC<DocumentItemProps> = ({
  document,
  onPress,
  onDelete,
  onShare,
  showActions = true,
  compact = false,
}) => {
  const [downloading, setDownloading] = useState(false);

  const getDocumentIcon = (type: DocumentType) => {
    switch (type) {
      case 'contract':
        return 'document-text-outline' as const;
      case 'petition':
        return 'document-outline' as const;
      case 'evidence':
        return 'camera-outline' as const;
      case 'court_decision':
        return 'library-outline' as const;
      case 'correspondence':
        return 'mail-outline' as const;
      case 'invoice':
        return 'receipt-outline' as const;
      case 'receipt':
        return 'card-outline' as const;
      case 'identity':
        return 'person-outline' as const;
      default:
        return 'document-outline' as const;
    }
  };

  const getDocumentTypeLabel = (type: DocumentType): string => {
    switch (type) {
      case 'contract':
        return 'Contrato';
      case 'petition':
        return 'Petição';
      case 'evidence':
        return 'Evidência';
      case 'court_decision':
        return 'Decisão Judicial';
      case 'correspondence':
        return 'Correspondência';
      case 'invoice':
        return 'Fatura';
      case 'receipt':
        return 'Recibo';
      case 'identity':
        return 'Identidade';
      default:
        return 'Documento';
    }
  };

  const formatFileSize = (bytes: number): string => {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const getStatusColor = (status: Document['status']): string => {
    switch (status) {
      case 'ready':
        return '#10b981';
      case 'processing':
        return '#f59e0b';
      case 'uploading':
        return '#3b82f6';
      case 'error':
        return '#ef4444';
      default:
        return '#6b7280';
    }
  };

  const getStatusLabel = (status: Document['status']): string => {
    switch (status) {
      case 'ready':
        return 'Pronto';
      case 'processing':
        return 'Processando';
      case 'uploading':
        return 'Enviando';
      case 'error':
        return 'Erro';
      default:
        return 'Desconhecido';
    }
  };

  const handleDownload = async () => {
    if (!document.file_url) return;

    try {
      setDownloading(true);
      
      // Criar nome do arquivo
      const fileName = `${document.name}.${document.mime_type.split('/')[1] || 'pdf'}`;
      const fileUri = FileSystem.documentDirectory + fileName;

      // Download do arquivo
      const downloadResult = await FileSystem.downloadAsync(
        document.file_url,
        fileUri
      );

      if (downloadResult.status === 200) {
        // Compartilhar o arquivo baixado
        if (await Sharing.isAvailableAsync()) {
          await Sharing.shareAsync(downloadResult.uri);
        } else {
          Alert.alert('Sucesso', 'Arquivo baixado com sucesso!');
        }
      } else {
        throw new Error('Falha no download');
      }
    } catch (error) {
      Alert.alert('Erro', 'Não foi possível baixar o documento');
      console.error('Download error:', error);
    } finally {
      setDownloading(false);
    }
  };

  const handleShare = () => {
    if (onShare) {
      onShare();
    } else {
      handleDownload();
    }
  };

  const handleDelete = () => {
    Alert.alert(
      'Excluir Documento',
      `Tem certeza que deseja excluir "${document.name}"?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Excluir',
          style: 'destructive',
          onPress: onDelete,
        },
      ]
    );
  };

  return (
    <TouchableOpacity
      style={[styles.documentItem, compact && styles.documentItemCompact]}
      onPress={onPress}
      disabled={document.status !== 'ready'}
    >
      <View style={styles.documentHeader}>
        <View style={styles.documentIcon}>
          <Ionicons
            name={getDocumentIcon(document.type)}
            size={compact ? 20 : 24}
            color="#007bff"
          />
        </View>

        <View style={styles.documentInfo}>
          <Text
            style={[styles.documentName, compact && styles.documentNameCompact]}
            numberOfLines={compact ? 1 : 2}
          >
            {document.name}
          </Text>
          
          {!compact && (
            <Text style={styles.documentType}>
              {getDocumentTypeLabel(document.type)}
            </Text>
          )}
          
          <View style={styles.documentMeta}>
            <Text style={styles.documentSize}>
              {formatFileSize(document.file_size)}
            </Text>
            <Text style={styles.documentDivider}>•</Text>
            <Text style={styles.documentDate}>
              {format(new Date(document.uploaded_at), 'dd/MM/yy', { locale: ptBR })}
            </Text>
          </View>
        </View>

        <View style={styles.documentStatus}>
          <View
            style={[
              styles.statusIndicator,
              { backgroundColor: getStatusColor(document.status) },
            ]}
          />
          {!compact && (
            <Text
              style={[
                styles.statusText,
                { color: getStatusColor(document.status) },
              ]}
            >
              {getStatusLabel(document.status)}
            </Text>
          )}
        </View>
      </View>

      {showActions && document.status === 'ready' && (
        <View style={styles.documentActions}>
          <TouchableOpacity
            style={styles.actionButton}
            onPress={handleShare}
            disabled={downloading}
          >
            {downloading ? (
              <ActivityIndicator size="small" color="#007bff" />
            ) : (
              <Ionicons name="share-outline" size={16} color="#007bff" />
            )}
          </TouchableOpacity>

          {onDelete && (
            <TouchableOpacity
              style={styles.actionButton}
              onPress={handleDelete}
            >
              <Ionicons name="trash-outline" size={16} color="#ef4444" />
            </TouchableOpacity>
          )}
        </View>
      )}
    </TouchableOpacity>
  );
};

const DocumentsPreviewCard: React.FC<DocumentsPreviewCardProps> = ({
  documents,
  onDocumentPress,
  onDocumentDelete,
  onDocumentShare,
  maxVisible = 5,
  showActions = true,
  compact = false,
}) => {
  const [showAll, setShowAll] = useState(false);

  const visibleDocuments = showAll 
    ? documents 
    : documents.slice(0, maxVisible);

  const hasMore = documents.length > maxVisible;

  if (documents.length === 0) {
    return (
      <View style={[styles.card, styles.emptyState]}>
        <Ionicons name="document-outline" size={48} color="#ccc" />
        <Text style={styles.emptyText}>Nenhum documento encontrado</Text>
        <Text style={styles.emptySubtext}>
          Os documentos aparecerão aqui quando forem adicionados
        </Text>
      </View>
    );
  }

  return (
    <View style={styles.card}>
      <View style={styles.header}>
        <View style={styles.titleContainer}>
          <Ionicons name="folder-outline" size={20} color="#007bff" />
          <Text style={styles.title}>
            Documentos ({documents.length})
          </Text>
        </View>

        {hasMore && (
          <TouchableOpacity
            style={styles.toggleButton}
            onPress={() => setShowAll(!showAll)}
          >
            <Text style={styles.toggleText}>
              {showAll ? 'Ver menos' : `Ver todos (${documents.length})`}
            </Text>
            <Ionicons
              name={showAll ? 'chevron-up' : 'chevron-down'}
              size={16}
              color="#007bff"
            />
          </TouchableOpacity>
        )}
      </View>

      <ScrollView
        style={styles.documentsList}
        showsVerticalScrollIndicator={false}
        nestedScrollEnabled
      >
        {visibleDocuments.map((document) => (
          <DocumentItem
            key={document.id}
            document={document}
            onPress={() => onDocumentPress?.(document)}
            onDelete={() => onDocumentDelete?.(document.id)}
            onShare={() => onDocumentShare?.(document)}
            showActions={showActions}
            compact={compact}
          />
        ))}
      </ScrollView>

      {documents.length > 0 && (
        <View style={styles.footer}>
          <Text style={styles.footerText}>
            {documents.filter(d => d.status === 'ready').length} de {documents.length} prontos
          </Text>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  titleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  title: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    marginLeft: 8,
  },
  toggleButton: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  toggleText: {
    fontSize: 14,
    color: '#007bff',
    marginRight: 4,
  },
  documentsList: {
    maxHeight: 300,
  },
  documentItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 12,
    paddingHorizontal: 8,
    borderRadius: 8,
    marginBottom: 8,
    backgroundColor: '#f8f9fa',
  },
  documentItemCompact: {
    paddingVertical: 8,
  },
  documentHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  documentIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#e3f2fd',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  documentInfo: {
    flex: 1,
  },
  documentName: {
    fontSize: 14,
    fontWeight: '500',
    color: '#333',
    marginBottom: 4,
  },
  documentNameCompact: {
    fontSize: 13,
    marginBottom: 2,
  },
  documentType: {
    fontSize: 12,
    color: '#666',
    marginBottom: 4,
  },
  documentMeta: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  documentSize: {
    fontSize: 11,
    color: '#999',
  },
  documentDivider: {
    fontSize: 11,
    color: '#999',
    marginHorizontal: 4,
  },
  documentDate: {
    fontSize: 11,
    color: '#999',
  },
  documentStatus: {
    alignItems: 'center',
    marginRight: 8,
  },
  statusIndicator: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginBottom: 4,
  },
  statusText: {
    fontSize: 10,
    fontWeight: '500',
  },
  documentActions: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  actionButton: {
    padding: 8,
    marginLeft: 4,
  },
  footer: {
    borderTopWidth: 1,
    borderTopColor: '#e5e5e5',
    paddingTop: 12,
    marginTop: 8,
  },
  footerText: {
    fontSize: 12,
    color: '#666',
    textAlign: 'center',
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: 32,
  },
  emptyText: {
    fontSize: 16,
    fontWeight: '500',
    color: '#666',
    marginTop: 16,
    marginBottom: 8,
  },
  emptySubtext: {
    fontSize: 14,
    color: '#999',
    textAlign: 'center',
  },
});

export default DocumentsPreviewCard; 