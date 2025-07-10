import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, StyleSheet, FlatList, ActivityIndicator, RefreshControl, TouchableOpacity, Modal, SafeAreaView, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { ArrowLeft, Download, CheckCircle, X } from 'lucide-react-native';
import { platformDocumentsService, PlatformDocument } from '@/lib/services/platform-documents';
import DocumentCard from './components/DocumentCard';
import * as WebBrowser from 'expo-web-browser';

const PlatformDocumentsScreen = () => {
  const router = useRouter();
  const [documents, setDocuments] = useState<PlatformDocument[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [selectedDoc, setSelectedDoc] = useState<PlatformDocument | null>(null);

  const loadDocuments = useCallback(async () => {
    try {
      setLoading(true);
      const docs = await platformDocumentsService.getDocuments();
      setDocuments(docs);
    } catch (error) {
      Alert.alert('Erro', 'Não foi possível carregar os documentos.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    loadDocuments();
  }, [loadDocuments]);

  const handleAccept = async () => {
    if (!selectedDoc) return;
    try {
      await platformDocumentsService.acceptDocument(selectedDoc.id);
      Alert.alert('Sucesso', `Você aceitou os termos de "${selectedDoc.title}".`);
      setSelectedDoc(null);
      loadDocuments(); // Recarregar para mostrar o status atualizado
    } catch (error) {
      Alert.alert('Erro', 'Não foi possível registrar seu aceite.');
    }
  };
  
  const handleDownload = async () => {
    if (!selectedDoc) return;
    try {
      const url = await platformDocumentsService.getDownloadUrl(selectedDoc.id);
      await WebBrowser.openBrowserAsync(url);
    } catch (error) {
      Alert.alert('Erro', 'Não foi possível obter o link para download.');
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
          <ArrowLeft size={24} color="#1F2937" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Documentos da Plataforma</Text>
      </View>

      {loading ? (
        <ActivityIndicator style={styles.loader} size="large" color="#006CFF" />
      ) : (
        <FlatList
          data={documents}
          keyExtractor={(item) => item.id}
          renderItem={({ item }) => (
            <DocumentCard document={item} onPress={() => setSelectedDoc(item)} />
          )}
          contentContainerStyle={styles.list}
          refreshControl={
            <RefreshControl refreshing={refreshing} onRefresh={loadDocuments} />
          }
        />
      )}

      {selectedDoc && (
        <Modal
          animationType="slide"
          transparent={true}
          visible={!!selectedDoc}
          onRequestClose={() => setSelectedDoc(null)}
        >
          <View style={styles.modalOverlay}>
            <View style={styles.modalContent}>
              <Text style={styles.modalTitle}>{selectedDoc.title}</Text>
              <Text style={styles.modalDescription}>{selectedDoc.description}</Text>
              
              <View style={styles.modalActions}>
                <TouchableOpacity style={styles.downloadButton} onPress={handleDownload}>
                  <Download size={20} color="#006CFF" />
                  <Text style={styles.downloadButtonText}>Baixar (Versão {selectedDoc.version})</Text>
                </TouchableOpacity>

                {!selectedDoc.accepted_at && (
                  <TouchableOpacity style={styles.acceptButton} onPress={handleAccept}>
                    <CheckCircle size={20} color="#FFFFFF" />
                    <Text style={styles.acceptButtonText}>Li e aceito os termos</Text>
                  </TouchableOpacity>
                )}
              </View>

              <TouchableOpacity style={styles.closeButton} onPress={() => setSelectedDoc(null)}>
                <X size={24} color="#6B7280" />
              </TouchableOpacity>
            </View>
          </View>
        </Modal>
      )}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F8FAFC' },
  header: { flexDirection: 'row', alignItems: 'center', padding: 16, borderBottomWidth: 1, borderBottomColor: '#E5E7EB' },
  backButton: { padding: 8 },
  headerTitle: { fontSize: 20, fontWeight: 'bold', marginLeft: 16, color: '#1F2937' },
  loader: { marginTop: 32 },
  list: { padding: 16 },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.6)', justifyContent: 'flex-end' },
  modalContent: { backgroundColor: 'white', borderTopLeftRadius: 20, borderTopRightRadius: 20, padding: 24, paddingTop: 32, },
  modalTitle: { fontSize: 22, fontWeight: 'bold', color: '#1F2937', marginBottom: 12, },
  modalDescription: { fontSize: 16, color: '#4B5563', lineHeight: 24, marginBottom: 24, },
  modalActions: { gap: 12 },
  downloadButton: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', padding: 16, borderRadius: 12, backgroundColor: '#EFF6FF', gap: 8 },
  downloadButtonText: { fontSize: 16, fontWeight: '600', color: '#006CFF' },
  acceptButton: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', padding: 16, borderRadius: 12, backgroundColor: '#10B981', gap: 8 },
  acceptButtonText: { fontSize: 16, fontWeight: '600', color: '#FFFFFF' },
  closeButton: { position: 'absolute', top: 16, right: 16, padding: 8 },
});

export default PlatformDocumentsScreen; 