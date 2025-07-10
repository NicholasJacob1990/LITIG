import React from 'react';
import { View, Text, StyleSheet, Image, TouchableOpacity } from 'react-native';
import { Star, MapPin, Award, MessageCircle, Video, Users, ArrowRight, Quote } from 'lucide-react-native';
import { LawyerMatch } from '@/lib/services/api';
import { useRouter } from 'expo-router';
import ExplainabilityCard from './organisms/ExplainabilityCard';
import LawyerCurriculumCard from './organisms/LawyerCurriculumCard';

interface LawyerCardProps {
  lawyer: LawyerMatch;
  onPress: () => void;
  showExplainability?: boolean;
  showCurriculum?: boolean;
}

const LawyerCard: React.FC<LawyerCardProps> = ({ lawyer, onPress, showExplainability = false, showCurriculum = false }) => {
  const router = useRouter();

  const formatPrice = (price?: number) => {
    if (!price) return 'N/A';
    return price.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
  };

  const highlightReview = lawyer.review_texts && lawyer.review_texts.length > 0
    ? lawyer.review_texts[0]
    : null;

  return (
    <View>
      <TouchableOpacity style={styles.card} onPress={onPress} activeOpacity={0.9}>
        <View style={styles.cardHeader}>
          <View style={styles.avatarContainer}>
            <Image source={{ uri: lawyer.avatar_url }} style={styles.avatar} />
            {lawyer.is_available && <View style={styles.onlineIndicator} />}
          </View>
          <View style={styles.headerInfo}>
            <Text style={styles.name}>{lawyer.nome}</Text>
            <Text style={styles.oab}>{lawyer.oab_numero}</Text>
            {lawyer.expertise_areas && lawyer.expertise_areas.length > 0 && (
              <View style={styles.specialtyChip}>
                <Text style={styles.specialtyText}>{lawyer.expertise_areas[0]}</Text>
              </View>
            )}
          </View>
          <View style={styles.ratingBadge}>
            <Star size={12} color="#FFFFFF" />
            <Text style={styles.ratingText}>{lawyer.rating?.toFixed(1)}</Text>
          </View>
        </View>

      <View style={styles.statsRow}>
        <View style={styles.statItem}>
          <Star size={16} color="#F59E0B" fill="#F59E0B" />
          <Text style={styles.statValue}>{lawyer.rating?.toFixed(1)}</Text>
          <Text style={styles.statLabel}>({lawyer.review_count} reviews)</Text>
        </View>
        <View style={styles.statItem}>
          <MapPin size={16} color="#6B7280" />
          <Text style={styles.statValue}>{lawyer.distance_km?.toFixed(1)} km</Text>
        </View>
        <View style={styles.statItem}>
          <Award size={16} color="#1E40AF" />
          <Text style={styles.statValue}>{lawyer.experience} anos</Text>
        </View>
      </View>

      {highlightReview && (
        <View style={styles.reviewContainer}>
          <Quote size={14} color="#6B7280" style={styles.reviewQuoteIcon} />
          <Text style={styles.reviewText} numberOfLines={2}>
            {highlightReview}
          </Text>
        </View>
      )}

      <View style={styles.consultationRow}>
        {lawyer.consultation_types?.includes('chat') && (
          <View style={styles.consultationChip}>
            <MessageCircle size={14} color="#6B7280" />
            <Text style={styles.consultationText}>Chat</Text>
          </View>
        )}
        {lawyer.consultation_types?.includes('video') && (
          <View style={styles.consultationChip}>
            <Video size={14} color="#6B7280" />
            <Text style={styles.consultationText}>Vídeo</Text>
          </View>
        )}
        {lawyer.consultation_types?.includes('presential') && (
          <View style={styles.consultationChip}>
            <Users size={14} color="#6B7280" />
            <Text style={styles.consultationText}>Presencial</Text>
          </View>
        )}
      </View>
      
      <View style={styles.footer}>
        <View>
          <Text style={styles.priceLabel}>A partir de</Text>
          <Text style={styles.priceValue}>{formatPrice(lawyer.consultation_fee)}</Text>
        </View>
        <View style={styles.actionButtons}>
          {lawyer.consultation_types?.includes('chat') && (
            <TouchableOpacity style={styles.iconButton} activeOpacity={0.7}>
              <MessageCircle size={20} color="#006CFF" />
            </TouchableOpacity>
          )}
          {lawyer.consultation_types?.includes('video') && (
            <TouchableOpacity 
              style={styles.iconButton} 
              activeOpacity={0.7}
              onPress={() => {
                // Navegar para videochamada
                router.push({
                  pathname: '/(tabs)/video-consultation',
                  params: { 
                    lawyerId: lawyer.id
                  }
                });
              }}
            >
              <Video size={20} color="#006CFF" />
            </TouchableOpacity>
          )}
          <TouchableOpacity style={styles.profileButton} activeOpacity={0.7}>
            <Text style={styles.profileButtonText}>Ver Perfil</Text>
            <ArrowRight size={16} color="#FFFFFF" />
          </TouchableOpacity>
        </View>
      </View>
    </TouchableOpacity>
    
    {showExplainability && (
      <ExplainabilityCard lawyer={lawyer} />
    )}
    
    {showCurriculum && lawyer.curriculo_json && (
      <LawyerCurriculumCard 
        curriculo={lawyer.curriculo_json} 
        lawyerName={lawyer.nome} 
      />
    )}
  </View>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 24,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#9CA3AF',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.1,
    shadowRadius: 24,
    elevation: 5,
    borderWidth: 1,
    borderColor: '#F3F4F6',
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  avatarContainer: {
    position: 'relative',
  },
  avatar: {
    width: 64,
    height: 64,
    borderRadius: 32,
    borderWidth: 2,
    borderColor: '#FFFFFF'
  },
  onlineIndicator: {
    width: 16,
    height: 16,
    borderRadius: 8,
    backgroundColor: '#10B981',
    position: 'absolute',
    bottom: 2,
    right: 2,
    borderWidth: 2,
    borderColor: '#FFFFFF',
  },
  headerInfo: {
    flex: 1,
    marginLeft: 16,
  },
  name: {
    fontSize: 18,
    fontFamily: 'Inter-Bold',
    color: '#1F2937',
  },
  oab: {
    fontSize: 14,
    fontFamily: 'Inter-Regular',
    color: '#6B7280',
    marginTop: 2,
  },
  specialtyChip: {
    backgroundColor: '#EFF6FF',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 16,
    marginTop: 8,
    alignSelf: 'flex-start',
  },
  specialtyText: {
    color: '#3B82F6',
    fontSize: 12,
    fontFamily: 'Inter-Medium',
  },
  ratingBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#059669',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 16,
  },
  ratingText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontFamily: 'Inter-Bold',
    marginLeft: 4,
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    backgroundColor: '#F9FAFB',
    borderRadius: 16,
    padding: 16,
    marginTop: 16,
  },
  statItem: {
    alignItems: 'center',
    gap: 4,
  },
  statValue: {
    fontSize: 14,
    fontFamily: 'Inter-Bold',
    color: '#1F2937',
  },
  statLabel: {
    fontSize: 12,
    fontFamily: 'Inter-Regular',
    color: '#6B7280',
  },
  consultationRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 16,
    flexWrap: 'wrap',
  },
  consultationChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#F3F4F6',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 16,
  },
  consultationText: {
    fontSize: 12,
    fontFamily: 'Inter-Medium',
    color: '#4B5563',
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 20,
    paddingTop: 16,
    borderTopWidth: 1,
    borderTopColor: '#F3F4F6',
  },
  priceLabel: {
    fontSize: 14,
    fontFamily: 'Inter-Regular',
    color: '#6B7280',
  },
  priceValue: {
    fontSize: 20,
    fontFamily: 'Inter-Bold',
    color: '#1E40AF',
  },
  profileButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#1E40AF',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 12,
    gap: 8,
  },
  profileButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontFamily: 'Inter-Bold',
  },
  actionButtons: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  iconButton: {
    width: 44,
    height: 44,
    borderRadius: 12,
    backgroundColor: '#F0F9FF',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: '#E0F2FE',
  },
  reviewContainer: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: '#F9FAFB',
    borderRadius: 16,
    paddingHorizontal: 16,
    paddingVertical: 12,
    marginTop: 12,
  },
  reviewQuoteIcon: {
    marginRight: 8,
    marginTop: 2,
  },
  reviewText: {
    flex: 1,
    fontFamily: 'Inter-Regular',
    fontSize: 13,
    color: '#4B5563',
    fontStyle: 'italic',
  },
});

export default LawyerCard; 