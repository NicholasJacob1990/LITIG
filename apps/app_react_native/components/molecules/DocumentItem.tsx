import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { FileText } from 'lucide-react-native';
import DownloadButton from '../atoms/DownloadButton';
import FileSize from '../atoms/FileSize';

interface DocumentItemProps {
  name: string;
  size: number; // bytes
  uploadedAt: string; // ISO string
  onDownload: () => void;
}

export default function DocumentItem({ name, size, uploadedAt, onDownload }: DocumentItemProps) {
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  };

  return (
    <View style={styles.container}>
      <View style={styles.leftSection}>
        <FileText size={24} color="#006CFF" />
        <View style={styles.fileInfo}>
          <Text style={styles.fileName}>{name}</Text>
          <View style={styles.fileMeta}>
            <FileSize size={size} />
            <Text style={styles.separator}> • </Text>
            <Text style={styles.fileDate}>{formatDate(uploadedAt)}</Text>
          </View>
        </View>
      </View>
      <DownloadButton onPress={onDownload} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 12,
  },
  leftSection: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    flex: 1,
    gap: 12,
  },
  fileInfo: {
    flex: 1,
  },
  fileName: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#1F2937',
    marginBottom: 4,
  },
  fileMeta: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  separator: {
    fontSize: 12,
    fontFamily: 'Inter-Regular',
    color: '#9CA3AF',
  },
  fileDate: {
    fontSize: 12,
    fontFamily: 'Inter-Regular',
    color: '#9CA3AF',
  },
}); 