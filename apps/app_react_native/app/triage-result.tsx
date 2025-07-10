import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  SafeAreaView,
  Dimensions,
  Animated
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { 
  ArrowLeft, 
  CheckCircle, 
  Clock, 
  AlertCircle, 
  Brain,
  Zap,
  Target,
  FileText,
  Users,
  TrendingUp,
  Shield,
  DollarSign,
  Calendar,
  MapPin
} from 'lucide-react-native';
import { LinearGradient } from 'expo-linear-gradient';

import { TriageResultResponse } from '@/lib/services/intelligentTriage';

const { width } = Dimensions.get('window');

export default function TriageResultScreen() {
  const router = useRouter();
  const params = useLocalSearchParams();
  const [result, setResult] = useState<TriageResultResponse | null>(null);
  const [fadeAnim] = useState(new Animated.Value(0));
  const [slideAnim] = useState(new Animated.Value(30));

  useEffect(() => {
    if (params.result) {
      try {
        const parsedResult = JSON.parse(params.result as string);
        setResult(parsedResult);
      } catch (error) {
        console.error('Erro ao parsear resultado:', error);
        Alert.alert('Erro', 'Não foi possível carregar o resultado da triagem.');
      }
    }
  }, [params.result]);

  useEffect(() => {
    if (result) {
      Animated.parallel([
        Animated.timing(fadeAnim, {
          toValue: 1,
          duration: 800,
          useNativeDriver: true,
        }),
        Animated.timing(slideAnim, {
          toValue: 0,
          duration: 600,
          useNativeDriver: true,
        }),
      ]).start();
    }
  }, [result]);

  if (!result) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.loadingContainer}>
          <Text style={styles.loadingText}>Carregando resultado...</Text>
        </View>
      </SafeAreaView>
    );
  }

  const getComplexityColor = (complexity: string) => {
    switch (complexity) {
      case 'low': return '#10B981';
      case 'medium': return '#F59E0B';
      case 'high': return '#EF4444';
      default: return '#6B7280';
    }
  };

  const getComplexityIcon = (complexity: string) => {
    switch (complexity) {
      case 'low': return CheckCircle;
      case 'medium': return Clock;
      case 'high': return AlertCircle;
      default: return Brain;
    }
  };

  const getStrategyInfo = (strategy: string) => {
    switch (strategy) {
      case 'simple':
        return {
          name: 'Análise Direta',
          description: 'Caso processado diretamente pela IA Entrevistadora',
          color: '#10B981',
          icon: Zap
        };
      case 'failover':
        return {
          name: 'Análise Padrão',
          description: 'Análise com estratégia de fallback inteligente',
          color: '#3B82F6',
          icon: Target
        };
      case 'ensemble':
        return {
          name: 'Análise Completa',
          description: 'Análise ensemble com múltiplas IAs e juiz',
          color: '#8B5CF6',
          icon: Brain
        };
      default:
        return {
          name: 'Análise Padrão',
          description: 'Estratégia não identificada',
          color: '#6B7280',
          icon: FileText
        };
    }
  };

  const ComplexityIcon = getComplexityIcon(result.complexity_level);
  const complexityColor = getComplexityColor(result.complexity_level);
  const strategyInfo = getStrategyInfo(result.strategy_used);
  const StrategyIcon = strategyInfo.icon;

  const renderHeader = () => (
    <LinearGradient
      colors={['#667eea', '#764ba2']}
      style={styles.header}
    >
      <TouchableOpacity 
        style={styles.backButton}
        onPress={() => router.back()}
      >
        <ArrowLeft size={24} color="#FFFFFF" />
      </TouchableOpacity>
      
      <View style={styles.headerContent}>
        <Text style={styles.headerTitle}>Resultado da Triagem</Text>
        <Text style={styles.headerSubtitle}>Análise Inteligente Concluída</Text>
      </View>
    </LinearGradient>
  );

  const renderSummaryCard = () => (
    <Animated.View 
      style={[
        styles.summaryCard,
        {
          opacity: fadeAnim,
          transform: [{ translateY: slideAnim }]
        }
      ]}
    >
      <View style={styles.summaryHeader}>
        <View style={styles.summaryIcon}>
          <ComplexityIcon size={24} color={complexityColor} />
        </View>
        <View style={styles.summaryInfo}>
          <Text style={styles.summaryTitle}>
            Complexidade: {result.complexity_level.toUpperCase()}
          </Text>
          <Text style={styles.summarySubtitle}>
            Confiança: {Math.round(result.confidence_score * 100)}%
          </Text>
        </View>
        <View style={styles.confidenceIndicator}>
          <View style={[styles.confidenceBar, { backgroundColor: complexityColor }]}>
            <View 
              style={[
                styles.confidenceFill,
                { width: `${result.confidence_score * 100}%` }
              ]}
            />
          </View>
        </View>
      </View>
      
      <View style={styles.strategyInfo}>
        <StrategyIcon size={20} color={strategyInfo.color} />
        <View style={styles.strategyText}>
          <Text style={styles.strategyName}>{strategyInfo.name}</Text>
          <Text style={styles.strategyDescription}>{strategyInfo.description}</Text>
        </View>
      </View>
    </Animated.View>
  );

  const renderTriageData = () => {
    const data = result.triage_data;
    
    return (
      <Animated.View 
        style={[
          styles.section,
          {
            opacity: fadeAnim,
            transform: [{ translateY: slideAnim }]
          }
        ]}
      >
        <Text style={styles.sectionTitle}>Dados da Análise</Text>
        
        <View style={styles.dataGrid}>
          <View style={styles.dataItem}>
            <FileText size={20} color="#3B82F6" />
            <Text style={styles.dataLabel}>Área Jurídica</Text>
            <Text style={styles.dataValue}>{data.area || 'Não identificado'}</Text>
          </View>
          
          <View style={styles.dataItem}>
            <Target size={20} color="#10B981" />
            <Text style={styles.dataLabel}>Subárea</Text>
            <Text style={styles.dataValue}>{data.subarea || 'Geral'}</Text>
          </View>
          
          <View style={styles.dataItem}>
            <Clock size={20} color="#F59E0B" />
            <Text style={styles.dataLabel}>Urgência</Text>
            <Text style={styles.dataValue}>{data.urgency_h || 72}h</Text>
          </View>
          
          <View style={styles.dataItem}>
            <TrendingUp size={20} color="#8B5CF6" />
            <Text style={styles.dataLabel}>Sentimento</Text>
            <Text style={styles.dataValue}>{data.sentiment || 'Neutro'}</Text>
          </View>
        </View>
        
        {data.summary && (
          <View style={styles.summarySection}>
            <Text style={styles.summaryLabel}>Resumo do Caso</Text>
            <Text style={styles.summaryText}>{data.summary}</Text>
          </View>
        )}
        
        {data.keywords && data.keywords.length > 0 && (
          <View style={styles.keywordsSection}>
            <Text style={styles.keywordsLabel}>Palavras-chave</Text>
            <View style={styles.keywordsList}>
              {data.keywords.map((keyword: string, index: number) => (
                <View key={index} style={styles.keywordTag}>
                  <Text style={styles.keywordText}>{keyword}</Text>
                </View>
              ))}
            </View>
          </View>
        )}
      </Animated.View>
    );
  };

  const renderAnalysisDetails = () => {
    if (!result.analysis_details) return null;

    return (
      <Animated.View 
        style={[
          styles.section,
          {
            opacity: fadeAnim,
            transform: [{ translateY: slideAnim }]
          }
        ]}
      >
        <Text style={styles.sectionTitle}>Detalhes da Análise</Text>
        
        <View style={styles.analysisCard}>
          <View style={styles.analysisHeader}>
            <Shield size={20} color="#3B82F6" />
            <Text style={styles.analysisTitle}>Processamento</Text>
          </View>
          
          <View style={styles.analysisDetails}>
            <Text style={styles.analysisLabel}>Tipo de Fluxo:</Text>
            <Text style={styles.analysisValue}>{result.flow_type}</Text>
          </View>
          
          <View style={styles.analysisDetails}>
            <Text style={styles.analysisLabel}>Tempo de Processamento:</Text>
            <Text style={styles.analysisValue}>{result.processing_time_ms}ms</Text>
          </View>
          
          {result.analysis_details.optimization && (
            <View style={styles.optimizationInfo}>
              <Text style={styles.optimizationText}>
                {result.analysis_details.optimization}
              </Text>
            </View>
          )}
        </View>
      </Animated.View>
    );
  };

  const renderActionButtons = () => (
    <Animated.View 
      style={[
        styles.actionSection,
        {
          opacity: fadeAnim,
          transform: [{ translateY: slideAnim }]
        }
      ]}
    >
      <TouchableOpacity
        style={styles.primaryButton}
        onPress={() => {
          router.push({
            pathname: '/MatchesPage',
            params: { 
              caseId: result.case_id,
              triageData: JSON.stringify(result.triage_data)
            }
          });
        }}
      >
        <Users size={20} color="#FFFFFF" />
        <Text style={styles.primaryButtonText}>Buscar Advogados</Text>
      </TouchableOpacity>
      
      <TouchableOpacity
        style={styles.secondaryButton}
        onPress={() => {
          // Implementar navegação para detalhes do caso
          router.push({
            pathname: '/case-details',
            params: { caseId: result.case_id }
          });
        }}
      >
        <FileText size={20} color="#667eea" />
        <Text style={styles.secondaryButtonText}>Ver Detalhes do Caso</Text>
      </TouchableOpacity>
    </Animated.View>
  );

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar style="light" />
      
      {renderHeader()}
      
      <ScrollView 
        style={styles.content}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.contentContainer}
      >
        {renderSummaryCard()}
        {renderTriageData()}
        {renderAnalysisDetails()}
        {renderActionButtons()}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    fontSize: 16,
    color: '#6B7280',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    paddingTop: 16,
  },
  backButton: {
    padding: 8,
  },
  headerContent: {
    flex: 1,
    marginLeft: 12,
  },
  headerTitle: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '600',
  },
  headerSubtitle: {
    color: '#E5E7EB',
    fontSize: 14,
    marginTop: 2,
  },
  content: {
    flex: 1,
  },
  contentContainer: {
    padding: 16,
  },
  summaryCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
  },
  summaryHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  summaryIcon: {
    marginRight: 12,
  },
  summaryInfo: {
    flex: 1,
  },
  summaryTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1F2937',
  },
  summarySubtitle: {
    fontSize: 14,
    color: '#6B7280',
    marginTop: 2,
  },
  confidenceIndicator: {
    width: 60,
  },
  confidenceBar: {
    height: 8,
    borderRadius: 4,
    backgroundColor: '#E5E7EB',
  },
  confidenceFill: {
    height: '100%',
    borderRadius: 4,
    backgroundColor: '#FFFFFF',
  },
  strategyInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingTop: 16,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
  },
  strategyText: {
    marginLeft: 12,
  },
  strategyName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
  },
  strategyDescription: {
    fontSize: 14,
    color: '#6B7280',
    marginTop: 2,
  },
  section: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 16,
  },
  dataGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginHorizontal: -8,
  },
  dataItem: {
    width: '50%',
    paddingHorizontal: 8,
    marginBottom: 16,
  },
  dataLabel: {
    fontSize: 12,
    color: '#6B7280',
    marginTop: 4,
    marginBottom: 2,
  },
  dataValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
  },
  summarySection: {
    marginTop: 16,
    paddingTop: 16,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
  },
  summaryLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 8,
  },
  summaryText: {
    fontSize: 14,
    color: '#4B5563',
    lineHeight: 20,
  },
  keywordsSection: {
    marginTop: 16,
    paddingTop: 16,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
  },
  keywordsLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 8,
  },
  keywordsList: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  keywordTag: {
    backgroundColor: '#F3F4F6',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    marginRight: 8,
    marginBottom: 8,
  },
  keywordText: {
    fontSize: 12,
    color: '#4B5563',
    fontWeight: '500',
  },
  analysisCard: {
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 12,
    padding: 16,
  },
  analysisHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  analysisTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    marginLeft: 8,
  },
  analysisDetails: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  analysisLabel: {
    fontSize: 14,
    color: '#6B7280',
  },
  analysisValue: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
  },
  optimizationInfo: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
  },
  optimizationText: {
    fontSize: 12,
    color: '#6B7280',
    fontStyle: 'italic',
  },
  actionSection: {
    marginTop: 8,
    marginBottom: 32,
  },
  primaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#667eea',
    paddingVertical: 16,
    paddingHorizontal: 24,
    borderRadius: 12,
    marginBottom: 12,
  },
  primaryButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 8,
  },
  secondaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FFFFFF',
    paddingVertical: 16,
    paddingHorizontal: 24,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#667eea',
  },
  secondaryButtonText: {
    color: '#667eea',
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 8,
  },
}); 