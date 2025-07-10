import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { 
  User, 
  Calendar, 
  Clock, 
  AlertTriangle, 
  FileText, 
  DollarSign,
  Eye,
  MessageCircle,
  ChevronDown,
  ChevronUp,
  Star,
  Shield,
  Briefcase,
  MapPin,
  Phone,
  Mail
} from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';
import Badge from '../atoms/Badge';
import ProgressBar from '../atoms/ProgressBar';
import MoneyTile from '../atoms/MoneyTile';
import CostEstimate from '../molecules/CostEstimate';
import { useNavigation } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';

interface Document {
  id: string;
  name: string;
  size: number;
  uploadedAt: string;
  type: string;
}

interface LawyerInfo {
  id: string;
  name: string;
  avatar?: string;
  specialty: string;
  oab: string;
  rating: number;
  experience_years: number;
  success_rate: number;
  phone?: string;
  email?: string;
  location?: string;
}

interface DetailedCaseCardProps {
  id: string;
  title: string;
  description: string;
  area: string;
  subarea: string;
  status: 'active' | 'pending' | 'completed' | 'summary_generated';
  priority: 'low' | 'medium' | 'high';
  urgencyHours: number;
  riskLevel: 'low' | 'medium' | 'high';
  confidenceScore: number;
  estimatedCost: number;
  createdAt: string;
  updatedAt: string;
  nextStep: string;
  // Estrutura de honorários
  consultationFee: number;
  representationFee: number;
  feeType: 'fixed' | 'success' | 'hourly' | 'plan' | 'mixed';
  successPercentage?: number;
  hourlyRate?: number;
  planType?: string;
  paymentTerms?: string;
  lawyer?: LawyerInfo;
  documents?: Document[];
  unreadMessages?: number;
  onPress?: () => void;
  onViewSummary?: () => void;
  onChat?: () => void;
  onViewDocuments?: () => void;
  onContactLawyer?: () => void;
}

export default function DetailedCaseCard({
  id,
  title,
  description,
  area,
  subarea,
  status,
  priority,
  urgencyHours,
  riskLevel,
  confidenceScore,
  estimatedCost,
  createdAt,
  updatedAt,
  nextStep,
  consultationFee,
  representationFee,
  feeType,
  successPercentage,
  hourlyRate,
  planType,
  paymentTerms,
  lawyer,
  documents = [],
  unreadMessages = 0,
  onPress,
  onViewSummary,
  onChat,
  onViewDocuments,
  onContactLawyer
}: DetailedCaseCardProps) {
  const navigation = useNavigation<any>();
  const [isExpanded, setIsExpanded] = useState(false);

  // Funções auxiliares
  const getStatusBadgeIntent = () => {
    switch (status) {
      case 'active': return 'primary';
      case 'completed': return 'success';
      case 'pending': return 'warning';
      case 'summary_generated': return 'info';
      default: return 'neutral';
    }
  };

  const getStatusText = () => {
    switch (status) {
      case 'active': return 'Em Andamento';
      case 'completed': return 'Concluído';
      case 'pending': return 'Aguardando';
      case 'summary_generated': return 'Pré-análise Pronta';
      default: return 'Desconhecido';
    }
  };

  const getPriorityColor = () => {
    switch (priority) {
      case 'high': return '#EF4444';
      case 'medium': return '#F59E0B';
      case 'low': return '#10B981';
      default: return '#6B7280';
    }
  };

  const getRiskBadgeIntent = () => {
    switch (riskLevel) {
      case 'low': return 'success';
      case 'medium': return 'warning';
      case 'high': return 'danger';
      default: return 'neutral';
    }
  };

  const getRiskText = () => {
    switch (riskLevel) {
      case 'low': return 'Risco Baixo';
      case 'medium': return 'Risco Médio';
      case 'high': return 'Risco Alto';
      default: return 'Risco Indefinido';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const getUrgencyText = () => {
    if (urgencyHours <= 24) return 'Urgente';
    if (urgencyHours <= 72) return 'Moderada';
    return 'Normal';
  };

  const getUrgencyColor = () => {
    if (urgencyHours <= 24) return '#EF4444';
    if (urgencyHours <= 72) return '#F59E0B';
    return '#10B981';
  };

  const handleVerCasoCompleto = () => {
    if (onPress) {
      onPress();
    } else {
      navigation.navigate('CaseDetail', { caseId: id });
    }
  };

  const handleVerResumoIA = () => {
    navigation.navigate('AISummary', { caseId: id });
  };

  const handleChat = () => {
    navigation.navigate('CaseChat', { caseId: id });
  };

  return (
    <View style={styles.card}>
      {/* Header com Gradiente */}
      <LinearGradient
        colors={[getPriorityColor(), getPriorityColor() + '80']}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 0 }}
        style={styles.headerGradient}
      >
        <View style={styles.headerContent}>
          <View style={styles.headerLeft}>
            <Text style={styles.title}>{title}</Text>
            <Text style={styles.areaText}>{area} • {subarea}</Text>
          </View>
          <View style={styles.headerRight}>
            <Badge 
              label={getStatusText()} 
              intent={getStatusBadgeIntent()} 
              size="small" 
            />
            {unreadMessages > 0 && (
              <View style={styles.messagesBadge}>
                <Text style={styles.messagesText}>{unreadMessages}</Text>
              </View>
            )}
          </View>
        </View>
      </LinearGradient>

      {/* Descrição */}
      <View style={styles.descriptionContainer}>
        <Text style={styles.description} numberOfLines={isExpanded ? undefined : 2}>
          {description}
        </Text>
      </View>

      {/* Métricas Principais */}
      <View style={styles.metricsContainer}>
        {/* Urgência */}
        <View style={styles.metricItem}>
          <View style={styles.metricHeader}>
            <Clock size={16} color={getUrgencyColor()} />
            <Text style={styles.metricLabel}>Urgência</Text>
          </View>
          <Text style={[styles.metricValue, { color: getUrgencyColor() }]}>
            {getUrgencyText()}
          </Text>
          <Text style={styles.metricSubtext}>{urgencyHours}h</Text>
        </View>

        {/* Risco */}
        <View style={styles.metricItem}>
          <View style={styles.metricHeader}>
            <AlertTriangle size={16} color="#F59E0B" />
            <Text style={styles.metricLabel}>Risco</Text>
          </View>
          <Badge 
            label={getRiskText()}
            intent={getRiskBadgeIntent()}
            size="small"
          />
        </View>

        {/* Confiança IA */}
        <View style={styles.metricItem}>
          <View style={styles.metricHeader}>
            <Star size={16} color="#FFD700" />
            <Text style={styles.metricLabel}>Confiança IA</Text>
          </View>
          <Text style={styles.metricValue}>{confidenceScore}%</Text>
          <ProgressBar 
            value={confidenceScore}
          />
        </View>
      </View>

      {/* Informações do Advogado */}
      {lawyer && (
        <View style={styles.lawyerContainer}>
          <View style={styles.lawyerHeader}>
            <View style={styles.lawyerInfo}>
              <User size={18} color="#3B82F6" />
              <View style={styles.lawyerDetails}>
                <Text style={styles.lawyerName}>{lawyer.name}</Text>
                <Text style={styles.lawyerSpecialty}>{lawyer.specialty}</Text>
                <Text style={styles.lawyerOab}>OAB: {lawyer.oab}</Text>
              </View>
            </View>
            <View style={styles.lawyerStats}>
              <View style={styles.statItem}>
                <Star size={12} color="#FFD700" />
                <Text style={styles.statText}>{lawyer.rating.toFixed(1)}</Text>
              </View>
              <View style={styles.statItem}>
                <Shield size={12} color="#10B981" />
                <Text style={styles.statText}>{lawyer.success_rate}%</Text>
              </View>
              <View style={styles.statItem}>
                <Briefcase size={12} color="#6B7280" />
                <Text style={styles.statText}>{lawyer.experience_years}a</Text>
              </View>
            </View>
          </View>
          
          {isExpanded && lawyer.location && (
            <View style={styles.lawyerContact}>
              <View style={styles.contactItem}>
                <MapPin size={14} color="#6B7280" />
                <Text style={styles.contactText}>{lawyer.location}</Text>
              </View>
              {lawyer.phone && (
                <View style={styles.contactItem}>
                  <Phone size={14} color="#6B7280" />
                  <Text style={styles.contactText}>{lawyer.phone}</Text>
                </View>
              )}
              {lawyer.email && (
                <View style={styles.contactItem}>
                  <Mail size={14} color="#6B7280" />
                  <Text style={styles.contactText}>{lawyer.email}</Text>
                </View>
              )}
            </View>
          )}
        </View>
      )}

      {/* Estimativa de Custos */}
      <CostEstimate
        consultationFee={consultationFee}
        representationFee={representationFee}
        feeType={feeType}
        successPercentage={successPercentage}
        hourlyRate={hourlyRate}
        planType={planType}
        paymentTerms={paymentTerms}
      />

      {/* Documentos */}
      {documents.length > 0 && (
        <View style={styles.documentsContainer}>
          <View style={styles.documentsHeader}>
            <FileText size={16} color="#3B82F6" />
            <Text style={styles.documentsTitle}>
              Documentos ({documents.length})
            </Text>
          </View>
          {isExpanded ? (
            <View style={styles.documentsList}>
              {documents.slice(0, 3).map((doc) => (
                <View key={doc.id} style={styles.documentItem}>
                  <View style={styles.documentInfo}>
                    <Text style={styles.documentName}>{doc.name}</Text>
                    <Text style={styles.documentSize}>{formatFileSize(doc.size)}</Text>
                  </View>
                  <Text style={styles.documentDate}>
                    {formatDate(doc.uploadedAt)}
                  </Text>
                </View>
              ))}
              {documents.length > 3 && (
                <TouchableOpacity onPress={onViewDocuments}>
                  <Text style={styles.viewAllDocs}>
                    Ver todos os {documents.length} documentos
                  </Text>
                </TouchableOpacity>
              )}
            </View>
          ) : (
            <TouchableOpacity onPress={onViewDocuments}>
              <Text style={styles.viewDocsButton}>Ver documentos</Text>
            </TouchableOpacity>
          )}
        </View>
      )}

      {/* Próximos Passos */}
      <View style={styles.nextStepContainer}>
        <Badge label="Próximo Passo" intent="info" size="small" />
        <Text style={styles.nextStepText}>{nextStep}</Text>
      </View>

      {/* Datas */}
      <View style={styles.datesContainer}>
        <View style={styles.dateItem}>
          <Calendar size={14} color="#6B7280" />
          <Text style={styles.dateText}>Criado: {formatDate(createdAt)}</Text>
        </View>
        <View style={styles.dateItem}>
          <Clock size={14} color="#6B7280" />
          <Text style={styles.dateText}>Atualizado: {formatDate(updatedAt)}</Text>
        </View>
      </View>

      {/* Ações */}
      <View style={styles.actionsContainer}>
        <TouchableOpacity style={styles.expandButton} onPress={() => setIsExpanded(!isExpanded)}>
          {isExpanded ? (
            <ChevronUp size={16} color="#3B82F6" />
          ) : (
            <ChevronDown size={16} color="#3B82F6" />
          )}
          <Text style={styles.expandText}>
            {isExpanded ? 'Menos detalhes' : 'Mais detalhes'}
          </Text>
        </TouchableOpacity>

        <View style={styles.actionButtons}>
          {onViewSummary && (
            <TouchableOpacity style={styles.actionButton} onPress={handleVerResumoIA}>
              <Ionicons name="bulb-outline" size={16} color="#fff" />
              <Text style={styles.actionText}>Ver Resumo IA</Text>
            </TouchableOpacity>
          )}
          
          {onChat && lawyer && (
            <TouchableOpacity style={styles.actionButton} onPress={handleChat}>
              <Ionicons name="chatbubble-outline" size={16} color="#3B82F6" />
              <Text style={styles.actionText}>Chat</Text>
            </TouchableOpacity>
          )}
          
          <TouchableOpacity style={styles.primaryActionButton} onPress={handleVerCasoCompleto}>
            <Ionicons name="eye-outline" size={16} color="#fff" />
            <Text style={styles.primaryActionText}>Ver Caso Completo</Text>
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
    overflow: 'hidden',
  },
  headerGradient: {
    padding: 20,
  },
  headerContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
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
    fontSize: 18,
    fontWeight: '700',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  areaText: {
    fontSize: 14,
    color: '#FFFFFF',
    opacity: 0.9,
  },
  messagesBadge: {
    backgroundColor: '#EF4444',
    borderRadius: 10,
    paddingHorizontal: 6,
    paddingVertical: 2,
    minWidth: 20,
    alignItems: 'center',
  },
  messagesText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '700',
  },
  descriptionContainer: {
    padding: 20,
    paddingBottom: 0,
  },
  description: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
  },
  metricsContainer: {
    flexDirection: 'row',
    padding: 20,
    paddingTop: 16,
    gap: 16,
  },
  metricItem: {
    flex: 1,
    alignItems: 'center',
  },
  metricHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginBottom: 4,
  },
  metricLabel: {
    fontSize: 12,
    color: '#6B7280',
    fontWeight: '500',
  },
  metricValue: {
    fontSize: 14,
    fontWeight: '700',
    color: '#1F2937',
    marginBottom: 2,
  },
  metricSubtext: {
    fontSize: 11,
    color: '#9CA3AF',
  },
  lawyerContainer: {
    paddingHorizontal: 20,
    paddingBottom: 16,
  },
  lawyerHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  lawyerInfo: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
    flex: 1,
  },
  lawyerDetails: {
    flex: 1,
  },
  lawyerName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
  },
  lawyerSpecialty: {
    fontSize: 14,
    color: '#6B7280',
    marginTop: 2,
  },
  lawyerOab: {
    fontSize: 12,
    color: '#9CA3AF',
    marginTop: 2,
  },
  lawyerStats: {
    flexDirection: 'row',
    gap: 8,
  },
  statItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  statText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#4B5563',
  },
  lawyerContact: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
  },
  contactItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 4,
  },
  contactText: {
    fontSize: 13,
    color: '#6B7280',
  },
  costContainer: {
    paddingHorizontal: 20,
    paddingBottom: 16,
  },
  documentsContainer: {
    paddingHorizontal: 20,
    paddingBottom: 16,
  },
  documentsHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 8,
  },
  documentsTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
  },
  documentsList: {
    gap: 8,
  },
  documentItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    paddingHorizontal: 12,
    backgroundColor: '#F9FAFB',
    borderRadius: 8,
  },
  documentInfo: {
    flex: 1,
  },
  documentName: {
    fontSize: 13,
    fontWeight: '500',
    color: '#1F2937',
  },
  documentSize: {
    fontSize: 11,
    color: '#6B7280',
    marginTop: 2,
  },
  documentDate: {
    fontSize: 11,
    color: '#9CA3AF',
  },
  viewAllDocs: {
    fontSize: 13,
    color: '#3B82F6',
    fontWeight: '500',
    textAlign: 'center',
    paddingVertical: 8,
  },
  viewDocsButton: {
    fontSize: 13,
    color: '#3B82F6',
    fontWeight: '500',
  },
  nextStepContainer: {
    paddingHorizontal: 20,
    paddingBottom: 16,
    gap: 8,
  },
  nextStepText: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
  },
  datesContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingBottom: 16,
  },
  dateItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  dateText: {
    fontSize: 12,
    color: '#6B7280',
  },
  actionsContainer: {
    paddingHorizontal: 20,
    paddingBottom: 20,
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
    paddingTop: 16,
  },
  expandButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    paddingVertical: 8,
    marginBottom: 12,
  },
  expandText: {
    fontSize: 13,
    color: '#3B82F6',
    fontWeight: '500',
  },
  actionButtons: {
    flexDirection: 'row',
    gap: 8,
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
    fontWeight: '500',
  },
  primaryActionButton: {
    backgroundColor: '#3B82F6',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 8,
    flex: 2,
    alignItems: 'center',
  },
  primaryActionText: {
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: '600',
  },
});
