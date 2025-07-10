import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { MessageCircle, AlertTriangle, Calendar, Clock, CheckCircle, User, Eye } from 'lucide-react-native';
import Badge from '../atoms/Badge';
import StatusDot from '../atoms/StatusDot';
import ProgressBar from '../atoms/ProgressBar';

interface LawyerCaseCardProps {
  id: string;
  title: string;
  description: string;
  status: 'active' | 'pending' | 'completed' | 'summary_generated';
  priority: 'low' | 'medium' | 'high';
  clientName: string;
  clientType: 'PF' | 'PJ';
  createdAt: string;
  lastActivity: string;
  // Métricas específicas para advogados
  unreadMessages: number;
  overdueTasks: number;
  nextDeadline?: {
    date: string;
    description: string;
    daysLeft: number;
  };
  pendingActions: number;
  // Callbacks
  onPress?: () => void;
  onChat?: () => void;
  onViewTasks?: () => void;
}

export default function LawyerCaseCard({
  id,
  title,
  description,
  status,
  priority,
  clientName,
  clientType,
  createdAt,
  lastActivity,
  unreadMessages = 0,
  overdueTasks = 0,
  nextDeadline,
  pendingActions = 0,
  onPress,
  onChat,
  onViewTasks
}: LawyerCaseCardProps) {
  const getStatusBadgeIntent = () => {
    switch (status) {
      case 'active':
        return 'primary';
      case 'completed':
        return 'success';
      case 'pending':
        return 'warning';
      case 'summary_generated':
        return 'info';
      default:
        return 'neutral';
    }
  };

  const getStatusText = () => {
    switch (status) {
      case 'active':
        return 'Em Andamento';
      case 'completed':
        return 'Concluído';
      case 'pending':
        return 'Aguardando';
      case 'summary_generated':
        return 'Pré-análise Pronta';
      default:
        return 'Desconhecido';
    }
  };

  const getPriorityColor = () => {
    switch (priority) {
      case 'high':
        return '#EF4444';
      case 'medium':
        return '#F59E0B';
      case 'low':
        return '#10B981';
      default:
        return '#6B7280';
    }
  };

  const getUrgencyLevel = () => {
    let urgencyScore = 0;
    
    // Adiciona pontos baseado nas métricas
    if (unreadMessages > 0) urgencyScore += 2;
    if (overdueTasks > 0) urgencyScore += 3;
    if (nextDeadline && nextDeadline.daysLeft <= 3) urgencyScore += 4;
    if (priority === 'high') urgencyScore += 3;
    
    return Math.min(urgencyScore, 10);
  };

  const formatRelativeTime = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffHours = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60));
    
    if (diffHours < 1) return 'Agora há pouco';
    if (diffHours < 24) return `${diffHours}h atrás`;
    const diffDays = Math.floor(diffHours / 24);
    if (diffDays < 7) return `${diffDays}d atrás`;
    return date.toLocaleDateString('pt-BR');
  };

  const getDeadlineColor = (daysLeft: number) => {
    if (daysLeft <= 1) return '#EF4444'; // Vermelho - crítico
    if (daysLeft <= 3) return '#F59E0B'; // Amarelo - atenção
    return '#10B981'; // Verde - ok
  };

  return (
    <TouchableOpacity style={[styles.card, { borderLeftColor: getPriorityColor() }]} onPress={onPress}>
      {/* Header Section */}
      <View style={styles.header}>
        <View style={styles.headerLeft}>
          <Text style={styles.title} numberOfLines={2}>{title}</Text>
          <Text style={styles.description} numberOfLines={2}>{description}</Text>
        </View>
        
        <View style={styles.headerRight}>
          <StatusDot status={status} />
          <Badge 
            label={getStatusText()} 
            intent={getStatusBadgeIntent()} 
            size="small" 
          />
        </View>
      </View>

      {/* Client Info */}
      <View style={styles.clientSection}>
        <User size={16} color="#6B7280" />
        <Text style={styles.clientName}>{clientName}</Text>
        <Badge label={clientType} intent="neutral" size="small" />
        <Text style={styles.lastActivity}>• {formatRelativeTime(lastActivity)}</Text>
      </View>

      {/* Urgency Bar */}
      {getUrgencyLevel() > 0 && (
        <View style={styles.urgencySection}>
          <Text style={styles.urgencyLabel}>Nível de Urgência</Text>
          <ProgressBar 
            value={getUrgencyLevel()} 
            maxValue={10} 
            height={6}
            color={getUrgencyLevel() >= 7 ? '#EF4444' : getUrgencyLevel() >= 4 ? '#F59E0B' : '#10B981'}
          />
        </View>
      )}

      {/* Action Metrics */}
      <View style={styles.metricsSection}>
        {/* Messages */}
        {unreadMessages > 0 && (
          <TouchableOpacity style={styles.metricItem} onPress={onChat}>
            <MessageCircle size={18} color="#3B82F6" />
            <Text style={styles.metricLabel}>Mensagens</Text>
            <Badge label={unreadMessages.toString()} intent="primary" size="small" />
          </TouchableOpacity>
        )}

        {/* Overdue Tasks */}
        {overdueTasks > 0 && (
          <TouchableOpacity style={styles.metricItem} onPress={onViewTasks}>
            <AlertTriangle size={18} color="#EF4444" />
            <Text style={styles.metricLabel}>Atrasadas</Text>
            <Badge label={overdueTasks.toString()} intent="danger" size="small" />
          </TouchableOpacity>
        )}

        {/* Next Deadline */}
        {nextDeadline && (
          <View style={styles.metricItem}>
            <Calendar size={18} color={getDeadlineColor(nextDeadline.daysLeft)} />
            <View style={styles.deadlineInfo}>
              <Text style={styles.deadlineText} numberOfLines={1}>
                {nextDeadline.description}
              </Text>
              <Text style={[styles.deadlineDays, { color: getDeadlineColor(nextDeadline.daysLeft) }]}>
                {nextDeadline.daysLeft === 0 ? 'Hoje' : 
                 nextDeadline.daysLeft === 1 ? 'Amanhã' : 
                 `${nextDeadline.daysLeft} dias`}
              </Text>
            </View>
          </View>
        )}

        {/* Pending Actions */}
        {pendingActions > 0 && (
          <View style={styles.metricItem}>
            <Clock size={18} color="#F59E0B" />
            <Text style={styles.metricLabel}>Pendências</Text>
            <Badge label={pendingActions.toString()} intent="warning" size="small" />
          </View>
        )}

        {/* No urgent actions */}
        {unreadMessages === 0 && overdueTasks === 0 && !nextDeadline && pendingActions === 0 && (
          <View style={styles.metricItem}>
            <CheckCircle size={18} color="#10B981" />
            <Text style={[styles.metricLabel, { color: '#10B981' }]}>Em dia</Text>
          </View>
        )}
      </View>

      {/* Actions */}
      <View style={styles.actionsSection}>
        <TouchableOpacity style={styles.viewDetailsButton} onPress={onPress}>
          <Eye size={16} color="#3B82F6" />
          <Text style={styles.viewDetailsText}>Gerenciar Caso</Text>
        </TouchableOpacity>
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
    borderLeftWidth: 4,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  headerLeft: {
    flex: 1,
    marginRight: 12,
  },
  headerRight: {
    alignItems: 'flex-end',
    gap: 8,
  },
  title: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    lineHeight: 22,
    marginBottom: 4,
  },
  description: {
    fontSize: 14,
    color: '#6B7280',
    lineHeight: 20,
  },
  clientSection: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
    gap: 8,
  },
  clientName: {
    fontSize: 14,
    fontWeight: '500',
    color: '#374151',
  },
  lastActivity: {
    fontSize: 12,
    color: '#9CA3AF',
  },
  urgencySection: {
    marginBottom: 16,
  },
  urgencyLabel: {
    fontSize: 12,
    fontWeight: '500',
    color: '#6B7280',
    marginBottom: 6,
  },
  metricsSection: {
    gap: 12,
    marginBottom: 16,
  },
  metricItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F9FAFB',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    gap: 8,
  },
  metricLabel: {
    fontSize: 14,
    fontWeight: '500',
    color: '#374151',
    flex: 1,
  },
  deadlineInfo: {
    flex: 1,
  },
  deadlineText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#374151',
  },
  deadlineDays: {
    fontSize: 12,
    fontWeight: '600',
    marginTop: 2,
  },
  actionsSection: {
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
  },
  viewDetailsButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#F0F9FF',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 8,
    gap: 8,
  },
  viewDetailsText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#3B82F6',
  },
}); 