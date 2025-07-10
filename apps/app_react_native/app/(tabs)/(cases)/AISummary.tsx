import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
  RefreshControl
} from 'react-native';
import { useLocalSearchParams, useNavigation } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { Brain, CheckCircle, AlertTriangle, FileText, Share } from 'lucide-react-native';
import { getCaseById, getAIAnalysis } from '@/lib/services/cases';
import TopBar from '@/components/layout/TopBar';
import Badge from '@/components/atoms/Badge';
import ProgressBar from '@/components/atoms/ProgressBar';
import CaseActions from '@/components/molecules/CaseActions';

export default function AISummary() {
  const navigation = useNavigation<any>();
  const { caseId } = useLocalSearchParams<{ caseId: string }>();

  const [caseData, setCaseData] = useState<any>(null);
  const [aiAnalysis, setAiAnalysis] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    if (caseId) {
      loadData();
    }
  }, [caseId]);

  const loadData = async () => {
    try {
      setLoading(true);
      const [caseResult, analysisResult] = await Promise.all([
        getCaseById(caseId),
        getAIAnalysis(caseId)
      ]);
      
      setCaseData(caseResult);
      setAiAnalysis(analysisResult);
    } catch (error) {
      console.error('Error loading AI summary:', error);
      Alert.alert('Erro', 'Não foi possível carregar o resumo da IA');
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  };

  const handleShare = () => {
    Alert.alert('Compartilhar', 'Funcionalidade de compartilhamento em desenvolvimento');
  };

  const getRiskColor = (level: string) => {
    switch (level?.toLowerCase()) {
      case 'low':
        return '#10B981';
      case 'medium':
        return '#F59E0B';
      case 'high':
        return '#EF4444';
      default:
        return '#6B7280';
    }
  };

  const getRiskLabel = (level: string) => {
    switch (level?.toLowerCase()) {
      case 'low':
        return 'Baixo';
      case 'medium':
        return 'Médio';
      case 'high':
        return 'Alto';
      default:
        return 'Não avaliado';
    }
  };

  if (loading) {
    return (
      <View style={styles.container}>
        <StatusBar style="light" />
        <TopBar title="Resumo IA" showBack />
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#006CFF" />
          <Text style={styles.loadingText}>Carregando análise...</Text>
        </View>
      </View>
    );
  }

  if (!aiAnalysis) {
    return (
      <View style={styles.container}>
        <StatusBar style="light" />
        <TopBar title="Resumo IA" showBack />
        <View style={styles.emptyState}>
          <Brain size={48} color="#9CA3AF" />
          <Text style={styles.emptyStateTitle}>Análise não disponível</Text>
          <Text style={styles.emptyStateDescription}>
            A análise de IA ainda não foi gerada para este caso.
          </Text>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      
      <TopBar
        title="Resumo IA"
        subtitle={aiAnalysis.title || 'Análise do Caso'}
        showBack
        rightActions={[{ icon: Share, onPress: handleShare }]}
      />

      <ScrollView
        style={styles.content}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
        }
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.headerCard}>
          <View style={styles.headerIcon}>
            <Brain size={24} color="#006CFF" />
          </View>
          <View style={styles.headerInfo}>
            <Text style={styles.headerTitle}>Análise Inteligente</Text>
            <Text style={styles.headerSubtitle}>
              Gerada em {new Date(aiAnalysis.generated_at || Date.now()).toLocaleDateString('pt-BR')}
            </Text>
          </View>
          <Badge
            label={`${aiAnalysis.confidence || 85}%`}
            intent="success"
            size="small"
          />
        </View>

        {aiAnalysis.confidence && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Nível de Confiança</Text>
            <ProgressBar
              progress={aiAnalysis.confidence}
              color="#10B981"
              height={8}
              showPercentage
            />
            <Text style={styles.confidenceDescription}>
              {aiAnalysis.confidence >= 90 ? 'Análise muito confiável' :
               aiAnalysis.confidence >= 70 ? 'Análise confiável' :
               'Análise preliminar - recomenda-se consultoria especializada'}
            </Text>
          </View>
        )}

        <View style={styles.card}>
            <Text style={styles.cardTitle}>Pontos Principais</Text>
            <View style={styles.keyPointsList}>
              {aiAnalysis.key_points?.map((point: string, index: number) => (
                <View key={index} style={styles.keyPointItem}>
                  <CheckCircle size={16} color="#10B981" />
                  <Text style={styles.keyPointText}>{point}</Text>
                </View>
              ))}
            </View>
          </View>

        <View style={styles.card}>
            <Text style={styles.cardTitle}>Próximos Passos</Text>
            <View style={styles.stepsList}>
              {aiAnalysis.next_steps?.map((step: string, index: number) => (
                <View key={index} style={styles.stepItem}>
                  <View style={styles.stepNumber}>
                    <Text style={styles.stepNumberText}>{index + 1}</Text>
                  </View>
                  <Text style={styles.stepText}>{step}</Text>
                </View>
              ))}
            </View>
          </View>
        
        <View style={styles.actionsContainer}>
          <TouchableOpacity 
            style={styles.primaryButton}
            onPress={() => navigation.navigate('DetailedAnalysis', { caseId })}
          >
            <Brain size={20} color="#FFFFFF" />
            <Text style={styles.primaryButtonText}>Ver Análise Detalhada</Text>
          </TouchableOpacity>
          
          <CaseActions 
            onScheduleConsult={() => navigation.navigate('ScheduleConsult', { caseId, analysis: aiAnalysis })}
            onViewDocuments={() => navigation.navigate('CaseDocuments', { caseId })}
          />
        </View>

        <View style={styles.disclaimer}>
          <AlertTriangle size={16} color="#F59E0B" />
          <Text style={styles.disclaimerText}>
            Esta análise é gerada por inteligência artificial e tem caráter orientativo. 
            Para decisões jurídicas importantes, consulte sempre um advogado especializado.
          </Text>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  content: {
    flex: 1,
    paddingHorizontal: 20,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  loadingText: {
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#6B7280',
    marginTop: 16,
  },
  emptyState: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
  },
  emptyStateTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1F2937',
    marginTop: 16,
    marginBottom: 8,
  },
  emptyStateDescription: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
    textAlign: 'center',
    lineHeight: 20,
  },
  headerCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    marginVertical: 12,
    flexDirection: 'row',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  headerIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#F0F9FF',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 16,
  },
  headerInfo: {
    flex: 1,
  },
  headerTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1F2937',
    marginBottom: 4,
  },
  headerSubtitle: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
  },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    marginVertical: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  cardTitle: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
    color: '#1F2937',
    marginBottom: 16,
  },
  confidenceDescription: {
    fontFamily: 'Inter-Regular',
    fontSize: 14,
    color: '#6B7280',
    marginTop: 8,
  },
  keyPointsList: {
    gap: 12,
  },
  keyPointItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
  },
  keyPointText: {
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#1F2937',
    flex: 1,
    lineHeight: 22,
  },
  stepsList: {
    gap: 16,
  },
  stepItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
  },
  stepNumber: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#006CFF',
    alignItems: 'center',
    justifyContent: 'center',
  },
  stepNumberText: {
    fontFamily: 'Inter-Bold',
    fontSize: 12,
    color: '#FFFFFF',
  },
  stepText: {
    fontFamily: 'Inter-Regular',
    fontSize: 16,
    color: '#1F2937',
    flex: 1,
    lineHeight: 22,
  },
  actionsContainer: {
    gap: 12,
    marginVertical: 20,
  },
  primaryButton: {
    backgroundColor: '#006CFF',
    borderRadius: 12,
    paddingVertical: 16,
    paddingHorizontal: 24,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  primaryButtonText: {
    fontFamily: 'Inter-SemiBold',
    fontSize: 16,
    color: '#FFFFFF',
  },
  disclaimer: {
    backgroundColor: '#FEF3C7',
    borderRadius: 12,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
    marginBottom: 24,
  },
  disclaimerText: {
    fontFamily: 'Inter-Regular',
    fontSize: 12,
    color: '#92400E',
    flex: 1,
    lineHeight: 18,
  },
});