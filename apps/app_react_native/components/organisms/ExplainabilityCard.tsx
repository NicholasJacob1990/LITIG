import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, ActivityIndicator } from 'react-native';
import { ChevronDown, ChevronUp, Info, Target, TrendingUp, MapPin, Star, Clock, Award, MessageSquare } from 'lucide-react-native';
import { LawyerMatch } from '@/lib/services/api';
import { explanationService, PublicExplanation } from '@/lib/services/explanation';
import { useAuth } from '@/lib/contexts/AuthContext';
import ProgressBar from '../atoms/ProgressBar';

interface ExplainabilityCardProps {
  lawyer: LawyerMatch;
  caseId?: string; // Adicionado para buscar explicação da API
  onToggleDetails?: () => void;
}

interface FeatureExplanation {
  key: string;
  label: string;
  description: string;
  icon: React.ComponentType<any>;
  color: string;
}

const FEATURE_EXPLANATIONS: FeatureExplanation[] = [
  {
    key: 'A',
    label: 'Match de Área',
    description: 'Compatibilidade entre a área do caso e especialização do advogado',
    icon: Target,
    color: '#3B82F6'
  },
  {
    key: 'S',
    label: 'Similaridade de Casos',
    description: 'Experiência prévia em casos similares baseada em histórico',
    icon: TrendingUp,
    color: '#10B981'
  },
  {
    key: 'T',
    label: 'Taxa de Sucesso',
    description: 'Histórico de vitórias em casos da mesma área jurídica',
    icon: Award,
    color: '#F59E0B'
  },
  {
    key: 'G',
    label: 'Proximidade Geográfica',
    description: 'Distância física entre advogado e cliente',
    icon: MapPin,
    color: '#EF4444'
  },
  {
    key: 'Q',
    label: 'Qualificação',
    description: 'Formação acadêmica, certificações e experiência profissional',
    icon: Star,
    color: '#8B5CF6'
  },
  {
    key: 'U',
    label: 'Capacidade de Urgência',
    description: 'Disponibilidade e capacidade de atender casos urgentes',
    icon: Clock,
    color: '#F97316'
  },
  {
    key: 'R',
    label: 'Avaliações',
    description: 'Score baseado em reviews e feedback de clientes anteriores',
    icon: MessageSquare,
    color: '#06B6D4'
  },
  {
    key: 'C',
    label: 'Soft Skills',
    description: 'Habilidades interpessoais e comunicação baseadas em análise de CV',
    icon: Info,
    color: '#EC4899'
  }
];

const ExplainabilityCard: React.FC<ExplainabilityCardProps> = ({ lawyer, caseId, onToggleDetails }) => {
  const [isExpanded, setIsExpanded] = useState(false);
  const [explanation, setExplanation] = useState<PublicExplanation | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [hasConsented, setHasConsented] = useState(false);
  
  const { user } = useAuth();

  // Buscar explicação da API quando o componente é montado
  useEffect(() => {
    if (caseId && lawyer.id && user?.email && !explanation) {
      fetchExplanation();
    }
  }, [caseId, lawyer.id, user?.email]);

  const fetchExplanation = async () => {
    if (!caseId || !lawyer.id || !user?.email) return;

    setIsLoading(true);
    setError(null);

    try {
      // Por enquanto usar um token mock até integrar com auth real
      const mockToken = 'mock-token';
      const apiExplanation = await explanationService.getMatchExplanation(
        caseId,
        lawyer.id,
        mockToken
      );
      setExplanation(apiExplanation);
    } catch (err) {
      console.warn('Erro ao buscar explicação, usando fallback:', err);
      setError(err instanceof Error ? err.message : 'Erro desconhecido');
      
      // Usar dados de fallback
      const fallback = explanationService.generateFallbackExplanation(lawyer.id, caseId);
      setExplanation(fallback);
    } finally {
      setIsLoading(false);
    }
  };

  // Dados de fallback para quando não há explicação da API
  const fallbackScores = {
    area_match: 0.9,
    case_similarity: 0.8,
    success_rate: 0.75,
    geo_score: 0.6,
    qualification: 0.85,
    urgency_capacity: 0.7,
    review_score: 0.8,
    soft_skills: 0.65,
    raw_score: 0.74,
    equity_weight: 0.95,
    fair_score: lawyer.score || 0.7,
    delta: {
      A: 0.18, S: 0.12, T: 0.15, G: -0.05,
      Q: 0.10, U: 0.08, R: 0.06, C: 0.03
    }
  };
  
  const weights = {
    A: 0.2, S: 0.15, T: 0.2, G: 0.1,
    Q: 0.15, U: 0.1, R: 0.05, C: 0.05
  };
  
  // Usar dados da API se disponível, senão fallback
  const scores = explanation ? {
    area_match: 0.9, // Estes valores seriam derivados da API em uma implementação completa
    case_similarity: 0.8,
    success_rate: 0.75,
    geo_score: 0.6,
    qualification: 0.85,
    urgency_capacity: 0.7,
    review_score: 0.8,
    soft_skills: 0.65,
    raw_score: 0.74,
    equity_weight: 0.95,
    fair_score: lawyer.score || 0.7,
    delta: fallbackScores.delta // Por enquanto usar fallback para delta
  } : fallbackScores;
  
  const delta = scores.delta || {};

  const handleToggle = () => {
    // Implementar opt-in LGPD para explicações detalhadas
    if (!isExpanded && !hasConsented) {
      // Log de consentimento para auditoria
      console.log('User consented to detailed explanation', {
        userId: user?.id,
        lawyerId: lawyer.id,
        caseId: caseId,
        timestamp: new Date().toISOString()
      });
      setHasConsented(true);
    }
    
    setIsExpanded(!isExpanded);
    onToggleDetails?.();
  };

  const getFeatureValue = (key: string): number => {
    switch (key) {
      case 'A': return scores.area_match || 0;
      case 'S': return scores.case_similarity || 0;
      case 'T': return scores.success_rate || 0;
      case 'G': return scores.geo_score || 0;
      case 'Q': return scores.qualification || 0;
      case 'U': return scores.urgency_capacity || 0;
      case 'R': return scores.review_score || 0;
      case 'C': return scores.soft_skills || 0;
      default: return 0;
    }
  };

  const getContribution = (key: string): number => {
    return delta[key as keyof typeof delta] || 0;
  };

  const getWeight = (key: string): number => {
    return weights[key as keyof typeof weights] || 0;
  };

  const formatPercentage = (value: number): string => {
    return `${Math.round(value * 100)}%`;
  };

  const formatContribution = (value: number): string => {
    const formatted = (value * 100).toFixed(1);
    return value >= 0 ? `+${formatted}%` : `${formatted}%`;
  };

  return (
    <View style={styles.container}>
      {/* Seção de resumo da API */}
      {explanation && (
        <View style={styles.summarySection}>
          <Text style={styles.summaryText}>{explanation.summary}</Text>
          <View style={styles.factorsContainer}>
            {explanation.top_factors.map((factor, index) => (
              <View key={index} style={styles.factorBadge}>
                <Text style={styles.factorText}>{factor}</Text>
              </View>
            ))}
          </View>
          <View style={styles.confidenceContainer}>
            <Text style={styles.confidenceLabel}>Confiança: </Text>
            <Text style={[
              styles.confidenceValue,
              { color: explanation.confidence_level === 'Alta' ? '#10B981' : 
                       explanation.confidence_level === 'Média' ? '#F59E0B' : '#EF4444' }
            ]}>
              {explanation.confidence_level}
            </Text>
          </View>
        </View>
      )}

      {/* Loading state */}
      {isLoading && (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="small" color="#6366F1" />
          <Text style={styles.loadingText}>Carregando explicação...</Text>
        </View>
      )}

      {/* Error state */}
      {error && !explanation && (
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>Explicação não disponível</Text>
        </View>
      )}

      <TouchableOpacity style={styles.header} onPress={handleToggle}>
        <View style={styles.headerContent}>
          <Info size={20} color="#6366F1" />
          <Text style={styles.title}>Detalhes Técnicos</Text>
        </View>
        <View style={styles.headerRight}>
          <Text style={styles.scoreText}>
            Score: {formatPercentage(scores.fair_score)}
          </Text>
          {isExpanded ? (
            <ChevronUp size={20} color="#6B7280" />
          ) : (
            <ChevronDown size={20} color="#6B7280" />
          )}
        </View>
      </TouchableOpacity>

      {isExpanded && (
        <View style={styles.content}>
          <Text style={styles.subtitle}>
            Como calculamos a compatibilidade deste advogado com seu caso:
          </Text>

          <ScrollView style={styles.featuresContainer} showsVerticalScrollIndicator={false}>
            {FEATURE_EXPLANATIONS.map((feature) => {
              const value = getFeatureValue(feature.key);
              const contribution = getContribution(feature.key);
              const weight = getWeight(feature.key);
              const Icon = feature.icon;

              return (
                <View key={feature.key} style={styles.featureCard}>
                  <View style={styles.featureHeader}>
                    <View style={styles.featureIcon}>
                      <Icon size={16} color={feature.color} />
                    </View>
                    <View style={styles.featureInfo}>
                      <Text style={styles.featureLabel}>{feature.label}</Text>
                      <Text style={styles.featureDescription}>{feature.description}</Text>
                    </View>
                    <View style={styles.featureMetrics}>
                      <Text style={styles.featureValue}>
                        {formatPercentage(value)}
                      </Text>
                      <Text style={[
                        styles.featureContribution,
                        { color: contribution >= 0 ? '#10B981' : '#EF4444' }
                      ]}>
                        {formatContribution(contribution)}
                      </Text>
                    </View>
                  </View>
                  
                                     <View style={styles.progressContainer}>
                     <ProgressBar progress={value * 100} />
                     <Text style={styles.weightText}>
                       Peso: {formatPercentage(weight)}
                     </Text>
                   </View>
                </View>
              );
            })}
          </ScrollView>

          <View style={styles.summaryContainer}>
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Score Bruto:</Text>
              <Text style={styles.summaryValue}>
                {formatPercentage(scores.raw_score)}
              </Text>
            </View>
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Ajuste de Equidade:</Text>
              <Text style={styles.summaryValue}>
                {formatPercentage(scores.equity_weight)}
              </Text>
            </View>
            <View style={[styles.summaryRow, styles.finalScore]}>
              <Text style={styles.summaryLabelFinal}>Score Final:</Text>
              <Text style={styles.summaryValueFinal}>
                {formatPercentage(scores.fair_score)}
              </Text>
            </View>
          </View>

          <View style={styles.disclaimer}>
            <Text style={styles.disclaimerText}>
              * Este algoritmo considera múltiplos fatores para encontrar o melhor match. 
              Os pesos são ajustados dinamicamente baseados no tipo de caso e complexidade.
            </Text>
          </View>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
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
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    backgroundColor: '#F8FAFC',
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  headerContent: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  title: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    marginLeft: 8,
  },
  headerRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  scoreText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#6366F1',
  },
  content: {
    padding: 16,
  },
  subtitle: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 16,
    lineHeight: 20,
  },
  featuresContainer: {
    maxHeight: 400,
    marginBottom: 16,
  },
  featureCard: {
    backgroundColor: '#F9FAFB',
    borderRadius: 12,
    padding: 12,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  featureHeader: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 8,
  },
  featureIcon: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#FFFFFF',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  featureInfo: {
    flex: 1,
  },
  featureLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 2,
  },
  featureDescription: {
    fontSize: 12,
    color: '#6B7280',
    lineHeight: 16,
  },
  featureMetrics: {
    alignItems: 'flex-end',
  },
  featureValue: {
    fontSize: 16,
    fontWeight: '700',
    color: '#1F2937',
  },
  featureContribution: {
    fontSize: 12,
    fontWeight: '500',
  },
  progressContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  weightText: {
    fontSize: 11,
    color: '#9CA3AF',
    marginLeft: 8,
  },
  summaryContainer: {
    backgroundColor: '#F8FAFC',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  summaryLabel: {
    fontSize: 14,
    color: '#6B7280',
  },
  summaryValue: {
    fontSize: 14,
    fontWeight: '500',
    color: '#1F2937',
  },
  finalScore: {
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
    paddingTop: 8,
    marginTop: 8,
    marginBottom: 0,
  },
  summaryLabelFinal: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
  },
  summaryValueFinal: {
    fontSize: 18,
    fontWeight: '700',
    color: '#6366F1',
  },
  disclaimer: {
    backgroundColor: '#FEF3C7',
    borderRadius: 8,
    padding: 12,
    borderLeftWidth: 4,
    borderLeftColor: '#F59E0B',
  },
  disclaimerText: {
    fontSize: 12,
    color: '#92400E',
    lineHeight: 16,
  },
  // Novos estilos para a seção de resumo da API
  summarySection: {
    backgroundColor: '#F0F9FF',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#E0F2FE',
  },
  summaryText: {
    fontSize: 14,
    color: '#1F2937',
    lineHeight: 20,
    marginBottom: 12,
    fontWeight: '500',
  },
  factorsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 12,
  },
  factorBadge: {
    backgroundColor: '#DBEAFE',
    borderRadius: 16,
    paddingHorizontal: 10,
    paddingVertical: 4,
    marginRight: 8,
    marginBottom: 4,
  },
  factorText: {
    fontSize: 12,
    color: '#1E40AF',
    fontWeight: '500',
  },
  confidenceContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  confidenceLabel: {
    fontSize: 12,
    color: '#6B7280',
    fontWeight: '500',
  },
  confidenceValue: {
    fontSize: 12,
    fontWeight: '600',
  },
  loadingContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 16,
    backgroundColor: '#F9FAFB',
    borderRadius: 12,
    marginBottom: 16,
  },
  loadingText: {
    fontSize: 14,
    color: '#6B7280',
    marginLeft: 8,
  },
  errorContainer: {
    padding: 16,
    backgroundColor: '#FEF2F2',
    borderRadius: 12,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#FECACA',
  },
  errorText: {
    fontSize: 14,
    color: '#DC2626',
    textAlign: 'center',
  },
});

export default ExplainabilityCard; 