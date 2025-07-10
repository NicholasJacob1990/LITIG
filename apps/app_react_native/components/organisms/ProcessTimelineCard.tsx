import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ActivityIndicator } from 'react-native';
import { ChevronRight, GanttChartSquare, AlertCircle } from 'lucide-react-native';
import { ProcessEventData } from '@/lib/services/processEvents';

interface ProcessTimelineCardProps {
  events: ProcessEventData[];
  onViewAll: () => void;
  loading?: boolean;
}

const ProcessTimelineCard: React.FC<ProcessTimelineCardProps> = ({
  events,
  onViewAll,
  loading = false,
}) => {
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });
  };

  const renderEvent = (event: ProcessEventData) => (
    <View key={event.id} style={styles.eventItem}>
      <View style={styles.eventDate}>
        <Text style={styles.dateText}>{formatDate(event.event_date)}</Text>
      </View>
      <View style={styles.timelineLine} />
      <View style={styles.eventDetails}>
        <Text style={styles.eventTitle}>{event.title}</Text>
        {event.description && <Text style={styles.eventDescription}>{event.description}</Text>}
      </View>
    </View>
  );

  return (
    <View style={styles.container}>
      <Text style={styles.sectionTitle}>Andamento Processual</Text>
      <View style={styles.card}>
        {loading ? (
          <View style={styles.centeredView}>
            <ActivityIndicator color="#006CFF" />
            <Text style={styles.loadingText}>Carregando andamento...</Text>
          </View>
        ) : events.length === 0 ? (
          <View style={styles.centeredView}>
            <GanttChartSquare size={40} color="#9CA3AF" />
            <Text style={styles.emptyText}>Nenhum andamento processual registrado.</Text>
          </View>
        ) : (
          <>
            <View style={styles.eventsContainer}>{events.map(renderEvent)}</View>
            <TouchableOpacity style={styles.viewAllButton} onPress={onViewAll}>
              <Text style={styles.viewAllButtonText}>Ver Andamento Completo</Text>
              <ChevronRight size={18} color="#006CFF" />
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
    paddingVertical: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  centeredView: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 32,
    paddingHorizontal: 16,
  },
  loadingText: {
    marginTop: 8,
    fontSize: 14,
    color: '#6B7280',
  },
  emptyText: {
    marginTop: 12,
    fontSize: 15,
    color: '#6B7280',
    textAlign: 'center',
  },
  eventsContainer: {
    paddingHorizontal: 16,
  },
  eventItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingVertical: 8,
  },
  eventDate: {
    width: 80,
    marginRight: 12,
    alignItems: 'flex-start',
  },
  dateText: {
    fontSize: 13,
    fontWeight: '500',
    color: '#4B5563',
  },
  timelineLine: {
    width: 2,
    backgroundColor: '#E5E7EB',
    position: 'absolute',
    left: 80,
    top: 12,
    bottom: -12,
  },
  eventDetails: {
    flex: 1,
    paddingLeft: 20,
    borderLeftWidth: 2,
    borderLeftColor: '#E5E7EB',
    marginLeft: 80,
    paddingBottom: 16,
  },
  eventTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 4,
  },
  eventDescription: {
    fontSize: 14,
    color: '#6B7280',
    lineHeight: 20,
  },
  viewAllButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    marginTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
  },
  viewAllButtonText: {
    fontSize: 15,
    fontWeight: '600',
    color: '#006CFF',
    marginRight: 4,
  },
});

export default ProcessTimelineCard; 