import React from 'react';
import { View, Text, StyleSheet, ActivityIndicator } from 'react-native';
import { FileText, MessageSquare, DollarSign, Star, Calendar } from 'lucide-react-native';

const eventIcons = {
  document_upload: <FileText size={16} color="#4A5568" />,
  lawyer_message: <MessageSquare size={16} color="#4A5568" />,
  fee_payment: <DollarSign size={16} color="#4A5568" />,
  review_submitted: <Star size={16} color="#4A5568" />,
  hearing_scheduled: <Calendar size={16} color="#4A5568" />,
  default: <FileText size={16} color="#4A5568" />,
};

const TimelineEvent = ({ event, isLast }) => {
  const Icon = eventIcons[event.event_type] || eventIcons.default;
  return (
    <View style={styles.eventContainer}>
      <View style={styles.iconContainer}>
        {Icon}
        {!isLast && <View style={styles.line} />}
      </View>
      <View style={styles.detailsContainer}>
        <Text style={styles.description}>{event.description}</Text>
        <Text style={styles.date}>{new Date(event.created_at).toLocaleString('pt-BR')}</Text>
      </View>
    </View>
  );
};

export default function CaseTimeline({ events, isLoading }) {
  if (isLoading) {
    return <ActivityIndicator color="#1E40AF" />;
  }

  return (
    <View style={styles.timelineContainer}>
      <Text style={styles.title}>Andamentos do Caso</Text>
      {events.map((event, index) => (
        <TimelineEvent key={event.id} event={event} isLast={index === events.length - 1} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  timelineContainer: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
  },
  title: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1F2937',
    marginBottom: 16,
  },
  eventContainer: {
    flexDirection: 'row',
  },
  iconContainer: {
    alignItems: 'center',
    marginRight: 12,
  },
  line: {
    flex: 1,
    width: 2,
    backgroundColor: '#E5E7EB',
  },
  detailsContainer: {
    flex: 1,
    paddingBottom: 24,
  },
  description: {
    fontSize: 14,
    fontWeight: '500',
    color: '#374151',
  },
  date: {
    fontSize: 12,
    color: '#6B7280',
    marginTop: 4,
  },
}); 