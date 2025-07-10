import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Image } from 'react-native';
import { Bot, Clock, MessageSquare, Eye } from 'lucide-react-native';

type CaseStatus = 'pending_assignment' | 'summary_generated' | 'assigned' | 'in_progress' | 'pending_client_action' | 'closed' | 'cancelled';

type CaseCardProps = {
  id: string;
  title: string;
  description: string;
  status: CaseStatus;
  statusLabel: string;
  clientType: 'PF' | 'PJ';
  createdAt: string;
  nextStep: string;
  hasAiSummary: boolean;
  summarySharedAt?: string;
  unreadMessages: number;
  priority: 'high' | 'medium' | 'low';
  lawyer?: {
    name: string;
    avatar?: string;
    specialty: string;
  };
  onPress: (id: string) => void;
  onViewSummary: (id: string) => void;
  onChat: (id: string) => void;
};

const statusStyles: Record<CaseStatus, {
  container: object;
  iconColor: string;
  text: object;
}> = {
  pending_assignment: { container: { backgroundColor: '#FEF3C7' }, iconColor: '#B45309', text: { color: '#92400E' } },
  summary_generated: { container: { backgroundColor: '#E0E7FF' }, iconColor: '#4338CA', text: { color: '#3730A3' } },
  assigned: { container: { backgroundColor: '#DBEAFE' }, iconColor: '#1D4ED8', text: { color: '#1E40AF' } },
  in_progress: { container: { backgroundColor: '#FEF3C7' }, iconColor: '#B45309', text: { color: '#92400E' } },
  pending_client_action: { container: { backgroundColor: '#FEE2E2' }, iconColor: '#B91C1C', text: { color: '#991B1B' } },
  closed: { container: { backgroundColor: '#D1FAE5' }, iconColor: '#047857', text: { color: '#065F46' } },
  cancelled: { container: { backgroundColor: '#E5E7EB' }, iconColor: '#4B5563', text: { color: '#374151' } },
};

const StatusBadge: React.FC<{ status: CaseStatus, label: string }> = ({ status, label }) => {
  const dynamicStyles = statusStyles[status] || statusStyles.cancelled;
  return (
    <View style={[styles.statusBadge, dynamicStyles.container]}>
      <Clock size={12} color={dynamicStyles.iconColor} />
      <Text style={[styles.statusBadgeText, dynamicStyles.text]}>{label.toUpperCase()}</Text>
    </View>
  );
};

const ClientTypeBadge: React.FC<{ type: 'PF' | 'PJ'; priority: 'high' | 'medium' | 'low' }> = ({ type, priority }) => (
  <View style={styles.clientTypeContainer}>
    <View style={styles.clientTypeBadge}>
      <Text style={styles.clientTypeBadgeText}>{type}</Text>
    </View>
    {priority === 'high' && <View style={styles.priorityDot} />}
  </View>
);

const CaseCard: React.FC<CaseCardProps> = ({
  id,
  title,
  description,
  status,
  statusLabel,
  clientType,
  createdAt,
  nextStep,
  hasAiSummary,
  summarySharedAt,
  unreadMessages,
  priority,
  lawyer,
  onPress,
  onViewSummary,
  onChat,
}) => {
  const formattedCreationDate = new Date(createdAt).toLocaleDateString('pt-BR');
  const formattedSummaryDate = summarySharedAt
    ? new Date(summarySharedAt).toLocaleString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      })
    : '';

  return (
    <TouchableOpacity style={styles.card} onPress={() => onPress(id)}>
      <View style={styles.header}>
        <Text style={styles.title} numberOfLines={1}>
          {title}
        </Text>
        <View style={styles.headerBadges}>
          <ClientTypeBadge type={clientType} priority={priority} />
          <StatusBadge status={status} label={statusLabel} />
        </View>
      </View>

      <Text style={styles.description} numberOfLines={2}>{description}</Text>

      {hasAiSummary && (
        <View style={styles.aiSummaryContainer}>
          <View style={styles.aiSummaryContent}>
            <Bot size={20} color="#6366F1" />
            <Text style={styles.aiSummaryText} numberOfLines={2}>
              Pré-análise IA gerada em {formattedSummaryDate}
            </Text>
          </View>
          <TouchableOpacity style={styles.aiViewButton} onPress={() => onViewSummary(id)}>
            <Text style={styles.aiViewButtonText}>Ver</Text>
          </TouchableOpacity>
        </View>
      )}

      {lawyer && (
        <View style={styles.lawyerContainer}>
          <Image source={{ uri: lawyer.avatar || 'https://via.placeholder.com/40' }} style={styles.lawyerAvatar} />
          <View style={styles.lawyerInfo}>
            <Text style={styles.lawyerName}>{lawyer.name}</Text>
            <Text style={styles.lawyerSpecialty}>{lawyer.specialty}</Text>
          </View>
          <TouchableOpacity style={styles.chatButton} onPress={() => onChat(id)}>
            <MessageSquare size={24} color="#64748B" />
            {unreadMessages > 0 && (
              <View style={styles.unreadBadge}>
                <Text style={styles.unreadBadgeText}>{unreadMessages}</Text>
              </View>
            )}
          </TouchableOpacity>
        </View>
      )}

      <View style={styles.footer}>
        <View>
          <Text style={styles.footerText}>Criado em {formattedCreationDate}</Text>
          <Text style={styles.nextStepText}>{nextStep}</Text>
        </View>
        <TouchableOpacity style={styles.detailsButton} onPress={() => onPress(id)}>
          <Eye size={16} color="#3B82F6" />
          <Text style={styles.detailsButtonText}>Ver Detalhes</Text>
        </TouchableOpacity>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 6,
    elevation: 3,
    gap: 16,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  title: {
    fontFamily: 'Inter-Bold',
    fontSize: 18,
    color: '#1F2937',
    flex: 1,
    marginRight: 8,
  },
  headerBadges: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  clientTypeContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  clientTypeBadge: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#E0E7FF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  clientTypeBadgeText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 10,
    color: '#4338CA',
  },
  priorityDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#EF4444',
  },
  statusBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 4,
    paddingHorizontal: 8,
    borderRadius: 12,
    gap: 4,
  },
  statusBadgeText: {
    fontFamily: 'Inter-Medium',
    fontSize: 12,
  },
  description: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
  },
  aiSummaryContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#EEF2FF',
    borderRadius: 12,
    padding: 12,
  },
  aiSummaryContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    flex: 1,
  },
  aiSummaryText: {
    fontFamily: 'Inter-Regular',
    fontSize: 13,
    color: '#4338CA',
    flex: 1,
  },
  aiViewButton: {
    backgroundColor: '#C7D2FE',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
    marginLeft: 8,
  },
  aiViewButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 12,
    color: '#3730A3',
  },
  lawyerContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
    paddingTop: 16,
  },
  lawyerAvatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
  },
  lawyerInfo: {
    flex: 1,
    marginLeft: 12,
  },
  lawyerName: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
    color: '#1F2937',
  },
  lawyerSpecialty: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: '#6B7280',
  },
  chatButton: {
    position: 'relative',
  },
  unreadBadge: {
    position: 'absolute',
    top: -4,
    right: -4,
    backgroundColor: '#EF4444',
    borderRadius: 10,
    minWidth: 20,
    height: 20,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#FFFFFF',
  },
  unreadBadgeText: {
    fontFamily: 'Inter-Bold',
    fontSize: 10,
    color: '#FFFFFF',
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
    paddingTop: 16,
  },
  footerText: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: '#6B7280',
    marginBottom: 4,
  },
  nextStepText: {
    fontFamily: 'Inter-Medium',
    fontSize: 13,
    color: '#374151',
  },
  detailsButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#E0F2FE',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    gap: 6,
  },
  detailsButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 13,
    color: '#0369A1',
  },
});

export default CaseCard; 