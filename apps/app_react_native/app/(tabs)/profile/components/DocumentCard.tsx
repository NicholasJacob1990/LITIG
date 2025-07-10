import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { FileText, CheckCircle, Clock } from 'lucide-react-native';
import { PlatformDocument } from '@/lib/services/platform-documents';

interface DocumentCardProps {
  document: PlatformDocument;
  onPress: () => void;
}

const DocumentCard: React.FC<DocumentCardProps> = ({ document, onPress }) => {
  const isAccepted = !!document.accepted_at;

  return (
    <TouchableOpacity style={styles.card} onPress={onPress}>
      <FileText size={32} color={isAccepted ? '#10B981' : '#6B7280'} />
      <View style={styles.info}>
        <Text style={styles.title}>{document.title}</Text>
        <Text style={styles.version}>Versão {document.version}</Text>
        {isAccepted ? (
          <View style={styles.status}>
            <CheckCircle size={14} color="#10B981" />
            <Text style={styles.acceptedText}>
              Aceito em {new Date(document.accepted_at!).toLocaleDateString('pt-BR')}
            </Text>
          </View>
        ) : (
          <View style={styles.status}>
            <Clock size={14} color="#F59E0B" />
            <Text style={styles.pendingText}>Aceite pendente</Text>
          </View>
        )}
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  info: {
    marginLeft: 16,
    flex: 1,
  },
  title: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
  },
  version: {
    fontSize: 12,
    color: '#6B7280',
    marginTop: 2,
  },
  status: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
  },
  acceptedText: {
    marginLeft: 4,
    fontSize: 12,
    color: '#10B981',
    fontWeight: '500',
  },
  pendingText: {
    marginLeft: 4,
    fontSize: 12,
    color: '#F59E0B',
    fontWeight: '500',
  },
});

export default DocumentCard; 