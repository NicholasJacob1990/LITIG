import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ActivityIndicator } from 'react-native';
import { FileText, Edit3, CheckCircle } from 'lucide-react-native';

interface ServiceScopeCardProps {
  serviceScope?: string;
  definedAt?: string;
  lawyerName?: string;
  loading?: boolean;
  isLawyer?: boolean;
  onEdit?: () => void;
}

const ServiceScopeCard: React.FC<ServiceScopeCardProps> = ({
  serviceScope,
  definedAt,
  lawyerName,
  loading = false,
  isLawyer = false,
  onEdit,
}) => {
  const hasScope = serviceScope && serviceScope.trim().length > 0;

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (loading) {
    return (
      <View style={styles.container}>
        <Text style={styles.sectionTitle}>Escopo do Serviço</Text>
        <View style={styles.loadingCard}>
          <ActivityIndicator size="small" color="#3B82F6" />
          <Text style={styles.loadingText}>Carregando escopo do serviço...</Text>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.sectionTitle}>Escopo do Serviço</Text>
        {isLawyer && onEdit && (
          <TouchableOpacity style={styles.editButton} onPress={onEdit}>
            <Edit3 size={16} color="#3B82F6" />
            <Text style={styles.editButtonText}>
              {hasScope ? 'Editar' : 'Definir'}
            </Text>
          </TouchableOpacity>
        )}
      </View>

      <View style={styles.card}>
        {hasScope ? (
          <>
            <View style={styles.statusHeader}>
              <CheckCircle size={20} color="#10B981" />
              <Text style={styles.statusText}>Escopo Definido</Text>
            </View>
            
            <Text style={styles.scopeText}>{serviceScope}</Text>
            
            {definedAt && (
              <View style={styles.footer}>
                <Text style={styles.footerText}>
                  Definido em {formatDate(definedAt)}
                  {lawyerName && ` por ${lawyerName}`}
                </Text>
              </View>
            )}
          </>
        ) : (
          <View style={styles.emptyState}>
            <FileText size={48} color="#9CA3AF" />
            <Text style={styles.emptyTitle}>
              {isLawyer ? 'Defina o Escopo do Serviço' : 'Escopo Pendente'}
            </Text>
            <Text style={styles.emptyDescription}>
              {isLawyer 
                ? 'Após analisar o caso e conversar com o cliente, defina detalhadamente o escopo do serviço a ser prestado.'
                : 'O advogado responsável ainda não definiu o escopo detalhado do serviço. Aguarde ou entre em contato.'
              }
            </Text>
            {isLawyer && onEdit && (
              <TouchableOpacity style={styles.defineButton} onPress={onEdit}>
                <Text style={styles.defineButtonText}>Definir Escopo</Text>
              </TouchableOpacity>
            )}
          </View>
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
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1E293B',
  },
  editButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#EFF6FF',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
    gap: 4,
  },
  editButtonText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#3B82F6',
  },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  loadingCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 24,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
  },
  loadingText: {
    fontSize: 14,
    color: '#6B7280',
    marginTop: 8,
  },
  statusHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
    gap: 8,
  },
  statusText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#10B981',
  },
  scopeText: {
    fontSize: 14,
    color: '#374151',
    lineHeight: 20,
    marginBottom: 12,
  },
  footer: {
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
    paddingTop: 12,
  },
  footerText: {
    fontSize: 12,
    color: '#6B7280',
    fontStyle: 'italic',
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: 24,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#374151',
    marginTop: 12,
    marginBottom: 8,
    textAlign: 'center',
  },
  emptyDescription: {
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
    lineHeight: 20,
    marginBottom: 16,
  },
  defineButton: {
    backgroundColor: '#3B82F6',
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 8,
  },
  defineButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
  },
});

export default ServiceScopeCard; 