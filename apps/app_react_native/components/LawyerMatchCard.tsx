import React, { useState, useEffect } from 'react';
import { View, Text, Image, StyleSheet, TouchableOpacity, ActivityIndicator, Alert } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Star, MapPin, Clock, Award, MessageCircle, Video, Users, CheckCircle, ArrowRight, Sparkles, BrainCircuit } from 'lucide-react-native';
import { LawyerSearchResult } from '@/lib/supabase';
import { getExplanation , Match } from '@/lib/services/api';
import { Ionicons } from '@expo/vector-icons';
import ContractForm from './organisms/ContractForm';
import { explanationService, PublicExplanation } from '@/lib/services/explanation';

interface LawyerMatchCardProps {
  lawyer: LawyerSearchResult;
  matchData: Match;
  onSelect: () => void;
  caseId: string;
  caseTitle: string;
  onVideoCall?: () => void;
  onChat?: () => void;
  authToken?: string; // Token de autenticação para API
}

const LawyerMatchCard: React.FC<LawyerMatchCardProps> = ({ 
  lawyer, 
  matchData, 
  onSelect, 
  caseId, 
  caseTitle, 
  onVideoCall, 
  onChat,
  authToken 
}) => {
  const [isExpanded, setIsExpanded] = useState(false);
  const [showContractForm, setShowContractForm] = useState(false);
  const [explanation, setExplanation] = useState<PublicExplanation | null>(null);
  const [explanationLoading, setExplanationLoading] = useState(false);
  const [explanationError, setExplanationError] = useState<string | null>(null);

  // Buscar explicação quando o componente monta
  useEffect(() => {
    if (authToken && caseId && lawyer.id) {
      loadExplanation();
    }
  }, [authToken, caseId, lawyer.id]);

  const loadExplanation = async () => {
    if (!authToken) return;

    setExplanationLoading(true);
    setExplanationError(null);

    try {
      const result = await explanationService.getMatchExplanation(
        caseId,
        lawyer.id,
        authToken
      );
      setExplanation(result);
    } catch (error) {
      console.warn('Erro ao carregar explicação:', error);
      setExplanationError('Não foi possível carregar a explicação');
      
      // Usar fallback
      const fallback = explanationService.generateFallbackExplanation(lawyer.id, caseId);
      setExplanation(fallback);
    } finally {
      setExplanationLoading(false);
    }
  };

  const handleContractCreated = (contractId: string) => {
    Alert.alert(
      'Contrato Criado',
      'O contrato foi criado com sucesso. Você pode visualizá-lo na aba Contratos.',
      [
        {
          text: 'OK',
          onPress: () => {
            // Navegar para a tela de contratos ou detalhes do contrato
            // router.push(`/contract/${contractId}`);
          },
        },
      ]
    );
  };

  const scoreParecer = matchData.features?.score_par || 0;
  const simParecer = matchData.features?.sim_par || 0;
  const isAutoridade = scoreParecer > 0.5 || simParecer > 0.6;

  // Função para renderizar badges dinâmicos
  const renderDynamicBadges = () => {
    if (explanationLoading) {
      return (
        <View style={styles.badgeContainer}>
          <ActivityIndicator size="small" color="#3b82f6" />
          <Text style={styles.badgeLoadingText}>Analisando...</Text>
        </View>
      );
    }

    if (!explanation || !explanation.top_factors || explanation.top_factors.length === 0) {
      // Fallback para badge estático se não houver explicação
      if (isAutoridade) {
        return (
          <View style={styles.badgeContainer}>
            <Text style={styles.badgeText}>⚖️ Autoridade no Assunto</Text>
          </View>
        );
      }
      return null;
    }

    // Mostrar até 2 badges dos top_factors
    const topFactors = explanation.top_factors.slice(0, 2);
    
    return (
      <View style={styles.dynamicBadgesContainer}>
        {topFactors.map((factor, index) => (
          <View key={index} style={styles.dynamicBadge}>
            <Text style={styles.dynamicBadgeText}>{factor}</Text>
          </View>
        ))}
      </View>
    );
  };

  // Função para obter cor do badge baseado no nível de confiança
  const getConfidenceColor = (level: string) => {
    switch (level?.toLowerCase()) {
      case 'alta':
        return '#10b981'; // Verde
      case 'média':
        return '#f59e0b'; // Amarelo
      case 'baixa':
        return '#ef4444'; // Vermelho
      default:
        return '#6b7280'; // Cinza
    }
  };

  return (
    <>
      <TouchableOpacity onPress={onSelect} style={styles.card}>
        <LinearGradient
          colors={['#ffffff', '#f8fafc']}
          style={styles.gradient}
        >
          <View style={styles.header}>
            <View style={styles.profileSection}>
              <View style={styles.avatarContainer}>
                <Image
                  source={{ uri: lawyer.avatar_url || 'https://via.placeholder.com/60' }}
                  style={styles.avatar}
                />
                <View style={[styles.statusDot, { backgroundColor: '#10b981' }]} />
              </View>
              
              <View style={styles.basicInfo}>
                <Text style={styles.name}>{lawyer.name}</Text>
                <View style={styles.locationRow}>
                  <MapPin size={14} color="#6b7280" />
                  <Text style={styles.location}>{matchData.distance_km?.toFixed(1)} km</Text>
                </View>
                <View style={styles.specialtyRow}>
                  <Award size={14} color="#3b82f6" />
                  <Text style={styles.specialty}>{lawyer.primary_area || 'N/A'}</Text>
                </View>
              </View>
            </View>

            <View style={styles.scoreContainer}>
              <View style={[
                styles.scoreCircle,
                explanation && { borderColor: getConfidenceColor(explanation.confidence_level) }
              ]}>
                <Text style={styles.scoreNumber}>{Math.round((matchData.fair || 0) * 100)}</Text>
                <Text style={styles.scoreLabel}>%</Text>
              </View>
              <Text style={styles.scoreSubtext}>Compatibilidade</Text>
              {explanation && (
                <Text style={[
                  styles.confidenceText,
                  { color: getConfidenceColor(explanation.confidence_level) }
                ]}>
                  {explanation.confidence_level}
                </Text>
              )}
            </View>
          </View>

          {/* Badges dinâmicos */}
          {renderDynamicBadges()}

          <View style={styles.metricsRow}>
            <View style={styles.metric}>
              <View style={styles.metricIcon}>
                <Star size={16} color="#f59e0b" fill="#f59e0b" />
              </View>
              <View>
                <Text style={styles.metricValue}>{lawyer.rating?.toFixed(1) || 'N/A'}</Text>
                <Text style={styles.metricLabel}>Avaliação</Text>
              </View>
            </View>

            <View style={styles.metric}>
              <View style={styles.metricIcon}>
                <CheckCircle size={16} color="#10b981" />
              </View>
              <View>
                <Text style={styles.metricValue}>{Math.round((matchData.features?.T || 0) * 100)}%</Text>
                <Text style={styles.metricLabel}>Taxa de Êxito</Text>
              </View>
            </View>

            <View style={styles.metric}>
              <View style={styles.metricIcon}>
                <Clock size={16} color="#3b82f6" />
              </View>
              <View>
                <Text style={styles.metricValue}>{lawyer.response_time || 'N/A'}h</Text>
                <Text style={styles.metricLabel}>Resposta</Text>
              </View>
            </View>

            {matchData.features?.C !== undefined && (
              <View style={styles.metric}>
                <View style={styles.metricIcon}>
                  <BrainCircuit size={16} color="#ec4899" />
                </View>
                <View>
                  <Text style={styles.metricValue}>{Math.round(matchData.features.C * 100)}</Text>
                  <Text style={styles.metricLabel}>Soft Skills</Text>
                </View>
              </View>
            )}

            <View style={styles.metric}>
              <View style={styles.metricIcon}>
                <Users size={16} color="#8b5cf6" />
              </View>
              <View>
                <Text style={styles.metricValue}>{lawyer.review_count || 0}</Text>
                <Text style={styles.metricLabel}>Casos</Text>
              </View>
            </View>
          </View>

          <TouchableOpacity 
            style={styles.explainButton} 
            onPress={() => setIsExpanded(!isExpanded)}
          >
            <View style={styles.explainButtonContent}>
              <Sparkles size={16} color="#3b82f6" />
              <Text style={styles.explainButtonText}>
                {isExpanded ? 'Ocultar Análise' : 'Analisar Compatibilidade'}
              </Text>
              <ArrowRight size={16} color="#3b82f6" style={{ transform: [{ rotate: isExpanded ? '90deg' : '0deg' }] }} />
            </View>
          </TouchableOpacity>

          {isExpanded && (
            <View style={styles.explanationContainer}>
              {explanation && explanation.summary ? (
                <Text style={styles.explanationText}>{explanation.summary}</Text>
              ) : (
                <Text style={styles.explanationText}>
                  Análise de compatibilidade baseada em experiência, localização, taxa de sucesso e perfil do caso.
                </Text>
              )}
              {explanationError && (
                <Text style={styles.explanationError}>
                  {explanationError}
                </Text>
              )}
            </View>
          )}

          <View style={styles.actions}>
            <TouchableOpacity
              style={[styles.actionButton, styles.contractButton]}
              onPress={() => setShowContractForm(true)}
            >
              <Ionicons name="document-text-outline" size={16} color="#fff" />
              <Text style={styles.contractButtonText}>Contratar</Text>
            </TouchableOpacity>

            {onChat && (
              <TouchableOpacity
                style={[styles.actionButton, styles.chatButton]}
                onPress={onChat}
              >
                <Ionicons name="chatbubble-outline" size={16} color="#007bff" />
                <Text style={styles.chatButtonText}>Chat</Text>
              </TouchableOpacity>
            )}

            {onVideoCall && (
              <TouchableOpacity
                style={[styles.actionButton, styles.videoButton]}
                onPress={onVideoCall}
              >
                <Ionicons name="videocam-outline" size={16} color="#10b981" />
                <Text style={styles.videoButtonText}>Vídeo</Text>
              </TouchableOpacity>
            )}
          </View>
        </LinearGradient>
      </TouchableOpacity>

      <ContractForm
        visible={showContractForm}
        onClose={() => setShowContractForm(false)}
        caseId={caseId}
        lawyerId={lawyer.id}
        lawyerName={lawyer.name}
        caseTitle={caseTitle}
        onContractCreated={handleContractCreated}
      />
    </>
  );
};

const styles = StyleSheet.create({
  card: {
    marginBottom: 16,
    borderRadius: 16,
    overflow: 'hidden',
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
  },
  gradient: {
    padding: 20,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 20,
  },
  profileSection: {
    flexDirection: 'row',
    flex: 1,
  },
  avatarContainer: {
    position: 'relative',
    marginRight: 16,
  },
  avatar: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: '#e5e7eb',
  },
  statusDot: {
    position: 'absolute',
    bottom: 2,
    right: 2,
    width: 16,
    height: 16,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: '#ffffff',
  },
  basicInfo: {
    flex: 1,
    justifyContent: 'center',
  },
  name: {
    fontSize: 18,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 4,
  },
  locationRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  location: {
    fontSize: 14,
    color: '#6b7280',
    marginLeft: 6,
  },
  specialtyRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  specialty: {
    fontSize: 14,
    color: '#3b82f6',
    marginLeft: 6,
    fontWeight: '500',
  },
  scoreContainer: {
    alignItems: 'center',
  },
  scoreCircle: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: '#dbeafe',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 4,
    borderWidth: 2,
    borderColor: '#dbeafe',
  },
  scoreNumber: {
    fontSize: 20,
    fontWeight: '800',
    color: '#1d4ed8',
    lineHeight: 24,
  },
  scoreLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: '#3b82f6',
    lineHeight: 14,
  },
  scoreSubtext: {
    fontSize: 12,
    color: '#6b7280',
    textAlign: 'center',
  },
  confidenceText: {
    fontSize: 10,
    fontWeight: '600',
    marginTop: 2,
    textAlign: 'center',
  },
  // Badges dinâmicos
  dynamicBadgesContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 12,
    gap: 8,
  },
  dynamicBadge: {
    backgroundColor: '#e0f2fe',
    borderRadius: 12,
    paddingHorizontal: 8,
    paddingVertical: 4,
    alignSelf: 'flex-start',
  },
  dynamicBadgeText: {
    color: '#0369a1',
    fontWeight: '600',
    fontSize: 12,
  },
  // Badge de loading
  badgeContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    backgroundColor: '#f0f9ff',
    borderRadius: 12,
    paddingHorizontal: 8,
    paddingVertical: 4,
    marginBottom: 12,
  },
  badgeText: {
    color: '#0369a1',
    fontWeight: '600',
    fontSize: 12,
  },
  badgeLoadingText: {
    color: '#3b82f6',
    fontWeight: '500',
    fontSize: 12,
    marginLeft: 6,
  },
  metricsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 20,
    paddingHorizontal: 4,
  },
  metric: {
    alignItems: 'center',
    flex: 1,
  },
  metricIcon: {
    marginBottom: 8,
  },
  metricValue: {
    fontSize: 16,
    fontWeight: '700',
    color: '#111827',
    textAlign: 'center',
  },
  metricLabel: {
    fontSize: 12,
    color: '#6b7280',
    textAlign: 'center',
    marginTop: 2,
  },
  explainButton: {
    backgroundColor: '#f0f9ff',
    borderRadius: 12,
    padding: 12,
    marginBottom: 20,
  },
  explainButtonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  explainButtonText: {
    color: '#3b82f6',
    fontWeight: '600',
    marginLeft: 8,
    marginRight: 8,
  },
  explanationContainer: {
    backgroundColor: '#f8fafc',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
  },
  explanationText: {
    fontSize: 14,
    color: '#374151',
    lineHeight: 20,
  },
  explanationError: {
    fontSize: 12,
    color: '#ef4444',
    marginTop: 8,
    fontStyle: 'italic',
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 12,
    flex: 1,
  },
  contractButton: {
    backgroundColor: '#3b82f6',
  },
  contractButtonText: {
    color: '#ffffff',
    fontWeight: '600',
    marginLeft: 6,
  },
  chatButton: {
    backgroundColor: '#f0f9ff',
    borderWidth: 1,
    borderColor: '#007bff',
  },
  chatButtonText: {
    color: '#007bff',
    fontWeight: '600',
    marginLeft: 6,
  },
  videoButton: {
    backgroundColor: '#f0fdf4',
    borderWidth: 1,
    borderColor: '#10b981',
  },
  videoButtonText: {
    color: '#10b981',
    fontWeight: '600',
    marginLeft: 6,
  },
});

export default LawyerMatchCard;