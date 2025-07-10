import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert, Linking } from 'react-native';
import { FileText, Image, Download, File } from 'lucide-react-native';

interface AttachmentItemProps {
  url: string;
  name: string;
  mimeType?: string;
  size?: number;
  onDownload?: () => void;
}

export default function AttachmentItem({ 
  url, 
  name, 
  mimeType, 
  size,
  onDownload 
}: AttachmentItemProps) {
  
  const getFileIcon = () => {
    if (!mimeType) return <File size={20} color="#6B7280" />;
    
    if (mimeType.startsWith('image/')) {
      return <Image size={20} color="#10B981" />;
    } else if (mimeType.includes('pdf')) {
      return <FileText size={20} color="#EF4444" />;
    } else if (mimeType.includes('text/') || mimeType.includes('document')) {
      return <FileText size={20} color="#3B82F6" />;
    } else {
      return <File size={20} color="#6B7280" />;
    }
  };

  const getFileExtension = (filename: string) => {
    const parts = filename.split('.');
    return parts.length > 1 ? parts.pop()?.toUpperCase() : '';
  };

  const formatFileSize = (bytes?: number) => {
    if (!bytes) return '';
    
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
  };

  const handleDownload = async () => {
    try {
      if (onDownload) {
        onDownload();
      } else {
        // Fallback: abrir URL no navegador
        const supported = await Linking.canOpenURL(url);
        if (supported) {
          await Linking.openURL(url);
        } else {
          Alert.alert('Erro', 'Não foi possível abrir o arquivo.');
        }
      }
    } catch (error) {
      console.error('Error downloading file:', error);
      Alert.alert('Erro', 'Não foi possível baixar o arquivo.');
    }
  };

  return (
    <TouchableOpacity style={styles.container} onPress={handleDownload}>
      <View style={styles.iconContainer}>
        {getFileIcon()}
      </View>
      
      <View style={styles.fileInfo}>
        <Text style={styles.fileName} numberOfLines={1}>
          {name}
        </Text>
        <View style={styles.metadata}>
          {getFileExtension(name) && (
            <Text style={styles.fileType}>
              {getFileExtension(name)}
            </Text>
          )}
          {size && (
            <>
              <Text style={styles.separator}>•</Text>
              <Text style={styles.fileSize}>
                {formatFileSize(size)}
              </Text>
            </>
          )}
        </View>
      </View>
      
      <TouchableOpacity style={styles.downloadButton} onPress={handleDownload}>
        <Download size={16} color="#4F46E5" />
      </TouchableOpacity>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F9FAFB',
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 8,
    padding: 12,
    marginTop: 8,
    maxWidth: 280,
  },
  iconContainer: {
    width: 40,
    height: 40,
    borderRadius: 8,
    backgroundColor: '#FFF',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  fileInfo: {
    flex: 1,
    marginRight: 8,
  },
  fileName: {
    fontSize: 14,
    fontWeight: '600',
    color: '#111827',
    marginBottom: 2,
  },
  metadata: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  fileType: {
    fontSize: 12,
    color: '#6B7280',
    fontWeight: '500',
  },
  separator: {
    fontSize: 12,
    color: '#9CA3AF',
    marginHorizontal: 4,
  },
  fileSize: {
    fontSize: 12,
    color: '#6B7280',
  },
  downloadButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#EEF2FF',
    justifyContent: 'center',
    alignItems: 'center',
  },
}); 