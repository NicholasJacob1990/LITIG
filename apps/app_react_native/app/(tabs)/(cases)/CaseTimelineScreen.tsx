import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, ActivityIndicator, Alert, Linking, TouchableOpacity, RefreshControl } from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import { getProcessEvents, ProcessEventData } from '@/lib/services/processEvents';
import TopBar from '@/components/layout/TopBar';
import { GanttChartSquare, Download, Plus } from 'lucide-react-native';
import ProcessEventForm from '@/components/organisms/ProcessEventForm';

export default function CaseTimelineScreen() {
  const route = useRoute<any>();
  const navigation = useNavigation();
  const { caseId } = route.params;

  const [events, setEvents] = useState<ProcessEventData[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [processEventFormVisible, setProcessEventFormVisible] = useState(false);

  useEffect(() => {
    loadTimeline();
  }, [caseId]);

  const loadTimeline = async () => {
    try {
      setLoading(true);
      const data = await getProcessEvents(caseId);
      setEvents(data);
    } catch (error) {
      console.error('Erro ao carregar linha do tempo:', error);
      Alert.alert('Erro', 'Não foi possível carregar o andamento do processo.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const handleRefresh = () => {
    setRefreshing(true);
    loadTimeline();
  };

  const openDocument = (url?: string) => {
    if (url && url.startsWith('http')) {
      Linking.openURL(url);
    } else {
      Alert.alert('Documento', 'Nenhum documento anexado a este andamento.');
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: 'long',
      year: 'numeric',
    });
  };

  const handleNewProcessEvent = () => {
    setProcessEventFormVisible(true);
  };

  const handleCloseProcessEventForm = () => {
    setProcessEventFormVisible(false);
    loadTimeline(); // Recarregar eventos
  };

  return (
    <View style={styles.container}>
      <TopBar title="Andamento Processual" subtitle={`Caso #${caseId.substring(0,4)}`} showBack />
      
      {loading && !refreshing ? (
        <View style={styles.centeredView}>
          <ActivityIndicator size="large" color="#006CFF" />
          <Text style={styles.loadingText}>Carregando histórico...</Text>
        </View>
      ) : events.length === 0 ? (
        <ScrollView 
            contentContainerStyle={styles.centeredView}
            refreshControl={<RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />}
        >
          <GanttChartSquare size={48} color="#9CA3AF" />
          <Text style={styles.emptyText}>Nenhum andamento processual registrado ainda.</Text>
        </ScrollView>
      ) : (
        <ScrollView
          style={styles.timelineContainer}
          refreshControl={<RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />}
        >
          {events.map((event, index) => (
            <View key={event.id} style={styles.timelineItem}>
              <View style={styles.timelineDecorator}>
                <View style={styles.timelineDot} />
                {index < events.length - 1 && <View style={styles.timelineLine} />}
              </View>
              <View style={styles.timelineContent}>
                <Text style={styles.eventDate}>{formatDate(event.event_date)}</Text>
                <Text style={styles.eventTitle}>{event.title}</Text>
                <Text style={styles.eventDescription}>{event.description}</Text>
                {event.document_url && (
                  <TouchableOpacity style={styles.documentButton} onPress={() => openDocument(event.document_url)}>
                    <Download size={16} color="#006CFF" />
                    <Text style={styles.documentButtonText}>Ver Documento</Text>
                  </TouchableOpacity>
                )}
              </View>
            </View>
          ))}
        </ScrollView>
      )}

      {/* FAB para novo evento */}
      <TouchableOpacity style={styles.fab} onPress={handleNewProcessEvent}>
        <Plus size={28} color="white" />
      </TouchableOpacity>

      {/* Modal do formulário */}
      <ProcessEventForm
        isVisible={processEventFormVisible}
        onClose={handleCloseProcessEventForm}
        caseId={caseId}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  centeredView: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  loadingText: {
    marginTop: 10,
    fontSize: 16,
    color: '#6B7280',
  },
  emptyText: {
    marginTop: 16,
    fontSize: 16,
    color: '#6B7280',
    textAlign: 'center',
  },
  timelineContainer: {
    paddingHorizontal: 20,
    paddingTop: 20,
  },
  timelineItem: {
    flexDirection: 'row',
  },
  timelineDecorator: {
    alignItems: 'center',
    marginRight: 16,
  },
  timelineDot: {
    width: 14,
    height: 14,
    borderRadius: 7,
    backgroundColor: '#006CFF',
    zIndex: 1,
  },
  timelineLine: {
    flex: 1,
    width: 2,
    backgroundColor: '#E5E7EB',
  },
  timelineContent: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    padding: 16,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  eventDate: {
    fontSize: 13,
    fontWeight: '500',
    color: '#6B7280',
    marginBottom: 8,
  },
  eventTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: '#1F2937',
    marginBottom: 6,
  },
  eventDescription: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 21,
  },
  documentButton: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 12,
    paddingVertical: 6,
    paddingHorizontal: 10,
    backgroundColor: '#EFF6FF',
    borderRadius: 6,
    alignSelf: 'flex-start',
  },
  documentButtonText: {
    marginLeft: 8,
    fontSize: 14,
    fontWeight: '600',
    color: '#006CFF',
  },
  fab: {
    position: 'absolute',
    bottom: 30,
    right: 30,
    backgroundColor: '#0F172A',
    width: 60,
    height: 60,
    borderRadius: 30,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 4,
    elevation: 5,
  },
}); 