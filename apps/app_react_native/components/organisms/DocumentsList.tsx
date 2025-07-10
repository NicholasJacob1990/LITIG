import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ActivityIndicator } from 'react-native';
import { FileText, Download } from 'lucide-react-native';
import { DocumentData } from '@/lib/services/documents';

interface Document {
  name: string;
  size: string;
  date: string;
  url: string;
}

interface DocumentsListProps {
  documents: DocumentData[];
  onDownload: (document: DocumentData) => void;
  loading?: boolean;
}

const DocumentsList: React.FC<DocumentsListProps> = ({ documents, onDownload, loading = false }) => {
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
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (loading) {
    return (
      <View style={styles.container}>
        <Text style={styles.sectionTitle}>Documentos</Text>
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="small" color="#3B82F6" />
          <Text style={styles.loadingText}>Carregando documentos...</Text>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.sectionTitle}>Documentos</Text>
      <View style={styles.listContainer}>
        {documents.length === 0 ? (
          <View style={styles.emptyState}>
            <FileText size={48} color="#9CA3AF" />
            <Text style={styles.emptyStateText}>Nenhum documento encontrado</Text>
            <Text style={styles.emptyStateSubtext}>
              Os documentos do caso aparecerão aqui
            </Text>
          </View>
        ) : (
          documents.map((doc) => (
            <View key={doc.id} style={styles.docItem}>
              <FileText size={24} color="#3B82F6" />
              <View style={styles.docInfo}>
                <Text style={styles.docName}>{doc.name}</Text>
                <Text style={styles.docMeta}>
                  {formatFileSize(doc.file_size)} • {formatDate(doc.uploaded_at)}
                </Text>
                {doc.uploader && (
                  <Text style={styles.uploaderText}>
                    Enviado por {doc.uploader.name}
                  </Text>
                )}
              </View>
              <TouchableOpacity onPress={() => onDownload(doc)} style={styles.downloadButton}>
                <Download size={20} color="#6B7280" />
              </TouchableOpacity>
            </View>
          ))
        )}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 16,
    paddingTop: 24,
    paddingBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1E293B',
    marginBottom: 12,
  },
  listContainer: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 6,
    elevation: 2,
  },
  loadingContainer: {
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
  emptyStateText: {
    fontSize: 16,
    fontWeight: '500',
    color: '#6B7280',
    marginTop: 12,
  },
  emptyStateSubtext: {
    fontSize: 14,
    color: '#9CA3AF',
    marginTop: 4,
    textAlign: 'center',
  },
  docItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
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
  uploaderText: {
    fontSize: 12,
    color: '#9CA3AF',
    marginTop: 2,
  },
  downloadButton: {
    padding: 8,
  },
});

export default DocumentsList; 