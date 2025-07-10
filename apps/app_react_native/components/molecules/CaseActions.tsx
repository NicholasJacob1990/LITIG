import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Alert, ActivityIndicator } from 'react-native';
import { Eye, MessageCircle, FileText, Calendar, MessageSquare, Video, Share2, Download } from 'lucide-react-native';
import { useNavigation } from 'expo-router';
import { useCase } from '@/lib/hooks/useCases';
import { downloadCaseReport } from '@/lib/services/reports';
import { useState } from 'react';

interface CaseActionsProps {
  onViewDetails?: () => void;
  onChat?: () => void;
  onViewSummary?: () => void;
  onSchedule?: () => void;
  variant?: 'compact' | 'full';
  showSummary?: boolean;
  showSchedule?: boolean;
}

export default function CaseActions({ 
  onViewDetails,
  onChat,
  onViewSummary,
  onSchedule,
  variant = 'compact',
  showSummary = false,
  showSchedule = false
}: CaseActionsProps) {
  const { data: caseData, isLoading } = useCase(caseId);
  const router = useNavigation();
  const [isDownloading, setIsDownloading] = useState(false);

  if (isLoading || !caseData) {
    return null;
  }

  const handleExport = async () => {
    if (isDownloading) return;

    setIsDownloading(true);
    try {
      await downloadCaseReport(caseId);
    } catch (error) {
      Alert.alert("Erro", "Não foi possível exportar o relatório. Tente novamente.");
    } finally {
      setIsDownloading(false);
    }
  };

  if (variant === 'compact') {
    return (
      <View style={styles.compactContainer}>
        {showSummary && (
          <TouchableOpacity 
            style={styles.summaryButton}
            onPress={onViewSummary}
          >
            <FileText size={14} color="#475569" />
            <Text style={styles.summaryButtonText}>Ver Resumo</Text>
          </TouchableOpacity>
        )}
        
        <TouchableOpacity 
          style={styles.detailsButton}
          onPress={onViewDetails}
        >
          <Eye size={16} color="#334155" />
          <Text style={styles.detailsButtonText}>Ver Detalhes</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={styles.fullContainer}>
      <TouchableOpacity style={styles.actionButton} onPress={onViewDetails}>
        <Eye size={20} color="#334155" />
        <Text style={styles.actionButtonText}>Ver Detalhes</Text>
      </TouchableOpacity>
      
      <TouchableOpacity style={styles.actionButton} onPress={onChat}>
        <MessageCircle size={20} color="#334155" />
        <Text style={styles.actionButtonText}>Chat</Text>
      </TouchableOpacity>
      
      {showSummary && (
        <TouchableOpacity style={styles.actionButton} onPress={onViewSummary}>
          <FileText size={20} color="#475569" />
          <Text style={styles.actionButtonText}>Resumo IA</Text>
        </TouchableOpacity>
      )}
      
      {showSchedule && (
        <TouchableOpacity style={styles.actionButton} onPress={onSchedule}>
          <Calendar size={20} color="#F5A623" />
          <Text style={styles.actionButtonText}>Agendar</Text>
        </TouchableOpacity>
      )}

      <TouchableOpacity
        style={styles.actionButton}
        onPress={() => router.push(`/pre-hiring-chat/${caseData.id}`)}
      >
        <MessageSquare size={20} color="#334155" />
        <Text style={styles.actionButtonText}>Chat</Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={styles.actionButton}
        onPress={() => console.log('Iniciar videochamada...')}
      >
        <Video size={20} color="#3B82F6" />
        <Text style={styles.actionButtonText}>Videochamada</Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={styles.actionButton}
        onPress={handleExport}
        disabled={isDownloading}
      >
        {isDownloading ? (
          <ActivityIndicator size="small" color="#10B981" />
        ) : (
          <Download size={20} color="#10B981" />
        )}
        <Text style={styles.actionButtonText}>Exportar PDF</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  compactContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 12,
  },
  fullContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  detailsButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#f1f5f9',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    gap: 4,
  },
  detailsButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
    color: '#334155',
  },
  summaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#e2e8f0',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    gap: 4,
  },
  summaryButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 11,
    color: '#475569',
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    gap: 8,
    minWidth: 120,
  },
  actionButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 14,
    color: '#374151',
  },
}); 