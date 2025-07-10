import React from 'react';
import { View, Text, StyleSheet, Image, TouchableOpacity } from 'react-native';
import { MessageCircle, Video, Star } from 'lucide-react-native';

interface LawyerInfoCardProps {
  name: string;
  specialty: string;
  rating: number;
  experienceYears: number;
  avatarUrl?: string;
  onChatPress: () => void;
  onVideoPress: () => void;
}

const LawyerInfoCard: React.FC<LawyerInfoCardProps> = ({
  name,
  specialty,
  rating,
  experienceYears,
  avatarUrl,
  onChatPress,
  onVideoPress,
}) => {
  return (
    <View style={styles.container}>
      <Text style={styles.sectionTitle}>Advogado Responsável</Text>
      <View style={styles.card}>
        <Image 
          source={{ uri: avatarUrl || 'https://via.placeholder.com/150' }} 
          style={styles.avatar} 
        />
        <View style={styles.infoContainer}>
          <Text style={styles.name}>{name}</Text>
          <Text style={styles.specialty}>{specialty}</Text>
          <View style={styles.statsContainer}>
            <Star size={16} color="#FBBF24" fill="#FBBF24" />
            <Text style={styles.statsText}>{rating.toFixed(1)}</Text>
            <Text style={styles.statsSeparator}>•</Text>
            <Text style={styles.statsText}>{experienceYears} anos</Text>
          </View>
        </View>
        <View style={styles.actionsContainer}>
          <TouchableOpacity style={styles.actionButton} onPress={onChatPress}>
            <MessageCircle size={22} color="#334155" />
            <Text style={styles.actionText}>Chat</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.actionButton} onPress={onVideoPress}>
            <Video size={22} color="#334155" />
            <Text style={styles.actionText}>Vídeo</Text>
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 16,
    paddingTop: 16,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#1E293B',
    marginBottom: 16,
  },
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    shadowColor: '#9FB0C2',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 12,
    elevation: 4,
  },
  avatar: {
    width: 56,
    height: 56,
    borderRadius: 28,
    marginRight: 16,
  },
  infoContainer: {
    flex: 1,
  },
  name: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1E293B',
  },
  specialty: {
    fontSize: 14,
    color: '#64748B',
    marginTop: 2,
    marginBottom: 8,
  },
  statsContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statsText: {
    marginLeft: 6,
    fontSize: 14,
    color: '#475569',
    fontWeight: '500',
  },
  statsSeparator: {
    marginHorizontal: 8,
    color: '#CBD5E1',
  },
  actionsContainer: {
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 16,
    borderLeftWidth: 1,
    borderLeftColor: '#F1F5F9',
    paddingLeft: 16,
    marginLeft: 12,
  },
  actionButton: {
    alignItems: 'center',
  },
  actionText: {
    fontSize: 12,
    color: '#475569',
    marginTop: 4,
  },
});

export default LawyerInfoCard; 