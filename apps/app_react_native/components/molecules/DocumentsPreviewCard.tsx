import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ActivityIndicator } from 'react-native';
import { FileText, ChevronRight, FolderOpen } from 'lucide-react-native';
import { DocumentData } from '@/lib/services/documents';

interface DocumentsPreviewCardProps {
  documents: DocumentData[];
  onViewAll: () => void;
  loading?: boolean;
  previewCount?: number;
}

const DocumentsPreviewCard: React.FC<DocumentsPreviewCardProps> = ({
  documents,
  onViewAll,
  loading = false,
  previewCount = 3,
}) => {
  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    });
  };

  const previewDocuments = documents.slice(0, previewCount);
  const remainingCount = Math.max(0, documents.length - previewCount);

  if (loading) {
    return (
      <View style={styles.container}>
        <Text style={styles.sectionTitle}>Documentos</Text>
        <View style={styles.loadingCard}>
          <ActivityIndicator size="small" color="#3B82F6" />
          <Text style={styles.loadingText}>Carregando documentos...</Text>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.sectionTitle}>Documentos</Text>
      <View style={styles.card}>
        {documents.length === 0 ? (
          <View style={styles.emptyState}>
            <FolderOpen size={40} color="#9CA3AF" />
            <Text style={styles.emptyText}>Nenhum documento encontrado</Text>
            <Text style={styles.emptySubtext}>
              Os documentos do caso aparecerão aqui
            </Text>
          </View>
        ) : (
          <>
            <View style={styles.documentsPreview}>
              {previewDocuments.map((doc) => (
                <View key={doc.id} style={styles.docItem}>
                  <FileText size={20} color="#3B82F6" />
                  <View style={styles.docInfo}>
                    <Text style={styles.docName} numberOfLines={1}>
                      {doc.name}
                    </Text>
                    <Text style={styles.docMeta}>
                      {formatFileSize(doc.file_size)} • {formatDate(doc.uploaded_at)}
                    </Text>
                  </View>
                </View>
              ))}
            </View>
            
            <TouchableOpacity style={styles.viewAllButton} onPress={onViewAll}>
              <View style={styles.viewAllContent}>
                <Text style={styles.viewAllText}>
                  Ver Todos os Documentos
                  {remainingCount > 0 && ` (${documents.length})`}
                </Text>
                <ChevronRight size={18} color="#006CFF" />
              </View>
            </TouchableOpacity>
          </>
        )}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 16,
    paddingTop: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1E293B',
    marginBottom: 12,
  },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 6,
    elevation: 2,
  },
  loadingCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 24,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 6,
    elevation: 2,
  },
  loadingText: {
    fontSize: 14,
    color: '#6B7280',
    marginTop: 8,
  },
  emptyState: {
    alignItems: 'center',
    padding: 32,
  },
  emptyText: {
    fontSize: 16,
    fontWeight: '500',
    color: '#6B7280',
    marginTop: 12,
  },
  emptySubtext: {
    fontSize: 14,
    color: '#9CA3AF',
    marginTop: 4,
    textAlign: 'center',
  },
  documentsPreview: {
    padding: 16,
  },
  docItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F3F4F6',
  },
  docInfo: {
    flex: 1,
    marginLeft: 12,
  },
  docName: {
    fontSize: 15,
    fontWeight: '500',
    color: '#1F2937',
  },
  docMeta: {
    fontSize: 13,
    color: '#6B7280',
    marginTop: 2,
  },
  viewAllButton: {
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
  },
  viewAllContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 14,
    paddingHorizontal: 16,
  },
  viewAllText: {
    fontSize: 15,
    fontWeight: '600',
    color: '#006CFF',
    marginRight: 4,
  },
});

export default DocumentsPreviewCard;
