import React, { useState } from 'react';
import { View, Text, Image, StyleSheet, TouchableOpacity, ActivityIndicator, Alert } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Star, MapPin, Clock, Award, MessageCircle, Video, Users, CheckCircle, ArrowRight, Sparkles, BrainCircuit } from 'lucide-react-native';
import { LawyerSearchResult } from '@/lib/supabase';
import { getExplanation , Match } from '@/lib/services/api';
import { Ionicons } from '@expo/vector-icons';
import ContractForm from './organisms/ContractForm';

interface LawyerMatchCardProps {
  lawyer: LawyerSearchResult;
  matchData: Match;
  onSelect: () => void;
  caseId: string;
  caseTitle: string;
  onVideoCall?: () => void;
  onChat?: () => void;
}

const LawyerMatchCard: React.FC<LawyerMatchCardProps> = ({ lawyer, matchData, onSelect, caseId, caseTitle, onVideoCall, onChat }) => {
  const [isExpanded, setIsExpanded] = useState(false);
  const [showContractForm, setShowContractForm] = useState(false);

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
              <View style={styles.scoreCircle}>
                <Text style={styles.scoreNumber}>{Math.round((matchData.fair || 0) * 100)}</Text>
                <Text style={styles.scoreLabel}>%</Text>
              </View>
              <Text style={styles.scoreSubtext}>Compatibilidade</Text>
            </View>
          </View>

          {isAutoridade && (
            <View style={styles.badgeContainer}>
              <Text style={styles.badgeText}>⚖️ Autoridade no Assunto</Text>
            </View>
          )}

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
              <Text style={styles.explanationText}>
                Análise de compatibilidade baseada em experiência, localização, taxa de sucesso e perfil do caso.
              </Text>
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
  metricsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 20,
    paddingHorizontal: 8,
  },
  metric: {
    alignItems: 'center',
    flex: 1,
  },
  metricIcon: {
    marginBottom: 6,
  },
  metricValue: {
    fontSize: 16,
    fontWeight: '700',
    color: '#111827',
    textAlign: 'center',
    lineHeight: 20,
  },
  metricLabel: {
    fontSize: 12,
    color: '#6b7280',
    textAlign: 'center',
    marginTop: 2,
  },
  explainButton: {
    backgroundColor: '#eff6ff',
    borderRadius: 12,
    padding: 12,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#dbeafe',
  },
  explainButtonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  explainButtonText: {
    fontSize: 14,
    color: '#1d4ed8',
    fontWeight: '600',
    marginHorizontal: 8,
  },
  explanationContainer: {
    backgroundColor: '#f0f9ff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    borderLeftWidth: 4,
    borderLeftColor: '#3b82f6',
  },
  explanationText: {
    fontSize: 14,
    color: '#374151',
    lineHeight: 20,
  },
  actions: {
    flexDirection: 'row',
    gap: 8,
  },
  actionButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 10,
    borderRadius: 8,
    gap: 4,
  },
  contractButton: {
    backgroundColor: '#007bff',
  },
  contractButtonText: {
    fontSize: 14,
    color: '#fff',
    fontWeight: '600',
  },
  chatButton: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#007bff',
  },
  chatButtonText: {
    fontSize: 14,
    color: '#007bff',
    fontWeight: '500',
  },
  videoButton: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#10b981',
  },
  videoButtonText: {
    fontSize: 14,
    color: '#10b981',
    fontWeight: '500',
  },
  badgeContainer: {
    alignSelf: 'flex-start',
    backgroundColor: '#E0F2FE',
    borderRadius: 12,
    paddingHorizontal: 8,
    paddingVertical: 4,
    marginBottom: 12,
  },
  badgeText: {
    color: '#0369A1',
    fontWeight: 'bold',
    fontSize: 12,
  },
  logosContainer: {
    marginTop: 16,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
  },
  logosTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: '#6B7280',
    marginBottom: 8,
  },
  logoRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  logo: {
    width: 80,
    height: 25,
    resizeMode: 'contain',
    marginRight: 12,
  }
});

export default LawyerMatchCard;