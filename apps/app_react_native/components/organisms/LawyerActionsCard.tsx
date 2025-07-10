import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { FileText, DollarSign, ListTodo, CalendarPlus, ChevronRight } from 'lucide-react-native';

interface LawyerActionsCardProps {
  onDefineScope: () => void;
  onAdjustFees: () => void;
  onAddTask: () => void;
  onScheduleConsultation: () => void;
}

const LawyerActionsCard: React.FC<LawyerActionsCardProps> = ({
  onDefineScope,
  onAdjustFees,
  onAddTask,
  onScheduleConsultation,
}) => {
  const actions = [
    {
      icon: <FileText size={22} color="#3B82F6" />,
      label: 'Definir Escopo do Serviço',
      description: 'Estabeleça os entregáveis e limites da atuação.',
      onPress: onDefineScope,
    },
    {
      icon: <DollarSign size={22} color="#16A34A" />,
      label: 'Ajustar Honorários',
      description: 'Defina os custos de consulta e representação.',
      onPress: onAdjustFees,
    },
    {
      icon: <ListTodo size={22} color="#F97316" />,
      label: 'Adicionar Tarefa',
      description: 'Crie um novo passo para o andamento do caso.',
      onPress: onAddTask,
    },
    {
      icon: <CalendarPlus size={22} color="#7C3AED" />,
      label: 'Agendar Consulta',
      description: 'Marque uma nova conversa com o cliente.',
      onPress: onScheduleConsultation,
    },
  ];

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Painel de Ações do Advogado</Text>
      <View style={styles.card}>
        {actions.map((action, index) => (
          <TouchableOpacity key={index} style={styles.actionRow} onPress={action.onPress}>
            <View style={styles.iconContainer}>{action.icon}</View>
            <View style={styles.textContainer}>
              <Text style={styles.actionLabel}>{action.label}</Text>
              <Text style={styles.actionDescription}>{action.description}</Text>
            </View>
            <ChevronRight size={20} color="#9CA3AF" />
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 16,
    paddingTop: 24,
    paddingBottom: 16,
    backgroundColor: '#F9FAFB',
  },
  title: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1E293B',
    marginBottom: 12,
  },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  actionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#F3F4F6',
  },
  actionRowLast: {
    borderBottomWidth: 0,
  },
  iconContainer: {
    marginRight: 16,
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#EFF6FF',
  },
  textContainer: {
    flex: 1,
  },
  actionLabel: {
    fontSize: 15,
    fontWeight: '600',
    color: '#374151',
  },
  actionDescription: {
    fontSize: 13,
    color: '#6B7280',
    marginTop: 2,
  },
});

export default LawyerActionsCard; 