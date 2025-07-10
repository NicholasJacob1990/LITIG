import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { CheckCircle, Clock, AlertCircle } from 'lucide-react-native';
import Badge from '../atoms/Badge';

type StepItemProps = {
  title: string;
  description: string;
  status: 'completed' | 'pending' | 'delayed';
  priority: 'high' | 'medium' | 'low';
  dueDate?: string;
  isLast?: boolean;
};

const statusConfig = {
  completed: { icon: CheckCircle, color: '#10B981' },
  pending: { icon: Clock, color: '#6B7280' },
  delayed: { icon: AlertCircle, color: '#EF4444' },
};

const priorityConfig = {
  high: { label: 'Alta', intent: 'danger' },
  medium: { label: 'Média', intent: 'warning' },
  low: { label: 'Baixa', intent: 'info' },
};

export default function StepItem({ title, description, status, priority, dueDate, isLast = false }: StepItemProps) {
  const { icon: Icon, color } = statusConfig[status];
  const { label: priorityLabel, intent: priorityIntent } = priorityConfig[priority];

  return (
    <View style={styles.container}>
      <View style={styles.iconContainer}>
        <View style={[styles.iconWrapper, { backgroundColor: color }]}>
          <Icon size={16} color="#FFFFFF" />
        </View>
        {!isLast && <View style={styles.line} />}
      </View>
      <View style={styles.content}>
        <View style={styles.header}>
          <Text style={styles.title}>{title}</Text>
          <Badge label={priorityLabel} intent={priorityIntent as any} size="small" />
        </View>
        <Text style={styles.description}>{description}</Text>
        {dueDate && (
          <Text style={styles.dueDate}>
            Prazo: {new Date(dueDate).toLocaleDateString('pt-BR')}
          </Text>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 16,
  },
  iconContainer: {
    alignItems: 'center',
  },
  iconWrapper: {
    width: 32,
    height: 32,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1,
  },
  line: {
    width: 2,
    height: '100%',
    backgroundColor: '#E5E7EB',
    position: 'absolute',
    top: 32,
    left: 15,
  },
  content: {
    flex: 1,
    paddingBottom: 24,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  title: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#1F2937',
    flex: 1,
    marginRight: 8,
  },
  description: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
    lineHeight: 20,
    marginBottom: 8,
  },
  dueDate: {
    fontFamily: 'Inter-Medium',
    fontSize: 12,
    color: '#4B5563',
  },
}); 