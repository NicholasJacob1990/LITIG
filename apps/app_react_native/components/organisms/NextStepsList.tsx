import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ActivityIndicator } from 'react-native';
import { ListTodo, ArrowRight } from 'lucide-react-native';
import StepItem from '../molecules/StepItem';
import { Task } from '@/lib/services/tasks';

type NextStepsListProps = {
  steps: Task[];
  loading: boolean;
  onViewAll?: () => void;
};

const mapStatus = (status: Task['status']): 'completed' | 'pending' | 'delayed' => {
  const statusMap: { [key: string]: 'completed' | 'pending' | 'delayed' } = {
    completed: 'completed',
    pending: 'pending',
    in_progress: 'pending',
    overdue: 'delayed',
  };
  return statusMap[status] || 'pending';
};

const mapPriority = (priority?: number | 'low' | 'medium' | 'high'): 'low' | 'medium' | 'high' => {
    if (typeof priority === 'number') {
        if (priority > 7) return 'high';
        if (priority > 4) return 'medium';
        return 'low';
    }
    return priority || 'low';
}

export default function NextStepsList({ steps, loading, onViewAll }: NextStepsListProps) {
  const visibleSteps = steps.slice(0, 3); // Mostrar apenas as 3 primeiras tarefas

  return (
    <View style={styles.card}>
      <View style={styles.cardHeader}>
        <Text style={styles.cardTitle}>Próximos Passos</Text>
        {onViewAll && (
          <TouchableOpacity style={styles.viewAllButton} onPress={onViewAll}>
            <Text style={styles.viewAllText}>Ver Todos</Text>
            <ArrowRight size={16} color="#006CFF" />
          </TouchableOpacity>
        )}
      </View>

      {loading ? (
        <ActivityIndicator size="small" color="#006CFF" style={{ marginVertical: 20 }}/>
      ) : visibleSteps.length > 0 ? (
        <View style={styles.stepsContainer}>
          {visibleSteps.map((step, index) => (
            <StepItem
              key={step.id}
              title={step.title}
              description={step.description || 'Sem descrição'}
              status={mapStatus(step.status)}
              priority={mapPriority(step.priority)}
              dueDate={step.due_date}
              isLast={index === visibleSteps.length - 1}
            />
          ))}
        </View>
      ) : (
        <View style={styles.emptyState}>
          <ListTodo size={32} color="#9CA3AF" />
          <Text style={styles.emptyStateText}>Nenhuma tarefa definida para este caso.</Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  cardTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1F2937',
  },
  viewAllButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  viewAllText: {
    fontFamily: 'Inter-Medium',
    fontSize: 14,
    color: '#006CFF',
  },
  stepsContainer: {
    // Estilos para o container da lista de steps
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: 24,
  },
  emptyStateText: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
    marginTop: 12,
  },
}); 