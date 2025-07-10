import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { MessageCircle, Eye, Calendar, User } from 'lucide-react-native';
import Badge from '../atoms/Badge';
import CaseHeaderMolecule from '../molecules/CaseHeaderMolecule';
import { useNavigation } from '@react-navigation/native';

interface ImprovedCaseCardProps {
  id: string;
  title: string;
  description: string;
  status: 'active' | 'pending' | 'completed' | 'summary_generated';
  priority: 'low' | 'medium' | 'high';
  clientType: 'PF' | 'PJ';
  createdAt: string;
  nextStep: string;
  hasAiSummary?: boolean;
  summarySharedAt?: string;
  unreadMessages?: number;
  lawyer?: {
    name: string;
    avatar?: string;
    specialty?: string;
  };
  onPress?: () => void;
  onViewSummary?: () => void;
  onChat?: () => void;
}

export default function ImprovedCaseCard({
  id,
  title,
  description,
  status,
  priority,
  clientType,
  createdAt,
  nextStep,
  hasAiSummary = false,
  summarySharedAt,
  unreadMessages = 0,
  lawyer,
  onPress,
  onViewSummary,
  onChat
}: ImprovedCaseCardProps) {
  const navigation = useNavigation<any>();

  const handlePress = () => {
    navigation.navigate('CaseDetail', { caseId: id });
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

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  return (
    <TouchableOpacity style={styles.card} activeOpacity={0.9} onPress={handlePress}>
      <CaseHeaderMolecule
        titulo={title}
        urgencia={priority === 'high' ? 'alta' : priority === 'medium' ? 'media' : 'baixa'}
        status={getStatusText()}
      />

      <Text style={styles.description} numberOfLines={2}>
        {description}
      </Text>

      {/* Meta Info */}
      <View style={styles.metaContainer}>
        {lawyer && (
          <View style={styles.metaRow}>
            <User size={14} color="#64748B" />
            <Text style={styles.metaText}>{lawyer.name}</Text>
            {unreadMessages > 0 && (
              <View style={styles.badge}>
                <Text style={styles.badgeText}>{unreadMessages}</Text>
              </View>
            )}
          </View>
        )}
        
        <View style={styles.metaRow}>
          <Calendar size={14} color="#64748B" />
          <Text style={styles.metaText}>Início: {formatDate(createdAt)}</Text>
        </View>
      </View>

      {/* Next Step */}
      {nextStep && (
        <View style={styles.nextStepContainer}>
          <Badge intent="info" outline>
            Próximo passo
          </Badge>
          <Text style={styles.nextStepText}>{nextStep}</Text>
        </View>
      )}

      {/* Actions */}
      <View style={styles.actionsContainer}>
        {hasAiSummary && (
          <TouchableOpacity style={styles.actionButton} onPress={onViewSummary}>
            <Eye size={16} color="#3B82F6" />
            <Text style={styles.actionText}>Ver Resumo IA</Text>
          </TouchableOpacity>
        )}
        
        {onChat && lawyer && (
          <TouchableOpacity style={styles.actionButton} onPress={onChat}>
            <MessageCircle size={16} color="#3B82F6" />
            <Text style={styles.actionText}>Chat</Text>
          </TouchableOpacity>
        )}
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    borderWidth: 1,
    borderColor: '#F1F5F9',
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    gap: 12,
  },
  description: {
    fontSize: 14,
    color: '#64748B',
    lineHeight: 20,
  },
  metaContainer: {
    gap: 8,
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  metaText: {
    fontSize: 13,
    color: '#64748B',
    flex: 1,
  },
  badge: {
    backgroundColor: '#EF4444',
    borderRadius: 10,
    paddingHorizontal: 6,
    paddingVertical: 2,
    minWidth: 20,
    alignItems: 'center',
  },
  badgeText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '700',
  },
  nextStepContainer: {
    backgroundColor: '#F8FAFC',
    padding: 12,
    borderRadius: 8,
    borderLeftWidth: 3,
    borderLeftColor: '#3B82F6',
    gap: 6,
  },
  nextStepText: {
    fontSize: 14,
    color: '#1E293B',
    lineHeight: 20,
  },
  actionsContainer: {
    flexDirection: 'row',
    gap: 12,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: '#F0F9FF',
    borderRadius: 8,
    flex: 1,
    justifyContent: 'center',
  },
  actionText: {
    fontSize: 13,
    color: '#3B82F6',
    fontWeight: '600',
  },
});
